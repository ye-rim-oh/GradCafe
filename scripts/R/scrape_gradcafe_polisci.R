# ============================================================
# GradCafe Political Science Scraper
# Purpose: Scrape current GradCafe Inertia payloads without touching
#          the legacy HTML-table scraper or app data files.
# Inputs:  The GradCafe survey pages
# Outputs: output/polisci_analysis/gradcafe_polisci_2016_2026_raw.rds
#          output/polisci_analysis/gradcafe_polisci_2016_2026_clean.rds
#          output/polisci_analysis/gradcafe_polisci_2016_2026_clean.csv
#          output/polisci_analysis/scrape_summary.md
# ============================================================

suppressPackageStartupMessages({
  library(rvest)
  library(httr)
  library(jsonlite)
  library(dplyr)
  library(stringr)
  library(lubridate)
})

source(file.path("scripts", "R", "institution_normalization.R"), encoding = "UTF-8")

`%+%` <- function(x, y) paste0(x, y)

set.seed(42)

out_dir <- "output/polisci_analysis"
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

base_url <- "https://www.thegradcafe.com/survey"
queries <- c("political science", "international relations", "politics", "government")
target_years <- 2016:2026
season_titles <- paste("Fall", target_years)
season_codes <- paste0("F", substr(target_years, 3, 4))
names(season_codes) <- target_years
start_date <- as.Date("2016-01-01")
end_date <- Sys.Date()
max_pages_per_query <- as.integer(Sys.getenv("GRADCAFE_MAX_PAGES", "2000"))
supplement_pages_per_query <- as.integer(Sys.getenv("GRADCAFE_SUPPLEMENT_PAGES", "80"))
sleep_min <- as.numeric(Sys.getenv("GRADCAFE_SLEEP_MIN", "0.15"))
sleep_max <- as.numeric(Sys.getenv("GRADCAFE_SLEEP_MAX", "0.35"))

ua <- user_agent(
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 " %+%
    "(KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
)

null_to_na <- function(x) {
  if (is.null(x) || length(x) == 0) NA else x
}

scalar_chr <- function(x) {
  x <- null_to_na(x)
  if (is.na(x)) NA_character_ else as.character(x)
}

scalar_num <- function(x) {
  x <- suppressWarnings(as.numeric(null_to_na(x)))
  ifelse(is.na(x) || x == 0, NA_real_, x)
}

scalar_date <- function(x) {
  x <- scalar_chr(x)
  if (is.na(x)) as.Date(NA) else as.Date(substr(x, 1, 10))
}

status_label <- function(x) {
  x <- scalar_chr(x)
  if (is.na(x) || !(x %in% c("American", "International", "Other"))) "Unknown" else x
}

encode_query <- function(params) {
  paste(
    sprintf("%s=%s", names(params), vapply(params, URLencode, character(1), reserved = TRUE)),
    collapse = "&"
  )
}

survey_url <- function(query, page, extra = list()) {
  params <- c(list(q = query, sort = "newest", page = as.character(page)), extra)
  paste0(base_url, "?", encode_query(params))
}

extract_payload <- function(html_text) {
  page <- read_html(html_text)
  node <- html_node(page, "[data-page]")
  if (is.null(node) || length(node) == 0) {
    stop("No data-page JSON payload found.")
  }
  fromJSON(html_attr(node, "data-page"), simplifyVector = FALSE)
}

record_to_row <- function(record, query_term, source_url, source_page, source_mode) {
  decision_date <- scalar_date(record$date_of_notification)
  added_date <- scalar_date(record$created_at)
  decision <- scalar_chr(record$decision)
  decision_text <- scalar_chr(record$decision_label)
  if (is.na(decision_text) && !is.na(decision) && !is.na(decision_date)) {
    decision_text <- paste(decision, "on", format(decision_date, "%b %d"))
  }

  gpa <- scalar_num(record$ugpa)
  if (!is.na(gpa) && gpa > 4.5) gpa <- NA_real_

  data.frame(
    result_id = scalar_chr(record$id),
    school = clean_institution_text(scalar_chr(record$school)),
    program = scalar_chr(record$program),
    degree = scalar_chr(record$level),
    decision_type = decision,
    decision_text = decision_text,
    decision_date = as.character(decision_date),
    added_date = as.character(added_date),
    season = scalar_chr(record$season),
    status = status_label(record$status),
    gpa = gpa,
    gre_v = scalar_num(record$grev),
    gre_q = scalar_num(record$greq),
    gre_aw = scalar_num(record$grew),
    gre_total = scalar_num(record$gres),
    notes = scalar_chr(record$notes),
    query_term = query_term,
    source_mode = source_mode,
    source_url = source_url,
    source_page = source_page,
    stringsAsFactors = FALSE
  )
}

fetch_page <- function(query, page, extra = list(), source_mode = "query") {
  url <- survey_url(query, page, extra)
  resp <- GET(url, ua)
  if (status_code(resp) != 200) {
    stop("HTTP ", status_code(resp), " for ", url)
  }
  payload <- extract_payload(content(resp, "text", encoding = "UTF-8"))
  rows <- payload$props$results$data
  meta <- payload$props$results$meta
  data <- if (length(rows) == 0) {
    data.frame()
  } else {
    bind_rows(lapply(rows, record_to_row, query_term = query, source_url = url, source_page = page, source_mode = source_mode))
  }
  list(data = data, meta = meta, url = url)
}

scrape_query_season <- function(query, season_code) {
  message("\n--- Query: ", query, " | Season: ", season_code, " ---")
  collected <- list()
  page <- 1
  last_page <- Inf

  repeat {
    if (page > max_pages_per_query || page > last_page) break

    result <- tryCatch(fetch_page(query, page, extra = list(season = season_code), source_mode = "season"), error = function(e) {
      message("page ", page, " error: ", conditionMessage(e))
      NULL
    })
    if (is.null(result) || nrow(result$data) == 0) break

    if (!is.null(result$meta$last_page)) {
      last_page <- result$meta$last_page
    }

    d <- result$data %>%
      mutate(decision_date_parsed = as.Date(decision_date))

    collected[[length(collected) + 1]] <- d %>% select(-decision_date_parsed)

    newest <- suppressWarnings(max(d$decision_date_parsed, na.rm = TRUE))
    oldest <- suppressWarnings(min(d$decision_date_parsed, na.rm = TRUE))
    message("page ", page, "/", last_page, ": ", nrow(d), " rows, dates ", oldest, " to ", newest)

    page <- page + 1
    Sys.sleep(runif(1, sleep_min, sleep_max))
  }

  if (length(collected) == 0) data.frame() else bind_rows(collected)
}

scrape_query_supplement <- function(query) {
  message("\n--- Query supplement: ", query, " ---")
  collected <- list()
  page <- 1
  last_page <- Inf

  repeat {
    if (page > supplement_pages_per_query || page > last_page) break

    result <- tryCatch(fetch_page(query, page, source_mode = "no-season-supplement"), error = function(e) {
      message("supplement page ", page, " error: ", conditionMessage(e))
      NULL
    })
    if (is.null(result) || nrow(result$data) == 0) break

    if (!is.null(result$meta$last_page)) {
      last_page <- result$meta$last_page
    }

    d <- result$data %>%
      mutate(decision_date_parsed = as.Date(decision_date))

    collected[[length(collected) + 1]] <- d %>% select(-decision_date_parsed)

    newest <- suppressWarnings(max(d$decision_date_parsed, na.rm = TRUE))
    oldest <- suppressWarnings(min(d$decision_date_parsed, na.rm = TRUE))
    message("supplement page ", page, "/", last_page, ": ", nrow(d), " rows, dates ", oldest, " to ", newest)

    page <- page + 1
    Sys.sleep(runif(1, sleep_min, sleep_max))
  }

  if (length(collected) == 0) data.frame() else bind_rows(collected)
}

classify_subfield <- function(notes) {
  notes <- ifelse(is.na(notes), "", notes)
  case_when(
    str_detect(notes, regex("\\bCP\\b|comparative\\s+politic", ignore_case = TRUE)) ~ "CP",
    str_detect(notes, regex("\\bIR\\b|international\\s+relation", ignore_case = TRUE)) ~ "IR",
    str_detect(notes, regex("\\bAP\\b\\s*(sub|field)?|american\\s+politic|american\\s+subfield", ignore_case = TRUE)) ~ "AP",
    str_detect(notes, regex("political\\s+theory|\\bTheory\\b\\s*(sub)?|\\bPT\\b\\s*(sub|field)?", ignore_case = TRUE)) ~ "Theory",
    str_detect(notes, regex("methods|methodology|quant", ignore_case = TRUE)) ~ "Methods",
    str_detect(notes, regex("political\\s+psychology|political\\s+behavior", ignore_case = TRUE)) ~ "Psych/Behavior",
    str_detect(notes, regex("public\\s+law|public\\s+policy", ignore_case = TRUE)) ~ "Public Law/Policy",
    TRUE ~ "Unknown"
  )
}

normalize_major_program <- function(program) {
  p <- str_to_lower(ifelse(is.na(program), "", program))
  p <- str_replace_all(p, "\\([^)]*\\)", " ")
  p <- str_replace_all(p, "\\b(department|deparment)\\s+of\\s+", " ")
  p <- str_replace_all(p, "^(phd|dphil)\\s+in\\s+", "")
  p <- str_replace_all(p, "^(phd|dphil)\\s+", "")
  p <- str_replace_all(p, ",?\\s*phd\\b.*$", "")
  p <- str_replace_all(p, "\\bpoir\\b", "political science and international relations")
  p <- str_replace_all(p, "government\\s+political\\s+science", "government and political science")
  p <- str_replace_all(p, "political\\s+science\\s+government", "political science and government")
  p <- str_replace_all(p, "international\\s+relations\\s+political\\s+science", "international relations and political science")
  p <- str_replace_all(p, "[,/&]", " and ")
  p <- str_replace_all(p, "\\s+", " ")
  str_squish(p)
}

is_target_major <- function(program) {
  p <- normalize_major_program(program)
  allowed <- c("political science", "international relations", "politics", "government")
  vapply(p, FUN.VALUE = logical(1), FUN = function(one_program) {
    if (is.na(one_program) || one_program == "") return(FALSE)
    parts <- str_split(one_program, "\\band\\b", simplify = FALSE)[[1]]
    parts <- str_squish(parts)
    parts <- parts[parts != ""]
    length(parts) > 0 && all(parts %in% allowed)
  })
}

season_jobs <- expand.grid(query = queries, year = target_years, stringsAsFactors = FALSE)
season_data <- bind_rows(lapply(seq_len(nrow(season_jobs)), function(i) {
  scrape_query_season(season_jobs$query[i], season_codes[as.character(season_jobs$year[i])])
}))

supplement_data <- bind_rows(lapply(queries, scrape_query_supplement))

raw_data <- bind_rows(season_data, supplement_data)
saveRDS(raw_data, file.path(out_dir, "gradcafe_polisci_2016_2026_raw.rds"))

clean_data <- raw_data %>%
  mutate(
    decision_date = as.Date(decision_date),
    added_date = as.Date(added_date),
    school = clean_institution_text(school),
    decision_year = year(decision_date),
    scrape_year = as.integer(str_extract(season, "\\d{4}$")),
    normalized_program = normalize_major_program(program)
  ) %>%
  filter(
    degree == "PhD",
    season %in% season_titles,
    decision_date >= start_date,
    decision_date <= end_date,
    is_target_major(program),
    valid_institution_school(school)
  ) %>%
  distinct(result_id, .keep_all = TRUE) %>%
  mutate(
    institution_raw = school,
    institution = normalize_institution(school),
    subfield = classify_subfield(notes)
  ) %>%
  arrange(desc(decision_date), school, program)

saveRDS(clean_data, file.path(out_dir, "gradcafe_polisci_2016_2026_clean.rds"))
write.csv(clean_data, file.path(out_dir, "gradcafe_polisci_2016_2026_clean.csv"), row.names = FALSE, fileEncoding = "UTF-8")

summary_by_year <- clean_data %>%
  group_by(scrape_year) %>%
  summarise(
    total = n(),
    accepted = sum(decision_type == "Accepted", na.rm = TRUE),
    rejected = sum(decision_type == "Rejected", na.rm = TRUE),
    interview = sum(decision_type == "Interview", na.rm = TRUE),
    wait_listed = sum(decision_type == "Wait listed", na.rm = TRUE),
    other = sum(!(decision_type %in% c("Accepted", "Rejected", "Interview", "Wait listed")), na.rm = TRUE),
    .groups = "drop"
  ) %>%
  arrange(scrape_year)

summary_by_query <- raw_data %>%
  count(query_term, name = "raw_rows") %>%
  arrange(desc(raw_rows))

saveRDS(summary_by_year, file.path(out_dir, "summary_by_year.rds"))
saveRDS(summary_by_query, file.path(out_dir, "summary_by_query.rds"))

md <- c(
  "# GradCafe Political Science Scrape Summary",
  "",
  paste0("Run date: ", Sys.Date()),
  paste0("Query terms: ", paste(queries, collapse = ", ")),
  paste0("Target seasons: ", min(season_titles), " to ", max(season_titles)),
  paste0("Raw rows: ", nrow(raw_data)),
  paste0("Clean PhD target-major rows: ", nrow(clean_data)),
  paste0("Latest decision date: ", max(clean_data$decision_date, na.rm = TRUE)),
  "",
  "## Year Counts",
  "",
  paste(capture.output(print(summary_by_year)), collapse = "\n"),
  "",
  "## Raw Rows by Query",
  "",
  paste(capture.output(print(summary_by_query)), collapse = "\n")
)
writeLines(md, file.path(out_dir, "scrape_summary.md"), useBytes = TRUE)

cat("Raw rows:", nrow(raw_data), "\n")
cat("Clean rows:", nrow(clean_data), "\n")
cat("Latest decision date:", as.character(max(clean_data$decision_date, na.rm = TRUE)), "\n")
