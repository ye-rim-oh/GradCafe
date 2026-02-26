# GradCafe PhD Admission Dashboard v3.0
# Upgraded: unified data, nationality/subfield tabs, trend charts

library(shiny)
library(tidyverse)
library(plotly)
library(stringr)
library(shinyjs)
library(shinyWidgets)
library(DT)

source("app_functions.R")

# Get list of all schools
overall_label <- "Overall (All Schools)"
school_choices_actual <- sort(unique_institutions$Institution)
school_choices <- c(overall_label, school_choices_actual)

available_years <- sort(unique(data$decision_year), decreasing = TRUE)
default_years <- available_years

# Color palette
nat_colors <- c("American" = "#2563eb", "International" = "#dc2626")
sf_colors <- c("CP" = "#6482A6", "IR" = "#CC7E7E", "AP" = "#729C7A",
               "Theory" = "#927AA6", "Methods" = "#D49D75",
               "Public Law/Policy" = "#659AA6", "Psych/Behavior" = "#B07590")

# =====================================================================
# UI
# =====================================================================
ui <- fluidPage(

  tags$head(
    tags$title("PhD Admission Results Dashboard"),
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"),
    tags$link(href = "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap",
              rel = "stylesheet"),
    tags$style(HTML("
      :root {
        --ink: #0f172a;
        --muted: #64748b;
        --paper: #ffffff;
        --surface: #f8fafc;
        --border: #e2e8f0;
        --accent: #2563eb;
        --radius: 12px;
      }

      body {
        font-family: 'Georgia', serif;
        background: linear-gradient(135deg, #f0f4ff 0%, #fafbff 50%, #f5f3ff 100%);
        min-height: 100vh;
        padding: 16px;
        color: var(--ink);
        font-size: 16px;
        letter-spacing: -0.01em;
      }

      .container-fluid {
        background: var(--paper);
        border-radius: 16px;
        padding: 24px;
        box-shadow: 0 1px 3px rgba(0,0,0,0.06), 0 8px 24px rgba(0,0,0,0.04);
        border: 1px solid var(--border);
        margin: 0 auto;
        min-width: 900px;
      }

      .main-title h2 {
        font-family: 'Georgia', serif;
        font-weight: 700;
        font-size: 2.2rem;
        color: var(--ink);
        margin-bottom: 4px;
        letter-spacing: -0.02em;
      }

      .main-title h5 {
        font-family: 'Georgia', serif;
        color: var(--muted);
        font-weight: 400;
        font-size: 1.2rem;
        letter-spacing: 0.02em;
      }

      .sidebar {
        background: var(--surface);
        border-radius: var(--radius);
        padding: 20px;
        border: 1px solid var(--border);
      }

      .nav-tabs { border-bottom: 2px solid var(--border); margin-bottom: 16px; }
      .nav-tabs > li > a {
        font-weight: 500;
        font-size: 1.25rem;
        color: var(--muted);
        border: none;
        padding: 8px 16px;
      }
      .nav-tabs > li.active > a,
      .nav-tabs > li.active > a:hover,
      .nav-tabs > li.active > a:focus {
        color: var(--accent);
        border: none;
        border-bottom: 2px solid var(--accent);
        background: transparent;
        font-weight: 600;
      }

      .stats-box {
        background: var(--paper);
        border-radius: var(--radius);
        padding: 16px;
        margin: 8px 0;
        box-shadow: 0 1px 2px rgba(0,0,0,0.04);
        border: 1px solid var(--border);
      }

      .stats-box h4 {
        font-weight: 600;
        font-size: 1.4rem;
        color: var(--ink);
        margin-bottom: 12px;
      }

      .summary-item {
        background: var(--surface);
        border-radius: 6px;
        padding: 6px 10px;
        margin: 4px 0;
        font-size: 1.1rem;
        font-weight: 500;
        border-left: 3px solid var(--accent);
        color: var(--ink);
      }

      .form-group label {
        font-weight: 600;
        color: var(--ink);
        font-size: 1.15rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
      }

      .selectize-input {
        border-radius: 8px !important;
        border: 1px solid var(--border) !important;
        padding: 8px 12px !important;
        font-size: 1.15rem !important;
        background: var(--paper) !important;
      }

      .btn-outline-secondary {
        border-radius: 8px;
        padding: 8px 16px;
        font-weight: 500;
        font-size: 1.15rem;
        color: var(--ink);
        border-color: var(--border);
      }

      .comparison-table {
        background: var(--paper);
        border-radius: 8px;
        padding: 12px;
        margin-top: 12px;
        border: 1px solid var(--border);
      }

      .comparison-table h6 {
        font-weight: 600;
        color: var(--ink);
        margin-bottom: 6px;
        font-size: 1rem;
        text-transform: uppercase;
        letter-spacing: 0.04em;
      }

      #comparison_table table {
        font-size: 1rem;
      }

      .dataTables_wrapper { font-size: 1.15rem; }
      table.dataTable thead th { background: var(--surface); font-weight: 600; color: var(--ink); }

      @media (max-width: 768px) {
        body { font-size: 15px; padding: 8px; }
        .container-fluid { padding: 12px; }
      }
    "))
  ),

  useShinyjs(),

  titlePanel(
    div(class = "main-title",
        h2("PhD Admission Results Dashboard"),
        h5("Political Science & Government | GradCafe 2020-2026")
    )
  ),

  sidebarLayout(
    sidebarPanel(
      class = "sidebar",
      width = 3,

      div(id = "form",
          pickerInput("institutions",
                      label = "School",
                      choices = NULL,
                      multiple = FALSE,
                      options = list(`live-search` = TRUE, size = 10, style = "btn-white")),

          checkboxGroupInput("years",
                             label = "Years",
                             choices = available_years,
                             selected = available_years,
                             inline = TRUE),

          checkboxGroupInput("decisions",
                             label = "Decision Types",
                             choices = levels(data$decision),
                             selected = c("Accepted", "Rejected", "Interview", "Wait listed"),
                             inline = TRUE),

          hr(style = "border-color: #e2e8f0; margin: 12px 0;"),

          actionButton("resetAll", "Reset Filters",
                       class = "btn-outline-secondary btn-sm",
                       style = "width: 100%;"),

          hr(style = "border-color: #e2e8f0; margin: 12px 0;"),

          h6("Key Dates", style = "font-weight: 600; font-size: 0.8rem; text-transform: uppercase; letter-spacing: 0.04em;"),
          div(class = "summary-item", textOutput("first_acceptance")),
          div(class = "summary-item", textOutput("first_rejection")),
          div(class = "summary-item", textOutput("first_interview")),
          div(class = "summary-item", textOutput("first_waitlist")),

          div(class = "comparison-table",
              h6("3yr vs All-Years Comparison"),
              tableOutput("comparison_table")
          )
      )
    ),

    mainPanel(
      width = 9,

      tabsetPanel(
        type = "tabs",

        # --- Tab 1: Timeline ---
        tabPanel("Timeline",
                 div(class = "stats-box",
                     h4("Decision Timeline"),
                     plotlyOutput("calendar_viz", height = "700px")
                 )
        ),

        # --- Tab 2: Trends ---
        tabPanel("Trends",
                 div(class = "stats-box",
                     h4("Yearly Acceptance Rate"),
                     plotlyOutput("trend_rate", height = "450px")
                 ),
                 div(class = "stats-box",
                     h4("American vs International Acceptance Rate"),
                     plotlyOutput("trend_nationality", height = "450px")
                 )
        ),

        # --- Tab 3: Subfields ---
        tabPanel("Subfields",
                 div(class = "stats-box",
                     h4("Subfield Report Volume (excl. Unknown)"),
                     plotlyOutput("subfield_vol", height = "450px")
                 ),
                 div(class = "stats-box",
                     h4("Subfield Acceptance Rate (n>=3)"),
                     plotlyOutput("subfield_rate", height = "450px")
                 )
        ),

        # --- Tab 4: Data Table ---
        tabPanel("Data",
                 div(class = "stats-box",
                     h4("All Results"),
                     DTOutput("results_table"),
                     conditionalPanel(
                       condition = "input.results_table_rows_selected.length > 0",
                       hr(),
                       h5("Selected Applicant Details:", style = "font-weight: 600; font-size: 0.9rem;"),
                       verbatimTextOutput("selected_details")
                     )
                 )
        )
      )
    )
  )
)

# =====================================================================
# SERVER
# =====================================================================
server <- function(input, output, session) {

  observe({
    updatePickerInput(session, "institutions",
                      choices = school_choices,
                      selected = overall_label)
  })

  is_overall <- reactive({
    !is.null(input$institutions) && identical(input$institutions, overall_label)
  })

  selected_institutions <- reactive({
    req(input$institutions)
    if (is_overall()) return(school_choices_actual)
    input$institutions
  })

  filtered_data <- reactive({
    data %>%
      filter(institution %in% selected_institutions(),
             decision %in% input$decisions,
             decision_year %in% input$years)
  })

  # --- Tab 1: Timeline ---
  output$calendar_viz <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    decision_calendar(
      selected_institutions(),
      input$decisions,
      input$years,
      title_label = if (is_overall()) overall_label else NULL
    )
  })

  # --- Tab 2: Trends ---
  output$trend_rate <- renderPlotly({
    rate_data <- get_yearly_accept_rate(selected_institutions())
    req(nrow(rate_data) > 0)

    plot_ly(rate_data, x = ~decision_year, y = ~rate,
            type = "scatter", mode = "lines+markers+text",
            line = list(color = "black", width = 3),
            marker = list(size = 10, color = "black"),
            text = ~paste0(round(rate, 1), "%"),
            textposition = "top center",
            hovertemplate = "Year: %{x}<br>Rate: %{y:.1f}%<br>n=%{customdata}<extra></extra>",
            customdata = ~total) %>%
      layout(xaxis = list(title = "", tickmode = "linear", dtick = 1),
             yaxis = list(title = "Accept Rate (%)"),
             plot_bgcolor = "rgba(0,0,0,0)",
             paper_bgcolor = "rgba(0,0,0,0)")
  })

  output$trend_nationality <- renderPlotly({
    nat_data <- get_nat_rate(selected_institutions())
    req(nrow(nat_data) > 0)

    plot_ly(nat_data, x = ~decision_year, y = ~rate, color = ~status,
            colors = nat_colors, type = "scatter", mode = "lines+markers",
            line = list(width = 3), marker = list(size = 9),
            hovertemplate = "%{fullData.name}<br>Year: %{x}<br>Rate: %{y:.1f}%<br>n=%{customdata}<extra></extra>",
            customdata = ~n) %>%
      layout(xaxis = list(title = "", tickmode = "linear", dtick = 1),
             yaxis = list(title = "Accept Rate (%)"),
             legend = list(orientation = "h", x = 0.3, y = -0.15),
             plot_bgcolor = "rgba(0,0,0,0)",
             paper_bgcolor = "rgba(0,0,0,0)")
  })

  # --- Tab 3: Subfields ---
  output$subfield_vol <- renderPlotly({
    sf_data <- filtered_data() %>%
      filter(subfield != "Unknown") %>%
      group_by(decision_year, subfield) %>%
      summarise(n = n(), .groups = "drop")

    req(nrow(sf_data) > 0)

    plot_ly(sf_data, x = ~decision_year, y = ~n, color = ~subfield,
            colors = sf_colors, type = "bar",
            hovertemplate = "%{fullData.name}<br>Year: %{x}<br>Count: %{y}<extra></extra>") %>%
      layout(barmode = "stack",
             xaxis = list(title = "", tickmode = "linear", dtick = 1),
             yaxis = list(title = "Count"),
             legend = list(orientation = "h", x = 0, y = -0.2),
             plot_bgcolor = "rgba(0,0,0,0)",
             paper_bgcolor = "rgba(0,0,0,0)")
  })

  output$subfield_rate <- renderPlotly({
    sf_rate <- filtered_data() %>%
      filter(subfield %in% c("CP", "IR", "AP", "Theory", "Methods"),
             decision %in% c("Accepted", "Rejected")) %>%
      group_by(decision_year, subfield) %>%
      summarise(rate = sum(decision == "Accepted") / n() * 100,
                n = n(), .groups = "drop") %>%
      filter(n >= 3)

    req(nrow(sf_rate) > 0)

    plot_ly(sf_rate, x = ~decision_year, y = ~rate, color = ~subfield,
            colors = sf_colors, type = "scatter", mode = "lines+markers",
            line = list(width = 2), marker = list(size = 7),
            hovertemplate = "%{fullData.name}<br>Year: %{x}<br>Rate: %{y:.1f}% (n=%{customdata})<extra></extra>",
            customdata = ~n) %>%
      layout(xaxis = list(title = "", tickmode = "linear", dtick = 1),
             yaxis = list(title = "Accept Rate (%)"),
             legend = list(orientation = "h", x = 0.1, y = -0.15),
             plot_bgcolor = "rgba(0,0,0,0)",
             paper_bgcolor = "rgba(0,0,0,0)")
  })

  # --- Key Dates ---
  output$first_acceptance <- renderText({
    first_acceptance(selected_institutions(), input$decisions, input$years)
  })
  output$first_rejection <- renderText({
    first_rejection(selected_institutions(), input$decisions, input$years)
  })
  output$first_waitlist <- renderText({
    first_waitlist(selected_institutions(), input$decisions, input$years)
  })
  output$first_interview <- renderText({
    first_interview(selected_institutions(), input$decisions, input$years)
  })

  output$comparison_table <- renderTable({
    get_comparison_data(selected_institutions())
  }, striped = TRUE, hover = TRUE, bordered = FALSE, width = "100%")

  # --- Tab 4: Data Table ---
  output$results_table <- renderDT({
    df <- filtered_data() %>%
      select(institution, decision, decision_year, decision_month_day,
             status, subfield, GPA, GRE_V, GRE_Q, notes) %>%
      mutate(
        Date = format(decision_month_day, "%m/%d"),
        Year = as.character(decision_year),
        GPA = ifelse(is.na(GPA), "-", sprintf("%.2f", GPA)),
        GRE = case_when(
          !is.na(GRE_V) & !is.na(GRE_Q) ~ paste0("V", GRE_V, "/Q", GRE_Q),
          !is.na(GRE_V) ~ paste0("V", GRE_V),
          !is.na(GRE_Q) ~ paste0("Q", GRE_Q),
          TRUE ~ "-"
        ),
        Status = ifelse(status == "Unknown", "-", status),
        Subfield = ifelse(subfield == "Unknown", "-", subfield),
        Notes = ifelse(is.na(notes) | notes == "", "-", str_sub(notes, 1, 40))
      )

    if (is_overall()) {
      df <- df %>% select(School = institution, Decision = decision, Year, Date,
                          Status, Subfield, GPA, GRE, Notes)
    } else {
      df <- df %>% select(Decision = decision, Year, Date,
                          Status, Subfield, GPA, GRE, Notes)
    }

    datatable(df,
              selection = "single",
              options = list(pageLength = 10, dom = 'frtip',
                             language = list(search = "Search:")),
              rownames = FALSE,
              class = 'compact stripe') %>%
      formatStyle(
        'Decision',
        backgroundColor = styleEqual(
          c("Accepted", "Rejected", "Interview", "Wait listed"),
          c("#dbeafe", "#fee2e2", "#dcfce7", "#fef3c7")
        )
      )
  })

  output$selected_details <- renderText({
    req(input$results_table_rows_selected)
    selected_row <- filtered_data()[input$results_table_rows_selected, ]
    school_line <- if (is_overall()) paste0("School: ", selected_row$institution, "\n") else ""
    gre_detail <- case_when(
      !is.na(selected_row$GRE_V) & !is.na(selected_row$GRE_Q) ~
        paste0("GRE: V", selected_row$GRE_V, "/Q", selected_row$GRE_Q),
      !is.na(selected_row$GRE_V) ~ paste0("GRE: V", selected_row$GRE_V),
      !is.na(selected_row$GRE_Q) ~ paste0("GRE: Q", selected_row$GRE_Q),
      TRUE ~ "GRE: Not reported"
    )
    paste0(
      school_line,
      "Decision: ", selected_row$decision, "\n",
      "Year: ", selected_row$decision_year, "\n",
      "Date: ", format(selected_row$decision_month_day, "%m/%d"), "\n",
      "Nationality: ", ifelse(selected_row$status == "Unknown", "Not reported", selected_row$status), "\n",
      "Subfield: ", ifelse(selected_row$subfield == "Unknown", "Not reported", selected_row$subfield), "\n",
      "GPA: ", ifelse(is.na(selected_row$GPA), "Not reported", selected_row$GPA), "\n",
      gre_detail, "\n",
      "\nNotes:\n", ifelse(is.na(selected_row$notes) | selected_row$notes == "", "No notes", selected_row$notes)
    )
  })

  observeEvent(input$resetAll, { reset("form") })
}

shinyApp(ui, server)
