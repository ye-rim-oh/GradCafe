# GradCafe PhD Admission Dashboard v2.0

library(shiny)
library(tidyverse)
library(plotly)
library(stringr)
library(shinyjs)
library(shinyWidgets)
library(DT)

source("Functions_v2.R")

# Get list of all schools (Alphabetical Sort)
overall_label <- "Overall (All Schools)"
school_choices_actual <- sort(unique_institutions$Institution)
school_choices <- c(overall_label, school_choices_actual)

# Default Years (Top 3 Recent)
# Ensure we pick the numeric max years available
available_years <- as.character(years[[1]])
default_years <- available_years[available_years %in% c("2026", "2025", "2024")]
if (length(default_years) == 0) {
  default_years <- head(available_years, 3) # fallback
}

# UI ----
ui <- fluidPage(
  
  tags$head(
    tags$title("PhD Admission Results Dashboard"), # Explicit Browser Title
    tags$meta(name = "viewport", content = "width=device-width, initial-scale=1"), # Mobile Viewport
    tags$style(HTML("
      :root {
        --ink: #111111;
        --muted: #6a6a6a;
        --paper: #ffffff;
        --fog: #f3f3f3;
        --line: #d9d9d9;
        --shadow: 0 20px 60px rgba(0,0,0,0.08);
      }

      body { 
        font-family: \"Georgia\", \"Times New Roman\", serif;
        background:
          radial-gradient(1200px 600px at 10% -10%, #f7f7f7 0%, transparent 60%),
          radial-gradient(1000px 500px at 100% 0%, #efefef 0%, transparent 55%),
          linear-gradient(180deg, #ffffff 0%, #f5f5f5 100%);
        min-height: 100vh;
        padding: 22px;
        color: var(--ink);
        font-size: clamp(14px, 1.4vw, 18px);
        letter-spacing: 0.2px;
        animation: fadeIn 0.6s ease-out;
      }

      @keyframes fadeIn {
        from { opacity: 0; transform: translateY(8px); }
        to { opacity: 1; transform: translateY(0); }
      }

      /* Aggressively force inheritance/same size for ALL UI text elements */
      .btn, .form-control, .dropdown-menu, .control-label, 
      .dataTables_wrapper, .dataTables_info, .dataTables_paginate,
      table.dataTable, table.table, th, td, tr,
      .well, pre, .shiny-text-output,
      .shiny-input-container, .selectize-input, .option,
      .checkbox-inline, .radio-inline, label,
      .well h3, .well h4, .well strong,
      .main-title h2, .main-title h5, h3, h4, h5 {
        font-size: clamp(14px, 1.4vw, 18px) !important;
        line-height: 1.5 !important;
        font-weight: 400 !important; /* Explicitly normal */
      }

      .main-title h2 {
        font-family: \"Garamond\", \"Georgia\", serif;
        font-size: clamp(22px, 3vw, 34px) !important;
        letter-spacing: 0.4px;
        text-transform: uppercase;
        font-weight: 700 !important;
      }

      /* Fix Sidebar Table Overflow */
      .well table {
        display: block;
        overflow-x: auto;
        white-space: nowrap;
        width: 100%;
      }

      /* Make Sidebar Headers Bigger */
      .well h3, .well h4, .well strong {
        font-size: clamp(18px, 2.0vw, 24px) !important;
        font-weight: 700 !important;
        color: var(--ink);
      }

      .container-fluid {
        background: rgba(255, 255, 255, 0.98);
        border-radius: 18px;
        padding: 28px;
        box-shadow: var(--shadow);
        border: 1px solid var(--line);
      }

      /* Equalize sidebar and main panel heights */
      .main-layout > .row {
        display: flex;
        align-items: stretch;
      }

      .main-layout > .row > [class^=\"col-\"] {
        display: flex;
        flex-direction: column;
      }

      .main-layout .sidebar {
        flex: 1;
      }

      .main-title h2 { 
        color: var(--ink);
        font-weight: 700;
        margin-bottom: 6px;
      }

      .main-title h5 {
        color: var(--muted);
        font-weight: 400;
        font-size: 0.95rem;
        letter-spacing: 0.6px;
        text-transform: uppercase;
      }

      .sidebar {
        background: linear-gradient(180deg, #ffffff 0%, #f7f7f7 100%);
        border-radius: 14px;
        padding: 22px;
        border: 1px solid var(--line);
      }

      .stats-box { 
        background: var(--paper);
        border-radius: 14px;
        padding: 20px;
        margin: 12px 0;
        box-shadow: 0 6px 18px rgba(0,0,0,0.05);
        border: 1px solid var(--line);
      }

      .stats-box h4 {
        color: var(--ink);
        font-weight: 600;
        font-size: 1.1rem;
        letter-spacing: 0.4px;
        text-transform: uppercase;
        margin-bottom: 10px;
      }

      .stats-box p {
        color: var(--muted);
        font-size: 0.95rem;
        margin-bottom: 8px;
      }

      /* Summary items */
      .summary-item {
        background: var(--paper);
        border-radius: 10px;
        padding: 12px 16px;
        margin: 8px 0;
        font-size: 0.95rem;
        font-weight: 500;
        border-left: 4px solid var(--ink);
        box-shadow: 0 2px 8px rgba(0,0,0,0.04);
        color: var(--ink);
      }

      .summary-item.accepted,
      .summary-item.rejected,
      .summary-item.interview,
      .summary-item.waitlist { border-color: var(--ink); color: var(--ink); }

      /* Form elements */
      .form-group label {
        font-weight: 600;
        color: var(--ink);
        font-size: 0.9rem;
        text-transform: uppercase;
        letter-spacing: 0.6px;
      }

      .selectize-input {
        border-radius: 10px !important;
        border: 2px solid var(--line) !important;
        padding: 10px 14px !important;
        font-size: 1rem !important;
        background: #ffffff !important;
      }

      .btn-outline-secondary {
        border-radius: 10px;
        padding: 10px 18px;
        font-weight: 600;
        font-size: 0.9rem;
        text-transform: uppercase;
        letter-spacing: 0.6px;
        color: var(--ink);
        border-color: var(--ink);
      }

      .checkbox-inline label {
        font-size: 0.9rem;
        margin-right: 12px;
        display: inline-flex;
        align_items: center;
        white-space: nowrap;
        color: var(--ink);
      }

      .checkbox-group {
        display: flex;
        flex-wrap: wrap;
        gap: 8px;
      }

      /* Comparison table */
      .comparison-table {
        background: var(--paper);
        border-radius: 12px;
        padding: 15px;
        margin-top: 15px;
        border: 1px solid var(--line);
      }

      .comparison-table h6 {
        font-weight: 600;
        color: var(--ink);
        margin-bottom: 12px;
        font-size: clamp(14px, 1.4vw, 18px);
        text-transform: uppercase;
        letter-spacing: 0.6px;
      }

      .comparison-table table { width: 100%; font-size: 0.9rem; }
      .comparison-table th { background: #f5f5f5; padding: 8px 10px; font-weight: 600; color: var(--ink); border-bottom: 2px solid var(--line); }
      .comparison-table td { padding: 8px 10px; border-bottom: 1px solid #ececec; }

      /* DataTable - Monochrome */
      .dataTables_wrapper { font-size: 0.95rem; }
      table.dataTable thead th { background: #f6f6f6; font-weight: 600; color: var(--ink); font-size: 0.9rem; }
      table.dataTable tbody td { font-size: 0.9rem; color: var(--ink); }
      /* Mobile Responsiveness */
      @media (max-width: 768px) {
        .main-layout > .row {
          flex-direction: column !important;
          height: auto !important;
        }
        
        .main-layout .sidebar, 
        .main-layout .main-panel {
          width: 100% !important;
          flex: none !important;
        }
        
        .sidebar {
          margin-bottom: 20px;
        }
        
        /* Adjust font sizes for mobile to be readable but not huge */
        body, .btn, .form-control, table.dataTable tbody td {
          font-size: 16px !important; 
        }
        
        h2 { font-size: 24px !important; }
        h4 { font-size: 18px !important; }
      }
    "))
  ),
  
  useShinyjs(),
  
  titlePanel(
    div(class = "main-title",
        h2("PhD Admission Results Dashboard"),
        h5("Political Science & Government Programs | 2020-2026")
    )
  ),
  
  div(class = "main-layout",
      sidebarLayout(
        sidebarPanel(
          class = "sidebar",
          width = 3,
          
          div(id = "form",
              
              pickerInput("institutions", 
                          label = "School",
                          choices = NULL, # Initialize empty to prevent flicker
                          multiple = FALSE,
                          options = list(
                            `live-search` = TRUE,
                            `size` = 10,
                            `style` = "btn-white"
                          )),
              
              checkboxGroupInput("years", 
                                 label = "Years",
                                 choices = years[[1]],
                                 selected = years[[1]], 
                                 inline = TRUE),
              
              checkboxGroupInput("decisions", 
                                 label = "Decision Types",
                                 choices = decisions[[1]],
                                 selected = c("Accepted", "Rejected", "Interview", "Wait listed"),
                                 inline = TRUE),
              
              hr(style = "border-color: #dee2e6; margin: 15px 0;"),
              
              actionButton("resetAll", "Reset Filters", 
                           class = "btn-outline-secondary btn-sm",
                           style = "width: 100%;"),
              
              hr(style = "border-color: #dee2e6; margin: 15px 0;"),
              
              h6("Key Dates (Selected Years)", style = "font-weight: 700; color: #111111; margin-bottom: 10px; text-transform: uppercase; letter-spacing: 0.6px; font-size: clamp(14px, 1.4vw, 18px) !important;"),
              div(class = "summary-item accepted", textOutput("first_acceptance")),
              div(class = "summary-item rejected", textOutput("first_rejection")),
              div(class = "summary-item interview", textOutput("first_interview")),
              div(class = "summary-item waitlist", textOutput("first_waitlist")),
              
              div(class = "comparison-table",
                  h6("3yr vs 6yr Comparison", style = "font-size: clamp(14px, 1.4vw, 18px) !important;"),
                  tableOutput("comparison_table")
              )
          )
        ),
        
        mainPanel(
          width = 9,
          
          fluidRow(
            div(class = "stats-box",
                h4("Decision Timeline"),
                plotlyOutput("calendar_viz", height = "700px")
            )
          ),
          
          fluidRow(
            div(class = "stats-box",
                h4("All Results"),
                DTOutput("results_table"),
                
                conditionalPanel(
                  condition = "input.results_table_rows_selected.length > 0",
                  hr(),
                  h5("Selected Applicant Details:", style = "font-weight: 600; color: #495057; font-size: 1rem;"),
                  verbatimTextOutput("selected_details")
                )
            )
          )
        )
      )
  )
)

# Server ----
server <- function(input, output, session) {
  
  # Server-side update to prevent flicker
  # We load choices here and set Overall as default
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
    if (is_overall()) {
      return(school_choices_actual)
    }
    input$institutions
  })

  filtered_data <- reactive({
    data %>%
      filter(institution %in% selected_institutions(),
             decision %in% input$decisions,
             decision_year %in% input$years)
  })
  
  output$calendar_viz <- renderPlotly({
    req(nrow(filtered_data()) > 0)
    decision_calendar(
      selected_institutions(),
      input$decisions,
      input$years,
      title_label = if (is_overall()) overall_label else NULL,
      y_spacing = if (is_overall()) NULL else 1
    )
  })
  
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
  
  output$results_table <- renderDT({
    df <- filtered_data() %>%
      select(institution, decision, decision_year, decision_month_day, GPA, GRE_V, GRE_Q, notes) %>%
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
        Notes = ifelse(is.na(notes) | notes == "", "-", str_sub(notes, 1, 40))
      )
    
    if (is_overall()) {
      df <- df %>%
        select(School = institution, Decision = decision, Year, Date, GPA, GRE, Notes)
    } else {
      df <- df %>%
        select(Decision = decision, Year, Date, GPA, GRE, Notes)
    }
    
    datatable(df,
              selection = "single",
              options = list(
                pageLength = 5,
                dom = 'frtip',
                language = list(search = "Search:")
              ),
              rownames = FALSE,
              class = 'compact stripe') %>%
      formatStyle(
        'Decision',
        backgroundColor = styleEqual(
          # Accepted = Green (#d4edda)
          # Rejected = Red (#ffcdd2)
          # Interview = Light Yellow (#fff9c4)
          # Wait listed = Orange (#ffe0b2)
          c("Accepted", "Rejected", "Interview", "Wait listed"),
          c("#cce5ff", "#f8d7da", "#d4edda", "#fff3cd")
        ),
        color = styleEqual("Accepted", "black") # Just ensure text is readable
      )
  })
  
  output$selected_details <- renderText({
    req(input$results_table_rows_selected)
    selected_row <- filtered_data()[input$results_table_rows_selected, ]
    school_line <- if (is_overall()) {
      paste0("School: ", selected_row$institution, "\n")
    } else {
      ""
    }
    gre_detail <- ifelse(
      !is.na(selected_row$GRE_V) & !is.na(selected_row$GRE_Q),
      paste0("GRE: V", selected_row$GRE_V, "/Q", selected_row$GRE_Q),
      ifelse(
        !is.na(selected_row$GRE_V),
        paste0("GRE: V", selected_row$GRE_V),
        ifelse(
          !is.na(selected_row$GRE_Q),
          paste0("GRE: Q", selected_row$GRE_Q),
          "GRE: Not reported"
        )
      )
    )
    paste0(
      school_line,
      "Decision: ", selected_row$decision, "\n",
      "Year: ", selected_row$decision_year, "\n",
      "Date: ", format(selected_row$decision_month_day, "%m/%d"), "\n",
      "GPA: ", ifelse(is.na(selected_row$GPA), "Not reported", selected_row$GPA), "\n",
      gre_detail, "\n",
      "\nNotes:\n", ifelse(is.na(selected_row$notes) | selected_row$notes == "", "No notes", selected_row$notes)
    )
  })
  
  observeEvent(input$resetAll, {
    reset("form")
  })
}

shinyApp(ui, server)
