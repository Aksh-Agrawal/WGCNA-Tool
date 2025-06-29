# Enhanced WGCNA Analysis Module with Advanced Features
# =====================================================

enhancedWGCNAAnalysisUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    wellPanel(
      style = "height: 550px; overflow-y: auto;",
      
      h4("⚙️ Network Analysis Configuration", style = "color: #4a5568; margin-bottom: 20px;"),
      
      # Power selection with automatic estimation
      div(
        style = "background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
        h5("🔌 Soft Threshold Power"),
        
        fluidRow(
          column(8,
            numericInput(ns("power"), "Power:", 
                        value = 6, min = 1, max = 30, step = 1)
          ),
          column(4,
            br(),
            actionButton(ns("estimate_power"), "Auto-Estimate", 
                        class = "btn-info btn-sm", style = "margin-top: 5px;")
          )
        ),
        
        helpText("Higher values create more stringent networks", style = "color: #718096;"),
        uiOutput(ns("power_suggestion"))
      ),
      
      # Module parameters
      div(
        style = "background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
        h5("📦 Module Detection Parameters"),
        
        fluidRow(
          column(6,
            numericInput(ns("min_module_size"), "Min Module Size:", 
                        value = 30, min = 5, max = 200, step = 5)
          ),
          column(6,
            numericInput(ns("merge_cut_height"), "Merge Cut Height:", 
                        value = 0.25, min = 0.1, max = 0.9, step = 0.05)
          )
        ),
        
        selectInput(ns("tom_type"), "Network Type:",
                   choices = list(
                     "Unsigned" = "unsigned", 
                     "Signed" = "signed",
                     "Signed Hybrid" = "signed hybrid"
                   ),
                   selected = "unsigned")
      ),
      
      # Advanced options
      div(
        style = "background: #f7fafc; padding: 15px; border-radius: 8px; margin-bottom: 15px;",
        h5("⚙️ Advanced Options"),
        
        fluidRow(
          column(6,
            checkboxInput(ns("enable_threading"), "Multi-threading", value = TRUE)
          ),
          column(6,
            checkboxInput(ns("save_toms"), "Save TOM Files", value = FALSE)
          )
        ),
        
        fluidRow(
          column(6,
            numericInput(ns("max_block_size"), "Max Block Size:", 
                        value = 5000, min = 1000, max = 20000, step = 1000)
          ),
          column(6,
            selectInput(ns("correlation_type"), "Correlation:",
                       choices = list("Pearson" = "pearson", "Bicor" = "bicor"),
                       selected = "pearson")
          )
        )
      ),
      
      # Run button
      div(
        style = "text-align: center; margin-top: 20px;",
        actionButton(
          ns("run_wgcna"), 
          "🚀 Run WGCNA Analysis", 
          class = "btn-primary btn-lg",
          style = "padding: 12px 30px; font-weight: bold;"
        )
      ),
      
      # Progress indicator
      uiOutput(ns("progress_section"))
    ),
    
    # Results section
    uiOutput(ns("results_section"))
  )
}

enhancedWGCNAAnalysisServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    
    # Ensure WGCNA is loaded
    if (!requireNamespace("WGCNA", quietly = TRUE)) {
      showNotification("WGCNA package not available", type = "error")
      return(NULL)
    }
    
    library(WGCNA)
    options(stringsAsFactors = FALSE)
    
    # Reactive values for results and state management
    analysis_results <- reactiveVal(NULL)
    power_analysis <- reactiveVal(NULL)
    analysis_running <- reactiveVal(FALSE)
    
    # Progress section UI
    output$progress_section <- renderUI({
      if (analysis_running()) {
        div(
          br(),
          div(
            style = "background: #edf2f7; padding: 15px; border-radius: 8px; text-align: center;",
            h5("📊 Analysis Progress"),
            div(
              style = "margin: 20px 0;",
              h5("Analysis in progress..."),
              div(class = "lds-dual-ring"),
              p("This may take several minutes for large datasets...", 
                style = "color: #718096; margin-top: 15px;")
            )
          )
        )
      } else {
        NULL
      }
    })
    
    # Results section UI
    output$results_section <- renderUI({
      if (!is.null(analysis_results())) {
        wellPanel(
          h4("📊 Analysis Results", style = "color: #4a5568;"),
          
          tabsetPanel(
            tabPanel("Module Summary",
              br(),
              DT::DTOutput(session$ns("modules_table"))
            ),
            tabPanel("Network Metrics",
              br(),
              verbatimTextOutput(session$ns("network_summary"))
            )
          )
        )
      } else {
        NULL
      }
    })
    
    # Enable/disable threading
    observe({
      if (input$enable_threading) {
        enableWGCNAThreads()
      } else {
        disableWGCNAThreads()
      }
    })
    
    # Power estimation
    observeEvent(input$estimate_power, {
      req(data()$expr())
      
      showNotification("Estimating optimal power...", type = "message")
      
      tryCatch({
        datExpr <- t(data()$expr())
        
        # Remove any samples/genes with too many missing values
        gsg <- goodSamplesGenes(datExpr, verbose = 0)
        if (!gsg$allOK) {
          datExpr <- datExpr[gsg$goodSamples, gsg$goodGenes]
        }
        
        # Power analysis
        powers <- c(1:20)
        sft <- pickSoftThreshold(datExpr, 
                               powerVector = powers, 
                               verbose = 0, 
                               networkType = input$tom_type)
        
        power_analysis(sft)
        
        # Update power input
        if (!is.na(sft$powerEst)) {
          updateNumericInput(session, "power", value = sft$powerEst)
          showNotification(paste("Suggested power:", sft$powerEst), type = "message")
        } else {
          # Find best power based on R-squared
          best_power <- powers[which.max(sft$fitIndices$SFT.R.sq)]
          updateNumericInput(session, "power", value = best_power)
          showNotification(paste("Best power based on fit:", best_power), type = "message")
        }
        
      }, error = function(e) {
        showNotification(paste("Error in power estimation:", e$message), type = "error")
      })
    })
    
    # Power suggestion display
    output$power_suggestion <- renderUI({
      if (!is.null(power_analysis())) {
        sft <- power_analysis()
        if (!is.na(sft$powerEst)) {
          div(
            class = "alert alert-info",
            style = "margin-top: 10px; padding: 10px;",
            paste("💡 Suggested power:", sft$powerEst, 
                  "(R² =", round(sft$fitIndices$SFT.R.sq[sft$fitIndices$Power == sft$powerEst], 3), ")")
          )
        }
      }
    })
    
    # Progress display
    output$progress_display <- renderUI({
      # Simple progress indication
      div(
        style = "text-align: center;",
        h5("Analysis in progress..."),
        div(class = "lds-dual-ring")
      )
    })
    
    # Main WGCNA analysis
    observeEvent(input$run_wgcna, {
      req(data()$expr(), data()$sample())
      
      # Set analysis as running
      analysis_running(TRUE)
      analysis_results(NULL)  # Clear previous results
      
      showNotification("Starting WGCNA analysis...", type = "message")
      
      tryCatch({
        # Prepare data
        datExpr <- t(data()$expr())
        datTraits <- data()$sample()
        
        # Initial validation
        if (is.null(datExpr) || is.null(datTraits)) {
          stop("Expression data or sample data is missing")
        }
        
        showNotification(paste("Starting with", nrow(datExpr), "samples and", ncol(datExpr), "genes"), 
                        type = "message")
        
        # Convert to numeric matrix and handle missing values
        datExpr <- as.matrix(datExpr)
        if (!is.numeric(datExpr)) {
          stop("Expression data must be numeric")
        }
        
        # Remove genes with too many missing values (>50% missing)
        missing_threshold <- 0.5
        genes_missing <- apply(datExpr, 2, function(x) sum(is.na(x)) / length(x))
        good_genes <- genes_missing < missing_threshold
        
        if (sum(good_genes) < ncol(datExpr)) {
          showNotification(paste("Removing", sum(!good_genes), "genes with >50% missing values"), 
                          type = "warning")
          datExpr <- datExpr[, good_genes]
        }
        
        # Quality control
        gsg <- goodSamplesGenes(datExpr, verbose = 0)
        if (!gsg$allOK) {
          if (sum(!gsg$goodGenes) > 0) {
            showNotification(paste("Removing", sum(!gsg$goodGenes), "genes"), type = "warning")
          }
          if (sum(!gsg$goodSamples) > 0) {
            showNotification(paste("Removing", sum(!gsg$goodSamples), "samples"), type = "warning")
          }
          datExpr <- datExpr[gsg$goodSamples, gsg$goodGenes]
        }
        
        # Validate final dimensions
        min_samples <- 3  # Minimum for WGCNA
        min_genes <- 20   # Reasonable minimum for network analysis
        
        if (nrow(datExpr) < min_samples) {
          stop(paste("Insufficient samples after quality control:", nrow(datExpr), 
                    "samples remaining. Need at least", min_samples, "samples."))
        }
        
        if (ncol(datExpr) < min_genes) {
          stop(paste("Insufficient genes after quality control:", ncol(datExpr), 
                    "genes remaining. Need at least", min_genes, "genes."))
        }
        
        showNotification(paste("Data validated:", nrow(datExpr), "samples,", ncol(datExpr), "genes"), 
                        type = "message")
        
        showNotification("Building network...", type = "message")
        
        # Network construction
        net <- blockwiseModules(
          datExpr,
          power = input$power,
          TOMType = input$tom_type,
          minModuleSize = input$min_module_size,
          reassignThreshold = 0,
          mergeCutHeight = input$merge_cut_height,
          numericLabels = TRUE,
          pamRespectsDendro = FALSE,
          saveTOMs = input$save_toms,
          verbose = 0,
          maxBlockSize = input$max_block_size,
          corType = input$correlation_type,
          networkType = input$tom_type,
          saveTOMFileBase = ifelse(input$save_toms, "blockwiseTOM", FALSE)
        )
        
        showNotification("Calculating module eigengenes...", type = "message")
        
        # Module eigengenes
        MEs <- moduleEigengenes(datExpr, net$colors)$eigengenes
        MEs <- orderMEs(MEs)
        
        # Prepare results
        results <- list(
          net = net,
          expr = datExpr,
          traits = datTraits,
          MEs = MEs,
          power_used = input$power,
          power_analysis = power_analysis(),  # Include power analysis results
          parameters = list(
            power = input$power,
            minModuleSize = input$min_module_size,
            mergeCutHeight = input$merge_cut_height,
            TOMType = input$tom_type,
            networkType = input$tom_type,
            correlationType = input$correlation_type,
            maxBlockSize = input$max_block_size
          )
        )
        
        analysis_results(results)
        analysis_running(FALSE)  # Mark analysis as complete
        showNotification("WGCNA analysis completed successfully!", type = "message")
        
      }, error = function(e) {
        analysis_running(FALSE)  # Mark analysis as stopped even on error
        showNotification(paste("Error in WGCNA analysis:", e$message), type = "error")
      })
    })
    
    # Analysis complete status
    output$analysis_complete <- reactive({
      !is.null(analysis_results())
    })
    outputOptions(output, "analysis_complete", suspendWhenHidden = FALSE)
    
    # Module summary table
    output$modules_table <- DT::renderDT({
      req(analysis_results())
      
      results <- analysis_results()
      module_colors <- labels2colors(results$net$colors)
      
      # Create summary table
      module_summary <- data.frame(
        Module = names(table(module_colors)),
        GeneCount = as.numeric(table(module_colors)),
        Percentage = round(as.numeric(table(module_colors)) / length(module_colors) * 100, 1),
        stringsAsFactors = FALSE
      )
      
      module_summary <- module_summary[order(module_summary$GeneCount, decreasing = TRUE), ]
      
      DT::datatable(
        module_summary,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        extensions = 'Buttons',
        rownames = FALSE,
        caption = paste("Total modules found:", nrow(module_summary))
      ) %>%
        DT::formatStyle("Module", 
                       backgroundColor = DT::styleEqual(
                         module_summary$Module, 
                         module_summary$Module
                       ))
    })
    
    # Network statistics
    output$network_summary <- renderText({
      req(analysis_results())
      
      results <- analysis_results()
      module_colors <- labels2colors(results$net$colors)
      
      paste(
        "=== Network Analysis Summary ===",
        "",
        paste("Analysis completed:", Sys.time()),
        paste("Power used:", results$power_used),
        paste("Network type:", results$parameters$TOMType),
        paste("Correlation method:", results$parameters$correlationType),
        "",
        "=== Data Dimensions ===",
        paste("Genes analyzed:", ncol(results$expr)),
        paste("Samples analyzed:", nrow(results$expr)),
        paste("Total modules:", length(unique(module_colors))),
        paste("Largest module:", max(table(module_colors)), "genes"),
        paste("Smallest module:", min(table(module_colors)), "genes"),
        "",
        "=== Module Distribution ===",
        paste(names(table(module_colors)), ":", table(module_colors), "genes", collapse = "\n"),
        sep = "\n"
      )
    })
    
    # Network statistics (legacy output name)
    output$network_stats <- renderText({
      req(analysis_results())
      
      results <- analysis_results()
      module_colors <- labels2colors(results$net$colors)
      
      paste(
        "=== Network Analysis Summary ===",
        "",
        paste("Analysis completed:", Sys.time()),
        paste("Power used:", results$power_used),
        paste("Network type:", results$parameters$TOMType),
        paste("Correlation method:", results$parameters$correlationType),
        "",
        "=== Data Dimensions ===",
        paste("Genes analyzed:", ncol(results$expr)),
        paste("Samples analyzed:", nrow(results$expr)),
        paste("Total modules:", length(unique(module_colors))),
        paste("Largest module:", max(table(module_colors)), "genes"),
        paste("Smallest module:", min(table(module_colors)), "genes"),
        "",
        "=== Module Distribution ===",
        paste(names(table(module_colors)), ":", table(module_colors), "genes", collapse = "\n"),
        sep = "\n"
      )
    })
    
    # Power analysis plot
    output$power_plot <- renderPlot({
      req(power_analysis())
      
      sft <- power_analysis()
      
      par(mfrow = c(1, 2))
      cex1 = 0.9
      
      # Scale-free topology fit
      plot(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
           xlab = "Soft Threshold (power)", 
           ylab = "Scale Free Topology Model Fit, signed R^2",
           type = "n", main = "Scale independence")
      text(sft$fitIndices[,1], -sign(sft$fitIndices[,3])*sft$fitIndices[,2],
           labels = sft$fitIndices[,1], cex = cex1, col = "red")
      abline(h = 0.8, col = "blue", lty = 2)
      
      # Mean connectivity
      plot(sft$fitIndices[,1], sft$fitIndices[,5],
           xlab = "Soft Threshold (power)", 
           ylab = "Mean Connectivity", 
           type = "n", main = "Mean connectivity")
      text(sft$fitIndices[,1], sft$fitIndices[,5], 
           labels = sft$fitIndices[,1], cex = cex1, col = "red")
    })
    
    # Download handler
    output$download_results <- downloadHandler(
      filename = function() {
        paste("wgcna_results_", Sys.Date(), ".RData", sep = "")
      },
      content = function(file) {
        wgcna_results <- analysis_results()
        save(wgcna_results, file = file)
      }
    )
    
    return(analysis_results)
  })
}
