# ============================================================
# Refresh Political Science Outputs
# Purpose: Re-apply local cleaning/normalization to an existing
#          GradCafe scrape without hitting GradCafe again.
# Outputs: output/polisci_analysis/gradcafe_polisci_2016_2026_clean.*
#          output/polisci_analysis/summary_by_*.rds
#          output/polisci_analysis/scrape_summary.md
# ============================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(stringr)
})

source(file.path("scripts", "R", "institution_normalization.R"), encoding = "UTF-8")

out_dir <- "output/polisci_analysis"
raw_path <- file.path(out_dir, "gradcafe_polisci_2016_2026_raw.rds")
raw_csv_path <- file.path(out_dir, "gradcafe_polisci_2016_2026_raw.csv")
clean_path <- file.path(out_dir, "gradcafe_polisci_2016_2026_clean.rds")

queries <- c("political science", "international relations", "politics", "government")
target_years <- 2016:2026
season_titles <- paste("Fall", target_years)
start_date <- as.Date("2016-01-01")
end_date <- Sys.Date()

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

use_raw_csv <- file.exists(raw_csv_path) && (
  !file.exists(raw_path) || file.info(raw_csv_path)$mtime >= file.info(raw_path)$mtime
)

raw_data <- if (use_raw_csv) {
  read.csv(raw_csv_path, stringsAsFactors = FALSE, fileEncoding = "UTF-8", na.strings = c("", "NA"))
} else if (file.exists(raw_path)) {
  readRDS(raw_path)
} else {
  stop("No raw GradCafe data found at ", raw_path, " or ", raw_csv_path, call. = FALSE)
}

saveRDS(raw_data, raw_path)

clean_data <- raw_data %>%
  mutate(
    decision_date = as.Date(decision_date),
    added_date = as.Date(added_date),
    school = clean_institution_text(school),
    decision_year = year(decision_date),
    scrape_year = as.integer(str_extract(season, "\\d{4}$")),
    normalized_program = normalize_major_program(program),
    gre_total_from_q = !is.na(gre_q) & gre_q > 170 & !is.na(gre_v) & gre_v >= 130 & gre_v <= 170,
    gre_total = ifelse(gre_total_from_q & is.na(gre_total), gre_q, gre_total),
    gre_q = ifelse(gre_total_from_q & (gre_total - gre_v) >= 130 & (gre_total - gre_v) <= 170, gre_total - gre_v, gre_q)
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
  select(-gre_total_from_q) %>%
  arrange(desc(decision_date), institution, program)

saveRDS(clean_data, clean_path)
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
  paste0("Unique canonical institutions: ", length(unique(clean_data$institution))),
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
cat("Unique institutions:", length(unique(clean_data$institution)), "\n")
cat("Latest decision date:", as.character(max(clean_data$decision_date, na.rm = TRUE)), "\n")
