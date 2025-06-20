
visualizationUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(12,
             tabsetPanel(
               tabPanel("🌳 Module Dendrogram",
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
               
               tabPanel("🔥 Module-Trait Heatmap",
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
                                   checkboxInput(ns("cluster_rows"), "Cluster Rows", FALSE),
                                   checkboxInput(ns("cluster_cols"), "Cluster Columns", FALSE),
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
               
               tabPanel("📊 Network Properties",
                        br(),
                        fluidRow(
                          column(6,
                                 wellPanel(
                                   h5("Scale-Free Topology Fit"),
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
               ),
               
               tabPanel("🎯 Module Preservation",
                        br(),
                        fluidRow(
                          column(4,
                                 wellPanel(
                                   h5("Preservation Options"),
                                   helpText("Module preservation analysis helps evaluate the stability of modules."),
                                   selectInput(ns("reference_module"), "Reference Module:",
                                               choices = NULL),
                                   actionButton(ns("run_preservation"), "Run Preservation Analysis",
                                                class = "btn-info")
                                 )
                          ),
                          column(8,
                                 conditionalPanel(
                                   condition = paste0("output['", ns("preservation_done"), "']"),
                                   plotOutput(ns("preservation_plot"), height = "400px")
                                 )
                          )
                        )
               )
             )
      )
    )
  )
}

visualizationServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    library(WGCNA)
    library(pheatmap)
    library(ggplot2)
    library(gridExtra)
    
    # Update module choices for preservation analysis
    observe({
      req(wgcna_results())
      net <- wgcna_results()$net
      module_colors <- unique(labels2colors(net$colors))
      module_colors <- module_colors[module_colors != "grey"]
      
      updateSelectInput(session, "reference_module", 
                        choices = setNames(module_colors, paste("Module", module_colors)))
    })
    
    # Enhanced Dendrogram
    output$dendrogram <- renderPlot({
      req(wgcna_results())
      
      net <- wgcna_results()$net
      dendro <- net$dendrograms[[1]]
      colors <- labels2colors(net$colors)
      
      # Create high-quality dendrogram
      par(cex = 1.2, mar = c(2, 2, 2, 2))
      plotDendroAndColors(
        dendro,
        colors,
        "Module colors",
        dendroLabels = input$show_labels,
        hang = input$hang_param,
        addGuide = TRUE,
        guideHang = 0.05,
        main = "Gene Clustering Dendrogram and Module Colors",
        cex.main = 1.5,
        cex.lab = 1.2,
        cex.colorLabels = 1.0
      )
      
    }, height = function() input$dend_height)
    
    # Enhanced Module-Trait Heatmap
    output$module_trait <- renderPlot({
      req(wgcna_results())
      
      MEs <- wgcna_results()$MEs
      traits <- wgcna_results()$traits
      
      # Ensure sample matching
      common_samples <- intersect(rownames(MEs), rownames(traits))
      if (length(common_samples) == 0) {
        plot.new()
        text(0.5, 0.5, "No matching samples between modules and traits", 
             cex = 1.5, col = "red")
        return()
      }
      
      MEs_matched <- MEs[common_samples, , drop = FALSE]
      traits_matched <- traits[common_samples, , drop = FALSE]
      
      # Calculate correlations
      cor_res <- cor(MEs_matched, traits_matched, 
                     method = input$correlation_method, 
                     use = "pairwise.complete.obs")
      
      # Calculate p-values
      p_values <- matrix(NA, nrow = nrow(cor_res), ncol = ncol(cor_res))
      for (i in 1:nrow(cor_res)) {
        for (j in 1:ncol(cor_res)) {
          test_result <- cor.test(MEs_matched[, i], traits_matched[, j], 
                                  method = input$correlation_method)
          p_values[i, j] <- test_result$p.value
        }
      }
      
      # Create annotation for significance
      sig_text <- matrix("", nrow = nrow(cor_res), ncol = ncol(cor_res))
      sig_text[p_values < 0.001] <- "***"
      sig_text[p_values >= 0.001 & p_values < 0.01] <- "**"
      sig_text[p_values >= 0.01 & p_values < 0.05] <- "*"
      
      # Enhanced heatmap
      pheatmap(
        cor_res,
        cluster_rows = input$cluster_rows,
        cluster_cols = input$cluster_cols,
        display_numbers = matrix(paste(round(cor_res, 2), sig_text, sep = "\n"), 
                                 nrow = nrow(cor_res)),
        number_color = "white",
        fontsize_number = 10 * input$text_size,
        fontsize = 12 * input$text_size,
        color = colorRampPalette(c("blue", "white", "red"))(50),
        breaks = seq(-1, 1, length.out = 51),
        main = "Module-Trait Correlations",
        angle_col = 45,
        cellwidth = 40,
        cellheight = 30
      )
      
    }, height = function() input$heatmap_height)
    
    # Scale-free topology plot
    output$scale_free_plot <- renderPlot({
      req(wgcna_results())
      
      if (!is.null(wgcna_results()$sft)) {
        sft <- wgcna_results()$sft
        
        par(mfrow = c(1, 2))
        # Scale-free topology fit index
        plot(sft$fitIndices[, 1], -sign(sft$fitIndices[, 3]) * sft$fitIndices[, 2],
             xlab = "Soft Threshold (power)", ylab = "Scale Free Topology Model Fit, signed R^2",
             type = "n", main = "Scale independence")
        text(sft$fitIndices[, 1], -sign(sft$fitIndices[, 3]) * sft$fitIndices[, 2],
             labels = sft$fitIndices[, 1], cex = 0.9, col = "red")
        abline(h = 0.90, col = "red", lty = 2)
        
        # Mean connectivity
        plot(sft$fitIndices[, 1], sft$fitIndices[, 5],
             xlab = "Soft Threshold (power)", ylab = "Mean Connectivity", type = "n",
             main = "Mean connectivity")
        text(sft$fitIndices[, 1], sft$fitIndices[, 5], 
             labels = sft$fitIndices[, 1], cex = 0.9, col = "red")
      }
    })
    
    # Module size distribution
    output$module_size_plot <- renderPlot({
      req(wgcna_results())
      
      net <- wgcna_results()$net
      module_sizes <- table(labels2colors(net$colors))
      
      barplot(sort(module_sizes, decreasing = TRUE),
              las = 2, col = names(sort(module_sizes, decreasing = TRUE)),
              main = "Module Size Distribution",
              ylab = "Number of Genes",
              cex.names = 0.8)
    })
    
    # Network statistics
    output$network_stats <- renderText({
      req(wgcna_results())
      
      net <- wgcna_results()$net
      params <- wgcna_results()$parameters
      
      total_genes <- length(net$colors)
      n_modules <- length(unique(net$colors)) - 1  # Exclude grey module
      grey_genes <- sum(net$colors == 0)
      
      paste(
        "Network Construction Parameters:",
        paste("- Soft threshold power:", params$power),
        paste("- TOM type:", params$TOMType),
        paste("- Minimum module size:", params$minModuleSize),
        paste("- Module merge cut height:", params$mergeCutHeight),
        "",
        "Network Statistics:",
        paste("- Total genes analyzed:", total_genes),
        paste("- Number of modules:", n_modules),
        paste("- Genes in modules:", total_genes - grey_genes),
        paste("- Unassigned genes (grey):", grey_genes),
        paste("- Proportion assigned:", round((total_genes - grey_genes) / total_genes * 100, 1), "%"),
        "",
        "Module Sizes:",
        paste(names(sort(table(labels2colors(net$colors)), decreasing = TRUE))[1:5],
              ":", sort(table(labels2colors(net$colors)), decreasing = TRUE)[1:5], 
              collapse = ", "),
        sep = "\n"
      )
    })
    
    # Download handlers
    output$download_dend <- downloadHandler(
      filename = function() paste("dendrogram_", Sys.Date(), ".png", sep = ""),
      content = function(file) {
        png(file, width = 1200, height = input$dend_height, res = 300)
        req(wgcna_results())
        net <- wgcna_results()$net
        dendro <- net$dendrograms[[1]]
        colors <- labels2colors(net$colors)
        
        par(cex = 1.2, mar = c(2, 2, 2, 2))
        plotDendroAndColors(dendro, colors, "Module colors",
                            dendroLabels = input$show_labels, hang = input$hang_param,
                            addGuide = TRUE, guideHang = 0.05)
        dev.off()
      }
    )
    
    output$download_heatmap <- downloadHandler(
      filename = function() paste("module_trait_heatmap_", Sys.Date(), ".png", sep = ""),
      content = function(file) {
        png(file, width = 1000, height = input$heatmap_height, res = 300)
        # Recreate heatmap code here
        dev.off()
      }
    )
  })
}
