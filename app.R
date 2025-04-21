### app.R
library(shiny)
library(shinydashboard)

source("modules/data_upload.R")
source("modules/wgcna_analysis.R")
source("modules/enrichment_analysis.R")
source("modules/visualization.R")

ui <- dashboardPage(
  dashboardHeader(title = "WGCNA Tool"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Data Upload", tabName = "upload", icon = icon("upload")),
      menuItem("WGCNA Analysis", tabName = "wgcna", icon = icon("project-diagram")),
      menuItem("Enrichment Analysis", tabName = "enrichment", icon = icon("dna")),
      menuItem("Visualization", tabName = "visual", icon = icon("chart-bar"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(tabName = "upload", dataUploadUI("data_upload")),
      tabItem(tabName = "wgcna", wgcnaAnalysisUI("wgcna_analysis")),
      tabItem(tabName = "enrichment", enrichmentAnalysisUI("enrich_analysis")),
      tabItem(tabName = "visual", visualizationUI("visualization"))
    )
  )
)

server <- function(input, output, session) {
  data <- callModule(dataUploadServer, "data_upload")
  wgcna_results <- callModule(wgcnaAnalysisServer, "wgcna_analysis", data)
  callModule(enrichmentAnalysisServer, "enrich_analysis", wgcna_results)
  callModule(visualizationServer, "visualization", wgcna_results)
}

shinyApp(ui, server)
