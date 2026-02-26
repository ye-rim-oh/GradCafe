# Functions v2.0 - Complete

load("cleaned_data.Rdata")

library(tidyverse)
library(lubridate)
library(plotly)

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
  "Accepted" = "#4173fdff",
  "Interview" = "#0f7a33f1", # Yellow
  "Wait listed" = "#ff9900e8", # Orange
  "Rejected" = "#a50e1bff",
  "Other" = "#6d6d6dff"
)

# Timeline visualization --------------------------------------------------------

decision_calendar <- function(institutions, decisions_filter, years_filter, title_label = NULL, y_spacing = 1) {
  
  data_to_visualize <- data %>%
    filter(institution %in% institutions,
           decision %in% decisions_filter,
           decision_year %in% years_filter) %>%
    filter(!is.na(decision_month_day)) %>%
    filter(month(decision_month_day) >= 1 & month(decision_month_day) <= 4) %>%
    arrange(decision_month_day, decision) %>%
    group_by(decision_month_day) %>%
    mutate(y_stack = row_number()) %>% # Stack dots on the same day
    ungroup()
  
  if (nrow(data_to_visualize) == 0) {
    p <- ggplot() + 
      annotate("text", x = as.Date("2020-02-15"), y = 0.5, 
               label = "No data for selected filters", size = 5) +
      theme_void()
    return(ggplotly(p))
  }
  
  max_per_day <- data_to_visualize %>%
    count(decision_month_day) %>%
    summarize(max_n = max(n)) %>%
    pull(max_n)
  
  if (is.na(max_per_day) || max_per_day < 1) {
    max_per_day <- 1
  }
  
  if (is.null(y_spacing)) {
    y_spacing <- if (max_per_day >= 180) {
      3.2
    } else if (max_per_day >= 120) {
      2.6
    } else if (max_per_day >= 80) {
      2.1
    } else if (max_per_day >= 40) {
      1.6
    } else {
      1
    }
  }
  
  data_to_visualize <- data_to_visualize %>%
    mutate(y_stack = y_stack * y_spacing) %>%
    mutate(
      gre_tooltip = case_when(
        !is.na(GRE_V) & !is.na(GRE_Q) ~ paste0("GRE: V", GRE_V, "/Q", GRE_Q, "<br>"),
        !is.na(GRE_V) ~ paste0("GRE: V", GRE_V, "<br>"),
        !is.na(GRE_Q) ~ paste0("GRE: Q", GRE_Q, "<br>"), # Ensure Q is shown
        TRUE ~ ""
      ),
      tooltip_text = paste0(
        "<b>", decision, "</b><br>",
        "Date: ", format(decision_month_day, "%m/%d"), ", ", decision_year, "<br>",
        ifelse(!is.na(GPA), paste0("GPA: ", GPA, "<br>"), ""),
        gre_tooltip
      )
    ) %>%
    select(-gre_tooltip)
  
  default_title <- if (length(institutions) == 1) {
    paste("School:", institutions)
  } else {
    paste("Schools:", length(institutions))
  }
  plot_title <- if (is.null(title_label)) default_title else title_label
  
  plot <- ggplot(data = data_to_visualize,
                 aes(x = decision_month_day,
                     y = y_stack,
                     text = tooltip_text,
                     color = decision)) +
    geom_point(size = 2.5, alpha = 0.7) + # Size reduced, Removed Jitter (Stacking)
    scale_x_date(
      date_labels = "%b",
      date_breaks = "1 month",
      limits = as.Date(c("2020-01-01", "2020-04-30"))
    ) +
    scale_y_continuous(
      breaks = NULL,
      expand = expansion(mult = c(0.05, 3.0)) # Compress vertical space by expanding range
    ) +
    scale_color_manual(
      breaks = c("Accepted", "Interview", "Wait listed", "Rejected", "Other"),
      values = decision_colors,
      name = "Decision:"
    ) +
    labs(x = "", y = "", title = plot_title) +
    theme_minimal(base_family = "Georgia") +
    theme(
      axis.text.x = element_text(size = 12, face = "bold"),
      axis.text.y = element_blank(),
      axis.ticks.y = element_blank(),
      panel.grid.major.y = element_blank(),
      panel.grid.minor.y = element_blank(),
      panel.grid.major.x = element_line(color = "#f0f0f0"), # Keep vertical grid
      legend.position = "bottom",
      legend.text = element_text(size = 11),
      plot.title = element_text(size = 14, face = "bold")
    )
  
  ggplotly(plot, tooltip = c("text")) %>%
    layout(
      font = list(family = "Georgia"),
      legend = list(orientation = "h", x = 0, y = -0.15)
    )
}

# 3yr/6yr Comparison function --------------------------------------------------------

get_comparison_data <- function(institutions) {
  current_year <- 2026
  
  # Last 3 years: 2024-2026
  last_3yr <- data %>%
    filter(institution %in% institutions,
           as.numeric(as.character(decision_year)) >= current_year - 2,
           !is.na(decision_month_day))
  
  # Last 6 years: 2021-2026
  last_6yr <- data %>%
    filter(institution %in% institutions,
           as.numeric(as.character(decision_year)) >= current_year - 6,
           !is.na(decision_month_day))
  
  get_first <- function(df, dec_type) {
    result <- df %>%
      filter(decision == dec_type) %>%
      summarize(first = min(decision_month_day, na.rm = TRUE)) %>%
      pull(first)
    
    if (is.infinite(result) || is.na(result)) {
      return("N/A")
    } else {
      return(format(result, "%m/%d"))
    }
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
    `Last 6 Years` = c(
      get_first(last_6yr, "Accepted"),
      get_first(last_6yr, "Rejected"),
      get_first(last_6yr, "Interview"),
      get_first(last_6yr, "Wait listed"),
      as.character(nrow(last_6yr))
    )
  )
}

# Single date functions --------------------------------------------------------

first_acceptance <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions,
           decision %in% decisions_filter,
           decision_year %in% years_filter,
           decision == "Accepted",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date)) {
    paste("First Acceptance:", format(key_dates$first_date, "%m/%d"))
  } else {
    "First Acceptance: N/A"
  }
}

first_rejection <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions,
           decision %in% decisions_filter,
           decision_year %in% years_filter,
           decision == "Rejected",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date)) {
    paste("First Rejection:", format(key_dates$first_date, "%m/%d"))
  } else {
    "First Rejection: N/A"
  }
}

first_waitlist <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions,
           decision %in% decisions_filter,
           decision_year %in% years_filter,
           decision == "Wait listed",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date)) {
    paste("First Waitlist:", format(key_dates$first_date, "%m/%d"))
  } else {
    "First Waitlist: N/A"
  }
}

first_interview <- function(institutions, decisions_filter, years_filter) {
  key_dates <- data %>%
    filter(institution %in% institutions,
           decision %in% decisions_filter,
           decision_year %in% years_filter,
           decision == "Interview",
           !is.na(decision_month_day)) %>%
    summarize(first_date = min(decision_month_day, na.rm = TRUE))
  
  if (nrow(key_dates) == 1 && !is.infinite(key_dates$first_date) && !is.na(key_dates$first_date)) {
    paste("First Interview:", format(key_dates$first_date, "%m/%d"))
  } else {
    "First Interview: N/A"
  }
}
