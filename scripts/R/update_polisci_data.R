# ============================================================
# Update GradCafe Political Science Data
# Purpose: Re-scrape GradCafe, rebuild the analysis report, and
#          regenerate the GitHub Pages data snapshot in site/data/.
# ============================================================

run_script <- function(path) {
  message("\n==> ", path)
  status <- system2(file.path(R.home("bin"), "Rscript"), path)
  if (!identical(status, 0L)) {
    stop("Script failed with exit status ", status, ": ", path, call. = FALSE)
  }
}

scripts <- c(
  file.path("scripts", "R", "scrape_gradcafe_polisci.R"),
  file.path("scripts", "R", "analyze_gradcafe_polisci.R"),
  file.path("scripts", "export_dashboard_data.R")
)

for (script in scripts) {
  run_script(script)
}

cat("\nUpdated GradCafe Political Science data, analysis, and GitHub Pages data snapshot.\n")
