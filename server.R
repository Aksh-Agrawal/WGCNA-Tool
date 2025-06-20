# server.R

# Source module files to make functions available
source("modules/data_upload.R")
source("modules/wgcna_analysis.R")
source("modules/enrichment_analysis.R")
source("modules/visualization.R")

function(input, output, session) {
  # Call module server functions
  data <- dataUploadServer("data_upload")
  wgcna_results <- wgcnaAnalysisServer("wgcna_analysis", data)
  enrichmentAnalysisServer("enrich_analysis", wgcna_results)
  visualizationServer("visualization", wgcna_results)
}
