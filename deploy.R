library(rsconnect)

# Set account info
rsconnect::setAccountInfo(name='z25die-0-0', 
                          token='4D3E74AE09097D2F436E705D4E1D6CAB', 
                          secret='pRacJWeylo6gYZ14IECq1cWo14IGZ3v+aCxln6/u')

# Deploy app.R (copied from app_v2.R) to ensure it's recognized as a Shiny App
deployApp(appDir = ".", 
          appFiles = c("app.R", "Functions_v2.R", "cleaned_data.Rdata", "www"),
          forceUpdate = TRUE,
          lint = FALSE,
          launch.browser = FALSE)
