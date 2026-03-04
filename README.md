# GradCafe 2020-2026 Political Science PhD Trend Analysis

🇰🇷 [한국어](README-ko.md)

This repository collects and analyzes self-reported GradCafe admission posts for Political Science PhD cycles from 2020 to 2026, then serves the results through a Shiny dashboard.

## Quick Start

### If data already exists (`scraped_2020_2026_combined.Rdata` is present):

```r
# Launch the Shiny dashboard
Rscript -e "shiny::runApp('app.R')"
```

### Full reproduction (re-scrape from scratch):

```r
Rscript scrape_all_years.R          # Scrapes 2020-2026, produces combined Rdata
Rscript -e "shiny::runApp('app.R')" # Launch the Shiny dashboard
```

## Pipeline

| Step | Script                      | Input                              | Output                                                       |
| ---: | --------------------------- | ---------------------------------- | ------------------------------------------------------------ |
|    1 | `scrape_all_years.R`        | GradCafe website                   | `scraped_2020_2026_combined.Rdata` + per-year `.Rdata` files |
|    - | `app.R` + `app_functions.R` | `scraped_2020_2026_combined.Rdata` | Shiny dashboard (local or shinyapps.io)                      |

## Files

| File                                 | Description                                                         |
| ------------------------------------ | ------------------------------------------------------------------- |
| `scrape_all_years.R`                 | Unified scraper for all years (2020-2026) using the same parser     |
| `app.R`                              | Shiny dashboard app with Timeline, Trends, Subfields, and Data tabs |
| `app_functions.R`                    | Helper functions and data loading for the Shiny app                 |
| `scraped_2020_2026_combined.Rdata`   | Pre-scraped combined dataset                                        |
| `[sample] PhD Admission Analysis.md` | Sample English text report summarizing trends                       |
| `README.md`                          | This file                                                           |

## Code Details

### `scrape_all_years.R` -- Scraper

The scraper pulls GradCafe search results with broad query terms (`political science`, `international relations`, `politics`, `government`) for each season from Fall 2020 to Fall 2026.

- **Page parsing**: Each record is rendered as three `<tr>` rows (main row, badges row, notes row). The parser stitches those rows into one observation.
- **Badge extraction**: GRE (V/Q/AW/Total), GPA, nationality, and season tags are parsed from badge `<div>` elements.
- **Decision parsing**: Decision type and date are parsed from strings such as `"Accepted on 14 Feb"`.
- **Deduplication**: Per-year dedup key is `(school, decision_text, notes, added_date)`.
- **PhD filter**: Only `degree == "PhD"` is kept.
- **Major filter**: After the PhD filter, `program` is normalized and retained only when it is composed of target majors (`political science`, `international relations`, `politics`, `government`) or direct combinations of those labels.
- **Subfield tagging**: Notes are tagged with CP, IR, AP, Theory, Methods, Public Law/Policy, Psych/Behavior, or Unknown using regex rules.
- **Institution handling**: The scraper passes through raw school text; canonical institution normalization happens in `app_functions.R`.

### `app_functions.R` -- Data Loading & Helpers

This script loads `scraped_2020_2026_combined.Rdata` and prepares the final app-ready dataset.

#### Data Cleaning

- **GRE score repair**: Missing `gre_q` is recovered from `gre_total` when possible, and invalid ranges are dropped to `NA`.
- **Date normalization**: Decision dates are collapsed into a common calendar year (`2020-MM-DD`) in `dmd`, making cross-year timeline plots comparable.
- **Junk filtering**: Clearly bogus rows (joke/profanity school names) are removed.

#### Institution Normalization

Institution labels are standardized with a large `case_when()` map using the raw `school` field. Main cleanup categories:

- **Truncated names**: Cut-off entries (e.g. `"Corne"`, `"University of Chi"`, `"Penn s"`) are removed.
- **Garbled names**: Corrupted strings (e.g. `"Northwestern Universitywestern"`) are removed.
- **UC system disaggregation**: Raw entries like `"UC Berkeley"`, `"UCSD"`, `"University of California, Davis"` are mapped to their full canonical forms (e.g. `"University of California, Berkeley (UCB)"`).
- **Abbreviation expansion**: Short forms like `UNC`, `UGA`, `UIUC`, `WashU`, `TAMU`, `UPenn`, `MIT`, `NYU`, etc. are expanded to full university names with the abbreviation in parentheses.
- **Disambiguation**: `Washington University` (in St. Louis) vs. `University of Washington` vs. `Washington State University` vs. `Western Washington University` are each mapped to distinct entries. Similarly, `Georgia State University` vs. `University of Georgia`.
- **Merging variants**: `York University` and `York University (Canada)` are unified into `York University`. Various SUNY campuses (`Binghamton`, `Stony Brook`, `Albany`, `Buffalo`) are tagged with `(SUNY)`.
- **Department-level entries**: Department names posted as if they were institutions are filtered out.

After mapping, a post-processing step uppercases text in parentheses and trims trailing artifacts.

#### Visualization & Analysis Functions

- `decision_calendar()`: Generates an interactive Plotly dot-chart of admission decisions over Jan-Apr, colored by decision type, with hover tooltips showing GRE/GPA/subfield.
- `get_comparison_data()`: Builds a comparison table of first acceptance/rejection/interview/waitlist dates for the last 3 years vs. all years.
- `first_acceptance()`, `first_rejection()`, `first_waitlist()`, `first_interview()`: Return formatted strings of the earliest date for each decision type.
- `get_yearly_accept_rate()`: Computes acceptance rate (Accepted / (Accepted + Rejected)) by year.
- `get_nat_rate()`: Computes acceptance rate broken down by nationality (American vs. International) and year.

### `app.R` -- Shiny Dashboard

The dashboard uses `fluidPage` with a filter sidebar and four tabs:

- **Sidebar**: Institution picker (with "All Schools" aggregate option), year checkboxes, decision type checkboxes, key date summaries, and a 3-year vs. all-year comparison table.
- **Timeline tab**: Interactive dot-plot of decisions across the Jan-Apr calendar, using `decision_calendar()`.
- **Trends tab**: Two Plotly line charts -- yearly acceptance rate and nationality-stratified acceptance rate.
- **Subfields tab**: Two Plotly charts -- subfield report volume over time and subfield-specific acceptance rates (CP, IR, AP, Theory, Methods).
- **Data tab**: A searchable, sortable `DT::datatable` with color-coded decision rows and a detail view panel for selected entries.

## Outputs

### Shiny Dashboard (`app.R`)

Interactive dashboard with:

- **Timeline tab**: Dot-stacked decision timeline with tooltips
- **Trends tab**: Yearly acceptance rate + nationality breakdown
- **Subfields tab**: Subfield report volume and acceptance rate
- **Data tab**: Searchable/filterable data table with detail view
- Sidebar: School selector, year/decision filters, key dates, 3yr vs all-year comparison

### Sample Analysis Report

`[sample] PhD Admission Analysis.md` is an example write-up generated from the dataset, covering acceptance rates, nationality gaps, subfield distribution, and score reporting trends.

## Dependencies

- R (>= 4.0)
- R packages:
  - Scraping: `rvest`, `httr`
  - Analysis: `dplyr`, `tidyr`, `lubridate`, `stringr`
  - Visualization: `plotly`, `ggplot2`
  - Reports: `rmarkdown`, `knitr`, `kableExtra`
  - Shiny: `shiny`, `shinyjs`, `shinyWidgets`, `DT`

Install all at once:

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

## Data Notes & Limitations

- **Self-reported source**: Data comes from anonymous user posts on [The GradCafe](https://www.thegradcafe.com/). Some records can be noisy or incomplete.
- **Cleaning is rule-based**: Regex-based parsing and normalization reduce errors, but edge cases still exist.
- **Last refresh**: March 4, 2026. Current pre-scraped file (`scraped_2020_2026_combined.Rdata`) contains 3,766 rows total, including 858 rows for 2026.
- **Acceptance rate formula**: `Accepted / (Accepted + Rejected)`. Interview and Waitlist are excluded from the denominator.
- **2026 is still moving**: Later posts can change counts and rates.

## Credits & Acknowledgments

This project builds on the earlier GradCafe Political Science PhD analysis by **Martin Devaux**. His original write-up:
<https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

All admission data comes from **[The GradCafe](https://www.thegradcafe.com/survey)**, where applicants self-report outcomes.

## 🕰️ Legacy Versions (Before 2026 Upgrade)

Pre-2026 scripts and old project structure are archived in `legacy_code/`.  
If you need older versions such as `Scraping.R`, `Cleaning.R`, `Functions.R`, or earlier `app.R` variants, use that folder.
