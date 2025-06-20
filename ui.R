library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(plotly)
library(DT)

# Source UI modules
source("modules/data_upload.R")
source("modules/wgcna_analysis.R")
source("modules/enrichment_analysis.R")
source("modules/visualization.R")

# Custom CSS for better styling
css <- "
.content-wrapper, .right-side {
  background-color: #f4f4f4;
}
.main-header .navbar {
  background-color: #3c8dbc !important;
}
.main-header .logo {
  background-color: #367fa9 !important;
}
.box.box-solid.box-primary > .box-header {
  background: #3c8dbc;
  color: #fff;
}
.box {
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  margin-bottom: 20px;
}
.btn-primary {
  background-color: #3c8dbc;
  border-color: #367fa9;
  border-radius: 4px;
  font-weight: 500;
  padding: 8px 16px;
}
.btn-primary:hover {
  background-color: #367fa9;
  border-color: #2e6da4;
}
.progress-bar {
  background-color: #3c8dbc;
}
.nav-tabs-custom > .nav-tabs > li.active > a {
  background-color: #3c8dbc;
  color: #fff;
}
"

ui <- dashboardPage(
  dashboardHeader(
    title = tags$div(
      tags$img(src = "https://cdn-icons-png.flaticon.com/512/2103/2103633.png", 
               height = "30", style = "margin-right: 10px;"),
      "Advanced WGCNA Analysis Tool"
    ),
    titleWidth = 300
  ),
  dashboardSidebar(
    width = 300,
    sidebarMenu(
      id = "sidebar",
      menuItem("📊 Data Upload", tabName = "upload", icon = icon("upload"),
               badgeLabel = "Start Here", badgeColor = "green"),
      menuItem("🔬 WGCNA Analysis", tabName = "wgcna", icon = icon("project-diagram"),
               badgeLabel = "Core", badgeColor = "blue"),
      menuItem("🧬 Enrichment Analysis", tabName = "enrichment", icon = icon("dna"),
               badgeLabel = "Advanced", badgeColor = "purple"),
      menuItem("📈 Visualization", tabName = "visual", icon = icon("chart-bar"),
               badgeLabel = "Results", badgeColor = "orange"),
      menuItem("ℹ️ Help & Info", tabName = "help", icon = icon("info-circle"))
    )
  ),
  dashboardBody(
    tags$head(tags$style(HTML(css))),
    tabItems(
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = "📁 Data Upload Center", status = "primary", solidHeader = TRUE,
            width = 12, collapsible = TRUE,
            dataUploadUI("data_upload")
          )
        )
      ),
      tabItem(
        tabName = "wgcna",
        fluidRow(
          box(
            title = "⚙️ WGCNA Configuration", status = "primary", solidHeader = TRUE,
            width = 4, height = "400px",
            wgcnaAnalysisUI("wgcna_analysis")
          ),
          box(
            title = "📊 Analysis Results", status = "info", solidHeader = TRUE,
            width = 8, height = "400px",
            div(id = "wgcna-results-content")
          )
        )
      ),
      tabItem(
        tabName = "enrichment",
        fluidRow(
          box(
            title = "🧬 Gene Enrichment Analysis", status = "primary", solidHeader = TRUE,
            width = 12,
            enrichmentAnalysisUI("enrich_analysis")
          )
        )
      ),
      tabItem(
        tabName = "visual",
        fluidRow(
          box(
            title = "🌳 Module Dendrogram", status = "primary", solidHeader = TRUE,
            width = 12, height = "500px",
            visualizationUI("visualization")
          )
        )
      ),
      tabItem(
        tabName = "help",
        fluidRow(
          box(
            title = "📖 How to Use This Tool", status = "info", solidHeader = TRUE,
            width = 12,
            h4("Getting Started"),
            p("1. Upload your expression matrix and sample annotation files"),
            p("2. Configure WGCNA parameters and run analysis"),
            p("3. Explore enrichment analysis for specific modules"),
            p("4. Visualize results with dendrograms and heatmaps"),
            br(),
            h4("File Requirements"),
            tags$ul(
              tags$li("Expression matrix: genes as rows, samples as columns"),
              tags$li("Sample annotation: samples as rows, traits as columns"),
              tags$li("Both files should be CSV format with proper headers")
            )
          )
        )
      )
    )
  )
)
