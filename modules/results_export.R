# Results Export Module
# ====================

resultsExportUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    h4("📥 Results Export & Reporting"),
    p("Download your WGCNA analysis results in various formats"),
    
    conditionalPanel(
      condition = "output.results_available",
      ns = ns,
      
      wellPanel(
        h5("Available Downloads"),
        
        fluidRow(
          column(4,
            h6("Data Files"),
            downloadButton(ns("download_modules"), "Module Assignments", 
                          class = "btn-primary btn-block"),
            br(), br(),
            downloadButton(ns("download_eigengenes"), "Module Eigengenes", 
                          class = "btn-primary btn-block")
          ),
          
          column(4,
            h6("Analysis Results"), 
            downloadButton(ns("download_correlations"), "Module-Trait Correlations", 
                          class = "btn-info btn-block"),
            br(), br(),
            downloadButton(ns("download_network"), "Network Data", 
                          class = "btn-info btn-block")
          ),
          
          column(4,
            h6("Reports"),
            downloadButton(ns("download_report"), "Full Analysis Report", 
                          class = "btn-success btn-block"),
            br(), br(),
            downloadButton(ns("download_summary"), "Executive Summary", 
                          class = "btn-success btn-block")
          )
        )
      )
    ),
    
    # Placeholder when no results
    div(
      style = "text-align: center; padding: 50px; color: #999;",
      icon("download", style = "font-size: 48px;"),
      h4("Export options will be available after running WGCNA analysis", 
         style = "margin-top: 20px; color: #718096;")
    )
  )
}

resultsExportServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive to check if results are available
    output$results_available <- reactive({
      !is.null(wgcna_results()) && !is.null(wgcna_results()$net)
    })
    outputOptions(output, "results_available", suspendWhenHidden = FALSE)
    
    # Module assignments download
    output$download_modules <- downloadHandler(
      filename = function() {
        paste("module_assignments_", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(wgcna_results())
        results <- wgcna_results()
        
        if (!is.null(results$net) && !is.null(results$net$colors)) {
          module_colors <- WGCNA::labels2colors(results$net$colors)
          gene_names <- names(results$net$colors)
          
          df <- data.frame(
            Gene = gene_names,
            Module_Number = results$net$colors,
            Module_Color = module_colors,
            stringsAsFactors = FALSE
          )
          
          write.csv(df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(Error = "No module data available"), file, row.names = FALSE)
        }
      }
    )
    
    # Module eigengenes download
    output$download_eigengenes <- downloadHandler(
      filename = function() {
        paste("module_eigengenes_", Sys.Date(), ".csv", sep = "")
      }, 
      content = function(file) {
        req(wgcna_results())
        results <- wgcna_results()
        
        if (!is.null(results$MEs)) {
          write.csv(results$MEs, file, row.names = TRUE)
        } else {
          write.csv(data.frame(Error = "No module eigengenes available"), file, row.names = FALSE)
        }
      }
    )
    
    # Module-trait correlations download
    output$download_correlations <- downloadHandler(
      filename = function() {
        paste("module_trait_correlations_", Sys.Date(), ".csv", sep = "")
      },
      content = function(file) {
        req(wgcna_results())
        results <- wgcna_results()
        
        if (!is.null(results$MEs) && !is.null(results$traits) && ncol(results$traits) > 0) {
          # Calculate correlations
          moduleTraitCor <- cor(results$MEs, results$traits, use = "pairwise.complete.obs")
          moduleTraitPvalue <- WGCNA::corPvalueStudent(moduleTraitCor, nrow(results$MEs))
          
          # Combine correlation and p-values
          cor_df <- data.frame(
            Module = rep(rownames(moduleTraitCor), ncol(moduleTraitCor)),
            Trait = rep(colnames(moduleTraitCor), each = nrow(moduleTraitCor)),
            Correlation = as.vector(moduleTraitCor),
            P_Value = as.vector(moduleTraitPvalue),
            stringsAsFactors = FALSE
          )
          
          write.csv(cor_df, file, row.names = FALSE)
        } else {
          write.csv(data.frame(Error = "No trait data available for correlations"), file, row.names = FALSE)
        }
      }
    )
    
    # Network data download
    output$download_network <- downloadHandler(
      filename = function() {
        paste("network_data_", Sys.Date(), ".RData", sep = "")
      },
      content = function(file) {
        req(wgcna_results())
        results <- wgcna_results()
        
        if (!is.null(results$net)) {
          # Save the complete network object
          network_data <- list(
            colors = results$net$colors,
            dendrograms = results$net$dendrograms,
            parameters = results$parameters,
            power_used = results$power_used
          )
          save(network_data, file = file)
        } else {
          placeholder_data <- list(message = "No network data available")
          save(placeholder_data, file = file)
        }
      }
    )
    
    # Analysis report download
    output$download_report <- downloadHandler(
      filename = function() {
        paste("wgcna_report_", Sys.Date(), ".html", sep = "")
      },
      content = function(file) {
        req(wgcna_results())
        results <- wgcna_results()
        
        if (!is.null(results$net)) {
          module_colors <- WGCNA::labels2colors(results$net$colors)
          module_sizes <- table(module_colors)
          
          # Generate HTML report
          html_content <- paste(
            "<html><head><title>WGCNA Analysis Report</title></head><body>",
            "<h1>WGCNA Analysis Report</h1>",
            paste("<p>Generated on:", Sys.time(), "</p>"),
            "<h2>Analysis Summary</h2>",
            paste("<p>Total genes analyzed:", length(results$net$colors), "</p>"),
            paste("<p>Number of modules detected:", length(unique(module_colors)), "</p>"),
            paste("<p>Power used:", results$power_used, "</p>"),
            "<h2>Module Summary</h2>",
            "<table border='1'>",
            "<tr><th>Module</th><th>Gene Count</th></tr>",
            paste(mapply(function(mod, count) paste("<tr><td>", mod, "</td><td>", count, "</td></tr>"),
                        names(module_sizes), module_sizes), collapse = ""),
            "</table>",
            "<h2>Parameters Used</h2>",
            paste("<p>Minimum module size:", results$parameters$minModuleSize, "</p>"),
            paste("<p>Merge cut height:", results$parameters$mergeCutHeight, "</p>"),
            paste("<p>Network type:", results$parameters$networkType, "</p>"),
            "</body></html>",
            sep = "\n"
          )
          
          writeLines(html_content, file)
        } else {
          writeLines("<html><body><h1>WGCNA Report</h1><p>No analysis results available</p></body></html>", file)
        }
      }
    )
    
    # Executive summary download
    output$download_summary <- downloadHandler(
      filename = function() {
        paste("executive_summary_", Sys.Date(), ".txt", sep = "")
      },
      content = function(file) {
        req(wgcna_results())
        results <- wgcna_results()
        
        if (!is.null(results$net)) {
          module_colors <- WGCNA::labels2colors(results$net$colors)
          module_sizes <- table(module_colors)
          
          summary_text <- paste(
            "WGCNA ANALYSIS EXECUTIVE SUMMARY",
            "================================",
            "",
            paste("Analysis Date:", Sys.Date()),
            "",
            "DATASET OVERVIEW:",
            paste("- Total genes analyzed:", length(results$net$colors)),
            paste("- Number of samples:", nrow(results$expr)),
            "",
            "NETWORK PARAMETERS:",
            paste("- Soft threshold power:", results$power_used),
            paste("- Minimum module size:", results$parameters$minModuleSize),
            paste("- Network type:", results$parameters$networkType),
            "",
            "MODULE DETECTION RESULTS:",
            paste("- Total modules detected:", length(unique(module_colors))),
            paste("- Largest module:", names(which.max(module_sizes)), "(", max(module_sizes), "genes)"),
            paste("- Smallest module:", names(which.min(module_sizes)), "(", min(module_sizes), "genes)"),
            paste("- Average module size:", round(mean(module_sizes), 1), "genes"),
            "",
            "MODULE BREAKDOWN:",
            paste(names(module_sizes), ":", module_sizes, "genes", collapse = "\n"),
            "",
            "RECOMMENDATIONS:",
            "- Review module-trait correlations for biological insights",
            "- Consider functional enrichment analysis for significant modules", 
            "- Validate key findings with independent datasets",
            "",
            "Generated by WGCNA Shiny Tool",
            sep = "\n"
          )
          
          writeLines(summary_text, file)
        } else {
          writeLines("No WGCNA analysis results available for summary.", file)
        }
      }
    )
  })
}
