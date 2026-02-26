
# Scraping.R (Robust V9 - Fix Date Parsing)

library(rvest)
library(dplyr)
library(stringr)
library(lubridate)
library(readr)
library(httr)

# --- Configuration ---
queries <- c("political science", "international relations", "politics", "government")
start_year <- 2020
end_year <- 2026
max_pages <- 50 

base_url <- "https://www.thegradcafe.com/survey/index.php"
ua <- user_agent("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36")

# --- Scraping ---
scrape_query <- function(q) {
  cat("\n--- Query:", q, "---\n")
  rows_list <- list()
  
  for (p in 1:max_pages) {
    url <- paste0(base_url, "?q=", URLencode(q), "&t=a&o=&p=", p)
    cat(p, ".")
    
    tryCatch({
      # Use httr GET directly as it seems more robust
      resp <- GET(url, ua)
      if (status_code(resp) != 200) {
        cat("x")
        break
      }
      
      page <- read_html(content(resp, "text"))
      row_nodes <- html_nodes(page, "table tr")
      
      if (length(row_nodes) == 0) {
        cat("x")
        break
      }
      
      p_data <- lapply(row_nodes, function(node) {
        # Get full text
        txt <- html_text(node, trim=TRUE)
        txt <- str_squish(txt)
        if (nchar(txt) < 10) return(NULL)
        
        # Check if header
        if (str_detect(txt, "^School|^Institution")) return(NULL)
        
        list(full_text = txt)
      })
      
      p_data <- p_data[!sapply(p_data, is.null)]
      
      if (length(p_data) > 0) {
        df_page <- bind_rows(p_data)
        df_page$query_term <- q
        
        rows_list[[length(rows_list) + 1]] <- df_page
        
        # Early Stop Check
        # Extract 4-digit year
        years <- str_extract(df_page$full_text, "\\d{4}")
        y <- as.numeric(years)
        valid_y <- y[!is.na(y)]
        
        # Heuristic: if scraping sorted by Newest, and we see years < start_year
        if (length(valid_y) > 0 && all(valid_y < start_year)) {
          cat(" [Old]")
          return(bind_rows(rows_list)) 
        }
      }
      
    }, error = function(e) {
      cat("E")
    })
    
    Sys.sleep(0.5)
  }
  
  bind_rows(rows_list)
}

cat("Running Scraper...\n")
results <- lapply(queries, scrape_query)
raw_data <- bind_rows(results)

cat("\nScraped", nrow(raw_data), "rows.\n")
if (nrow(raw_data) > 0) {
    cat("Sample Row 1:", raw_data$full_text[1], "\n")
}

# --- Cleaning ---
cat("Cleaning...\n")

clean_data <- raw_data %>%
  distinct(full_text, .keep_all=TRUE) %>%
  mutate(
    # 1. Degree
    degree = case_when(
      str_detect(full_text, regex("PhD|Ph\\.D", ignore_case=T)) ~ "PhD",
      str_detect(full_text, regex("Masters|MA|MS|MPhil", ignore_case=T)) ~ "Masters",
      TRUE ~ "Other"
    ),
    
    # 2. Date
    # Support "February 11, 2026" (MDY) and "11 Feb 2026" (DMY)
    # Extract date-like string
    date_str_mdy = str_extract(full_text, "[A-Za-z]+\\s+\\d{1,2},?\\s+\\d{4}"),
    date_str_dmy = str_extract(full_text, "\\d{1,2}\\s+[A-Za-z]+\\s+\\d{4}"),
    
    decision_date = parse_date_time(coalesce(date_str_mdy, date_str_dmy), 
                                    orders = c("mdy", "dmy", "BdY", "Bdy"), quiet=TRUE),
    
    decision_year = year(decision_date),
    decision_month_day = decision_date,
    
    # 3. Decision
    decision = case_when(
      str_detect(full_text, regex("Accepted", ignore_case=T)) ~ "Accepted",
      str_detect(full_text, regex("Rejected", ignore_case=T)) ~ "Rejected",
      str_detect(full_text, regex("Wait listed|Waitlisted", ignore_case=T)) ~ "Wait listed",
      str_detect(full_text, regex("Interview", ignore_case=T)) ~ "Interview",
      TRUE ~ "Other"
    ),
    
    # 4. Status
    status_parsed = case_when(
      str_detect(full_text, regex("\\bIntl\\b|International", ignore_case=T)) ~ "International",
      str_detect(full_text, regex("\\bAmerican\\b|Domestic", ignore_case=T)) ~ "American",
      TRUE ~ "Unknown"
    ),
    
    # 5. GRE
    gre_v = as.numeric(str_match(full_text, regex("GRE V\\s*:?\\s*(\\d+)", ignore_case=T))[,2]),
    gre_q = as.numeric(str_match(full_text, regex("GRE Q\\s*:?\\s*(\\d+)", ignore_case=T))[,2]),
    gre_w = as.numeric(str_match(full_text, regex("GRE AW\\s*:?\\s*(\\d\\.?\\d*)", ignore_case=T))[,2]),
    gre_total = as.numeric(str_match(full_text, regex("\\b(3[0-3][0-9]|340)\\b"))[,2]),
    
    GPA = as.numeric(str_match(full_text, regex("GPA\\s*:?\\s*(\\d\\.\\d+)", ignore_case=T))[,2]),
    
    # Institution Normalization
    institution = case_when(
      str_detect(full_text, regex("San Diego|UCSD", ignore_case=T)) ~ "University of California, San Diego",
      str_detect(full_text, regex("Los Angeles|UCLA", ignore_case=T)) ~ "University of California, Los Angeles",
      str_detect(full_text, regex("Berkeley|UCB", ignore_case=T)) ~ "University of California, Berkeley",
      str_detect(full_text, regex("Stanford", ignore_case=T)) ~ "Stanford University",
      str_detect(full_text, regex("Princeton", ignore_case=T)) ~ "Princeton University",
      str_detect(full_text, regex("Harvard", ignore_case=T)) ~ "Harvard University",
      str_detect(full_text, regex("Yale", ignore_case=T)) ~ "Yale University",
      str_detect(full_text, regex("Cornell", ignore_case=T)) ~ "Cornell University",
      str_detect(full_text, regex("Columbia", ignore_case=T)) ~ "Columbia University",
      str_detect(full_text, regex("Chicago", ignore_case=T)) ~ "University of Chicago",
      str_detect(full_text, regex("Michigan", ignore_case=T)) ~ "University of Michigan",
      str_detect(full_text, regex("Pennsylvania|UPenn", ignore_case=T)) ~ "University of Pennsylvania",
      str_detect(full_text, regex("Duke", ignore_case=T)) ~ "Duke University",
      str_detect(full_text, regex("MIT|Massachusetts Institute of Technology", ignore_case=T)) ~ "MIT",
      str_detect(full_text, regex("Northwestern", ignore_case=T)) ~ "Northwestern University",
      str_detect(full_text, regex("New York University|NYU", ignore_case=T)) ~ "New York University",
      str_detect(full_text, regex("Georgetown", ignore_case=T)) ~ "Georgetown University",
      str_detect(full_text, regex("Johns Hopkins|JHU", ignore_case=T)) ~ "Johns Hopkins University",
      str_detect(full_text, regex("Wisconsin.*Madison", ignore_case=T)) ~ "University of Wisconsin-Madison",
      str_detect(full_text, regex("Texas.*Austin|UT Austin", ignore_case=T)) ~ "University of Texas at Austin",
      str_detect(full_text, regex("Washington University", ignore_case=T)) ~ "Washington University in St. Louis",
      str_detect(full_text, regex("London School of Economics|LSE", ignore_case=T)) ~ "London School of Economics",
      str_detect(full_text, regex("Oxford", ignore_case=T)) ~ "University of Oxford",
      str_detect(full_text, regex("Cambridge", ignore_case=T)) ~ "University of Cambridge",
      TRUE ~ "Other"
    ),
    
    # Synthesize
    notes_raw = full_text,
    program_raw = full_text
  ) 

# GRE Imputation
clean_data <- clean_data %>%
  mutate(
    GRE_V = if_else(is.na(gre_v) & !is.na(gre_total) & !is.na(gre_q), gre_total - gre_q, gre_v),
    GRE_Q = if_else(is.na(gre_q) & !is.na(gre_total) & !is.na(gre_v), gre_total - gre_v, gre_q),
    GRE_W = gre_w
  ) %>%
  select(-gre_v, -gre_q, -gre_w, -gre_total)

cat("Filtering PhD Only...\n")
clean_data <- clean_data %>% filter(degree == "PhD")

cat("Filtering Year Range (2020-2026)...\n")
clean_data <- clean_data %>% filter(!is.na(decision_year) & decision_year >= start_year & decision_year <= end_year)

cat("Cleaned Count:", nrow(clean_data), "\n")

# --- Save ---
data <- clean_data
save(data, file = "cleaned_data.Rdata")
cat("Saved to cleaned_data.Rdata\n")
