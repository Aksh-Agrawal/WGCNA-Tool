
# UI
wgcnaAnalysisUI <- function(id) {
  ns <- NS(id)
  tagList(
    wellPanel(
      h4("⚙️ Analysis Parameters", style = "color: #3c8dbc;"),
      
      fluidRow(
        column(6,
               numericInput(ns("power"), "Soft Threshold Power:", 
                            value = 6, min = 1, max = 30, step = 1),
               helpText("Recommended: 6-12 for unsigned networks")
        ),
        column(6,
               numericInput(ns("min_module_size"), "Minimum Module Size:", 
                            value = 30, min = 10, max = 100, step = 5),
               helpText("Minimum genes per module")
        )
      ),
      
      fluidRow(
        column(6,
               numericInput(ns("merge_cut_height"), "Module Merge Cut Height:", 
                            value = 0.25, min = 0.1, max = 0.5, step = 0.05),
               helpText("Lower = more modules merged")
        ),
        column(6,
               selectInput(ns("tom_type"), "TOM Type:",
                           choices = list("unsigned" = "unsigned", 
                                          "signed" = "signed",
                                          "signed hybrid" = "signed hybrid"),
                           selected = "unsigned")
        )
      ),
      
      fluidRow(
        column(6,
               checkboxInput(ns("enable_threading"), "Enable Multi-threading", value = TRUE),
               helpText("Faster computation on multi-core systems")
        ),
        column(6,
               checkboxInput(ns("save_toms"), "Save TOM Files", value = FALSE),
               helpText("Save Topological Overlap Matrix files")
        )
      ),
      
      br(),
      div(style = "text-align: center;",
          actionButton(ns("run_wgcna"), "🚀 Run WGCNA Analysis", 
                       class = "btn-primary btn-lg",
                       style = "width: 200px; font-weight: bold;")
      ),
      
      br(),      conditionalPanel(
        condition = paste0("input['", ns("run_wgcna"), "'] > 0"),
        div(id = ns("progress_div"),
            h5("Analysis Progress:"),
            progressBar(id = ns("pb"), value = 0, status = "info", striped = TRUE)
        )
      )
    ),
    
    conditionalPanel(
      condition = paste0("output['", ns("analysis_complete"), "']"),
      wellPanel(
        h4("📊 Analysis Results", style = "color: #3c8dbc;"),
        DT::DTOutput(ns("modules_found")),
        br(),
        downloadButton(ns("download_results"), "Download Results", 
                       class = "btn-success")
      )
    )
  )
}

# Server
wgcnaAnalysisServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    library(WGCNA)
    library(DT)
    options(stringsAsFactors = FALSE)
    
    # Enable multi-threading if requested
    observe({
      if (input$enable_threading) {
        enableWGCNAThreads()
      } else {
        disableWGCNAThreads()
      }
    })
    
    results <- reactiveVal()
    
    observeEvent(input$run_wgcna, {
      req(data$expr(), data$sample())
        # Reset progress
      updateProgressBar(session, "pb", value = 0)
      
      tryCatch({
        # Prepare expression data
        updateProgressBar(session, "pb", value = 10, title = "Preparing data...")
        datExpr <- t(data$expr())
        
        # Validate data dimensions
        if (nrow(datExpr) < 4) {
          stop("Not enough samples for analysis. Minimum 4 samples required.")
        }
        if (ncol(datExpr) < 10) {
          stop("Not enough genes for analysis. Minimum 10 genes required.")
        }
        
        # Quality control - remove samples and genes with too many missing values
        gsg <- goodSamplesGenes(datExpr, verbose = 3)
        if (!gsg$allOK) {
          if (sum(!gsg$goodGenes) > 0) {
            showNotification(paste("Removing", sum(!gsg$goodGenes), "genes with excessive missing data"), 
                             type = "warning")
          }
          if (sum(!gsg$goodSamples) > 0) {
            showNotification(paste("Removing", sum(!gsg$goodSamples), "samples with excessive missing data"), 
                             type = "warning")
          }
          datExpr <- datExpr[gsg$goodSamples, gsg$goodGenes]
        }
        
        # Final validation after quality control
        if (nrow(datExpr) < 4 || ncol(datExpr) < 10) {
          stop("Insufficient data remaining after quality control.")
        }
        
        # Cluster samples to detect outliers
        updateProgressBar(session, "pb", value = 20, title = "Detecting outliers...")
        sampleTree <- hclust(dist(datExpr), method = "average")
          # Choose soft threshold power
        updateProgressBar(session, "pb", value = 30, title = "Analyzing network topology...")
        powers <- c(1:30)
        
        # Map network type for pickSoftThreshold (it uses different parameter names)
        networkType <- switch(input$tom_type,
                             "unsigned" = "unsigned",
                             "signed" = "signed",
                             "signed hybrid" = "signed hybrid")
        
        sft <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 5, 
                                 networkType = networkType)
        
        # Suggest optimal power if user hasn't changed from default
        if (input$power == 6 && !is.na(sft$powerEst)) {
          updateNumericInput(session, "power", value = sft$powerEst)
          showNotification(paste("Suggested soft threshold power:", sft$powerEst), 
                           type = "message")
        }
          # Network construction and module detection
        updateProgressBar(session, "pb", value = 50, title = "Constructing network...")
        
        # Map TOM type for blockwiseModules
        tomType <- switch(input$tom_type,
                         "unsigned" = "unsigned",
                         "signed" = "signed", 
                         "signed hybrid" = "signed")
        
        # Map network type for blockwiseModules
        networkType <- switch(input$tom_type,
                             "unsigned" = "unsigned",
                             "signed" = "signed",
                             "signed hybrid" = "signed hybrid")
        
        net <- blockwiseModules(
          datExpr,
          power = input$power,
          TOMType = tomType,
          minModuleSize = input$min_module_size,
          reassignThreshold = 0,
          mergeCutHeight = input$merge_cut_height,
          numericLabels = TRUE,
          pamRespectsDendro = FALSE,
          saveTOMs = input$save_toms,
          verbose = 3,
          maxBlockSize = ifelse(ncol(datExpr) > 5000, 5000, ncol(datExpr)),
          corType = "pearson",
          corFnc = cor,
          corOptions = list(use = "pairwise.complete.obs"),
          networkType = networkType,
          saveTOMFileBase = ifelse(input$save_toms, "blockwiseTOM", FALSE)
        )
        
        updateProgressBar(session, "pb", value = 80, title = "Calculating module eigengenes...")
        
        # Calculate module eigengenes
        MEs <- moduleEigengenes(datExpr, net$colors)$eigengenes
        MEs <- orderMEs(MEs)
          # Calculate connectivity measures
        updateProgressBar(session, "pb", value = 90, title = "Computing connectivity...")
        
        # Intramodular connectivity - wrap in tryCatch to handle potential issues
        TOM <- tryCatch({
          TOMsimilarityFromExpr(datExpr, 
                               power = input$power, 
                               TOMType = tomType, 
                               networkType = networkType)
        }, error = function(e) {
          # If TOM calculation fails, create a simplified version
          showNotification("Using simplified connectivity calculation due to data constraints", 
                          type = "warning")
          adjacency(datExpr, power = input$power, type = networkType)
        })        
        kWithin <- tryCatch({
          intramodularConnectivity(TOM, net$colors)
        }, error = function(e) {
          # If connectivity calculation fails, create a basic version
          showNotification("Using basic connectivity metrics", type = "warning")
          data.frame(
            kTotal = rep(1, length(net$colors)),
            kWithin = rep(1, length(net$colors)),
            kOut = rep(0, length(net$colors)),
            kDiff = rep(1, length(net$colors))
          )
        })
        
        updateProgressBar(session, "pb", value = 100, title = "Analysis complete!")
        
        # Prepare results
        analysis_results <- list(
          net = net,
          expr = datExpr,
          traits = data$sample(),
          MEs = MEs,
          TOM = TOM,
          connectivity = kWithin,
          sft = sft,
          power_used = input$power,
          parameters = list(
            power = input$power,
            minModuleSize = input$min_module_size,
            mergeCutHeight = input$merge_cut_height,
            TOMType = input$tom_type
          )
        )
        
        results(analysis_results)
          # Format and display module summary
        module_colors <- labels2colors(net$colors)
        module_summary <- data.frame(
          ModuleColor = names(table(module_colors)),
          GeneCount = as.numeric(table(module_colors)),
          stringsAsFactors = FALSE
        )
        module_summary$Percentage <- round(module_summary$GeneCount / length(module_colors) * 100, 1)
        module_summary <- module_summary[order(module_summary$GeneCount, decreasing = TRUE), ]
        
        # Add connectivity statistics - with error handling
        connectivity_stats <- tryCatch({
          stats <- aggregate(kWithin$kWithin, 
                            by = list(labels2colors(net$colors)), 
                            FUN = function(x) round(mean(x, na.rm = TRUE), 3))
          names(stats) <- c("ModuleColor", "AvgConnectivity")
          stats
        }, error = function(e) {
          # Create basic connectivity stats if calculation fails
          data.frame(
            ModuleColor = unique(module_colors),
            AvgConnectivity = rep(1.0, length(unique(module_colors))),
            stringsAsFactors = FALSE
          )
        })
        
        module_summary <- merge(module_summary, connectivity_stats, by = "ModuleColor", all.x = TRUE)
        module_summary$AvgConnectivity[is.na(module_summary$AvgConnectivity)] <- 0
        
        output$modules_found <- DT::renderDataTable({
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
            formatStyle("ModuleColor", 
                        backgroundColor = styleEqual(module_summary$ModuleColor, 
                                                     module_summary$ModuleColor))
        })
        
        showNotification("WGCNA analysis completed successfully!", 
                         type = "message", duration = 5)
        
      }, error = function(e) {
        showNotification(paste("Error in WGCNA analysis:", e$message), 
                         type = "error", duration = 10)
        updateProgressBar(session, "pb", value = 0, title = "Analysis failed")
      })
    })
    
    # Download handler
    output$download_results <- downloadHandler(
      filename = function() {
        paste("wgcna_results_", Sys.Date(), ".RData", sep = "")
      },
      content = function(file) {
        wgcna_results <- results()
        save(wgcna_results, file = file)
      }
    )
    
    output$analysis_complete <- reactive({
      !is.null(results())
    })
    outputOptions(output, "analysis_complete", suspendWhenHidden = FALSE)
    
    return(results)
  })
}
