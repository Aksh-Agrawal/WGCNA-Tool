# UI
dataUploadUI <- function(id) {
  ns <- NS(id)
  tagList(
    wellPanel(
      h4("📁 Data Upload", style = "color: #3c8dbc;"),
      
      fluidRow(
        column(6,
               h5("Expression Data", style = "color: #2c3e50;"),
               fileInput(ns("expression_data"), 
                         "Choose Expression Matrix CSV File",
                         accept = c(".csv", ".txt")),
               helpText("Rows: Genes, Columns: Samples"),
               
               conditionalPanel(
                 condition = paste0("output['", ns("expr_uploaded"), "']"),
                 div(class = "alert alert-success",
                     style = "margin-top: 10px;",
                     icon("check-circle"), " Expression data loaded successfully!")
               )
        ),
        
        column(6,
               h5("Sample Annotation", style = "color: #2c3e50;"),
               fileInput(ns("sample_data"), 
                         "Choose Sample Annotation CSV File",
                         accept = c(".csv", ".txt")),
               helpText("Rows: Samples, Columns: Traits"),
               
               conditionalPanel(
                 condition = paste0("output['", ns("sample_uploaded"), "']"),
                 div(class = "alert alert-success",
                     style = "margin-top: 10px;",
                     icon("check-circle"), " Sample data loaded successfully!")
               )
        )
      ),
      
      br(),
      
      conditionalPanel(
        condition = paste0("output['", ns("show_preview"), "']"),
        wellPanel(
          h5("📊 Data Summary", style = "color: #2c3e50;"),
          verbatimTextOutput(ns("data_summary")),
          
          br(),
          
          tabsetPanel(
            tabPanel("Expression Preview", 
                     DT::DTOutput(ns("expr_preview"))),
            tabPanel("Sample Preview", 
                     DT::DTOutput(ns("sample_preview")))
          )
        )
      )
    )
  )
}

dataUploadServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    expression_data <- reactive({
      req(input$expression_data)
      tryCatch({
        data <- read.csv(input$expression_data$datapath, row.names = 1, check.names = FALSE)
        numeric_cols <- sapply(data, is.numeric)
        if (!all(numeric_cols)) {
          showNotification("Warning: Non-numeric columns detected in expression data", 
                           type = "warning", duration = 5)
        }
        data[, numeric_cols, drop = FALSE]
      }, error = function(e) {
        showNotification(paste("Error loading expression data:", e$message), 
                         type = "error", duration = 10)
        NULL
      })
    })
    
    sample_data <- reactive({
      req(input$sample_data)
      tryCatch({
        read.csv(input$sample_data$datapath, row.names = 1, check.names = FALSE)
      }, error = function(e) {
        showNotification(paste("Error loading sample data:", e$message), 
                         type = "error", duration = 10)
        NULL
      })
    })
    
    # Status outputs
    output$expr_uploaded <- reactive({
      !is.null(expression_data())
    })
    outputOptions(output, "expr_uploaded", suspendWhenHidden = FALSE)
    
    output$sample_uploaded <- reactive({
      !is.null(sample_data())
    })
    outputOptions(output, "sample_uploaded", suspendWhenHidden = FALSE)
    
    output$show_preview <- reactive({
      !is.null(expression_data()) && !is.null(sample_data())
    })
    outputOptions(output, "show_preview", suspendWhenHidden = FALSE)

    output$expr_preview <- DT::renderDT({
      req(expression_data())
      DT::datatable(expression_data()[1:min(100, nrow(expression_data())), 1:min(10, ncol(expression_data()))],
                    options = list(scrollX = TRUE, pageLength = 10))
    })
    
    output$sample_preview <- DT::renderDT({
      req(sample_data())
      DT::datatable(sample_data(),
                    options = list(scrollX = TRUE, pageLength = 10))
    })
    
    output$data_summary <- renderText({
      req(expression_data(), sample_data())
      paste(
        "Expression Data:",
        paste("- Genes:", nrow(expression_data())),
        paste("- Samples:", ncol(expression_data())),
        "",
        "Sample Annotation:",
        paste("- Samples:", nrow(sample_data())),
        paste("- Traits:", ncol(sample_data())),
        "",
        "Data Quality:",
        paste("- Expression data type:", class(expression_data()[,1])),
        paste("- Missing values in expression:", sum(is.na(expression_data()))),
        paste("- Sample overlap:", length(intersect(colnames(expression_data()), rownames(sample_data())))),
        sep = "\n"
      )
    })
    
    return(list(expr = expression_data, sample = sample_data))
  })
}
