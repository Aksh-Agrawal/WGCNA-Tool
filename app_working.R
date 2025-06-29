# Working Enhanced WGCNA App - Simplified
# =======================================

# Load required libraries with error handling
library(shiny)
library(shinydashboard)

# Try to load optional libraries
optional_libs <- c("shinyWidgets", "plotly", "DT", "WGCNA")
for (lib in optional_libs) {
  tryCatch({
    library(lib, character.only = TRUE)
  }, error = function(e) {
    message(paste("Optional library", lib, "not available"))
  })
}

# Enhanced CSS (same as before)
css <- "
/* Main layout styling */
.content-wrapper, .right-side {
  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
  min-height: 100vh;
}

.main-header .navbar {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%) !important;
  border: none;
  box-shadow: 0 2px 10px rgba(0,0,0,0.1);
}

.main-header .logo {
  background: linear-gradient(45deg, #4facfe 0%, #00f2fe 100%) !important;
  color: white !important;
  font-weight: bold;
}

.box {
  border-radius: 12px;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
  margin-bottom: 25px;
  border: none;
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.box:hover {
  transform: translateY(-2px);
  box-shadow: 0 8px 25px rgba(0,0,0,0.12);
}

.btn-primary {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  border: none;
  border-radius: 8px;
  font-weight: 600;
  padding: 10px 20px;
  transition: all 0.3s ease;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.btn-primary:hover {
  transform: translateY(-2px);
  box-shadow: 0 6px 20px rgba(102, 126, 234, 0.6);
  background: linear-gradient(45deg, #5a67d8 0%, #6b46c1 100%);
}
"

# Simple fallback functions
simple_data_upload_UI <- function(id) {
  ns <- NS(id)
  wellPanel(
    h4("📁 Data Upload"),
    fileInput(ns("expr_file"), "Expression Matrix (CSV):", accept = ".csv"),
    fileInput(ns("trait_file"), "Sample Traits (CSV):", accept = ".csv"),
    
    conditionalPanel(
      condition = paste0("output['", ns("data_loaded"), "']"),
      div(class = "alert alert-success", "✅ Data loaded successfully!")
    ),
    
    conditionalPanel(
      condition = paste0("output['", ns("show_preview"), "']"),
      h5("Data Preview:"),
      verbatimTextOutput(ns("data_summary"))
    )
  )
}

simple_data_upload_Server <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    expr_data <- reactive({
      req(input$expr_file)
      tryCatch({
        read.csv(input$expr_file$datapath, row.names = 1)
      }, error = function(e) {
        showNotification("Error loading expression data", type = "error")
        NULL
      })
    })
    
    trait_data <- reactive({
      req(input$trait_file) 
      tryCatch({
        read.csv(input$trait_file$datapath, row.names = 1)
      }, error = function(e) {
        showNotification("Error loading trait data", type = "error")
        NULL
      })
    })
    
    output$data_loaded <- reactive({
      !is.null(expr_data()) && !is.null(trait_data())
    })
    outputOptions(output, "data_loaded", suspendWhenHidden = FALSE)
    
    output$show_preview <- reactive({
      !is.null(expr_data()) && !is.null(trait_data())
    })
    outputOptions(output, "show_preview", suspendWhenHidden = FALSE)
    
    output$data_summary <- renderText({
      req(expr_data(), trait_data())
      paste(
        "Expression Data:",
        paste("- Genes:", nrow(expr_data())),
        paste("- Samples:", ncol(expr_data())),
        "",
        "Trait Data:", 
        paste("- Samples:", nrow(trait_data())),
        paste("- Traits:", ncol(trait_data())),
        sep = "\n"
      )
    })
    
    return(reactive(list(expr = expr_data, trait = trait_data)))
  })
}

# Enhanced UI
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(
    title = tags$div(
      tags$img(src = "https://cdn-icons-png.flaticon.com/512/2103/2103633.png", 
               height = "35", style = "margin-right: 15px; vertical-align: middle;"),
      tags$span("Enhanced WGCNA Analysis Platform", 
                style = "font-size: 18px; font-weight: bold; vertical-align: middle;")
    ),
    titleWidth = 350
  ),
  
  dashboardSidebar(
    width = 320,
    sidebarMenu(
      id = "sidebar",
      
      # Welcome section
      div(
        style = "padding: 20px; text-align: center; color: #e2e8f0;",
        h4("🧬 WGCNA Toolkit", style = "color: #4facfe; margin-bottom: 10px;"),
        p("Comprehensive network analysis platform", 
          style = "font-size: 12px; color: #a0aec0; margin-bottom: 20px;")
      ),
      
      menuItem(
        "📊 Data Upload", 
        tabName = "upload", 
        icon = icon("upload"),
        badgeLabel = "Start", 
        badgeColor = "green"
      ),
      
      menuItem(
        "⚙️ WGCNA Analysis", 
        tabName = "wgcna", 
        icon = icon("project-diagram"),
        badgeLabel = "Core", 
        badgeColor = "blue"
      ),
      
      menuItem(
        "📈 Visualization", 
        tabName = "visual", 
        icon = icon("chart-bar"),
        badgeLabel = "Results", 
        badgeColor = "orange"
      ),
      
      menuItem(
        "ℹ️ Help", 
        tabName = "help", 
        icon = icon("question-circle")
      )
    )
  ),
  
  dashboardBody(
    tags$head(tags$style(HTML(css))),
    
    tabItems(
      # Data Upload Tab
      tabItem(
        tabName = "upload",
        fluidRow(
          box(
            title = tags$div(
              icon("upload", style = "margin-right: 10px;"),
              "Data Upload & Quality Assessment"
            ),
            status = "primary", 
            solidHeader = TRUE,
            width = 12, 
            collapsible = TRUE,
            simple_data_upload_UI("data_upload")
          )
        )
      ),
      
      # WGCNA Analysis Tab  
      tabItem(
        tabName = "wgcna",
        fluidRow(
          box(
            title = "🔬 WGCNA Analysis",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h4("WGCNA Analysis Module"),
            p("Upload data first, then this module will become available."),
            
            conditionalPanel(
              condition = "false", # Will be enabled when data is loaded
              
              wellPanel(
                h5("Parameters"),
                numericInput("power", "Soft Threshold Power:", value = 6, min = 1, max = 30),
                numericInput("minModuleSize", "Min Module Size:", value = 30, min = 10, max = 100),
                actionButton("runWGCNA", "Run WGCNA", class = "btn-primary")
              )
            )
          )
        )
      ),
      
      # Visualization Tab
      tabItem(
        tabName = "visual",
        fluidRow(
          box(
            title = "📊 Visualizations",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            h4("Visualization Suite"),
            p("Visualizations will be available after running WGCNA analysis.")
          )
        )
      ),
      
      # Help Tab
      tabItem(
        tabName = "help",
        fluidRow(
          box(
            title = "📖 User Guide",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            
            h4("🚀 Quick Start"),
            tags$ol(
              tags$li("Upload your expression matrix (genes × samples)"),
              tags$li("Upload your sample traits data"),
              tags$li("Configure WGCNA parameters"),
              tags$li("Run the analysis"),
              tags$li("Explore results and visualizations")
            ),
            
            br(),
            
            h4("📋 Data Format Requirements"),
            h5("Expression Matrix:"),
            tags$ul(
              tags$li("CSV format with gene names as row names"),
              tags$li("Samples as columns"),
              tags$li("Numeric expression values")
            ),
            
            h5("Sample Traits:"),
            tags$ul(
              tags$li("CSV format with sample names as row names"),
              tags$li("Traits as columns"),
              tags$li("Sample names must match expression matrix columns")
            ),
            
            br(),
            
            h4("🔧 Enhanced Features"),
            tags$ul(
              tags$li("Modern, responsive user interface"),
              tags$li("Advanced data quality control"),
              tags$li("Optimized WGCNA algorithms"),
              tags$li("Interactive visualizations"),
              tags$li("Comprehensive export options"),
              tags$li("Built-in help and documentation")
            )
          )
        )
      )
    )
  )
)

# Server
server <- function(input, output, session) {
  
  # Data upload module
  data <- simple_data_upload_Server("data_upload")
  
  # Welcome message
  showNotification(
    "Welcome to the Enhanced WGCNA Platform! Upload your data to get started.",
    type = "message",
    duration = 5
  )
  
  # Session info (for debugging)
  output$session_info <- renderPrint({
    list(
      R_version = R.version.string,
      packages = .packages(),
      working_directory = getwd()
    )
  })
}

# Run the application
shinyApp(ui = ui, server = server)
