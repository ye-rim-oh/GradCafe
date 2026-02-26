
load("scraped_2026.Rdata")
data <- as.data.frame(data)

# Filter rows with GRE info in badges
gre_rows <- data[grepl("GRE", data$badges), ]
cat("Found", nrow(gre_rows), "rows with GRE info.\n")

if(nrow(gre_rows) > 0) {
  writeLines(head(gre_rows$badges, 50), "badges_dump.txt")
  cat("Wrote first 50 badges to badges_dump.txt\n")
}
