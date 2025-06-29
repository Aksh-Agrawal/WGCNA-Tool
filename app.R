# Enhanced WGCNA Analysis Tool
# ============================

# Load global configuration and utilities
source("global.R", local = FALSE)  # Make functions globally available

# Source utility files explicitly with error handling
tryCatch({
  source("utils/helper_functions.R", local = FALSE)
  message("Helper functions loaded successfully")
}, error = function(e) {
  message("Warning: Could not load helper functions - ", e$message)
})

tryCatch({
  source("utils/validation_functions.R", local = FALSE)
  message("Validation functions loaded successfully")
}, error = function(e) {
  message("Warning: Could not load validation functions - ", e$message)
})

tryCatch({
  source("utils/plot_functions.R", local = FALSE)
  message("Plot functions loaded successfully")
}, error = function(e) {
  message("Warning: Could not load plot functions - ", e$message)
})

# Source enhanced module files
source("modules/enhanced_data_upload.R")
source("modules/enhanced_wgcna_analysis.R")
source("modules/enhanced_enrichment_analysis.R")
source("modules/enhanced_visualization.R")
source("modules/quality_control.R")
source("modules/results_export.R")

# Enhanced Custom CSS with modern design
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

/* Enhanced box styling */
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

.box.box-solid.box-primary > .box-header {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  border-radius: 12px 12px 0 0;
}

.box.box-solid.box-info > .box-header {
  background: linear-gradient(45deg, #4facfe 0%, #00f2fe 100%);
  color: #fff;
  border-radius: 12px 12px 0 0;
}

.box.box-solid.box-success > .box-header {
  background: linear-gradient(45deg, #43e97b 0%, #38f9d7 100%);
  color: #fff;
  border-radius: 12px 12px 0 0;
}

/* Enhanced buttons */
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

.btn-success {
  background: linear-gradient(45deg, #48bb78 0%, #38a169 100%);
  border: none;
  border-radius: 8px;
  font-weight: 600;
  transition: all 0.3s ease;
}

.btn-info {
  background: linear-gradient(45deg, #4299e1 0%, #3182ce 100%);
  border: none;
  border-radius: 8px;
  font-weight: 600;
  transition: all 0.3s ease;
}

/* Progress bars */
.progress {
  border-radius: 10px;
  height: 25px;
  background: rgba(255,255,255,0.3);
}

.progress-bar {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  border-radius: 10px;
  transition: width 0.4s ease;
}

/* Alert styling */
.alert-success {
  background: linear-gradient(45deg, #c6f6d5 0%, #9ae6b4 100%);
  border: none;
  border-radius: 8px;
  color: #2d3748;
}

.alert-warning {
  background: linear-gradient(45deg, #fefcbf 0%, #faf089 100%);
  border: none;
  border-radius: 8px;
  color: #2d3748;
}

/* Sidebar enhancements */
.main-sidebar {
  background: linear-gradient(180deg, #2d3748 0%, #1a202c 100%) !important;
}

.sidebar-menu > li > a {
  color: #e2e8f0 !important;
  border-radius: 8px;
  margin: 2px 8px;
  transition: all 0.3s ease;
}

.sidebar-menu > li.active > a {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%) !important;
  color: white !important;
  border-radius: 8px;
  box-shadow: 0 4px 15px rgba(102, 126, 234, 0.4);
}

.sidebar-menu > li:hover > a {
  background: rgba(255,255,255,0.1) !important;
  color: white !important;
}

/* Tab styling */
.nav-tabs-custom > .nav-tabs > li.active > a {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%);
  color: #fff;
  border-radius: 8px 8px 0 0;
}

/* Data table enhancements */
.dataTables_wrapper .dataTables_paginate .paginate_button.current {
  background: linear-gradient(45deg, #667eea 0%, #764ba2 100%) !important;
  border: none !important;
  color: white !important;
}

/* Loading spinner */
.lds-dual-ring {
  display: inline-block;
  width: 80px;
  height: 80px;
}
.lds-dual-ring:after {
  content: ' ';
  display: block;
  width: 64px;
  height: 64px;
  margin: 8px;
  border-radius: 50%;
  border: 6px solid #667eea;
  border-color: #667eea transparent #667eea transparent;
  animation: lds-dual-ring 1.2s linear infinite;
}
@keyframes lds-dual-ring {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

/* Custom value boxes */
.small-box {
  border-radius: 12px;
  overflow: hidden;
  box-shadow: 0 4px 20px rgba(0,0,0,0.08);
  transition: transform 0.2s ease;
}

.small-box:hover {
  transform: translateY(-3px);
}

/* File input styling */
.form-control {
  border-radius: 8px;
  border: 2px solid #e2e8f0;
  transition: all 0.3s ease;
}

.form-control:focus {
  border-color: #667eea;
  box-shadow: 0 0 0 3px rgba(102, 126, 234, 0.1);
}
"

# Enhanced UI with improved layout and features
ui <- dashboardPage(
  skin = "blue",
  dashboardHeader(
    title = tags$div(
      tags$img(src = "https://cdn-icons-png.flaticon.com/512/2103/2103633.png", 
               height = "35", style = "margin-right: 15px; vertical-align: middle;"),
      tags$span("Advanced WGCNA Analysis Platform", 
                style = "font-size: 18px; font-weight: bold; vertical-align: middle;")
    ),
    titleWidth = 350,
    # Add notification dropdown
    dropdownMenu(
      type = "notifications", 
      headerText = "Analysis Status",
      icon = icon("bell"),
      badgeStatus = "info"
    )
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
      
      # Navigation items with enhanced styling
      menuItem(
        "📊 Data Upload & QC", 
        tabName = "upload", 
        icon = icon("upload"),
        badgeLabel = "Start", 
        badgeColor = "green"
      ),
      
      menuItem(
        "⚙️ Network Analysis", 
        tabName = "wgcna", 
        icon = icon("project-diagram"),
        badgeLabel = "Core", 
        badgeColor = "blue"
      ),
      
      menuItem(
        "🧬 Enrichment Analysis", 
        tabName = "enrichment", 
        icon = icon("dna"),
        badgeLabel = "Functional", 
        badgeColor = "purple"
      ),
      
      menuItem(
        "📈 Visualization Suite", 
        tabName = "visual", 
        icon = icon("chart-bar"),
        badgeLabel = "Results", 
        badgeColor = "orange"
      ),
      
      menuItem(
        "📋 Results Export", 
        tabName = "export", 
        icon = icon("download"),
        badgeLabel = "Export", 
        badgeColor = "yellow"
      ),
      
      menuItem(
        "🔍 Quality Control", 
        tabName = "qc", 
        icon = icon("check-circle"),
        badgeLabel = "QC", 
        badgeColor = "teal"
      ),
      
      menuItem(
        "ℹ️ Help & Documentation", 
        tabName = "help", 
        icon = icon("question-circle")
      ),
      
      # Footer
      div(
        style = "position: absolute; bottom: 20px; left: 20px; right: 20px; 
                 text-align: center; color: #718096; font-size: 11px;",
        hr(style = "border-color: #4a5568; margin: 15px 0;"),
        p("Version 2.0 Enhanced", style = "margin: 5px 0;"),
        p("© 2025 WGCNA Platform", style = "margin: 0;")
      )
    )
  ),
  
  dashboardBody(
    # Enhanced styling
    tags$head(
      tags$style(HTML(css)),
      tags$script("
        // Add smooth transitions
        $(document).ready(function() {
          $('.box').hide().fadeIn(800);
        });
      ")
    ),
    
    # Loading functionality (placeholder for waiter)
    div(id = "loading-placeholder", style = "display: none;"),
    
    tabItems(
      # Enhanced Data Upload Tab
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
            enhancedDataUploadUI("data_upload")
          )
        )
      ),
      
      # Enhanced WGCNA Analysis Tab
      tabItem(
        tabName = "wgcna",
        fluidRow(
          # Parameter panel
          column(4,
            box(
              title = tags$div(
                icon("cogs", style = "margin-right: 10px;"),
                "Analysis Configuration"
              ),
              status = "primary", 
              solidHeader = TRUE,
              width = NULL,
              height = "600px",
              enhancedWGCNAAnalysisUI("wgcna_analysis")
            )
          ),
          
          # Results panel
          column(8,
            box(
              title = tags$div(
                icon("chart-line", style = "margin-right: 10px;"),
                "Analysis Results & Metrics"
              ),
              status = "info", 
              solidHeader = TRUE,
              width = NULL,
              height = "600px",
              # Results will be populated by server
              div(id = "wgcna-results-content")
            )
          )
        )
      ),
      
      # Enhanced Enrichment Analysis Tab
      tabItem(
        tabName = "enrichment",
        fluidRow(
          box(
            title = tags$div(
              icon("dna", style = "margin-right: 10px;"),
              "Functional Enrichment Analysis"
            ),
            status = "primary", 
            solidHeader = TRUE,
            width = 12,
            enhancedEnrichmentAnalysisUI("enrich_analysis")
          )
        )
      ),
      
      # Enhanced Visualization Tab
      tabItem(
        tabName = "visual",
        fluidRow(
          box(
            title = tags$div(
              icon("chart-bar", style = "margin-right: 10px;"),
              "Interactive Visualization Suite"
            ),
            status = "primary", 
            solidHeader = TRUE,
            width = 12,
            enhancedVisualizationUI("visualization")
          )
        )
      ),
      
      # New Export Tab
      tabItem(
        tabName = "export",
        fluidRow(
          box(
            title = tags$div(
              icon("download", style = "margin-right: 10px;"),
              "Results Export & Reporting"
            ),
            status = "success", 
            solidHeader = TRUE,
            width = 12,
            resultsExportUI("results_export")
          )
        )
      ),
      
      # New Quality Control Tab
      tabItem(
        tabName = "qc",
        fluidRow(
          box(
            title = tags$div(
              icon("check-circle", style = "margin-right: 10px;"),
              "Quality Control Dashboard"
            ),
            status = "info", 
            solidHeader = TRUE,
            width = 12,
            qualityControlUI("quality_control")
          )
        )
      ),
      
      # Enhanced Help Tab
      tabItem(
        tabName = "help",
        fluidRow(
          box(
            title = tags$div(
              icon("book", style = "margin-right: 10px;"),
              "Documentation & User Guide"
            ),
            status = "info", 
            solidHeader = TRUE,
            width = 12,
            
            tabsetPanel(
              tabPanel(
                "🚀 Quick Start",
                br(),
                div(
                  class = "row",
                  div(
                    class = "col-md-6",
                    h4("📁 Step 1: Data Upload"),
                    tags$ul(
                      tags$li("Upload expression matrix (genes × samples)"),
                      tags$li("Upload sample annotation (samples × traits)"),
                      tags$li("Review quality control metrics"),
                      tags$li("Address any data quality issues")
                    ),
                    br(),
                    h4("⚙️ Step 2: Network Analysis"),
                    tags$ul(
                      tags$li("Configure soft threshold power"),
                      tags$li("Set minimum module size"),
                      tags$li("Adjust merge cut height"),
                      tags$li("Run WGCNA analysis")
                    )
                  ),
                  div(
                    class = "col-md-6",
                    h4("🧬 Step 3: Functional Analysis"),
                    tags$ul(
                      tags$li("Select modules of interest"),
                      tags$li("Choose organism database"),
                      tags$li("Run GO enrichment analysis"),
                      tags$li("Explore functional annotations")
                    ),
                    br(),
                    h4("📊 Step 4: Visualization"),
                    tags$ul(
                      tags$li("Generate dendrograms"),
                      tags$li("Create module-trait heatmaps"),
                      tags$li("Explore network properties"),
                      tags$li("Export publication-ready figures")
                    )
                  )
                )
              ),
              
              tabPanel(
                "📋 Data Requirements",
                br(),
                h4("Expression Matrix Format"),
                tags$div(
                  style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;",
                  tags$ul(
                    tags$li("CSV format with proper headers"),
                    tags$li("Genes as rows, samples as columns"),
                    tags$li("Numeric expression values only"),
                    tags$li("Missing values should be minimal (<20%)"),
                    tags$li("Recommended: log2-transformed, normalized data")
                  )
                ),
                
                h4("Sample Annotation Format"),
                tags$div(
                  style = "background: #f8f9fa; padding: 15px; border-radius: 8px; margin: 10px 0;",
                  tags$ul(
                    tags$li("CSV format with sample IDs as row names"),
                    tags$li("Samples as rows, traits as columns"),
                    tags$li("Sample IDs must match expression matrix columns"),
                    tags$li("Categorical traits should be properly encoded"),
                    tags$li("Continuous traits should be numeric")
                  )
                )
              ),
              
              tabPanel(
                "🔧 Parameter Guide",
                br(),
                h4("Soft Threshold Power"),
                p("Controls the strength of connection weights. Higher values create more stringent networks."),
                tags$ul(
                  tags$li("Unsigned networks: typically 6-12"),
                  tags$li("Signed networks: typically 12-20"),
                  tags$li("Use scale-free topology plot to guide selection")
                ),
                
                h4("Minimum Module Size"),
                p("Smallest allowable module size. Affects sensitivity vs. specificity trade-off."),
                tags$ul(
                  tags$li("Larger values: fewer, larger modules"),
                  tags$li("Smaller values: more, smaller modules"),
                  tags$li("Typical range: 20-100 genes")
                ),
                
                h4("Merge Cut Height"),
                p("Threshold for merging similar modules based on eigengene correlation."),
                tags$ul(
                  tags$li("Lower values: more modules retained"),
                  tags$li("Higher values: more modules merged"),
                  tags$li("Typical range: 0.15-0.35")
                )
              ),
              
              tabPanel(
                "❓ Troubleshooting",
                br(),
                h4("Common Issues & Solutions"),
                
                tags$div(
                  style = "margin: 15px 0;",
                  h5("🔴 Memory Issues"),
                  p("For large datasets (>20,000 genes):"),
                  tags$ul(
                    tags$li("Enable blockwise analysis (automatic for >5,000 genes)"),
                    tags$li("Increase RAM allocation in R"),
                    tags$li("Consider pre-filtering low-variance genes")
                  )
                ),
                
                tags$div(
                  style = "margin: 15px 0;",
                  h5("🔴 No Modules Detected"),
                  p("Possible causes and solutions:"),
                  tags$ul(
                    tags$li("Lower the soft threshold power"),
                    tags$li("Reduce minimum module size"),
                    tags$li("Check data quality and normalization"),
                    tags$li("Ensure sufficient sample size (>15 recommended)")
                  )
                ),
                
                tags$div(
                  style = "margin: 15px 0;",
                  h5("🔴 Analysis Takes Too Long"),
                  p("Performance optimization tips:"),
                  tags$ul(
                    tags$li("Enable multi-threading"),
                    tags$li("Pre-filter genes by variance"),
                    tags$li("Use blockwise analysis for large datasets"),
                    tags$li("Disable TOM file saving if not needed")
                  )
                )
              )
            )
          )
        )
      )
    )
  )
)

# Enhanced server function with improved error handling
server <- function(input, output, session) {
  
  # Call enhanced module server functions with proper fallbacks
  tryCatch({
    data <- enhancedDataUploadServer("data_upload")
  }, error = function(e) {
    # Fallback to original function if enhanced version fails
    if (exists("dataUploadServer")) {
      data <- dataUploadServer("data_upload")
    } else {
      showNotification("Data upload module not available", type = "error")
      data <- reactive(list(expr = function() NULL, sample = function() NULL))
    }
  })
  
  tryCatch({
    wgcna_results <- enhancedWGCNAAnalysisServer("wgcna_analysis", data)
  }, error = function(e) {
    # Fallback to original function if enhanced version fails
    if (exists("wgcnaAnalysisServer")) {
      wgcna_results <- wgcnaAnalysisServer("wgcna_analysis", data)
    } else {
      showNotification("WGCNA analysis module not available", type = "error")
      wgcna_results <- reactive(NULL)
    }
  })
  
  tryCatch({
    enrichmentAnalysisServer("enrich_analysis", wgcna_results)
  }, error = function(e) {
    showNotification("Enrichment analysis module not available", type = "warning")
  })
  
  tryCatch({
    visualizationServer("visualization", wgcna_results)
  }, error = function(e) {
    showNotification("Visualization module not available", type = "warning")
  })
  
  tryCatch({
    qualityControlServer("quality_control", data, wgcna_results)
  }, error = function(e) {
    showNotification("Quality control module not available", type = "warning")
  })
  
  tryCatch({
    resultsExportServer("results_export", wgcna_results)
  }, error = function(e) {
    showNotification("Results export module not available", type = "warning")
  })
  
  # Session info for debugging
  output$session_info <- renderPrint({
    sessionInfo()
  })
}

# Run the application
shinyApp(ui = ui, server = server)
