#!/usr/bin/env Rscript

out_dir <- file.path("site", "data")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

source(file.path("scripts", "R", "institution_normalization.R"), encoding = "UTF-8")

clean_rds <- file.path("output", "polisci_analysis", "gradcafe_polisci_2016_2026_clean.rds")
clean_csv <- file.path("output", "polisci_analysis", "gradcafe_polisci_2016_2026_clean.csv")

load_clean_data <- function() {
  if (file.exists(clean_rds)) {
    return(as.data.frame(readRDS(clean_rds), stringsAsFactors = FALSE))
  }

  if (file.exists(clean_csv)) {
    return(read.csv(clean_csv, stringsAsFactors = FALSE, fileEncoding = "UTF-8"))
  }

  stop(
    "No cleaned GradCafe data found. Run scripts/R/update_polisci_data.R or scripts/R/scrape_gradcafe_polisci.R first.",
    call. = FALSE
  )
}

clean_number <- function(x, lower = -Inf, upper = Inf) {
  value <- suppressWarnings(as.numeric(x))
  value[!is.finite(value) | value < lower | value > upper] <- NA_real_
  value
}

json_escape <- function(x) {
  x <- enc2utf8(as.character(x))
  x <- gsub("\\", "\\\\", x, fixed = TRUE)
  x <- gsub('"', '\\"', x, fixed = TRUE)
  x <- gsub("\r", "\\r", x, fixed = TRUE)
  x <- gsub("\n", "\\n", x, fixed = TRUE)
  x <- gsub("\t", "\\t", x, fixed = TRUE)
  paste0('"', x, '"')
}

json_value <- function(x) {
  if (length(x) == 0 || is.na(x)) {
    return("null")
  }

  if (inherits(x, "Date")) {
    return(json_escape(format(x, "%Y-%m-%d")))
  }

  if (is.numeric(x) || is.integer(x)) {
    if (!is.finite(x)) {
      return("null")
    }
    return(format(x, scientific = FALSE, trim = TRUE))
  }

  json_escape(x)
}

json_array <- function(values) {
  paste0("[", paste(vapply(values, json_value, character(1)), collapse = ", "), "]")
}

df <- load_clean_data()
school_source <- df$school
if ("institution_raw" %in% names(df)) {
  school_source <- ifelse(is.na(df$institution_raw) | df$institution_raw == "", df$school, df$institution_raw)
}

df$school <- clean_institution_text(school_source)
df$institution <- normalize_institution(school_source)
df <- df[valid_institution_school(school_source), , drop = FALSE]

decision_date <- as.Date(df$decision_date)
decision_month <- as.integer(format(decision_date, "%m"))
decision_month_day <- as.Date(paste0("2020-", format(decision_date, "%m-%d")))
decision_month_day[is.na(decision_date) | decision_month >= 5] <- NA

records <- data.frame(
  institution = df$institution,
  decision = ifelse(
    df$decision_type %in% c("Accepted", "Rejected", "Interview", "Wait listed", "Other"),
    df$decision_type,
    "Other"
  ),
  decisionYear = as.integer(ifelse(!is.na(df$scrape_year), df$scrape_year, df$decision_year)),
  decisionMonthDay = ifelse(is.na(decision_month_day), NA_character_, format(decision_month_day, "%Y-%m-%d")),
  status = ifelse(is.na(df$status) | df$status == "", "Unknown", df$status),
  subfield = ifelse(is.na(df$subfield) | df$subfield == "", "Unknown", df$subfield),
  gpa = round(clean_number(df$gpa), 2),
  greV = clean_number(df$gre_v, 130, 170),
  greQ = clean_number(df$gre_q, 130, 170),
  notes = ifelse(is.na(df$notes), "", df$notes),
  stringsAsFactors = FALSE
)

record_fields <- c(
  "institution",
  "decision",
  "decisionYear",
  "decisionMonthDay",
  "status",
  "subfield",
  "gpa",
  "greV",
  "greQ",
  "notes"
)

write_record <- function(row) {
  field_json <- vapply(
    record_fields,
    function(field) paste0(json_escape(field), ": ", json_value(row[[field]])),
    character(1)
  )
  paste0("    {", paste(field_json, collapse = ", "), "}")
}

json_path <- file.path(out_dir, "gradcafe.json")
con <- file(json_path, open = "w", encoding = "UTF-8")
on.exit(close(con), add = TRUE)

latest_decision_date <- max(decision_date, na.rm = TRUE)

writeLines("{", con, useBytes = TRUE)
writeLines(paste0('  "generatedAt": ', json_value(Sys.Date()), ","), con, useBytes = TRUE)
writeLines(paste0('  "recordCount": ', nrow(records), ","), con, useBytes = TRUE)
writeLines('  "seasonRange": "2016-2026",', con, useBytes = TRUE)
writeLines(paste0('  "latestDecisionDate": ', json_value(latest_decision_date), ","), con, useBytes = TRUE)
writeLines(paste0('  "decisionChoices": ', json_array(c("Accepted", "Rejected", "Interview", "Wait listed", "Other")), ","), con, useBytes = TRUE)
writeLines('  "records": [', con, useBytes = TRUE)
for (i in seq_len(nrow(records))) {
  suffix <- if (i < nrow(records)) "," else ""
  writeLines(paste0(write_record(records[i, , drop = FALSE]), suffix), con, useBytes = TRUE)
}
writeLines("  ]", con, useBytes = TRUE)
writeLines("}", con, useBytes = TRUE)

message(sprintf("Wrote %s records to %s", nrow(records), json_path))
