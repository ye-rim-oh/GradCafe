source(file.path("scripts", "R", "institution_normalization.R"), encoding = "UTF-8")

inputs <- c(
  "NIU",
  "Uc Berkekey",
  "George Washingon University",
  "U Mass Amherst",
  "the university of toront",
  "Florida International UniversityÂ"
)

expected <- c(
  "Northern Illinois University (NIU)",
  "University of California, Berkeley (UCB)",
  "George Washington University (GWU)",
  "University of Massachusetts Amherst (UMass)",
  "University of Toronto (UofT)",
  "Florida International University (FIU)"
)

actual <- normalize_institution(inputs)
if (!identical(actual, expected)) {
  print(data.frame(input = inputs, expected = expected, actual = actual))
  stop("Institution normalization fixtures failed.", call. = FALSE)
}

bad_schools <- c("all", "ALL", "Overall", "NSF GRFP", "Sis", "Coomtown University")
if (any(valid_institution_school(bad_schools))) {
  print(data.frame(input = bad_schools, valid = valid_institution_school(bad_schools)))
  stop("Invalid institution fixtures were not filtered.", call. = FALSE)
}

cat("normalization tests passed\n")
