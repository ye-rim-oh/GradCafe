# ============================================================
# Analyze GradCafe Political Science Scrape
# Purpose: Produce a descriptive analysis report for the current
#          political science admissions dataset.
# Inputs:  output/polisci_analysis/gradcafe_polisci_2016_2026_clean.rds
# Outputs: output/polisci_analysis/gradcafe_polisci_2016_2026_analysis.md
#          output/polisci_analysis/analysis_tables.rds
# ============================================================

suppressPackageStartupMessages({
  library(dplyr)
  library(lubridate)
  library(stringr)
})

set.seed(42)

out_dir <- "output/polisci_analysis"
data_path <- file.path(out_dir, "gradcafe_polisci_2016_2026_clean.rds")
df <- readRDS(data_path) %>%
  mutate(
    decision_date = as.Date(decision_date),
    decision_group = ifelse(
      decision_type %in% c("Accepted", "Rejected", "Interview", "Wait listed", "Other"),
      decision_type,
      "Other"
    ),
    status = ifelse(is.na(status) | status == "", "Unknown", status),
    subfield = ifelse(is.na(subfield) | subfield == "", "Unknown", subfield),
    gre_v_clean = ifelse(!is.na(gre_v) & gre_v >= 130 & gre_v <= 170, gre_v, NA_real_),
    gre_q_clean = ifelse(!is.na(gre_q) & gre_q >= 130 & gre_q <= 170, gre_q, NA_real_),
    gre_aw_clean = ifelse(!is.na(gre_aw) & gre_aw >= 0 & gre_aw <= 6, gre_aw, NA_real_)
  )

target_year <- max(df$scrape_year, na.rm = TRUE)

pct_num <- function(num, den) {
  ifelse(den > 0, 100 * num / den, NA_real_)
}

pct <- function(num, den) {
  ifelse(den > 0, sprintf("%.1f%%", 100 * num / den), "NA")
}

fmt_num <- function(x, digits = 1) {
  ifelse(is.na(x), "NA", sprintf(paste0("%.", digits, "f"), x))
}

fmt_p <- function(p) {
  ifelse(is.na(p), "NA", ifelse(p < 0.001, "<0.001", sprintf("%.4f", p)))
}

md_table <- function(x) {
  x <- as.data.frame(x, stringsAsFactors = FALSE)
  headers <- names(x)
  clean_cell <- function(value) {
    value <- as.character(value)
    value <- ifelse(is.na(value) | value == "NA", "NA", value)
    value <- str_replace_all(value, "[\r\n]+", " ")
    value <- str_replace_all(value, "\\|", "\\\\|")
    str_squish(value)
  }
  lines <- c(
    paste("|", paste(headers, collapse = " | "), "|"),
    paste("|", paste(rep("---", length(headers)), collapse = " | "), "|")
  )
  for (i in seq_len(nrow(x))) {
    vals <- vapply(x[i, ], clean_cell, character(1), USE.NAMES = FALSE)
    lines <- c(lines, paste("|", paste(vals, collapse = " | "), "|"))
  }
  lines
}

wide_count_table <- function(data, row_var, col_var, value_var = "n") {
  data <- as.data.frame(data)
  if (nrow(data) == 0) return(data.frame())
  form <- as.formula(paste(row_var, "~", col_var))
  mat <- xtabs(as.formula(paste(value_var, "~", row_var, "+", col_var)), data = data)
  out <- as.data.frame.matrix(mat)
  out <- cbind(setNames(data.frame(rownames(out), check.names = FALSE), row_var), out)
  rownames(out) <- NULL
  out
}

year_summary <- df %>%
  group_by(scrape_year) %>%
  summarise(
    Year = first(scrape_year),
    `Total Cases` = n(),
    Accepted = sum(decision_group == "Accepted", na.rm = TRUE),
    Rejected = sum(decision_group == "Rejected", na.rm = TRUE),
    Interview = sum(decision_group == "Interview", na.rm = TRUE),
    `Wait listed` = sum(decision_group == "Wait listed", na.rm = TRUE),
    Other = sum(decision_group == "Other", na.rm = TRUE),
    `Accept Rate` = pct(Accepted, Accepted + Rejected),
    accept_rate_num = pct_num(Accepted, Accepted + Rejected),
    .groups = "drop"
  ) %>%
  arrange(Year)

year_display <- year_summary %>%
  select(-scrape_year, -accept_rate_num)

status_summary <- df %>%
  filter(status %in% c("American", "International")) %>%
  group_by(scrape_year, status) %>%
  summarise(
    Year = first(scrape_year),
    Status = first(status),
    `Total Cases` = n(),
    Accepted = sum(decision_group == "Accepted", na.rm = TRUE),
    Rejected = sum(decision_group == "Rejected", na.rm = TRUE),
    Interview = sum(decision_group == "Interview", na.rm = TRUE),
    `Wait listed` = sum(decision_group == "Wait listed", na.rm = TRUE),
    Other = sum(decision_group == "Other", na.rm = TRUE),
    `Accept Rate` = pct(Accepted, Accepted + Rejected),
    accept_rate_num = pct_num(Accepted, Accepted + Rejected),
    .groups = "drop"
  ) %>%
  arrange(Year, Status)

make_status_wide <- function(status_summary) {
  years <- sort(unique(status_summary$Year))
  out <- data.frame(Year = years)
  for (status_name in c("American", "International")) {
    rates <- status_summary$`Accept Rate`[match(
      paste(years, status_name),
      paste(status_summary$Year, status_summary$Status)
    )]
    out[[status_name]] <- rates
  }
  out
}

status_wide <- make_status_wide(status_summary)

target_status <- status_summary %>%
  filter(Year == target_year) %>%
  select(Year, Status, `Total Cases`, Accepted, Rejected, Interview, `Wait listed`, Other, `Accept Rate`, accept_rate_num)

subfield_counts <- df %>%
  count(scrape_year, subfield, name = "n") %>%
  arrange(scrape_year, desc(n))

subfield_volume_wide <- subfield_counts %>%
  rename(Year = scrape_year, Subfield = subfield) %>%
  wide_count_table("Year", "Subfield", "n")

subfield_rate <- df %>%
  filter(
    subfield %in% c("AP", "CP", "IR", "Theory", "Methods", "Public Law/Policy"),
    decision_group %in% c("Accepted", "Rejected")
  ) %>%
  group_by(scrape_year, subfield) %>%
  summarise(
    n = n(),
    accepted = sum(decision_group == "Accepted", na.rm = TRUE),
    rate = pct_num(accepted, n),
    .groups = "drop"
  ) %>%
  filter(n >= 3) %>%
  mutate(`Accept Rate` = sprintf("%.1f%%", rate)) %>%
  select(Year = scrape_year, Subfield = subfield, `Accept Rate`)

make_subfield_rate_wide <- function(subfield_rate) {
  years <- sort(unique(subfield_rate$Year))
  subfields <- c("AP", "CP", "IR", "Theory", "Methods", "Public Law/Policy")
  out <- data.frame(Year = years)
  for (subfield_name in subfields) {
    rates <- subfield_rate$`Accept Rate`[match(
      paste(years, subfield_name),
      paste(subfield_rate$Year, subfield_rate$Subfield)
    )]
    out[[subfield_name]] <- rates
  }
  out
}

subfield_rate_wide <- make_subfield_rate_wide(subfield_rate)

institution_summary <- df %>%
  group_by(institution) %>%
  summarise(
    Institution = first(institution),
    `Total Cases` = n(),
    Accepted = sum(decision_group == "Accepted", na.rm = TRUE),
    Rejected = sum(decision_group == "Rejected", na.rm = TRUE),
    `Accept Rate` = pct(Accepted, Accepted + Rejected),
    Latest = max(decision_date, na.rm = TRUE),
    .groups = "drop"
  ) %>%
  select(Institution, `Total Cases`, Accepted, Rejected, `Accept Rate`, Latest) %>%
  arrange(desc(`Total Cases`), Institution)

gre_summary <- df %>%
  filter(scrape_year == target_year, decision_group %in% c("Accepted", "Rejected")) %>%
  group_by(scrape_year, decision_group) %>%
  summarise(
    Year = first(scrape_year),
    Decision = first(decision_group),
    `GRE V n` = sum(!is.na(gre_v_clean)),
    `GRE V mean` = fmt_num(mean(gre_v_clean, na.rm = TRUE)),
    `GRE Q n` = sum(!is.na(gre_q_clean)),
    `GRE Q mean` = fmt_num(mean(gre_q_clean, na.rm = TRUE)),
    `GRE AW n` = sum(!is.na(gre_aw_clean)),
    `GRE AW mean` = fmt_num(mean(gre_aw_clean, na.rm = TRUE), 2),
    `GPA n` = sum(!is.na(gpa)),
    `GPA mean` = fmt_num(mean(gpa, na.rm = TRUE), 2),
    .groups = "drop"
  ) %>%
  select(Year, Decision, `GRE V n`, `GRE V mean`, `GRE Q n`, `GRE Q mean`, `GRE AW n`, `GRE AW mean`, `GPA n`, `GPA mean`)

correlation_for <- function(metric) {
  sample <- df %>%
    filter(decision_group %in% c("Accepted", "Rejected")) %>%
    mutate(outcome = ifelse(decision_group == "Accepted", 1, 0)) %>%
    filter(!is.na(.data[[metric]]))
  if (nrow(sample) < 3 || length(unique(sample[[metric]])) < 2) {
    return(data.frame(Metric = metric, `Valid N` = nrow(sample), `Correlation r` = NA, `p-value` = NA, Interpretation = "Insufficient variation"))
  }
  test <- suppressWarnings(cor.test(sample[[metric]], sample$outcome))
  r <- unname(test$estimate)
  interpretation <- case_when(
    abs(r) < 0.05 ~ "No meaningful linear correlation",
    abs(r) < 0.15 ~ "Very weak linear correlation",
    abs(r) < 0.30 ~ "Weak linear correlation",
    TRUE ~ "Moderate or stronger linear correlation"
  )
  data.frame(
    Metric = metric,
    `Valid N` = nrow(sample),
    `Correlation r` = sprintf("%.3f", r),
    `p-value` = fmt_p(test$p.value),
    Interpretation = interpretation,
    check.names = FALSE
  )
}

correlation_summary <- bind_rows(lapply(c("gpa", "gre_v_clean", "gre_q_clean", "gre_aw_clean"), correlation_for)) %>%
  mutate(Metric = recode(
    Metric,
    gpa = "GPA",
    gre_v_clean = "GRE V",
    gre_q_clean = "GRE Q",
    gre_aw_clean = "GRE AW"
  ))

timeline_summary <- df %>%
  mutate(
    decision_month = month(decision_date),
    dmd = as.Date(paste0("2020-", format(decision_date, "%m-%d"))),
    dmd_num = as.numeric(dmd)
  ) %>%
  filter(decision_month <= 4) %>%
  group_by(scrape_year) %>%
  summarise(
    Year = first(scrape_year),
    Start = format(min(dmd, na.rm = TRUE), "%m/%d"),
    `25%` = format(as.Date(quantile(dmd_num, 0.25, na.rm = TRUE), origin = "1970-01-01"), "%m/%d"),
    Median = format(as.Date(quantile(dmd_num, 0.50, na.rm = TRUE), origin = "1970-01-01"), "%m/%d"),
    `75%` = format(as.Date(quantile(dmd_num, 0.75, na.rm = TRUE), origin = "1970-01-01"), "%m/%d"),
    End = paste0(format(max(dmd, na.rm = TRUE), "%m/%d"), " (n=", n(), ")"),
    .groups = "drop"
  ) %>%
  select(Year, Start, `25%`, Median, `75%`, End) %>%
  arrange(Year)

master_summary <- year_summary %>%
  select(Year, `Total Cases`, `Overall Accept Rate` = `Accept Rate`) %>%
  left_join(
    status_summary %>%
      filter(Status == "American") %>%
      select(Year, `American Cases` = `Total Cases`, `American Accept Rate` = `Accept Rate`),
    by = "Year"
  ) %>%
  left_join(
    status_summary %>%
      filter(Status == "International") %>%
      select(Year, `International Cases` = `Total Cases`, `International Accept Rate` = `Accept Rate`),
    by = "Year"
  ) %>%
  left_join(
    df %>%
      group_by(scrape_year) %>%
      summarise(
        Year = first(scrape_year),
        `GRE V n` = sum(!is.na(gre_v_clean)),
        `GRE V mean` = fmt_num(mean(gre_v_clean, na.rm = TRUE)),
        `GRE Q n` = sum(!is.na(gre_q_clean)),
        `GRE Q mean` = fmt_num(mean(gre_q_clean, na.rm = TRUE)),
        `GPA Reporting Rate` = pct(sum(!is.na(gpa)), n()),
        .groups = "drop"
      ) %>%
      select(Year, `GRE V n`, `GRE V mean`, `GRE Q n`, `GRE Q mean`, `GPA Reporting Rate`),
    by = "Year"
  ) %>%
  left_join(
    timeline_summary %>% select(Year, `Timeline Start` = Start, `Timeline 75%` = `75%`),
    by = "Year"
  )

latest_rows <- df %>%
  arrange(desc(decision_date)) %>%
  select(decision_date, institution, institution_raw, program, decision_group, status, subfield) %>%
  rename(decision_type = decision_group) %>%
  head(25)

top_year <- year_summary$Year[which.max(year_summary$accept_rate_num)]
low_year <- year_summary$Year[which.min(year_summary$accept_rate_num)]
top_rate <- max(year_summary$accept_rate_num, na.rm = TRUE)
low_rate <- min(year_summary$accept_rate_num, na.rm = TRUE)
target_row <- year_summary %>% filter(Year == target_year)
target_american <- target_status %>% filter(Status == "American")
target_international <- target_status %>% filter(Status == "International")
nationality_gap <- target_american$accept_rate_num - target_international$accept_rate_num
unknown_subfield_share <- pct(sum(df$subfield == "Unknown", na.rm = TRUE), nrow(df))
target_unknown_subfield_share <- pct(
  sum(df$scrape_year == target_year & df$subfield == "Unknown", na.rm = TRUE),
  sum(df$scrape_year == target_year, na.rm = TRUE)
)
source_supplement_n <- sum(df$source_mode == "no-season-supplement", na.rm = TRUE)

takeaways <- c(
  paste0("1. The full 2016-", target_year, " sample contains ", format(nrow(df), big.mark = ","), " cleaned posts across ", length(unique(df$institution)), " canonical institutions."),
  paste0("2. Acceptance rates range from ", sprintf("%.1f%%", low_rate), " in ", low_year, " to ", sprintf("%.1f%%", top_rate), " in ", top_year, "; ", target_year, " sits at ", target_row$`Accept Rate`, "."),
  paste0("3. In ", target_year, ", American and international acceptance rates are ", target_american$`Accept Rate`, " and ", target_international$`Accept Rate`, ", a gap of ", sprintf("%.1f", nationality_gap), " percentage points."),
  paste0("4. Subfield information is sparse: ", unknown_subfield_share, " of all rows and ", target_unknown_subfield_share, " of ", target_year, " rows are tagged Unknown."),
  paste0("5. GRE/GPA fields are optional and self-reported, so their correlations with outcomes remain descriptive rather than predictive.")
)

tables <- list(
  year_summary = year_display,
  status_summary = status_summary,
  status_wide = status_wide,
  target_status = target_status,
  subfield_volume_wide = subfield_volume_wide,
  subfield_rate_wide = subfield_rate_wide,
  gre_summary = gre_summary,
  correlation_summary = correlation_summary,
  timeline_summary = timeline_summary,
  master_summary = master_summary
)
saveRDS(tables, file.path(out_dir, "analysis_tables.rds"))

report <- c(
  paste0("# 2016-", target_year, " GradCafe Political Science PhD Trend Report"),
  "",
  paste0("**Report Date**: ", Sys.Date()),
  paste0("**Data Source**: GradCafe survey data refreshed through ", max(df$decision_date, na.rm = TRUE)),
  paste0("**Total Sample**: **", format(nrow(df), big.mark = ","), "** cleaned posts"),
  "",
  "This note summarizes what the current snapshot shows. It is descriptive, not causal.",
  "",
  "## 1. Yearly Decision Mix and Acceptance Rate",
  "",
  md_table(year_display),
  "",
  "Accept rate is calculated as `Accepted / (Accepted + Rejected)`. Interview, waitlist, and other rows are excluded from the denominator.",
  "",
  "Quick read:",
  paste0("- Across 2016-", target_year, ", rates range from **", sprintf("%.1f%%", low_rate), "** to **", sprintf("%.1f%%", top_rate), "**."),
  paste0("- In this snapshot, ", top_year, " is the highest-rate year and ", low_year, " is the lowest-rate year."),
  paste0("- As of ", max(df$decision_date, na.rm = TRUE), ", the ", target_year, " sample has **", target_row$`Total Cases`, "** posts with a **", target_row$`Accept Rate`, "** acceptance rate."),
  "",
  "## 2. Nationality Split",
  "",
  "### 2.1 Yearly Acceptance Rate by Nationality",
  "",
  md_table(status_wide),
  "",
  paste0("### 2.2 ", target_year, " Breakdown"),
  "",
  md_table(target_status %>% select(-accept_rate_num)),
  "",
  paste0("In ", target_year, ", the American-International gap is **", sprintf("%.1f", nationality_gap), " percentage points**. This is a reporting snapshot, not an estimate of admission odds."),
  "",
  "## 3. Subfield Snapshot",
  "",
  "### 3.1 Subfield Volume by Year",
  "",
  md_table(subfield_volume_wide),
  "",
  "### 3.2 Subfield Acceptance Rate by Year",
  "",
  md_table(subfield_rate_wide),
  "",
  paste0("Most rows are still tagged as Unknown (**", unknown_subfield_share, "** of the full sample), so subfield tables are useful for direction but not for strict ranking."),
  "",
  paste0("## 4. GRE/GPA Summary (", target_year, ", Accepted vs Rejected)"),
  "",
  md_table(gre_summary),
  "",
  "GRE and GPA fields are self-reported and optional, so these means come from a selective subset.",
  "",
  paste0("## 5. GRE/GPA vs Outcome Correlation (2016-", target_year, ")"),
  "",
  "Accepted is coded as 1, Rejected as 0, and Pearson correlation is used.",
  "",
  md_table(correlation_summary),
  "",
  "These are small observational correlations and should not be interpreted as causal.",
  "",
  "## 6. Decision Timeline Markers",
  "",
  "The timeline table uses January-April decision dates only, because later dates often reflect off-cycle updates, historical cleanup, or season-label artifacts.",
  "",
  md_table(timeline_summary),
  "",
  "## 7. Master Summary Table",
  "",
  md_table(master_summary),
  "",
  "## 8. Takeaways",
  "",
  takeaways,
  "",
  paste0("## Fall ", target_year, " Snapshot"),
  "",
  paste0("- Total posts: **", target_row$`Total Cases`, "**"),
  paste0("- Overall acceptance rate: **", target_row$`Accept Rate`, "**"),
  paste0("- American vs International: **", target_american$`Accept Rate`, " vs ", target_international$`Accept Rate`, "**"),
  paste0("- Latest decision date in the dataset: **", max(df$decision_date, na.rm = TRUE), "**"),
  "",
  "## Method Notes",
  "",
  "- Source: user-reported GradCafe posts.",
  "- Scope: PhD entries filtered to Political Science, International Relations, Politics, Government, and direct combinations.",
  "- Cleaning: program labels and school names are rule-normalized; obvious junk or truncated school labels are filtered or repaired.",
  paste0("- Collection: season-filtered pages are supplemented with recent no-season pages; **", source_supplement_n, "** clean rows currently come from that supplement path."),
  "- Interpretation: use these numbers as a directional snapshot, not a full census."
)

writeLines(report, file.path(out_dir, "gradcafe_polisci_2016_2026_analysis.md"), useBytes = TRUE)
writeLines(report, "gradcafe_polisci_2016_2026_analysis.md", useBytes = TRUE)
cat("Wrote analysis report with", nrow(df), "rows.\n")
