# GradCafe 2016-2026 political science PhD trend analysis

This repository tracks self-reported GradCafe outcomes for political science PhD admissions from 2016 through 2026.

The point is straightforward: scrape each cycle the same way, clean it with the same rules, and make the results easy to inspect in a Shiny dashboard.

The repository now also includes a **GitHub Pages-ready static React dashboard** in `site/`. That version keeps the shared filters and tabs in the browser, so it can be deployed for free without running a Shiny server. Because GradCafe's current survey pages are no longer reliably available as the old HTML table, the scraper and Pages export now use the current JSON-backed survey data path.

Static site: <https://ye-rim-oh.github.io/GradCafe/>

### Data and Site

The JSON scraper produces cleaned data, exports it to `site/data/gradcafe.json`, and the GitHub Pages homepage reads that file to build the filters and visualizations.

The Shiny app uses the same cleaned data.

### Pipeline

| Step | Script | Input | Output |
| ---: | --- | --- | --- |
| 1 | `scripts/R/scrape_gradcafe_polisci.R` | GradCafe survey data | `output/polisci_analysis/gradcafe_polisci_2016_2026_clean.rds` |
| 2 | `scripts/R/analyze_gradcafe_polisci.R` | Cleaned data | `gradcafe_polisci_2016_2026_analysis.md` |
| 3 | `scripts/export_dashboard_data.R` + `site/` | Cleaned data | `site/data/gradcafe.json` for GitHub Pages |
| 4 | `app_functions.R` + `app.R` | Same cleaned data | Local or deployed Shiny dashboard |

### Main files

| File | Description |
| --- | --- |
| `scripts/R/scrape_gradcafe_polisci.R` | Scrapes 2016-2026 data against the current GradCafe survey structure |
| `scripts/R/update_polisci_data.R` | Runs scrape, analysis, and Pages data export together |
| `app_functions.R` | Data loading, cleanup, normalization, and helper functions |
| `app.R` | Shiny UI and server logic |
| `scripts/export_dashboard_data.R` | Exports the cleaned dataset to `site/data/gradcafe.json` |
| `site/` | Static React dashboard deployed to GitHub Pages |
| `legacy_code/html_version/` | Archived HTML-table parser and 2020-2026 Shiny version |
| `gradcafe_polisci_2016_2026_analysis.md` | Current analysis report generated from the cleaned dataset |
| `legacy_code/` | Older scripts and the previous project structure |

### How the scraper works

The scraper queries GradCafe survey data with four broad terms: `political science`, `international relations`, `politics`, and `government`, combined with Fall 2016-2026 season filters.

It then applies the same cleanup rules each year.

- It extracts result rows from the Inertia `data-page` JSON payload embedded in the survey page.
- It extracts decision labels, dates, GRE, GPA, nationality tags, and notes.
- It removes duplicates with `(school, decision_text, notes, added_date)`.
- It keeps only `degree == "PhD"`.
- It normalizes `program` text and keeps only the target majors.
- It tags subfields from notes: `CP`, `IR`, `AP`, `Theory`, `Methods`, `Public Law/Policy`, `Psych/Behavior`, and `Unknown`.

### App-side cleanup

Before plotting, the app makes one more cleanup pass.

- It recovers missing `gre_q` values from `gre_total` when possible.
- It removes impossible GRE and AW values.
- It standardizes timeline dates for cross-year comparison.
- It drops obvious junk rows and normalizes institution names with a rule map.

### Site sections

- `Decision timeline`: decision timing on a date axis
- `All results`: searchable raw table
- `Additional analysis`: yearly acceptance rates, nationality splits, subfield volume, and subfield-specific acceptance rates

### Dependencies

- R (>= 4.0)
- `rvest`, `httr`, `dplyr`, `tidyr`, `lubridate`, `stringr`, `plotly`, `ggplot2`, `rmarkdown`, `knitr`, `kableExtra`, `shiny`, `shinyjs`, `shinyWidgets`, `DT`

Install once:

```r
install.packages(c("rvest", "httr", "dplyr", "tidyr", "lubridate", "stringr",
                   "plotly", "ggplot2", "rmarkdown", "knitr", "kableExtra",
                   "shiny", "shinyjs", "shinyWidgets", "DT"))
```

### Data notes

- The source is self-reported GradCafe data, so missingness and reporting bias are unavoidable.
- Parsing and normalization are rule-based, so some edge cases may still remain.
- Acceptance rate is defined as `Accepted / (Accepted + Rejected)`.
- Latest data date: **April 15, 2026**
- Website rows: **4,746**. Non-school noise rows and fake institution labels are excluded from the public dashboard.
- 2026 rows: **1,030**

### Credits

This repository extends the earlier GradCafe political science PhD analysis by **Martin Devaux**.
Original post: <https://www.martindevaux.com/2020/11/political-science-phd-admission-decisions/>

Martin published the original workflow clearly, and that made this extension much easier to build and maintain.

I also owe a lot to the GradCafe community and the site maintainers. Without their posts and the platform itself, there would be nothing here to analyze.

Data source: **[The GradCafe](https://www.thegradcafe.com/survey)**

### Legacy code

The previous HTML-table parser version is now grouped under `legacy_code/html_version/`. The main homepage and default refresh path use the JSON version.

Older scripts and the previous project structure are preserved in `legacy_code/`.

