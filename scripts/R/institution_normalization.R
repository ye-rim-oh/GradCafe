# ============================================================
# Institution Normalization Helpers
# Purpose: Keep school cleanup rules in one place for scraper,
#          analysis, Shiny, and GitHub Pages export.
# ============================================================

squish_text <- function(x) {
  x <- ifelse(is.na(x), "", as.character(x))
  x <- gsub("[[:cntrl:]]", " ", x, perl = TRUE)
  x <- gsub("\\\\b", " ", x, perl = TRUE)
  x <- gsub("\u00a0", " ", x, fixed = TRUE)
  x <- gsub("\\s+", " ", x, perl = TRUE)
  trimws(x)
}

title_text <- function(x) {
  vapply(strsplit(tolower(x), " ", fixed = TRUE), function(parts) {
    paste0(toupper(substr(parts, 1, 1)), substr(parts, 2, nchar(parts))) |>
      paste(collapse = " ")
  }, character(1), USE.NAMES = FALSE)
}

fix_institution_case <- function(institution) {
  acronyms <- c(
    "UIUC", "UCLA", "MIT", "NYU", "SUNY", "CUNY", "PSU", "UBC", "LSE",
    "USC", "TAMU", "WUSTL", "UMICH", "UGA", "SAIS", "FIU", "FSU", "NIU",
    "GMU", "LSU", "MSU", "USF", "UTD", "GESS", "UCB", "UCD", "UCI", "UCM",
    "UCR", "UCSD", "UCSC", "UCSB", "AU", "GWU", "JHU", "NU", "ASU", "UA",
    "IU", "CEU", "EUI", "OSU", "WSU", "UNC", "UMD", "UW", "UF", "FAU", "UVA",
    "CUHK", "UNT"
  )
  for (acronym in acronyms) {
    institution <- gsub(
      paste0("\\b", acronym, "\\b"),
      acronym,
      institution,
      ignore.case = TRUE,
      perl = TRUE
    )
  }

  replacements <- c(
    "\\(UOFT\\)" = "(UofT)",
    "\\(UT AUSTIN\\)" = "(UT Austin)",
    "\\(UW-MADISON\\)" = "(UW-Madison)",
    "\\(CU BOULDER\\)" = "(CU Boulder)",
    "\\(UCONN\\)" = "(UConn)",
    "\\(UMICH\\)" = "(UMich)",
    "\\(UMASS\\)" = "(UMass)",
    "\\(UPENN\\)" = "(UPenn)",
    "\\(FLETCHER\\)" = "(Fletcher)",
    "\\(KORBEL\\)" = "(Korbel)",
    "\\(UNSPECIFIED\\)" = "(Unspecified)"
  )
  for (pattern in names(replacements)) {
    institution <- gsub(pattern, replacements[[pattern]], institution, perl = TRUE)
  }

  squish_text(gsub("Â", "", institution, fixed = TRUE))
}

clean_institution_text <- function(school) {
  x <- squish_text(school)
  x <- gsub("^The\\s+University\\s+Of\\s+Toront(o)?$", "University of Toronto", x, ignore.case = TRUE, perl = TRUE)
  x <- gsub("^University\\s+Of\\s+Toronto$", "University of Toronto", x, ignore.case = TRUE, perl = TRUE)
  x
}

valid_institution_school <- function(school) {
  x <- clean_institution_text(school)
  keep <- x != ""

  bad_patterns <- c(
    "Piss|Trump|McDonalds|Ravinder|Cocksucker|Cunnilingus",
    "^Corne$|^Penn s$|^Penns$|^Stony$|^University of Chi$",
    "^University of Connec$|^University of Oreg$|^University Of Wiscon$",
    "Universitywestern$|UniversityGSB$|Ann Arbor\\)gan|Madisonnsin$",
    "^Florida International University\\x{00C2}$|^Floirda International",
    "^University of mennesota$",
    "^Brown Rice University$",
    "^Iqtisad Uni$",
    "^(All|ALL|Overall|Overall \\(All Schools\\))$",
    "^Nsf Grfp$|^Sis$|^Coomtown University$",
    "^Graduate School Of Arts|^Henry Jackson School|^Said Business School$|^Krieger School|^Kennedy School Of|^SAIS$"
  )

  for (pattern in bad_patterns) {
    keep <- keep & !grepl(pattern, x, ignore.case = TRUE, perl = TRUE)
  }
  keep
}

normalize_institution <- function(school) {
  x <- clean_institution_text(school)
  x_for_match <- gsub("(?i)\\b of \\b", " of ", x, perl = TRUE)

  institution <- title_text(x)
  institution <- gsub("(?i)\\b of \\b", " of ", institution, perl = TRUE)
  for (word in c("At", "In", "And")) {
    institution <- gsub(paste0("\\b", word, "\\b"), tolower(word), institution, perl = TRUE)
  }
  matched <- rep(FALSE, length(institution))

  apply_rule <- function(pattern, replacement) {
    hit <- grepl(pattern, x_for_match, ignore.case = TRUE, perl = TRUE) & !matched
    institution[hit] <<- replacement
    matched[hit] <<- TRUE
  }

  apply_rule("Santa Barbara|UCSB", "University of California, Santa Barbara (UCSB)")
  apply_rule("Irvine|UCI", "University of California, Irvine (UCI)")
  apply_rule("Santa Cruz|UCSC", "University of California, Santa Cruz (UCSC)")
  apply_rule("Riverside|UC RIVERSIDE|UCR", "University of California, Riverside (UCR)")
  apply_rule("Merced|UCM", "University of California, Merced (UCM)")
  apply_rule("Davis|UCD", "University of California, Davis (UCD)")
  apply_rule("San Diego|UCSD", "University of California, San Diego (UCSD)")
  apply_rule("Los Angeles|UCLA", "University of California, Los Angeles (UCLA)")
  apply_rule("Berkeley|Berkekey|Berkely|Berekeley|UCB", "University of California, Berkeley (UCB)")
  apply_rule("University of California$", "University of California (Unspecified)")

  apply_rule("^Colorado.*Boulder|^University of Colorado Boulder", "University of Colorado Boulder (CU Boulder)")
  apply_rule("Florida International|^Floirda International", "Florida International University (FIU)")
  apply_rule("Florida Atlantic", "Florida Atlantic University (FAU)")
  apply_rule("Florida State|FSU", "Florida State University (FSU)")
  apply_rule("Northern Illinois|^NIU$", "Northern Illinois University (NIU)")
  apply_rule("George Washingon|George Washington", "George Washington University (GWU)")
  apply_rule("George Mason|^GMU$", "George Mason University (GMU)")
  apply_rule("Boston University", "Boston University")
  apply_rule("Boston College", "Boston College")
  apply_rule("Colorado State", "Colorado State University")
  apply_rule("Louisiana State University and Agricultural|^LSU$|Louisiana State", "Louisiana State University (LSU)")
  apply_rule("Michigan State|^MSU$", "Michigan State University (MSU)")
  apply_rule("University of Pittsburgh|^Pitt$", "University of Pittsburgh")
  apply_rule("University of Houston", "University of Houston")
  apply_rule("University of Iowa", "University of Iowa")
  apply_rule("University of Kansas", "University of Kansas")
  apply_rule("University of Missouri", "University of Missouri")
  apply_rule("University of Cincinnati", "University of Cincinnati")
  apply_rule("University of South Florida|^USF$", "University of South Florida (USF)")
  apply_rule("University of Hawaii", "University of Hawaii at Manoa")
  apply_rule("University of Ottawa", "University of Ottawa")
  apply_rule("Western Ontario", "University of Western Ontario")
  apply_rule("University of Texas at Dallas|UT Dallas|^UTD$", "University of Texas at Dallas (UT Dallas)")
  apply_rule("Illinois.*Urbana|Illinois UIUC|UIUC|^University of Illinois$", "University of Illinois Urbana-Champaign (UIUC)")
  apply_rule("Illinois.*Chicago|UIC", "University of Illinois Chicago (UIC)")
  apply_rule("^Texas A$|Texas A&M|TAMU|Texas A & M", "Texas A&M University (TAMU)")
  apply_rule("Texas.*Austin|UT Austin|^University of Texas$", "University of Texas at Austin (UT Austin)")
  apply_rule("Western Washington", "Western Washington University")
  apply_rule("Washington University.*St|WUSTL|WashU|^Washington University$", "Washington University in St. Louis")
  apply_rule("^University of Washington|UW Seattle", "University of Washington (UW)")

  apply_rule("Southern California|USC", "University of Southern California (USC)")
  apply_rule("Max Plank|Max Planck|IMPRS", "International Max Planck Research School (IMPRS)")
  apply_rule("Pennsylvania.*State|Penn State|PSU|Penns$|Penn s", "Pennsylvania State University (PSU)")
  apply_rule("Pennsylvania|UPenn|U Penn", "University of Pennsylvania (UPenn)")
  apply_rule("Maryland.*College Park|[^a-z]UMD|^University of Maryland$|^University of maryland|^University of Mary$", "University of Maryland, College Park (UMD)")
  apply_rule("North Carolina.*Chapel|^UNC[- ]|[^a-z]UNC[^a-z]|^UNC$|^University of North Carolina$", "University of North Carolina at Chapel Hill (UNC)")
  apply_rule("City University of New York|CUNY|Graduate Center", "City University of New York (CUNY)")
  apply_rule("British Columbia|UBC", "University of British Columbia (UBC)")
  apply_rule("London School of Economics|LSE", "London School of Economics (LSE)")
  apply_rule("Bocconi", "Bocconi University")
  apply_rule("Binghamton", "Binghamton University (SUNY)")
  apply_rule("Stony|Stony Brook", "Stony Brook University (SUNY)")
  apply_rule("Albany", "University at Albany (SUNY)")
  apply_rule("Buffalo", "University at Buffalo (SUNY)")
  apply_rule("Columbia.*Teachers|Teachers College", "Teachers College, Columbia University")

  apply_rule("University of Connec", "University of Connecticut (UConn)")
  apply_rule("University of Oreg", "University of Oregon")
  apply_rule("Wisconsin|^Uw Madison$", "University of Wisconsin-Madison (UW-Madison)")
  apply_rule("Cornell", "Cornell University")
  apply_rule("UChicago|Chicago", "University of Chicago (UChicago)")
  apply_rule("Virginia", "University of Virginia (UVA)")
  apply_rule("Minnesota|mennesota", "University of Minnesota")
  apply_rule("Brown Rice", "Brown University")
  apply_rule("Arizona State", "Arizona State University (ASU)")
  apply_rule("Arizona", "University of Arizona (UA)")
  apply_rule("Indiana", "Indiana University Bloomington (IU)")
  apply_rule("Alabama", "University of Alabama (UA)")
  apply_rule("Iqtisad", "Iqtisad University")
  apply_rule("Purdue", "Purdue University")
  apply_rule("Hillsdale", "Hillsdale College")
  apply_rule("Denver.*Korbel|University of Denver", "University of Denver (Korbel)")

  apply_rule("Yale", "Yale University")
  apply_rule("Harvard|Kennedy School", "Harvard University")
  apply_rule("Stanford", "Stanford University")
  apply_rule("Princeton", "Princeton University")
  apply_rule("Columbia", "Columbia University")
  apply_rule("Brown", "Brown University")
  apply_rule("Dartmouth", "Dartmouth College")
  apply_rule("Massachusetts Institute of Technology|^MIT$|Massaa+chusett|Massachussett", "Massachusetts Institute of Technology (MIT)")
  apply_rule("New York University|NYU|Steinhardt", "New York University (NYU)")
  apply_rule("Northwestern", "Northwestern University (NU)")
  apply_rule("Duke", "Duke University")
  apply_rule("Johns Hopkins|SAIS|Bloomberg|Krieger", "Johns Hopkins University (JHU)")
  apply_rule("Michigan", "University of Michigan (UMich)")
  apply_rule("Emory", "Emory University")
  apply_rule("Toront", "University of Toronto (UofT)")
  apply_rule("Pompeu Fabra|UPF", "Pompeu Fabra University (UPF)")
  apply_rule("Syracuse|Maxwell", "Syracuse University")
  apply_rule("Georgetown", "Georgetown University")
  apply_rule("Georgia State", "Georgia State University")
  apply_rule("Georgia.*Athens|[^a-z]UGA[^a-z]|^UGA$|^University of Georgia$|Georiga", "University of Georgia (UGA)")
  apply_rule("Rutgers", "Rutgers University")
  apply_rule("^American U|American University", "American University (AU)")
  apply_rule("McGill", "McGill University")
  apply_rule("McMaster", "McMaster University")
  apply_rule("Queen.*Canada|Queens University", "Queen's University")
  apply_rule("^York University", "York University")
  apply_rule("European University Institute|EUI", "European University Institute (EUI)")
  apply_rule("Gess Mannheim|Mannheim, Gess", "University of Mannheim (GESS)")
  apply_rule("Cambridge", "University of Cambridge")
  apply_rule("Oxford", "University of Oxford")
  apply_rule("St\\.? Andrews|University of St Andrews", "University of St Andrews")
  apply_rule("Fletcher School|^Tufts", "Tufts University (Fletcher)")
  apply_rule("Texas Tech", "Texas Tech University")
  apply_rule("Washington State", "Washington State University (WSU)")
  apply_rule("New School", "The New School")
  apply_rule("Central European University", "Central European University (CEU)")
  apply_rule("Richard Gilder|AMNH", "Richard Gilder Graduate School (AMNH)")
  apply_rule("Rice", "Rice University")
  apply_rule("Rochester", "University of Rochester")
  apply_rule("Ohio State|^OSU|Ohio State University - Columbus", "Ohio State University (OSU)")
  apply_rule("Ohio University", "Ohio University")
  apply_rule("EMBL", "European Molecular Biology Laboratory (EMBL)")
  apply_rule("ETH Zurich", "ETH Zurich")
  apply_rule("Geneva Graduate Institute", "Geneva Graduate Institute")
  apply_rule("Vanderbilt", "Vanderbilt University")
  apply_rule("Nebraska", "University of Nebraska-Lincoln")
  apply_rule("Delaware|UDEL", "University of Delaware")
  apply_rule("Tulane", "Tulane University")
  apply_rule("Tennessee", "University of Tennessee (UTK)")
  apply_rule("South Carolina", "University of South Carolina (USC)")
  apply_rule("^U Mass|University of Massachusetts$|Massachusetts.*Amherst|UMass", "University of Massachusetts Amherst (UMass)")
  apply_rule("Notre Dame", "University of Notre Dame")
  apply_rule("Université De Montréal|University of Montreal", "Université de Montréal")
  apply_rule("ีUniversity of Florida|University of Florida|UFL|^UF$", "University of Florida (UF)")

  fix_institution_case(institution)
}
