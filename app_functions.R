# app_functions.R -- Data loading and helper functions for the Shiny Dashboard
# Uses scraped_2020_2026_combined.Rdata (unified parser)

library(tidyverse)
library(lubridate)
library(plotly)

load("scraped_2020_2026_combined.Rdata")
df_raw <- as.data.frame(data)

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

# --- Better Institution Normalization ---
# Re-normalize using the raw 'school' column to fix UC aggregation errors
df_raw <- df_raw %>%
  filter(!grepl("Piss|Trump|McDonalds|Ravinder|Cocksucker|Cunnilingus", school, ignore.case = TRUE)) %>%
  # Remove truncated / garbled school names that cannot be reliably identified
  filter(!grepl("^Corne$|^Penn s$|^Penns$|^Stony$|^University of Chi$", school, ignore.case = TRUE)) %>%
  filter(!grepl("^University of Connec$|^University of Oreg$|^University Of Wiscon$", school, ignore.case = TRUE)) %>%
  filter(!grepl("Universitywestern$|UniversityGSB$|Ann Arbor\\)gan|Madisonnsin$", school)) %>%
  filter(!grepl("^Florida International University\u00c2$|^Floirda International", school)) %>%
  filter(!grepl("^University of mennesota$", school, ignore.case = TRUE)) %>%
  filter(!grepl("^Brown Rice University$", school)) %>%
  filter(!grepl("^Iqtisad Uni$", school)) %>%
  # Remove department-level entries (not actual school names)
  filter(!grepl("^Graduate School Of Arts|^Henry Jackson School|^Said Business School$|^Krieger School|^Kennedy School Of|^SAIS$", school)) %>%
  mutate(
    # First, apply Title Case to raw institution string so fallbacks are clean
    institution = str_to_title(institution),
    institution = str_replace_all(institution, "(?i)\\b of \\b", " of "),
    institution = str_replace_all(institution, "\\b(At|In|And)\\b", function(x) tolower(x)),
    school = str_replace_all(school, "(?i)\\b of \\b", " of ")
  ) %>%
  mutate(
    institution = case_when(
      grepl("Santa Barbara|UCSB", school, ignore.case = TRUE) ~ "University of California, Santa Barbara (UCSB)",
      grepl("Irvine|UCI", school, ignore.case = TRUE) ~ "University of California, Irvine (UCI)",
      grepl("Santa Cruz|UCSC", school, ignore.case = TRUE) ~ "University of California, Santa Cruz (UCSC)",
      grepl("Riverside|UC RIVERSIDE|UCR", school, ignore.case = TRUE) ~ "University of California, Riverside (UCR)",
      grepl("Merced|UCM", school, ignore.case = TRUE) ~ "University of California, Merced (UCM)",
      grepl("Davis|UCD", school, ignore.case = TRUE) ~ "University of California, Davis (UCD)",
      grepl("San Diego|UCSD", school, ignore.case = TRUE) ~ "University of California, San Diego (UCSD)",
      grepl("Los Angeles|UCLA", school, ignore.case = TRUE) ~ "University of California, Los Angeles (UCLA)",
      grepl("Berkeley|UCB", school, ignore.case = TRUE) ~ "University of California, Berkeley (UCB)",
      grepl("University of California$", school, ignore.case = TRUE) ~ "University of California (Unspecified)",
      
      grepl("^Colorado.*Boulder|^University of Colorado Boulder", school, ignore.case = TRUE) ~ "University of Colorado Boulder (CU Boulder)",
      grepl("Florida International|^Floirda International", school, ignore.case = TRUE) ~ "Florida International University (FIU)",
      grepl("Florida Atlantic", school, ignore.case = TRUE) ~ "Florida Atlantic University (FAU)",
      grepl("Florida State|FSU", school, ignore.case = TRUE) ~ "Florida State University (FSU)",
      grepl("Illinois.*Urbana|Illinois UIUC|UIUC|^University of Illinois$", school, ignore.case = TRUE) ~ "University of Illinois Urbana-Champaign (UIUC)",
      grepl("Illinois.*Chicago|UIC", school, ignore.case = TRUE) ~ "University of Illinois Chicago (UIC)",
      grepl("Texas A&M|TAMU|Texas A & M", school, ignore.case = TRUE) ~ "Texas A&M University (TAMU)",
      grepl("Texas.*Austin|UT Austin|^University of Texas$", school, ignore.case = TRUE) ~ "University of Texas at Austin (UT Austin)",
      grepl("Western Washington", school, ignore.case = TRUE) ~ "Western Washington University",
      grepl("Washington University.*St|WUSTL|WashU|^Washington University$", school, ignore.case = TRUE) ~ "Washington University in St. Louis",
      grepl("^University of Washington|UW Seattle", school, ignore.case = TRUE) ~ "University of Washington (UW)",
      
      grepl("Southern California|USC", school, ignore.case = TRUE) ~ "University of Southern California (USC)",
      grepl("Max Plank|Max Planck|IMPRS", school, ignore.case = TRUE) ~ "International Max Planck Research School (IMPRS)",
      grepl("Pennsylvania.*State|Penn State|PSU|Penns$|Penn s", school, ignore.case = TRUE) ~ "Pennsylvania State University (PSU)",
      grepl("Pennsylvania|UPenn|U Penn", school, ignore.case = TRUE) ~ "University of Pennsylvania (UPenn)",
      grepl("Maryland.*College Park|[^a-z]UMD|^University of Maryland$|^University of maryland", school, ignore.case = TRUE) ~ "University of Maryland, College Park (UMD)",
      grepl("North Carolina.*Chapel|^UNC[- ]|[^a-z]UNC[^a-z]|^UNC$|^University of North Carolina$", school, ignore.case = TRUE) ~ "University of North Carolina at Chapel Hill (UNC)",
      grepl("City University of New York|CUNY|Graduate Center", school, ignore.case = TRUE) ~ "City University of New York (CUNY)",
      grepl("British Columbia|UBC", school, ignore.case = TRUE) ~ "University of British Columbia (UBC)",
      grepl("London School of Economics|LSE", school, ignore.case = TRUE) ~ "London School of Economics (LSE)",
      grepl("Bocconi", school, ignore.case = TRUE) ~ "Bocconi University",
      grepl("Binghamton", school, ignore.case = TRUE) ~ "Binghamton University (SUNY)",
      grepl("Stony|Stony Brook", school, ignore.case = TRUE) ~ "Stony Brook University (SUNY)",
      grepl("Albany", school, ignore.case = TRUE) ~ "University at Albany (SUNY)",
      grepl("Buffalo", school, ignore.case = TRUE) ~ "University at Buffalo (SUNY)",
      grepl("Columbia.*Teachers|Teachers College", school, ignore.case = TRUE) ~ "Teachers College, Columbia University",
      
      # Badly chopped names and sole words
      grepl("University of Connec", school, ignore.case = TRUE) ~ "University of Connecticut (UConn)",
      grepl("University of Oreg", school, ignore.case = TRUE) ~ "University of Oregon",
      grepl("Wisconsin", school, ignore.case = TRUE) ~ "University of Wisconsin-Madison (UW-Madison)",
      grepl("Cornell", school, ignore.case = TRUE) ~ "Cornell University",
      grepl("UChicago|Chicago", school, ignore.case = TRUE) ~ "University of Chicago (UChicago)",
      grepl("Virginia", school, ignore.case = TRUE) ~ "University of Virginia (UVA)",
      grepl("Minnesota|mennesota", school, ignore.case = TRUE) ~ "University of Minnesota",
      grepl("Brown Rice", school, ignore.case = TRUE) ~ "Brown University",
      grepl("Arizona State", school, ignore.case = TRUE) ~ "Arizona State University (ASU)",
      grepl("Arizona", school, ignore.case = TRUE) ~ "University of Arizona (UA)",
      grepl("Indiana", school, ignore.case = TRUE) ~ "Indiana University Bloomington (IU)",
      grepl("Alabama", school, ignore.case = TRUE) ~ "University of Alabama (UA)",
      grepl("Iqtisad", school, ignore.case = TRUE) ~ "Iqtisad University",
      grepl("Purdue", school, ignore.case = TRUE) ~ "Purdue University",
      grepl("Hillsdale", school, ignore.case = TRUE) ~ "Hillsdale College",
      grepl("Denver.*Korbel|University of Denver", school, ignore.case = TRUE) ~ "University of Denver (Korbel)",
      
      # Proper full names for Ivies and Majors
      grepl("Yale", school, ignore.case = TRUE) ~ "Yale University",
      grepl("Harvard|Kennedy School", school, ignore.case = TRUE) ~ "Harvard University",
      grepl("Stanford", school, ignore.case = TRUE) ~ "Stanford University",
      grepl("Princeton", school, ignore.case = TRUE) ~ "Princeton University",
      grepl("Columbia", school, ignore.case = TRUE) ~ "Columbia University",
      grepl("Brown", school, ignore.case = TRUE) ~ "Brown University",
      grepl("Dartmouth", school, ignore.case = TRUE) ~ "Dartmouth College",
      grepl("Massachusetts Institute of Technology|^MIT$", school, ignore.case = TRUE) ~ "Massachusetts Institute of Technology (MIT)",
      grepl("New York University|NYU|Steinhardt", school, ignore.case = TRUE) ~ "New York University (NYU)",
      grepl("Northwestern", school, ignore.case = TRUE) ~ "Northwestern University (NU)",
      grepl("Duke", school, ignore.case = TRUE) ~ "Duke University",
      grepl("Johns Hopkins|SAIS|Bloomberg|Krieger", school, ignore.case = TRUE) ~ "Johns Hopkins University (JHU)",
      grepl("Michigan", school, ignore.case = TRUE) ~ "University of Michigan (UMich)",
      grepl("Emory", school, ignore.case = TRUE) ~ "Emory University",
      grepl("Toronto", school, ignore.case = TRUE) ~ "University of Toronto (UofT)",
      grepl("Pompeu Fabra|UPF", school, ignore.case = TRUE) ~ "Pompeu Fabra University (UPF)",
      grepl("Syracuse|Maxwell", school, ignore.case = TRUE) ~ "Syracuse University",
      grepl("Georgetown", school, ignore.case = TRUE) ~ "Georgetown University",
      grepl("George Washington", school, ignore.case = TRUE) ~ "George Washington University (GWU)",
      grepl("Georgia State", school, ignore.case = TRUE) ~ "Georgia State University",
      grepl("Georgia.*Athens|[^a-z]UGA[^a-z]|^UGA$|^University of Georgia$", school, ignore.case = TRUE) ~ "University of Georgia (UGA)",
      grepl("Rutgers", school, ignore.case = TRUE) ~ "Rutgers University",
      grepl("^American U|American University", school, ignore.case = TRUE) ~ "American University (AU)",
      grepl("McGill", school, ignore.case = TRUE) ~ "McGill University",
      grepl("McMaster", school, ignore.case = TRUE) ~ "McMaster University",
      grepl("Queen.*Canada|Queens University", school, ignore.case = TRUE) ~ "Queen's University",
      grepl("^York University", school, ignore.case = TRUE) ~ "York University",
      grepl("European University Institute|EUI", school, ignore.case = TRUE) ~ "European University Institute (EUI)",
      grepl("Cambridge", school, ignore.case = TRUE) ~ "University of Cambridge",
      grepl("Oxford", school, ignore.case = TRUE) ~ "University of Oxford",
      grepl("Fletcher School|^Tufts", school, ignore.case = TRUE) ~ "Tufts University (Fletcher)",
      grepl("Texas Tech", school, ignore.case = TRUE) ~ "Texas Tech University",
      grepl("Washington State", school, ignore.case = TRUE) ~ "Washington State University (WSU)",
      grepl("New School", school, ignore.case = TRUE) ~ "The New School",
      grepl("Central European University", school, ignore.case = TRUE) ~ "Central European University (CEU)",
      grepl("Richard Gilder|AMNH", school, ignore.case = TRUE) ~ "Richard Gilder Graduate School (AMNH)",
      grepl("Rice", school, ignore.case = TRUE) ~ "Rice University",
      grepl("Rochester", school, ignore.case = TRUE) ~ "University of Rochester",
      grepl("Ohio State|^OSU|Ohio State University - Columbus", school, ignore.case = TRUE) ~ "Ohio State University (OSU)",
      grepl("Ohio University", school, ignore.case = TRUE) ~ "Ohio University",
      grepl("EMBL", school, ignore.case = TRUE) ~ "European Molecular Biology Laboratory (EMBL)",
      grepl("ETH Zurich", school, ignore.case = TRUE) ~ "ETH Zurich",
      grepl("Geneva Graduate Institute", school, ignore.case = TRUE) ~ "Geneva Graduate Institute",
      grepl("Vanderbilt", school, ignore.case = TRUE) ~ "Vanderbilt University",
      grepl("Nebraska", school, ignore.case = TRUE) ~ "University of Nebraska-Lincoln",
      grepl("Tulane", school, ignore.case = TRUE) ~ "Tulane University",
      grepl("Tennessee", school, ignore.case = TRUE) ~ "University of Tennessee (UTK)",
      grepl("South Carolina", school, ignore.case = TRUE) ~ "University of South Carolina (USC)",
      grepl("Massachusetts.*Amherst|UMass", school, ignore.case = TRUE) ~ "University of Massachusetts Amherst (UMass)",
      grepl("Notre Dame", school, ignore.case = TRUE) ~ "University of Notre Dame",
      
      TRUE ~ institution
    )
  ) %>%
  mutate(
    # Force anything inside parentheses to be fully uppercase (e.g. (Cuhk) -> (CUHK))
    institution = str_replace_all(institution, "\\((.*?)\\)", function(x) toupper(x)),
    institution = str_replace_all(institution, "\\b(?i)(Uiuc|Ucla|Mit|Nyu|Suny|Cuny|Psu|Ubc|Lse|Usc|Tamu|Wustl|Umich|Uga|Sais)\\b", function(x) toupper(x)),
    institution = str_replace_all(institution, "Â|\\s+$", "")
  )

# Rename columns for Shiny compatibility
# Drop the original scraper columns that conflict, use our recomputed ones
data <- df_raw %>%
  select(-decision_year, -decision_month_day) %>%
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
