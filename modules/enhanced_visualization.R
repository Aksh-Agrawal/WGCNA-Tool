# Enhanced Visualization Module
# ============================

enhancedVisualizationUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    tabsetPanel(
      # Module Dendrogram Tab
      tabPanel(
        "🌳 Module Dendrogram",
        br(),
        fluidRow(
          column(3,
            wellPanel(
              h5("Dendrogram Options"),
              sliderInput(ns("dend_height"), "Plot Height (px):", 
                         min = 400, max = 1000, value = 600, step = 50),
              checkboxInput(ns("show_labels"), "Show Gene Labels", FALSE),
              numericInput(ns("hang_param"), "Hang Parameter:", 
                          value = 0.03, min = 0.01, max = 0.1, step = 0.01),
              downloadButton(ns("download_dend"), "Download Plot", 
                            class = "btn-primary btn-sm")
            )
          ),
          column(9,
            div(style = "border: 1px solid #ddd; border-radius: 4px; padding: 10px;",
                plotOutput(ns("dendrogram"), height = "auto")
            )
          )
        )
      ),
      
      # Module-Trait Heatmap Tab
      tabPanel(
        "🔥 Module-Trait Heatmap",
        br(),
        fluidRow(
          column(3,
            wellPanel(
              h5("Heatmap Options"),
              sliderInput(ns("heatmap_height"), "Plot Height (px):", 
                         min = 400, max = 800, value = 500, step = 50),
              selectInput(ns("correlation_method"), "Correlation Method:",
                         choices = list("Pearson" = "pearson", 
                                       "Spearman" = "spearman", 
                                       "Kendall" = "kendall"),
                         selected = "pearson"),
              numericInput(ns("text_size"), "Text Size:", 
                          value = 0.8, min = 0.5, max = 1.5, step = 0.1),
              downloadButton(ns("download_heatmap"), "Download Plot", 
                            class = "btn-primary btn-sm")
            )
          ),
          column(9,
            div(style = "border: 1px solid #ddd; border-radius: 4px; padding: 10px;",
                plotOutput(ns("module_trait"), height = "auto")
            )
          )
        )
      ),
      
      # Network Properties Tab
      tabPanel(
        "📊 Network Properties",
        br(),
        fluidRow(
          column(6,
            wellPanel(
              h5("Scale-Free Topology"),
              plotOutput(ns("scale_free_plot"), height = "300px")
            )
          ),
          column(6,
            wellPanel(
              h5("Module Size Distribution"),
              plotOutput(ns("module_size_plot"), height = "300px")
            )
          )
        ),
        fluidRow(
          column(12,
            wellPanel(
              h5("Network Statistics"),
              verbatimTextOutput(ns("network_stats"))
            )
          )
        )
      )
    )
  )
}

visualizationServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    
    # Module dendrogram
    output$dendrogram <- renderPlot({
      req(wgcna_results())
      
      results <- wgcna_results()
      if (!is.null(results$net) && !is.null(results$net$dendrograms)) {
        tryCatch({
          # Plot dendrogram with module colors
          module_colors <- WGCNA::labels2colors(results$net$colors)
          
          WGCNA::plotDendroAndColors(
            results$net$dendrograms[[1]], 
            module_colors,
            "Module colors",
            dendroLabels = input$show_labels, 
            hang = input$hang_param,
            addGuide = TRUE, 
            guideHang = 0.05,
            main = "Module Clustering Dendrogram"
          )
        }, error = function(e) {
          plot.new()
          text(0.5, 0.5, paste("Error creating dendrogram:", e$message), 
               cex = 1.2, col = "red")
        })
      }
    }, height = function() input$dend_height)
    
    # Module-trait correlation heatmap
    output$module_trait <- renderPlot({
      req(wgcna_results())
      
      results <- wgcna_results()
      if (!is.null(results$MEs) && !is.null(results$traits)) {
        tryCatch({
          # Calculate correlations
          moduleTraitCor <- cor(results$MEs, results$traits, 
                               use = "pairwise.complete.obs", 
                               method = input$correlation_method)
          moduleTraitPvalue <- WGCNA::corPvalueStudent(moduleTraitCor, nrow(results$MEs))
          
          # Create text matrix
          textMatrix <- paste(signif(moduleTraitCor, 2), "\n(",
                             signif(moduleTraitPvalue, 1), ")", sep = "")
          dim(textMatrix) <- dim(moduleTraitCor)
          
          # Plot heatmap
          par(mar = c(6, 8.5, 3, 3))
          WGCNA::labeledHeatmap(
            Matrix = moduleTraitCor,
            xLabels = names(results$traits),
            yLabels = names(results$MEs),
            ySymbols = names(results$MEs),
            colorLabels = FALSE,
            colors = WGCNA::blueWhiteRed(50),
            textMatrix = textMatrix,
            setStdMargins = FALSE,
            cex.text = input$text_size,
            zlim = c(-1, 1),
            main = "Module-Trait Relationships"
          )
        }, error = function(e) {
          plot.new()
          text(0.5, 0.5, paste("Error creating heatmap:", e$message), 
               cex = 1.2, col = "red")
        })
      }
    }, height = function() input$heatmap_height)
    
    # Scale-free topology plot
    output$scale_free_plot <- renderPlot({
      req(wgcna_results())
      
      # This would require storing the power analysis results
      # For now, show a placeholder
      plot.new()
      text(0.5, 0.5, "Scale-free topology plot\n(requires power analysis results)", 
           cex = 1.2, col = "gray")
    })
    
    # Module size distribution
    output$module_size_plot <- renderPlot({
      req(wgcna_results())
      
      results <- wgcna_results()
      if (!is.null(results$net)) {
        tryCatch({
          module_colors <- WGCNA::labels2colors(results$net$colors)
          module_sizes <- table(module_colors)
          
          # Create bar plot
          par(mar = c(8, 4, 4, 2))
          bp <- barplot(sort(module_sizes, decreasing = TRUE),
                       las = 2, 
                       col = names(sort(module_sizes, decreasing = TRUE)),
                       main = "Module Size Distribution",
                       ylab = "Number of Genes")
          
          # Add value labels
          text(bp, sort(module_sizes, decreasing = TRUE) + max(module_sizes) * 0.02,
               labels = sort(module_sizes, decreasing = TRUE), 
               cex = 0.8, pos = 3)
        }, error = function(e) {
          plot.new()
          text(0.5, 0.5, paste("Error creating plot:", e$message), 
               cex = 1.2, col = "red")
        })
      }
    })
    
    # Network statistics
    output$network_stats <- renderText({
      req(wgcna_results())
      
      results <- wgcna_results()
      if (!is.null(results$net)) {
        module_colors <- WGCNA::labels2colors(results$net$colors)
        module_sizes <- table(module_colors)
        
        paste(
          "=== Network Visualization Statistics ===",
          "",
          paste("Total genes:", length(results$net$colors)),
          paste("Total modules:", length(unique(module_colors))),
          paste("Largest module:", names(which.max(module_sizes)), 
                "(", max(module_sizes), "genes)"),
          paste("Smallest module:", names(which.min(module_sizes)), 
                "(", min(module_sizes), "genes)"),
          paste("Average module size:", round(mean(module_sizes), 1)),
          "",
          "Module breakdown:",
          paste(names(module_sizes), ":", module_sizes, "genes", collapse = "\n"),
          sep = "\n"
        )
      } else {
        "No WGCNA results available for visualization."
      }
    })
    
    # Download handlers
    output$download_dend <- downloadHandler(
      filename = function() {
        paste("dendrogram_", Sys.Date(), ".png", sep = "")
      },
      content = function(file) {
        png(file, width = 1200, height = input$dend_height, res = 150)
        
        req(wgcna_results())
        results <- wgcna_results()
        if (!is.null(results$net) && !is.null(results$net$dendrograms)) {
          module_colors <- WGCNA::labels2colors(results$net$colors)
          
          WGCNA::plotDendroAndColors(
            results$net$dendrograms[[1]], 
            module_colors,
            "Module colors",
            dendroLabels = input$show_labels, 
            hang = input$hang_param,
            addGuide = TRUE, 
            guideHang = 0.05,
            main = "Module Clustering Dendrogram"
          )
        }
        
        dev.off()
      }
    )
    
    output$download_heatmap <- downloadHandler(
      filename = function() {
        paste("module_trait_heatmap_", Sys.Date(), ".png", sep = "")
      },
      content = function(file) {
        png(file, width = 1000, height = input$heatmap_height, res = 150)
        
        req(wgcna_results())
        results <- wgcna_results()
        if (!is.null(results$MEs) && !is.null(results$traits)) {
          moduleTraitCor <- cor(results$MEs, results$traits, 
                               use = "pairwise.complete.obs", 
                               method = input$correlation_method)
          moduleTraitPvalue <- WGCNA::corPvalueStudent(moduleTraitCor, nrow(results$MEs))
          
          textMatrix <- paste(signif(moduleTraitCor, 2), "\n(",
                             signif(moduleTraitPvalue, 1), ")", sep = "")
          dim(textMatrix) <- dim(moduleTraitCor)
          
          par(mar = c(6, 8.5, 3, 3))
          WGCNA::labeledHeatmap(
            Matrix = moduleTraitCor,
            xLabels = names(results$traits),
            yLabels = names(results$MEs),
            ySymbols = names(results$MEs),
            colorLabels = FALSE,
            colors = WGCNA::blueWhiteRed(50),
            textMatrix = textMatrix,
            setStdMargins = FALSE,
            cex.text = input$text_size,
            zlim = c(-1, 1),
            main = "Module-Trait Relationships"
          )
        }
        
        dev.off()
      }
    )
  })
}
