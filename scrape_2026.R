
# scrape_2026.R -- 2026 GradCafe Scraper (New Site Structure)
# Each result = 3 TRs: main data / badges / notes

library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(httr)

# --- Configuration ---
queries <- c("political science", "international relations", "politics", "government", "comparative politics")
max_pages <- 50
base_url <- "https://www.thegradcafe.com/survey/index.php"
ua <- user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

# --- Parse one page ---
parse_page <- function(page) {
  all_trs <- html_nodes(page, "tbody tr")
  if (length(all_trs) == 0) return(NULL)
  
  results <- list()
  i <- 1
  
  while (i <= length(all_trs)) {
    tr <- all_trs[i]
    tr_class <- html_attr(tr, "class")
    
    # Skip border-none rows (badges/notes rows processed with their parent)
    if (!is.na(tr_class) && grepl("tw-border-none", tr_class)) {
      i <- i + 1
      next
    }
    
    # Main data row
    tds <- html_nodes(tr, "td")
    if (length(tds) < 4) {
      i <- i + 1
      next
    }
    
    # School
    school_node <- html_node(tds[1], "div.tw-font-medium")
    school <- if (!is.null(school_node) && length(school_node) > 0) html_text(school_node, trim = TRUE) else ""
    
    # Program + Degree
    prog_td <- tds[2]
    prog_span <- html_node(prog_td, "span")
    program <- if (!is.null(prog_span) && length(prog_span) > 0) html_text(prog_span, trim = TRUE) else ""
    degree_span <- html_nodes(prog_td, "span.tw-text-gray-500")
    degree <- if (length(degree_span) > 0) html_text(degree_span[1], trim = TRUE) else ""
    
    # Added date
    added_date <- str_squish(html_text(tds[3], trim = TRUE))
    
    # Decision (e.g. "Accepted on 14 Feb", "Rejected on 13 Feb")
    decision_div <- html_node(tds[4], "div")
    decision_text <- if (!is.null(decision_div) && length(decision_div) > 0) str_squish(html_text(decision_div, trim = TRUE)) else ""
    
    # Parse decision type and date
    decision_type <- case_when(
      grepl("Accepted", decision_text, ignore.case = TRUE) ~ "Accepted",
      grepl("Rejected", decision_text, ignore.case = TRUE) ~ "Rejected",
      grepl("Wait listed|Waitlisted", decision_text, ignore.case = TRUE) ~ "Wait listed",
      grepl("Interview", decision_text, ignore.case = TRUE) ~ "Interview",
      TRUE ~ "Other"
    )
    
    # Extract decision date like "on 14 Feb" -> parse
    dec_date_match <- str_match(decision_text, "on\\s+(\\d{1,2}\\s+[A-Za-z]+)")
    dec_date_str <- if (!is.na(dec_date_match[1, 2])) paste(dec_date_match[1, 2], "2026") else NA
    decision_date <- if (!is.na(dec_date_str)) dmy(dec_date_str, quiet = TRUE) else NA
    
    # Now check next TRs for badges and notes
    badges_text <- ""
    notes_text <- ""
    season <- ""
    status <- "Unknown"
    gpa <- NA_real_
    gre_v <- NA_real_
    gre_q <- NA_real_
    gre_aw <- NA_real_
    gre_total <- NA_real_
    
    # Badge row (i+1)
    if (i + 1 <= length(all_trs)) {
      next_tr <- all_trs[i + 1]
      next_class <- html_attr(next_tr, "class")
      if (!is.na(next_class) && grepl("tw-border-none", next_class)) {
        badge_divs <- html_nodes(next_tr, "div.tw-inline-flex")
        badge_texts <- html_text(badge_divs, trim = TRUE)
        badges_text <- paste(badge_texts, collapse = " | ")
        
        for (b in badge_texts) {
          b <- str_squish(b)
          if (grepl("^Fall|^Spring", b)) season <- b
          if (grepl("^International$", b)) status <- "International"
          if (grepl("^American$", b)) status <- "American"
          if (grepl("^GPA", b)) {
            gpa_val <- as.numeric(str_extract(b, "[0-9]+\\.?[0-9]*"))
            if (!is.na(gpa_val) && gpa_val <= 4.5) gpa <- gpa_val
          }
          if (grepl("^GRE V", b)) gre_v <- as.numeric(str_extract(b, "\\d+$"))
          if (grepl("^GRE Q", b)) gre_q <- as.numeric(str_extract(b, "\\d+$"))
          if (grepl("^GRE AW", b)) gre_aw <- as.numeric(str_extract(b, "[0-9]+\\.?[0-9]*$"))
          if (grepl("^GRE \\d{3}", b)) gre_total <- as.numeric(str_extract(b, "\\d{3}"))
        }
      }
    }
    
    # Notes row (i+2)
    if (i + 2 <= length(all_trs)) {
      notes_tr <- all_trs[i + 2]
      notes_class <- html_attr(notes_tr, "class")
      if (!is.na(notes_class) && grepl("tw-border-none", notes_class)) {
        notes_p <- html_node(notes_tr, "p")
        if (!is.null(notes_p) && length(notes_p) > 0) {
          notes_text <- str_squish(html_text(notes_p, trim = TRUE))
        }
      }
    }
    
    results[[length(results) + 1]] <- data.frame(
      school = school,
      program = program,
      degree = degree,
      added_date = added_date,
      decision_type = decision_type,
      decision_text = decision_text,
      decision_date = as.character(decision_date),
      season = season,
      status = status,
      gpa = gpa,
      gre_v = gre_v,
      gre_q = gre_q,
      gre_aw = gre_aw,
      gre_total = gre_total,
      notes = notes_text,
      badges = badges_text,
      stringsAsFactors = FALSE
    )
    
    i <- i + 1
  }
  
  if (length(results) > 0) bind_rows(results) else NULL
}

# --- Scrape ---
scrape_query <- function(q) {
  cat("\n--- Query:", q, "---\n")
  rows_list <- list()
  
  for (p in 1:max_pages) {
    # Use season=F26 to filter Fall 2026, and page parameter
    url <- paste0(base_url, "?q=", URLencode(q), "&season=F26&t=a&o=&p=1&page=", p)
    cat(p, ".")
    
    tryCatch({
      resp <- GET(url, ua)
      if (status_code(resp) != 200) {
        cat("x(", status_code(resp), ")")
        break
      }
      
      page <- read_html(content(resp, "text", encoding = "UTF-8"))
      df_page <- parse_page(page)
      
      if (is.null(df_page) || nrow(df_page) == 0) {
        cat("[empty]")
        break
      }
      
      df_page$query_term <- q
      rows_list[[length(rows_list) + 1]] <- df_page
      
      cat("(", nrow(df_page), ")")
      
    }, error = function(e) {
      cat("E(", conditionMessage(e), ")")
    })
    
    Sys.sleep(runif(1, 0.3, 0.7))
  }
  
  if (length(rows_list) > 0) bind_rows(rows_list) else data.frame()
}

cat("=== Starting 2026 GradCafe Scraper (v2) ===\n")
results <- lapply(queries, scrape_query)
raw_data <- bind_rows(results)

cat("\n\nTotal scraped rows:", nrow(raw_data), "\n")

if (nrow(raw_data) == 0) {
  cat("ERROR: No data scraped!\n")
  quit(status = 1)
}

# --- Dedup + Clean ---
cat("Deduplicating...\n")
clean_data <- raw_data %>%
  distinct(school, decision_text, notes, added_date, .keep_all = TRUE)

cat("After dedup:", nrow(clean_data), "\n")

# Filter PhD only
cat("Filtering PhD...\n")
clean_data <- clean_data %>% filter(degree == "PhD")
cat("PhD count:", nrow(clean_data), "\n")

# Parse decision_date properly
clean_data <- clean_data %>%
  mutate(
    decision_date = as.Date(decision_date),
    decision_year = year(decision_date),
    decision_month_day = decision_date
  )

# --- Subfield extraction from notes ---
clean_data <- clean_data %>%
  mutate(
    subfield = case_when(
      str_detect(notes, regex("\\bCP\\b|[Cc]omparative\\s+[Pp]olitic", ignore_case = FALSE)) ~ "CP",
      str_detect(notes, regex("\\bIR\\b|[Ii]nternational\\s+[Rr]elation", ignore_case = FALSE)) ~ "IR",
      str_detect(notes, regex("\\bAP\\b\\s*(sub|field)?|[Aa]merican\\s+[Pp]olitic|[Aa]merican\\s+subfield", ignore_case = FALSE)) ~ "AP",
      str_detect(notes, regex("[Pp]olitical\\s+[Tt]heory|\\bTheory\\b\\s*(sub)?|\\bPT\\b\\s*(sub|field)?", ignore_case = FALSE)) ~ "Theory",
      str_detect(notes, regex("[Mm]ethods|[Mm]ethodology|[Qq]uant", ignore_case = FALSE)) ~ "Methods",
      str_detect(notes, regex("[Pp]olitical\\s+[Pp]sychology|[Pp]olitical\\s+[Bb]ehavior", ignore_case = FALSE)) ~ "Psych/Behavior",
      str_detect(notes, regex("[Pp]ublic\\s+[Ll]aw|[Pp]ublic\\s+[Pp]olicy", ignore_case = FALSE)) ~ "Public Law/Policy",
      TRUE ~ "Unknown"
    )
  )

# --- Institution normalization ---
clean_data <- clean_data %>%
  mutate(
    institution = case_when(
      grepl("San Diego|UCSD", school, ignore.case = TRUE) ~ "UCSD",
      grepl("Los Angeles|UCLA", school, ignore.case = TRUE) ~ "UCLA",
      grepl("Berkeley", school, ignore.case = TRUE) ~ "UC Berkeley",
      grepl("Stanford", school, ignore.case = TRUE) ~ "Stanford",
      grepl("Princeton", school, ignore.case = TRUE) ~ "Princeton",
      grepl("Harvard", school, ignore.case = TRUE) ~ "Harvard",
      grepl("Yale", school, ignore.case = TRUE) ~ "Yale",
      grepl("Cornell", school, ignore.case = TRUE) ~ "Cornell",
      grepl("Columbia", school, ignore.case = TRUE) ~ "Columbia",
      grepl("Chicago", school, ignore.case = TRUE) ~ "UChicago",
      grepl("Michigan", school, ignore.case = TRUE) ~ "Michigan",
      grepl("Pennsylvania|U Penn|UPenn", school, ignore.case = TRUE) ~ "UPenn",
      grepl("Duke", school, ignore.case = TRUE) ~ "Duke",
      grepl("MIT|Massachusetts Institute", school, ignore.case = TRUE) ~ "MIT",
      grepl("Northwestern", school, ignore.case = TRUE) ~ "Northwestern",
      grepl("NYU|New York University", school, ignore.case = TRUE) ~ "NYU",
      grepl("Georgetown", school, ignore.case = TRUE) ~ "Georgetown",
      grepl("Johns Hopkins|JHU", school, ignore.case = TRUE) ~ "JHU",
      grepl("Wisconsin", school, ignore.case = TRUE) ~ "UW-Madison",
      grepl("Texas.*Austin|UT Austin", school, ignore.case = TRUE) ~ "UT Austin",
      grepl("Washington University", school, ignore.case = TRUE) ~ "WashU",
      grepl("Ohio State", school, ignore.case = TRUE) ~ "Ohio State",
      grepl("Emory", school, ignore.case = TRUE) ~ "Emory",
      grepl("Brown", school, ignore.case = TRUE) ~ "Brown",
      grepl("Vanderbilt", school, ignore.case = TRUE) ~ "Vanderbilt",
      grepl("Rice", school, ignore.case = TRUE) ~ "Rice",
      grepl("Notre Dame", school, ignore.case = TRUE) ~ "Notre Dame",
      grepl("Indiana", school, ignore.case = TRUE) ~ "Indiana",
      grepl("UNC|Chapel Hill", school, ignore.case = TRUE) ~ "UNC",
      grepl("Virginia(?!.*Tech)", school, ignore.case = TRUE, perl = TRUE) ~ "UVA",
      grepl("Maryland", school, ignore.case = TRUE) ~ "UMD",
      grepl("Minnesota", school, ignore.case = TRUE) ~ "Minnesota",
      grepl("Penn State|Pennsylvania State", school, ignore.case = TRUE) ~ "Penn State",
      grepl("Rutgers", school, ignore.case = TRUE) ~ "Rutgers",
      grepl("Purdue", school, ignore.case = TRUE) ~ "Purdue",
      grepl("Syracuse", school, ignore.case = TRUE) ~ "Syracuse",
      grepl("Arizona", school, ignore.case = TRUE) ~ "Arizona",
      grepl("Georgia(?!.*Tech)", school, ignore.case = TRUE, perl = TRUE) ~ "UGA",
      grepl("LSE|London School", school, ignore.case = TRUE) ~ "LSE",
      grepl("Oxford", school, ignore.case = TRUE) ~ "Oxford",
      grepl("Cambridge", school, ignore.case = TRUE) ~ "Cambridge",
      grepl("Stony Brook", school, ignore.case = TRUE) ~ "Stony Brook",
      grepl("Rochester", school, ignore.case = TRUE) ~ "Rochester",
      grepl("Florida State", school, ignore.case = TRUE) ~ "FSU",
      grepl("George Washington", school, ignore.case = TRUE) ~ "GWU",
      grepl("American University", school, ignore.case = TRUE) ~ "American U",
      grepl("Alabama", school, ignore.case = TRUE) ~ "Alabama",
      TRUE ~ school  # Keep original name
    )
  )

# --- Save ---
data <- clean_data
save(data, file = "scraped_2026.Rdata")

cat("\n=== RESULTS ===\n")
cat("Total 2026 PhD results:", nrow(data), "\n\n")

cat("Decision breakdown:\n")
print(table(data$decision_type))

cat("\nSubfield breakdown:\n")
print(table(data$subfield))

cat("\nNationality/Status breakdown:\n")
print(table(data$status))

cat("\nTop 20 institutions:\n")
print(head(sort(table(data$institution), decreasing = TRUE), 20))

cat("\nDate range:", as.character(min(data$decision_date, na.rm = TRUE)), 
    "to", as.character(max(data$decision_date, na.rm = TRUE)), "\n")

cat("\nSaved to scraped_2026.Rdata\n")
cat("Done!\n")
