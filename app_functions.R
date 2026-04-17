# app_functions.R -- Data loading and helper functions for the Shiny Dashboard
# Uses the current GradCafe survey JSON scraper output when available.

library(tidyverse)
library(lubridate)
library(plotly)

load_gradcafe_data <- function() {
  clean_rds <- file.path("output", "polisci_analysis", "gradcafe_polisci_2016_2026_clean.rds")
  clean_csv <- file.path("output", "polisci_analysis", "gradcafe_polisci_2016_2026_clean.csv")

  if (file.exists(clean_rds)) {
    return(as.data.frame(readRDS(clean_rds)))
  }

  if (file.exists(clean_csv)) {
    return(as.data.frame(readr::read_csv(clean_csv, show_col_types = FALSE)))
  }

  legacy_rdata <- "scraped_2020_2026_combined.Rdata"
  if (file.exists(legacy_rdata)) {
    loaded_names <- load(legacy_rdata)
    if (!"data" %in% loaded_names) {
      stop("Legacy Rdata file did not contain an object named data.", call. = FALSE)
    }
    return(as.data.frame(data))
  }

  stop(
    "No GradCafe data found. Run scripts/R/update_polisci_data.R or scripts/R/scrape_gradcafe_polisci.R first.",
    call. = FALSE
  )
}

df_raw <- load_gradcafe_data()

# --- Data Prep ---
df_raw$year <- as.integer(df_raw$scrape_year)

decision_levels <- c("Accepted", "Rejected", "Interview", "Wait listed", "Other")
df_raw$decision_type <- ifelse(df_raw$decision_type %in% decision_levels, df_raw$decision_type, "Other")
df_raw$decision_type <- factor(df_raw$decision_type, levels = decision_levels)

df_raw$gre_v <- suppressWarnings(as.numeric(df_raw$gre_v))
df_raw$gre_q <- suppressWarnings(as.numeric(df_raw$gre_q))
df_raw$gre_aw <- suppressWarnings(as.numeric(df_raw$gre_aw))
df_raw$gre_total <- suppressWarnings(as.numeric(df_raw$gre_total))

# GRE Q derivation
fill_q <- is.na(df_raw$gre_q) & !is.na(df_raw$gre_total) & df_raw$gre_total >= 130 & df_raw$gre_total <= 170
df_raw$gre_q[fill_q] <- df_raw$gre_total[fill_q]
fill_q2 <- is.na(df_raw$gre_q) & !is.na(df_raw$gre_total) & df_raw$gre_total >= 260 & df_raw$gre_total <= 340 & !is.na(df_raw$gre_v)
df_raw$gre_q[fill_q2] <- df_raw$gre_total[fill_q2] - df_raw$gre_v[fill_q2]
df_raw$gre_q[df_raw$gre_q < 130 | df_raw$gre_q > 170] <- NA
df_raw$gre_v[df_raw$gre_v < 130 | df_raw$gre_v > 170] <- NA
df_raw$gre_aw[df_raw$gre_aw < 0 | df_raw$gre_aw > 6] <- NA

df_raw$decision_date <- as.Date(df_raw$decision_date)
df_raw$dmd <- ifelse(is.na(df_raw$decision_date), NA,
                     as.Date(paste0("2020-", format(df_raw$decision_date, "%m-%d"))))
df_raw$dmd <- as.Date(df_raw$dmd, origin = "1970-01-01")

out_of_season <- !is.na(df_raw$dmd) & month(df_raw$dmd) >= 5
df_raw$dmd[out_of_season] <- NA

df_raw$status <- ifelse(is.na(df_raw$status) | df_raw$status == "", "Unknown", df_raw$status)
df_raw$subfield <- ifelse(is.na(df_raw$subfield) | df_raw$subfield == "", "Unknown", df_raw$subfield)

# Normalize noisy GradCafe program labels before filtering.
# This keeps label variants comparable between years and app runs.
normalize_major_program <- function(program) {
  p <- str_to_lower(program)
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

# Keep only rows composed of target majors:
# political science, international relations, politics, government.
is_target_major <- function(program) {
  p <- normalize_major_program(program)
  allowed <- c("political science", "international relations", "politics", "government")
  vapply(
    p,
    FUN.VALUE = logical(1),
    FUN = function(one_program) {
      if (is.na(one_program) || one_program == "") {
        return(FALSE)
      }
      parts <- str_split(one_program, "\\band\\b", simplify = FALSE)[[1]]
      parts <- str_squish(parts)
      parts <- parts[parts != ""]
      length(parts) > 0 && all(parts %in% allowed)
    }
  )
}

df_raw <- df_raw %>%
  filter(is_target_major(program))

# --- Canonical Institution Normalization ---
# Keep institution cleanup in one shared helper used by scraper, export, and app code.
source(file.path("scripts", "R", "institution_normalization.R"), encoding = "UTF-8")

if (!"institution_raw" %in% names(df_raw)) {
  df_raw$institution_raw <- df_raw$school
}

df_raw$institution_source <- ifelse(
  is.na(df_raw$institution_raw) | df_raw$institution_raw == "",
  df_raw$school,
  df_raw$institution_raw
)

df_raw <- df_raw %>%
  mutate(
    school = clean_institution_text(institution_source),
    institution = normalize_institution(institution_source)
  ) %>%
  filter(valid_institution_school(institution_source)) %>%
  mutate(institution_raw = school)
# Rename columns for Shiny compatibility
# Drop the original scraper columns that conflict, use our recomputed ones
data <- df_raw %>%
  select(-any_of(c("decision_year", "decision_month_day", "institution_source"))) %>%
  rename(
    decision = decision_type,
    decision_year = year,
    decision_month_day = dmd,
    GPA = gpa,
    GRE_V = gre_v,
    GRE_Q = gre_q,
    GRE_AW = gre_aw
  )

# Unique values
unique_institutions <- data %>%
  select(institution) %>%
  unique() %>%
  rename(Institution = institution) %>%
  arrange(Institution)

years <- data %>%
  select(decision_year) %>%
  unique() %>%
  arrange(desc(decision_year))

decisions <- data %>%
  select(decision) %>%
  unique() %>%
  filter(!is.na(decision)) %>%
  arrange(decision)

# Color palette
decision_colors <- c(
  "Accepted" = "#2563eb",
  "Interview" = "#16a34a",
  "Wait listed" = "#ea580c",
  "Rejected" = "#dc2626",
  "Other" = "#6b7280"
)

# --- Timeline visualization ---
decision_calendar <- function(institutions, decisions_filter, years_filter,
                              title_label = NULL) {

  data_to_visualize <- data %>%
    filter(institution %in% institutions,
           decision %in% decisions_filter,
           decision_year %in% years_filter) %>%
    filter(!is.na(decision_month_day)) %>%
    filter(month(decision_month_day) >= 1 & month(decision_month_day) <= 4) %>%
    arrange(decision_month_day, decision) %>%
    group_by(decision_month_day) %>%
    mutate(y_stack = row_number()) %>%
    ungroup()

  if (nrow(data_to_visualize) == 0) {
    p <- ggplot() +
      annotate("text", x = as.Date("2020-02-15"), y = 0.5,
               label = "No data for selected filters", size = 5, family="Georgia") +
      theme_void()
    return(ggplotly(p))
  }

  data_to_visualize <- data_to_visualize %>%
    mutate(
      gre_tooltip = case_when(
        !is.na(GRE_V) & !is.na(GRE_Q) ~ paste0("GRE: V", GRE_V, "/Q", GRE_Q, "<br>"),
        !is.na(GRE_V) ~ paste0("GRE: V", GRE_V, "<br>"),
        !is.na(GRE_Q) ~ paste0("GRE: Q", GRE_Q, "<br>"),
        TRUE ~ ""
      ),
      tooltip_text = paste0(
        "<b>", decision, "</b><br>",
        "Date: ", format(decision_month_day, "%m/%d"), ", ", decision_year, "<br>",
        ifelse(!is.na(status) & status != "Unknown", paste0("Status: ", status, "<br>"), ""),
        ifelse(!is.na(subfield) & subfield != "Unknown", paste0("Subfield: ", subfield, "<br>"), ""),
        ifelse(!is.na(GPA), paste0("GPA: ", GPA, "<br>"), ""),
        gre_tooltip
      )
    ) %>%
    select(-gre_tooltip)

  default_title <- if (length(institutions) == 1) paste("School:", institutions)
  else paste("Schools:", length(institutions))
  plot_title <- if (is.null(title_label)) default_title else title_label

  # Lane-based visualization instead of scattered dots
  plot <- ggplot(data = data_to_visualize,
                 aes(x = decision_month_day,
                     y = decision,
                     text = tooltip_text,
                     color = decision)) +
    geom_jitter(width = 0, height = 0.25, size = 3, alpha = 0.5) +
    scale_x_date(
      date_labels = "%b",
      date_breaks = "1 month",
      limits = as.Date(c("2020-01-01", "2020-04-30"))
    ) +
    scale_color_manual(
      breaks = c("Accepted", "Interview", "Wait listed", "Rejected", "Other"),
      values = decision_colors,
      name = "Decision:"
    ) +
    labs(x = "", y = "", title = plot_title) +
    theme_minimal(base_family = "Georgia") +
    theme(
      axis.text.x = element_text(size = 14, color = "#334155"),
      axis.text.y = element_text(size = 14, face = "bold", color = "#334155"),
      axis.ticks.y = element_blank(),
      panel.grid.major.y = element_line(color = "#e2e8f0", linetype = "dashed"),
      panel.grid.minor.y = element_blank(),
      panel.grid.major.x = element_line(color = "#e2e8f0"),
      legend.position = "none",
      plot.title = element_text(size = 16, face = "bold", color = "#0f172a")
    )

  ggplotly(plot, tooltip = c("text")) %>%
    layout(
      font = list(family = "Georgia"),
      margin = list(l = 80, b = 40, t = 50, r = 20),
      hoverlabel = list(font = list(family = "Georgia", size = 15))
    )
}

# --- Comparison table ---
get_comparison_data <- function(institutions) {
  current_year <- max(data$decision_year, na.rm = TRUE)

  last_3yr <- data %>%
    filter(institution %in% institutions,
           decision_year >= current_year - 2,
           !is.na(decision_month_day))

  last_6yr <- data %>%
    filter(institution %in% institutions,
           decision_year >= current_year - 6,
           !is.na(decision_month_day))

  get_first <- function(df, dec_type) {
    result <- df %>%
      filter(decision == dec_type) %>%
      summarize(first = min(decision_month_day, na.rm = TRUE)) %>%
      pull(first)
    if (is.infinite(result) || is.na(result)) "N/A"
    else format(result, "%m/%d")
  }

  tibble(
    Metric = c("First Acceptance", "First Rejection", "First Interview", "First Waitlist", "Total Results"),
    `Last 3 Years` = c(
      get_first(last_3yr, "Accepted"),
      get_first(last_3yr, "Rejected"),
      get_first(last_3yr, "Interview"),
      get_first(last_3yr, "Wait listed"),
      as.character(nrow(last_3yr))
    ),
    `All Years` = c(
      get_first(last_6yr, "Accepted"),
      get_first(last_6yr, "Rejected"),
      get_first(last_6yr, "Interview"),
      get_first(last_6yr, "Wait listed"),
      as.character(nrow(last_6yr))
    )
  )
}

# --- Single date functions ---
first_acceptance <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions, decision %in% decisions_filter,
           decision_year %in% years_filter, decision == "Accepted",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date))
    paste("First Acceptance:", format(key_dates$first_date, "%m/%d"))
  else "First Acceptance: N/A"
}

first_rejection <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions, decision %in% decisions_filter,
           decision_year %in% years_filter, decision == "Rejected",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date))
    paste("First Rejection:", format(key_dates$first_date, "%m/%d"))
  else "First Rejection: N/A"
}

first_waitlist <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions, decision %in% decisions_filter,
           decision_year %in% years_filter, decision == "Wait listed",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date))
    paste("First Waitlist:", format(key_dates$first_date, "%m/%d"))
  else "First Waitlist: N/A"
}

first_interview <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions, decision %in% decisions_filter,
           decision_year %in% years_filter, decision == "Interview",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date))
    paste("First Interview:", format(key_dates$first_date, "%m/%d"))
  else "First Interview: N/A"
}

# --- Yearly accept rate for overview chart ---
get_yearly_accept_rate <- function(institutions) {
  data %>%
    filter(institution %in% institutions,
           decision %in% c("Accepted", "Rejected")) %>%
    group_by(decision_year) %>%
    summarise(
      acc = sum(decision == "Accepted"),
      rej = sum(decision == "Rejected"),
      rate = acc / (acc + rej) * 100,
      total = acc + rej,
      .groups = "drop"
    )
}

# --- Nationality rate for overview chart ---
get_nat_rate <- function(institutions) {
  data %>%
    filter(institution %in% institutions,
           status %in% c("American", "International"),
           decision %in% c("Accepted", "Rejected")) %>%
    group_by(decision_year, status) %>%
    summarise(
      rate = sum(decision == "Accepted") / n() * 100,
      n = n(),
      .groups = "drop"
    )
}
