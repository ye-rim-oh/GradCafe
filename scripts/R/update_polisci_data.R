# ============================================================
# Update GradCafe Political Science Data
# Purpose: Re-scrape GradCafe, rebuild the analysis report, and
#          regenerate the GitHub Pages data snapshot in site/data/.
# ============================================================

run_r_script <- function(path) {
  message("\n==> ", path)
  status <- system2(file.path(R.home("bin"), "Rscript"), path)
  if (!identical(status, 0L)) {
    stop("Script failed with exit status ", status, ": ", path, call. = FALSE)
  }
}

run_node_script <- function(path) {
  message("\n==> ", path)
  status <- system2("node", path)
  if (!identical(status, 0L)) {
    stop("Script failed with exit status ", status, ": ", path, call. = FALSE)
  }
}

node_scripts <- c(
  file.path("scripts", "scrape_gradcafe_polisci_fast.mjs")
)

r_scripts <- c(
  file.path("scripts", "R", "refresh_polisci_outputs.R"),
  file.path("scripts", "R", "analyze_gradcafe_polisci.R"),
  file.path("scripts", "export_dashboard_data.R")
)

for (script in node_scripts) {
  run_node_script(script)
}

for (script in r_scripts) {
  run_r_script(script)
}

cat("\nUpdated GradCafe Political Science data, analysis, and GitHub Pages data snapshot.\n")
