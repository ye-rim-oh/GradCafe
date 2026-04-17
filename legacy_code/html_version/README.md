# HTML Parser Version

This folder preserves the previous GradCafe HTML-table parser and the 2020-2026 Shiny app snapshot that used it.

The main repository now uses the JSON-backed GradCafe survey scraper in `scripts/R/scrape_gradcafe_polisci.R`, and the public GitHub Pages dashboard reads `site/data/gradcafe.json`.

## Contents

| File | Purpose |
| --- | --- |
| `scrape_all_years.R` | Legacy HTML-table scraper for the old GradCafe page structure |
| `scraped_2020_2026_combined.Rdata` | Legacy combined dataset used by the old app |
| `app_functions.R` | Legacy app-side loading and cleanup code |
| `app.R` | Legacy Shiny dashboard wired to the HTML-parser dataset |

## Run

From the repository root:

```r
setwd("legacy_code/html_version")
shiny::runApp("app.R")
```

This path is archival. New data refreshes should use the JSON scraper from the repository root:

```r
Rscript scripts/R/update_polisci_data.R
```
