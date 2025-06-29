# Enhanced Data Upload Module with Advanced QC
# =============================================

# Helper function for spinner with fallback
spinner_wrapper <- function(ui_element, type = 6) {
  if (requireNamespace("shinycssloaders", quietly = TRUE)) {
    shinycssloaders::withSpinner(ui_element, type = type)
  } else {
    ui_element
  }
}

enhancedDataUploadUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    # Progress indicator
    uiOutput(ns("upload_progress")),
    
    fluidRow(
      # Left panel - File uploads
      column(6,
        wellPanel(
          style = "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; border-radius: 12px;",
          
          h4("📁 Data Upload", style = "color: white; text-align: center; margin-bottom: 20px;"),
          
          # Expression data upload
          div(
            style = "background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px; margin-bottom: 15px;",
            h5("🧬 Expression Matrix", style = "color: #e2e8f0;"),
            fileInput(
              ns("expression_data"), 
              "",
              accept = c(".csv", ".txt", ".tsv"),
              placeholder = "Choose expression matrix file...",
              buttonLabel = "Browse",
              multiple = FALSE
            ),
            helpText("Genes as rows, samples as columns | CSV/TSV format", 
                    style = "color: #cbd5e0; font-size: 12px;"),
            
            conditionalPanel(
              condition = "output.expr_uploaded",
              ns = ns,
              div(
                class = "alert alert-success",
                style = "background: rgba(72, 187, 120, 0.2); border: 1px solid #48bb78; border-radius: 6px; color: white;",
                icon("check-circle"), " Expression data loaded successfully!"
              )
            )
          ),
          
          # Sample annotation upload
          div(
            style = "background: rgba(255,255,255,0.1); padding: 15px; border-radius: 8px;",
            h5("📋 Sample Annotation", style = "color: #e2e8f0;"),
            fileInput(
              ns("sample_data"), 
              "",
              accept = c(".csv", ".txt", ".tsv"),
              placeholder = "Choose sample annotation file...",
              buttonLabel = "Browse",
              multiple = FALSE
            ),
            helpText("Samples as rows, traits as columns | CSV/TSV format", 
                    style = "color: #cbd5e0; font-size: 12px;"),
            
            conditionalPanel(
              condition = "output.sample_uploaded",
              ns = ns,
              div(
                class = "alert alert-success",
                style = "background: rgba(72, 187, 120, 0.2); border: 1px solid #48bb78; border-radius: 6px; color: white;",
                icon("check-circle"), " Sample data loaded successfully!"
              )
            )
          )
        )
      ),
      
      # Right panel - Sample data
      column(6,
        wellPanel(
          h4("📊 Sample Data Options", style = "color: #4a5568; margin-bottom: 15px;"),
          
          p("Or use built-in sample datasets:", style = "color: #718096;"),
          
          fluidRow(
            column(6,
              actionButton(
                ns("load_sample_small"), 
                "📁 Load Small Dataset",
                class = "btn-info btn-block",
                style = "margin-bottom: 10px;"
              ),
              helpText("~1000 genes, 20 samples", style = "font-size: 11px; color: #a0aec0;")
            ),
            column(6,
              actionButton(
                ns("load_sample_large"), 
                "📁 Load Large Dataset",
                class = "btn-warning btn-block",
                style = "margin-bottom: 10px;"
              ),
              helpText("~5000 genes, 50 samples", style = "font-size: 11px; color: #a0aec0;")
            )
          ),
          
          br(),
          
          # Advanced options
          h5("⚙️ Advanced Options", style = "color: #4a5568;"),
          
          fluidRow(
            column(6,
              checkboxInput(ns("transpose_expr"), "Transpose Expression Matrix", FALSE),
              helpText("Check if samples are in rows", style = "font-size: 11px;")
            ),
            column(6,
              numericInput(ns("missing_threshold"), "Missing Data Threshold (%):", 
                          value = 50, min = 10, max = 90, step = 5),
              helpText("Max % missing values per gene/sample", style = "font-size: 11px;")
            )
          ),
          
          fluidRow(
            column(6,
              selectInput(ns("separator"), "File Separator:",
                         choices = list("Comma (,)" = ",", "Tab" = "\t", "Semicolon (;)" = ";"),
                         selected = ",")
            ),
            column(6,
              checkboxInput(ns("has_rownames"), "First Column as Row Names", TRUE)
            )
          )
        )
      )
    ),
    
    # Data preview and quality control section
    conditionalPanel(
      condition = "output.show_preview",
      ns = ns,
      
      # Data summary cards
      fluidRow(
        valueBoxOutput(ns("genes_count"), width = 3),
        valueBoxOutput(ns("samples_count"), width = 3),
        valueBoxOutput(ns("missing_data"), width = 3),
        valueBoxOutput(ns("data_quality"), width = 3)
      ),
      
      br(),
      
      # Detailed quality control
      box(
        title = "🔍 Data Quality Assessment", 
        status = "info", 
        solidHeader = TRUE,
        width = 12,
        collapsible = TRUE,
        
        tabsetPanel(
          id = ns("qc_tabs"),
          
          # Data preview tab
          tabPanel(
            "📊 Data Preview",
            br(),
            fluidRow(
              column(6,
                h5("Expression Data Preview"),
                spinner_wrapper(DT::DTOutput(ns("expr_preview")), type = 6)
              ),
              column(6,
                h5("Sample Annotation Preview"),
                spinner_wrapper(DT::DTOutput(ns("sample_preview")), type = 6)
              )
            )
          ),
          
          # Quality metrics tab
          tabPanel(
            "📈 Quality Metrics",
            br(),
            fluidRow(
              column(6,
                h5("Expression Distribution"),
                spinner_wrapper(plotOutput(ns("expr_distribution")), type = 6)
              ),
              column(6,
                h5("Sample Clustering"),
                spinner_wrapper(plotOutput(ns("sample_clustering")), type = 6)
              )
            ),
            br(),
            fluidRow(
              column(12,
                h5("Data Quality Report"),
                verbatimTextOutput(ns("quality_report"))
              )
            )
          ),
          
          # Data processing tab
          tabPanel(
            "⚙️ Data Processing",
            br(),
            fluidRow(
              column(4,
                h5("Preprocessing Options"),
                checkboxInput(ns("remove_outliers"), "Remove Outlier Samples", FALSE),
                checkboxInput(ns("filter_lowvar"), "Filter Low Variance Genes", TRUE),
                numericInput(ns("variance_threshold"), "Variance Threshold:", 
                           value = 0.1, min = 0.01, max = 1, step = 0.01),
                br(),
                actionButton(ns("process_data"), "Process Data", 
                           class = "btn-primary btn-block")
              ),
              column(8,
                h5("Processing Results"),
                verbatimTextOutput(ns("processing_results"))
              )
            )
          )
        )
      )
    )
  )
}

enhancedDataUploadServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive values to store data
    values <- reactiveValues(
      expr_raw = NULL,
      sample_raw = NULL,
      expr_processed = NULL,
      sample_processed = NULL,
      processing_done = FALSE
    )
    
    # Upload progress indicator
    output$upload_progress <- renderUI({
      if (!is.null(values$expr_raw) && !is.null(values$sample_raw)) {
        if (values$processing_done) {
          div(
            class = "alert alert-success",
            style = "text-align: center; margin-bottom: 20px;",
            h4(icon("check-circle"), " Data Successfully Loaded & Processed"),
            p("Ready for WGCNA analysis")
          )
        } else {
          div(
            class = "alert alert-info",
            style = "text-align: center; margin-bottom: 20px;",
            h4(icon("info-circle"), " Data Loaded - Processing Recommended"),
            p("Review quality metrics and apply preprocessing if needed")
          )
        }
      }
    })
    
    # Load expression data
    expression_data <- reactive({
      if (!is.null(input$expression_data)) {
        result <- safe_read_csv(
          input$expression_data$datapath, 
          row_names = input$has_rownames,
          sep = input$separator
        )
        
        if (result$success) {
          data <- result$data
          
          # Transpose if needed
          if (input$transpose_expr) {
            data <- t(data)
          }
          
          # Validate and clean
          validation <- validate_expression_data(data)
          if (!validation$valid) {
            showNotification(validation$message, type = "error", duration = 10)
            return(NULL)
          }
          
          values$expr_raw <- data
          showNotification("Expression data loaded successfully", type = "message")
          return(data)
        } else {
          showNotification(result$message, type = "error", duration = 10)
          return(NULL)
        }
      }
      return(values$expr_raw)
    })
    
    # Load sample data
    sample_data <- reactive({
      if (!is.null(input$sample_data)) {
        result <- safe_read_csv(
          input$sample_data$datapath, 
          row_names = input$has_rownames,
          sep = input$separator
        )
        
        if (result$success) {
          data <- result$data
          
          # Validate compatibility
          if (!is.null(values$expr_raw)) {
            validation <- validate_sample_data(data, values$expr_raw)
            if (!validation$valid) {
              showNotification(validation$message, type = "error", duration = 10)
              return(NULL)
            }
          }
          
          values$sample_raw <- data
          showNotification("Sample data loaded successfully", type = "message")
          return(data)
        } else {
          showNotification(result$message, type = "error", duration = 10)
          return(NULL)
        }
      }
      return(values$sample_raw)
    })
    
    # Load sample datasets
    observeEvent(input$load_sample_small, {
      tryCatch({
        # Load small sample dataset
        expr_file <- file.path("data", "sample_expression.csv")
        trait_file <- file.path("data", "sample_traits.csv")
        
        if (file.exists(expr_file) && file.exists(trait_file)) {
          values$expr_raw <- read.csv(expr_file, row.names = 1, check.names = FALSE)
          values$sample_raw <- read.csv(trait_file, row.names = 1, check.names = FALSE)
          showNotification("Sample dataset loaded successfully", type = "message")
        } else {
          showNotification("Sample files not found", type = "error")
        }
      }, error = function(e) {
        showNotification(paste("Error loading sample data:", e$message), type = "error")
      })
    })
    
    observeEvent(input$load_sample_large, {
      tryCatch({
        # Load large sample dataset
        expr_file <- file.path("data", "expression_matrix_large.csv")
        trait_file <- file.path("data", "sample_annotation_large.csv")
        
        if (file.exists(expr_file) && file.exists(trait_file)) {
          values$expr_raw <- read.csv(expr_file, row.names = 1, check.names = FALSE)
          values$sample_raw <- read.csv(trait_file, row.names = 1, check.names = FALSE)
          showNotification("Large sample dataset loaded successfully", type = "message")
        } else {
          showNotification("Large sample files not found", type = "error")
        }
      }, error = function(e) {
        showNotification(paste("Error loading large sample data:", e$message), type = "error")
      })
    })
    
    # Status outputs
    output$expr_uploaded <- reactive({
      !is.null(values$expr_raw)
    })
    outputOptions(output, "expr_uploaded", suspendWhenHidden = FALSE)
    
    output$sample_uploaded <- reactive({
      !is.null(values$sample_raw)
    })
    outputOptions(output, "sample_uploaded", suspendWhenHidden = FALSE)
    
    output$show_preview <- reactive({
      !is.null(values$expr_raw) && !is.null(values$sample_raw)
    })
    outputOptions(output, "show_preview", suspendWhenHidden = FALSE)
    
    # Value boxes for summary statistics
    output$genes_count <- renderValueBox({
      valueBox(
        value = if (!is.null(values$expr_raw)) nrow(values$expr_raw) else 0,
        subtitle = "Genes",
        icon = icon("dna"),
        color = "blue"
      )
    })
    
    output$samples_count <- renderValueBox({
      valueBox(
        value = if (!is.null(values$expr_raw)) ncol(values$expr_raw) else 0,
        subtitle = "Samples",
        icon = icon("users"),
        color = "green"
      )
    })
    
    output$missing_data <- renderValueBox({
      missing_pct <- if (!is.null(values$expr_raw)) {
        round(sum(is.na(values$expr_raw)) / length(values$expr_raw) * 100, 1)
      } else 0
      
      valueBox(
        value = paste0(missing_pct, "%"),
        subtitle = "Missing Data",
        icon = icon("exclamation-triangle"),
        color = if (missing_pct > 20) "red" else if (missing_pct > 10) "yellow" else "green"
      )
    })
    
    output$data_quality <- renderValueBox({
      quality <- if (!is.null(values$expr_raw)) {
        check_expression_quality(values$expr_raw)$quality
      } else "unknown"
      
      valueBox(
        value = stringr::str_to_title(quality),
        subtitle = "Data Quality",
        icon = icon("check-circle"),
        color = switch(quality, "good" = "green", "warning" = "yellow", "red")
      )
    })
    
    # Data previews
    output$expr_preview <- DT::renderDT({
      req(values$expr_raw)
      DT::datatable(
        values$expr_raw[1:min(100, nrow(values$expr_raw)), 1:min(10, ncol(values$expr_raw))],
        options = list(
          scrollX = TRUE, 
          pageLength = 10,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv')
        ),
        extensions = 'Buttons',
        caption = "Expression Matrix Preview"
      )
    })
    
    output$sample_preview <- DT::renderDT({
      req(values$sample_raw)
      DT::datatable(
        values$sample_raw,
        options = list(
          scrollX = TRUE, 
          pageLength = 10,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv')
        ),
        extensions = 'Buttons',
        caption = "Sample Annotation Preview"
      )
    })
    
    # Quality plots
    output$expr_distribution <- renderPlot({
      req(values$expr_raw)
      
      # Sample expression distribution
      expr_means <- colMeans(values$expr_raw, na.rm = TRUE)
      hist(expr_means, 
           breaks = 30, 
           main = "Sample Expression Distribution",
           xlab = "Mean Expression",
           col = "lightblue",
           border = "white")
    })
    
    output$sample_clustering <- renderPlot({
      req(values$expr_raw)
      
      if (ncol(values$expr_raw) > 3) {
        # Hierarchical clustering of samples
        sample_dist <- dist(t(values$expr_raw))
        sample_clust <- hclust(sample_dist, method = "average")
        plot(sample_clust, 
             main = "Sample Clustering Dendrogram",
             xlab = "Samples",
             sub = "",
             cex = 0.8)
      }
    })
    
    # Quality report
    output$quality_report <- renderText({
      req(values$expr_raw, values$sample_raw)
      
      # Comprehensive quality assessment
      expr_validation <- validate_expression_data(values$expr_raw)
      sample_validation <- validate_sample_data(values$sample_raw, values$expr_raw)
      expr_quality <- check_expression_quality(values$expr_raw)
      
      paste(
        "=== Data Quality Assessment ===",
        "",
        "Expression Data:",
        paste("- Dimensions:", nrow(values$expr_raw), "genes ×", ncol(values$expr_raw), "samples"),
        paste("- Data type:", class(values$expr_raw[1,1])),
        paste("- Missing values:", sum(is.na(values$expr_raw)), 
              paste0("(", round(sum(is.na(values$expr_raw))/length(values$expr_raw)*100, 2), "%)")),
        paste("- Validation:", expr_validation$message),
        "",
        "Sample Annotation:",
        paste("- Dimensions:", nrow(values$sample_raw), "samples ×", ncol(values$sample_raw), "traits"),
        paste("- Validation:", sample_validation$message),
        "",
        "Quality Assessment:",
        paste("- Overall quality:", expr_quality$quality),
        paste("- Details:", expr_quality$message),
        "",
        if (values$processing_done) "✅ Data has been processed and is ready for analysis" else "⚠️ Consider applying preprocessing steps",
        sep = "\n"
      )
    })
    
    # Data processing
    observeEvent(input$process_data, {
      req(values$expr_raw, values$sample_raw)
      
      showNotification("Processing data...", type = "message")
      
      tryCatch({
        processed_expr <- values$expr_raw
        processed_sample <- values$sample_raw
        
        # Remove outlier samples if requested
        if (input$remove_outliers) {
          outlier_info <- detect_outliers(t(processed_expr))
          if (length(outlier_info$outliers) > 0) {
            outlier_samples <- colnames(processed_expr)[outlier_info$outliers]
            processed_expr <- processed_expr[, -outlier_info$outliers]
            processed_sample <- processed_sample[!(rownames(processed_sample) %in% outlier_samples), ]
            showNotification(paste("Removed", length(outlier_info$outliers), "outlier samples"), type = "warning")
          }
        }
        
        # Filter low variance genes if requested
        if (input$filter_lowvar) {
          gene_vars <- apply(processed_expr, 1, var, na.rm = TRUE)
          keep_genes <- gene_vars > input$variance_threshold
          processed_expr <- processed_expr[keep_genes, ]
          showNotification(paste("Filtered", sum(!keep_genes), "low variance genes"), type = "message")
        }
        
        # Store processed data
        values$expr_processed <- processed_expr
        values$sample_processed <- processed_sample
        values$processing_done <- TRUE
        
        showNotification("Data processing completed successfully!", type = "message")
        
      }, error = function(e) {
        showNotification(paste("Error in data processing:", e$message), type = "error")
      })
    })
    
    # Processing results
    output$processing_results <- renderText({
      if (values$processing_done) {
        paste(
          "=== Processing Results ===",
          "",
          "Original Data:",
          paste("- Genes:", nrow(values$expr_raw)),
          paste("- Samples:", ncol(values$expr_raw)),
          "",
          "Processed Data:",
          paste("- Genes:", nrow(values$expr_processed)),
          paste("- Samples:", ncol(values$expr_processed)),
          "",
          "Changes:",
          paste("- Genes removed:", nrow(values$expr_raw) - nrow(values$expr_processed)),
          paste("- Samples removed:", ncol(values$expr_raw) - ncol(values$expr_processed)),
          "",
          "Status: ✅ Ready for WGCNA analysis",
          sep = "\n"
        )
      } else {
        "No processing applied yet. Review quality metrics and select appropriate preprocessing options."
      }
    })
    
    # Return processed data for downstream analysis
    return(reactive({
      list(
        expr = if (values$processing_done) 
                function() values$expr_processed 
               else 
                function() values$expr_raw,
        sample = if (values$processing_done) 
                  function() values$sample_processed 
                 else 
                  function() values$sample_raw,
        processed = reactive(values$processing_done)
      )
    }))
  })
}
