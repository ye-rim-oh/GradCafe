#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
})

source("app_functions.R", local = TRUE)

dir.create("site/data", recursive = TRUE, showWarnings = FALSE)

records <- data %>%
  transmute(
    institution = institution,
    decision = as.character(decision),
    decisionYear = as.integer(decision_year),
    decisionMonthDay = ifelse(is.na(decision_month_day), NA_character_, format(decision_month_day, "%Y-%m-%d")),
    status = ifelse(is.na(status), "Unknown", status),
    subfield = ifelse(is.na(subfield), "Unknown", subfield),
    gpa = ifelse(is.na(GPA), NA_real_, round(as.numeric(GPA), 2)),
    greV = ifelse(is.na(GRE_V), NA_real_, as.numeric(GRE_V)),
    greQ = ifelse(is.na(GRE_Q), NA_real_, as.numeric(GRE_Q)),
    notes = ifelse(is.na(notes), "", notes)
  )

payload <- list(
  generatedAt = "2026-03-04",
  recordCount = nrow(records),
  decisionChoices = c("Accepted", "Rejected", "Interview", "Wait listed", "Other"),
  records = records
)

write_json(
  payload,
  path = "site/data/gradcafe.json",
  pretty = TRUE,
  auto_unbox = TRUE,
  null = "null",
  na = "null"
)

message(sprintf("Wrote %s records to site/data/gradcafe.json", nrow(records)))
