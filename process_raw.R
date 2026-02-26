
# process_raw.R
load("raw_scraped_data.Rdata")
library(dplyr)
library(stringr)
library(lubridate)
library(readr)

cat("Total Raw Rows:", nrow(raw_data), "\n")

# Squish whitespace in all character columns
raw_data <- raw_data %>%
  mutate(across(where(is.character), str_squish))

# Inspect after squish
cat("\nSample Full Text (After Squish):\n")
print(raw_data$full_text[1])

# Clean
clean_data <- raw_data %>%
  distinct(institution, program_raw, decision_raw, notes_raw, .keep_all = TRUE) %>%
  mutate(
    # Degree from full text
    degree = case_when(
      str_detect(full_text, regex("PhD|Ph\\.D", ignore_case=T)) ~ "PhD",
      str_detect(full_text, regex("Masters|MA|MS|MPhil", ignore_case=T)) ~ "Masters",
      TRUE ~ "Other"
    ),
    
    # Date extraction (regex from full text)
    date_str = str_extract(full_text, "\\d{1,2}\\s+[A-Za-z]{3}\\s+\\d{4}"),
    decision_date = dmy(date_str, quiet=TRUE),
    decision_year = year(decision_date),
    decision_month_day = decision_date,
    
    # Decision from full text
    decision = case_when(
      str_detect(full_text, regex("Accepted", ignore_case=T)) ~ "Accepted",
      str_detect(full_text, regex("Rejected", ignore_case=T)) ~ "Rejected",
      str_detect(full_text, regex("Wait listed|Waitlisted", ignore_case=T)) ~ "Wait listed",
      str_detect(full_text, regex("Interview", ignore_case=T)) ~ "Interview",
      TRUE ~ "Other"
    ),
    
    # Institution from full text (Heuristic: extract known names or assume Col 1)
    institution = institution # Keep original attempt or normalize
  )

cat("\nDegree Breakdown:\n")
print(table(clean_data$degree))

cat("\nYear Breakdown:\n")
print(table(clean_data$decision_year))

# Filter
final_data <- clean_data %>%
  filter(degree == "PhD") %>%
  filter(!is.na(decision_year) & decision_year >= 2020 & decision_year <= 2026)

cat("\nFinal Count (PhD 2020-2026):", nrow(final_data), "\n")

if (nrow(final_data) > 0) {
    # Normalize Institutions
    final_data <- final_data %>%
      mutate(institution = case_when(
        str_detect(full_text, regex("San Diego|UCSD", ignore_case=T)) ~ "University of California, San Diego",
        str_detect(full_text, regex("Los Angeles|UCLA", ignore_case=T)) ~ "University of California, Los Angeles",
        str_detect(full_text, regex("Berkeley", ignore_case=T)) ~ "University of California, Berkeley",
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
        TRUE ~ institution
      ))
      
    # Parse GRE
    print("Parsing GRE...")
    # ... (Same GRE logic)
    # Just save for now
    data <- final_data
    save(data, file = "cleaned_data.Rdata")
    cat("Saved cleaned_data.Rdata\n")
} else {
    cat("No rows left after filtering. Improve extraction.\n")
}
