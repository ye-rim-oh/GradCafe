# GradCafe 2020-2026 Political Science PhD Trend Analysis

🇰🇷 [한국어](README-ko.md)

This project tracks self-reported GradCafe outcomes for Political Science PhD admissions (2020-2026) and serves them through a Shiny dashboard.

The goal is simple: keep one reproducible pipeline for scraping, cleaning, and quickly checking cycle-level patterns.

## Quick Start

### If `scraped_2020_2026_combined.Rdata` already exists

```r
Rscript -e "shiny::runApp('app.R')"
```

### Full refresh (re-scrape + run app)

```r
Rscript scrape_all_years.R
Rscript -e "shiny::runApp('app.R')"
```

## Pipeline

| Step | Script | Input | Output |
| ---: | --- | --- | --- |
| 1 | `scrape_all_years.R` | GradCafe search pages | Per-year `.Rdata` + `scraped_2020_2026_combined.Rdata` |
| 2 | `app_functions.R` + `app.R` | `scraped_2020_2026_combined.Rdata` | Local (or deployed) Shiny dashboard |

## Repository Files

| File | What it does |
| --- | --- |
| `scrape_all_years.R` | Unified scraper for 2020-2026 using one parser flow |
| `app_functions.R` | Data loading, cleaning, normalization, and plotting helpers |
| `app.R` | Shiny UI and server logic |
| `scraped_2020_2026_combined.Rdata` | Combined pre-scraped dataset |
| `[sample] PhD Admission Analysis.md` | Sample text report generated from the dataset |
| `README-ko.md` | Korean README |

## How the Scraper Works (`scrape_all_years.R`)

The scraper queries GradCafe with four broad terms:
`political science`, `international relations`, `politics`, `government`.

Then it applies the same cleanup logic each year:

- Parse each post from the 3-row table structure (main row, badge row, notes row).
- Extract decision labels, dates, GRE, GPA, nationality tags, and notes.
- Deduplicate rows using `(school, decision_text, notes, added_date)`.
- Keep only `degree == "PhD"`.
- Normalize `program` text and keep only target majors (Political Science / IR / Politics / Government and direct combinations).
- Tag subfields from notes (`CP`, `IR`, `AP`, `Theory`, `Methods`, `Public Law/Policy`, `Psych/Behavior`, `Unknown`).

## App-Side Data Prep (`app_functions.R`)

Before plotting, the app pipeline:

- Repairs missing `gre_q` values from `gre_total` when recoverable.
- Removes impossible GRE/AW values.
- Standardizes timeline dates for cross-year comparison.
- Filters obvious junk rows and normalizes institution names with a rule map.

## Dashboard Structure (`app.R`)

- `Timeline`: Dot-based decision calendar.
- `Trends`: Yearly acceptance rate and nationality split.
- `Subfields`: Subfield volume and subfield-specific acceptance rates.
- `Data`: Searchable raw table with detail panel.

## Dependencies

- R (>= 4.0)
- Packages: `rvest`, `httr`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `plotly`, `ggplot2`, `rmarkdown`, `knitr`, `kableExtra`, `shiny`, `shinyjs`, `shinyWidgets`, `DT`

Install once:

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

## Data Notes

- Source is self-reported GradCafe data, so missingness and reporting bias are unavoidable.
- Parsing and normalization are rule-based; a few edge cases can remain.
- Acceptance rate is defined as `Accepted / (Accepted + Rejected)`.
- Last refresh: **March 4, 2026**.
  - Combined rows: **3,766**
  - 2026 rows: **858**
- 2026 is still a moving snapshot as additional posts appear.

## Credits

This repository extends the earlier GradCafe Political Science PhD analysis by **Martin Devaux**:
<https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

I am genuinely grateful to Martin for publishing the original workflow so clearly.
His early work made this extension much easier to build and maintain.

I am also very thankful to the GradCafe community and site maintainers.
Without their self-reported posts and continued platform support, this project would not exist.

Data source: **[The GradCafe](https://www.thegradcafe.com/survey)**.

## Legacy Code

Older scripts and project structure are preserved in `legacy_code/`.
