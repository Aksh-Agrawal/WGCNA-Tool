# server.R
server <- function(input, output, session) {
  data <- dataUploadServer("data_upload")
  wgcna_results <- wgcnaAnalysisServer("wgcna_analysis", data)
  enrichmentAnalysisServer("enrich_analysis", wgcna_results)
  visualizationServer("visualization", wgcna_results)
}
