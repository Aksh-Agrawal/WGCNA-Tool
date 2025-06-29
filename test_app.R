# Test WGCNA App - Basic Version
# ===============================

# Load basic libraries
library(shiny)
library(shinydashboard)

# Simple test to ensure the app structure works
ui <- dashboardPage(
  dashboardHeader(title = "WGCNA Test App"),
  dashboardSidebar(
    sidebarMenu(
      menuItem("Test", tabName = "test", icon = icon("home"))
    )
  ),
  dashboardBody(
    tabItems(
      tabItem(
        tabName = "test",
        h2("Enhanced WGCNA Tool - Test Version"),
        p("This is a test version to verify the app structure."),
        
        # Try to load the enhanced modules
        div(
          h3("Module Loading Status:"),
          verbatimTextOutput("module_status")
        )
      )
    )
  )
)

server <- function(input, output, session) {
  output$module_status <- renderText({
    status <- c()
    
    # Test global.R
    tryCatch({
      source("global.R", local = TRUE)
      status <- c(status, "✅ global.R loaded successfully")
    }, error = function(e) {
      status <- c(status, paste("❌ global.R error:", e$message))
    })
    
    # Test modules
    modules <- c(
      "modules/enhanced_data_upload.R",
      "modules/enhanced_wgcna_analysis.R", 
      "modules/enhanced_enrichment_analysis.R",
      "modules/enhanced_visualization.R",
      "modules/quality_control.R",
      "modules/results_export.R"
    )
    
    for (module in modules) {
      tryCatch({
        source(module, local = TRUE)
        status <- c(status, paste("✅", basename(module), "loaded successfully"))
      }, error = function(e) {
        status <- c(status, paste("❌", basename(module), "error:", e$message))
      })
    }
    
    paste(status, collapse = "\n")
  })
}

shinyApp(ui = ui, server = server)
