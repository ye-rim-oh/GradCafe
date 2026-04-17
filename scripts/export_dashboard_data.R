#!/usr/bin/env Rscript

out_dir <- file.path("site", "data")
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

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

canonical_institution <- function(institution, school) {
  value <- ifelse(is.na(institution) | institution == "", school, institution)
  value <- trimws(as.character(value))
  value <- gsub("[[:cntrl:]]", " ", value)
  value <- gsub("\\s+", " ", value)

  replace_hit <- function(pattern, replacement) {
    hit <- grepl(pattern, value, ignore.case = TRUE)
    value[hit] <<- replacement
  }

  replace_hit("The\\s+University\\s+Of\\s+Toront(o)?|University\\s+Of\\s+Toronto|Toront", "University of Toronto (UofT)")
  replace_hit("University of Texas at Austin|UT Austin|UT AUSTIN", "University of Texas at Austin (UT Austin)")
  replace_hit("Wisconsin-Madison|UW-MADISON", "University of Wisconsin-Madison (UW-Madison)")
  replace_hit("Colorado Boulder|CU BOULDER", "University of Colorado Boulder (CU Boulder)")
  replace_hit("University of California \\(UNSPECIFIED\\)|University of California \\(Unspecified\\)$", "University of California (Unspecified)")

  value <- gsub("\\(UOFT\\)", "(UofT)", value)
  value <- gsub("\\(UT AUSTIN\\)", "(UT Austin)", value)
  value <- gsub("\\(UW-MADISON\\)", "(UW-Madison)", value)
  value <- gsub("\\(CU BOULDER\\)", "(CU Boulder)", value)
  value <- gsub("\\(UNSPECIFIED\\)", "(Unspecified)", value)
  trimws(value)
}

valid_export_institution <- function(institution) {
  value <- trimws(as.character(institution))
  !is.na(value) &
    value != "" &
    !grepl("^(All|ALL|Overall|Overall \\(All Schools\\))$", value, ignore.case = TRUE)
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
df$institution <- canonical_institution(df$institution, df$school)
df <- df[valid_export_institution(df$institution), , drop = FALSE]

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
