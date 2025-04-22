library(shiny)
library(shinydashboard)

# Source UI modules only
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

# Source the new modular server
source("server.R")

shinyApp(ui = ui, server = server)
