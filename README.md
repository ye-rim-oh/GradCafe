# GradCafe 2020-2026 Political Science PhD Trend Analysis

Reproducible pipeline and interactive dashboards for analyzing GradCafe self-reported admission results across 7 years of Political Science PhD programs.

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

The scraper queries The GradCafe search page for multiple political-science-related keywords (`political science`, `international relations`, `politics`, `government`, `comparative politics`) across each admission season from Fall 2020 to Fall 2026.

- **Page parsing**: Each GradCafe result consists of 3 `<tr>` rows (main data, badge row, notes row). The parser walks through all `<tr>`s and groups them by checking the `tw-border-none` CSS class on child rows.
- **Badge extraction**: GRE scores (V/Q/AW/Total), GPA, nationality (American/International), and season tags are extracted from inline badge `<div>` elements.
- **Decision parsing**: The decision type (Accepted/Rejected/Interview/Wait listed) and date are parsed from strings like `"Accepted on 14 Feb"` using regex.
- **Deduplication**: Results are deduplicated per year by `(school, decision_text, notes, added_date)` to remove overlap between query terms.
- **PhD filter**: Only `degree == "PhD"` rows are kept.
- **Subfield classification**: Notes text is classified into CP, IR, AP, Theory, Methods, or Psych/Behavior using keyword regex matching.
- **Initial institution normalization**: A first-pass `normalize_institution()` function maps common school names to short labels. This is further refined in `app_functions.R`.

### `app_functions.R` -- Data Loading & Helpers

This file loads `scraped_2020_2026_combined.Rdata` and prepares the data for the Shiny dashboard.

#### Data Cleaning

- **GRE score repair**: If `gre_q` is missing but `gre_total` is available (and in the 130-170 or 260-340 range), `gre_q` is derived. Out-of-range GRE values are set to `NA`.
- **Date normalization**: Decision dates are collapsed to a common year (`2020-MM-DD`) in the `dmd` column so that dates from different years can be compared on the same calendar axis. Dates outside Jan-Apr (out of season) are set to `NA`.
- **Junk filtering**: Rows with clearly bogus school names (profanity, joke entries) are removed.

#### Institution Normalization

The core of the data cleaning is a large `case_when()` block that re-normalizes school names using the raw `school` column. This addresses several categories of issues:

- **Truncated names**: Entries with prematurely cut-off names (e.g. `"Corne"`, `"University of Chi"`, `"Penn s"`) are filtered out entirely, since the underlying data may also be unreliable.
- **Garbled names**: Entries with corrupted text (e.g. `"Northwestern Universitywestern"`, `"University Of Michigan (Ann Arbor)gan"`) are filtered out.
- **UC system disaggregation**: Raw entries like `"UC Berkeley"`, `"UCSD"`, `"University of California, Davis"` are mapped to their full canonical forms (e.g. `"University of California, Berkeley (UCB)"`).
- **Abbreviation expansion**: Short forms like `UNC`, `UGA`, `UIUC`, `WashU`, `TAMU`, `UPenn`, `MIT`, `NYU`, etc. are expanded to full university names with the abbreviation in parentheses.
- **Disambiguation**: `Washington University` (in St. Louis) vs. `University of Washington` vs. `Washington State University` vs. `Western Washington University` are each mapped to distinct entries. Similarly, `Georgia State University` vs. `University of Georgia`.
- **Merging variants**: `York University` and `York University (Canada)` are unified into `York University`. Various SUNY campuses (`Binghamton`, `Stony Brook`, `Albany`, `Buffalo`) are tagged with `(SUNY)`.
- **Department-level entries**: Entries like `"Graduate School of Arts & Science"` or `"Said Business School"` (which are departments, not schools) are filtered out.

After the `case_when()`, a post-processing step forces all text inside parentheses to uppercase and cleans trailing whitespace.

#### Visualization & Analysis Functions

- `decision_calendar()`: Generates an interactive Plotly dot-chart of admission decisions over Jan-Apr, colored by decision type, with hover tooltips showing GRE/GPA/subfield.
- `get_comparison_data()`: Builds a comparison table of first acceptance/rejection/interview/waitlist dates for the last 3 years vs. all years.
- `first_acceptance()`, `first_rejection()`, `first_waitlist()`, `first_interview()`: Return formatted strings of the earliest date for each decision type.
- `get_yearly_accept_rate()`: Computes acceptance rate (Accepted / (Accepted + Rejected)) by year.
- `get_nat_rate()`: Computes acceptance rate broken down by nationality (American vs. International) and year.

### `app.R` -- Shiny Dashboard

The dashboard UI is built with `fluidPage` and consists of a sidebar + 4 main tabs:

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

A sample text report (`[sample] PhD Admission Analysis.md`) is included to demonstrate how the scraped data can be used to generate a comprehensive yearly trend document summarizing acceptance rates, nationality distributions, and subfield popularity.

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

- **Self-Reported Data**: All data is self-reported by users on [The GradCafe](https://www.thegradcafe.com/). Due to the anonymous and self-reported nature of the platform, the data cannot be independently verified and may contain inaccuracies, exaggerations, or omissions.
- **Scraping & Cleaning Anomalies**: While extensive pattern matching is used to normalize university names, extract GRE scores, and classify subfields, there may still be scraping artifacts, misclassifications, or unhandled edge cases. Treat the data as an approximate trend indicator rather than an exact official record.
- **Data was last updated on February 24, 2026.** Pre-scraped data includes `scraped_2020_2026_combined.Rdata`.
- **Extensible & Real-Time**: You can freely run the `scrape_all_years.R` script at any time to gather the absolute latest data from GradCafe. The Shiny dashboard will automatically integrate the newly generated `.Rdata` file.
- Accept Rate = Accepted / (Accepted + Rejected). Interview and Waitlist are excluded from the denominator.
- The 2026 season data is partial (as of scraping date) and subject to change.
- University names are normalized via extensive pattern matching in `app_functions.R` (see details above).

## Credits & Acknowledgments

This project builds upon the original work by **Martin Devaux**, who first collected and analyzed GradCafe Political Science PhD admission data. His methodology and initial dataset provided the foundation and inspiration for this extended analysis. See his original work here:
<https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

All admission data is sourced from **[The GradCafe](https://www.thegradcafe.com/survey)**, a community where applicants self-report their graduate school admission results. I am grateful to The GradCafe for making this data publicly accessible.

## 🕰️ Legacy Versions (Before 2026 Upgrade)

The original structure, scripts, and initial forks of this project have been archived into the `legacy_code/` directory to keep the root directory clean. If you are looking for the pre-2026 versions of the R scripts (`Scraping.R`, `Cleaning.R`, `Functions.R`, `app.R` or their `_v2` counterparts), you can find them all safely backed up there.
