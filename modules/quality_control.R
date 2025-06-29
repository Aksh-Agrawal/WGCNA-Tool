# Quality Control Module
# ======================

qualityControlUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    h4("🔍 Quality Control Dashboard"),
    p("Comprehensive quality assessment for your WGCNA analysis"),
    
    conditionalPanel(
      condition = "output.data_available",
      ns = ns,
      
      fluidRow(
        valueBoxOutput(ns("data_quality_score"), width = 3),
        valueBoxOutput(ns("outlier_samples"), width = 3),
        valueBoxOutput(ns("variance_genes"), width = 3),
        valueBoxOutput(ns("missing_data_pct"), width = 3)
      ),
      
      br(),
      
      tabsetPanel(
        tabPanel("Data Quality",
          br(),
          plotOutput(ns("quality_plots"))
        ),
        
        tabPanel("Sample Assessment",
          br(),
          plotOutput(ns("sample_plots"))
        ),
        
        tabPanel("Gene Filtering",
          br(),
          plotOutput(ns("gene_plots"))
        )
      )
    ),
    
    # Placeholder when no data
    div(
      style = "text-align: center; padding: 50px; color: #999;",
      icon("chart-line", style = "font-size: 48px;"),
      h4("Quality control will be available after data upload", 
         style = "margin-top: 20px; color: #718096;")
    )
  )
}

qualityControlServer <- function(id, data, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    
    # Reactive to check if data is available
    output$data_available <- reactive({
      !is.null(data()) && !is.null(data()$expr)
    })
    outputOptions(output, "data_available", suspendWhenHidden = FALSE)
    
    # Quality metrics value boxes
    output$data_quality_score <- renderValueBox({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        
        # Calculate quality score based on missing data and variance
        missing_pct <- sum(is.na(expr_data)) / (nrow(expr_data) * ncol(expr_data)) * 100
        quality_score <- round(max(0, 100 - missing_pct), 1)
        
        color <- if (quality_score >= 80) "green" else if (quality_score >= 60) "yellow" else "red"
        
        valueBox(
          value = paste0(quality_score, "%"),
          subtitle = "Data Quality Score",
          icon = icon("star"),
          color = color
        )
      } else {
        valueBox(
          value = "N/A",
          subtitle = "Data Quality Score",
          icon = icon("star"),
          color = "blue"
        )
      }
    })
    
    output$outlier_samples <- renderValueBox({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        
        # Simple outlier detection based on total expression
        sample_totals <- rowSums(expr_data, na.rm = TRUE)
        q1 <- quantile(sample_totals, 0.25, na.rm = TRUE)
        q3 <- quantile(sample_totals, 0.75, na.rm = TRUE)
        iqr <- q3 - q1
        outliers <- sum(sample_totals < (q1 - 1.5 * iqr) | sample_totals > (q3 + 1.5 * iqr))
        
        color <- if (outliers == 0) "green" else if (outliers <= 2) "yellow" else "red"
        
        valueBox(
          value = outliers,
          subtitle = "Potential Outliers",
          icon = icon("exclamation-triangle"),
          color = color
        )
      } else {
        valueBox(
          value = "N/A",
          subtitle = "Potential Outliers",
          icon = icon("exclamation-triangle"),
          color = "blue"
        )
      }
    })
    
    output$variance_genes <- renderValueBox({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        
        # Calculate gene variances
        gene_vars <- apply(expr_data, 2, var, na.rm = TRUE)
        high_var_genes <- sum(gene_vars > median(gene_vars, na.rm = TRUE), na.rm = TRUE)
        
        valueBox(
          value = high_var_genes,
          subtitle = "High Variance Genes",
          icon = icon("dna"),
          color = "green"
        )
      } else {
        valueBox(
          value = "N/A",
          subtitle = "High Variance Genes",
          icon = icon("dna"),
          color = "blue"
        )
      }
    })
    
    output$missing_data_pct <- renderValueBox({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        missing_pct <- round(sum(is.na(expr_data)) / (nrow(expr_data) * ncol(expr_data)) * 100, 2)
        
        color <- if (missing_pct < 5) "green" else if (missing_pct < 15) "yellow" else "red"
        
        valueBox(
          value = paste0(missing_pct, "%"),
          subtitle = "Missing Data",
          icon = icon("question-circle"),
          color = color
        )
      } else {
        valueBox(
          value = "N/A",
          subtitle = "Missing Data",
          icon = icon("question-circle"),
          color = "blue"
        )
      }
    })
    
    # Quality plots
    output$quality_plots <- renderPlot({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        
        par(mfrow = c(2, 2))
        
        # 1. Sample correlation heatmap
        if (nrow(expr_data) > 1) {
          sample_cor <- cor(t(expr_data), use = "pairwise.complete.obs")
          heatmap(sample_cor, main = "Sample Correlation Heatmap")
        }
        
        # 2. Gene expression distribution
        gene_means <- colMeans(expr_data, na.rm = TRUE)
        hist(gene_means, main = "Gene Expression Distribution", 
             xlab = "Mean Expression", breaks = 30, col = "lightblue")
        
        # 3. Missing data pattern
        missing_by_sample <- rowSums(is.na(expr_data))
        barplot(missing_by_sample, main = "Missing Values by Sample",
                xlab = "Sample", ylab = "Missing Count", col = "salmon")
        
        # 4. Variance vs Mean plot
        gene_vars <- apply(expr_data, 2, var, na.rm = TRUE)
        plot(gene_means, gene_vars, main = "Mean-Variance Relationship",
             xlab = "Mean Expression", ylab = "Variance", pch = 16, col = "darkblue")
      } else {
        plot(1, 1, type = "n", xlab = "", ylab = "", main = "No data available for quality assessment")
      }
    })
    
    # Sample assessment plots
    output$sample_plots <- renderPlot({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        
        par(mfrow = c(2, 2))
        
        # 1. Sample total expression
        sample_totals <- rowSums(expr_data, na.rm = TRUE)
        barplot(sample_totals, main = "Total Expression by Sample",
                xlab = "Sample", ylab = "Total Expression", col = "lightgreen")
        
        # 2. Sample-wise missing data
        missing_by_sample <- rowSums(is.na(expr_data))
        barplot(missing_by_sample, main = "Missing Data by Sample",
                xlab = "Sample", ylab = "Missing Count", col = "orange")
        
        # 3. Sample clustering dendrogram
        if (nrow(expr_data) > 2) {
          sample_dist <- dist(expr_data)
          sample_clust <- hclust(sample_dist)
          plot(sample_clust, main = "Sample Clustering", xlab = "Sample")
        }
        
        # 4. PCA of samples
        if (nrow(expr_data) > 2 && ncol(expr_data) > 2) {
          expr_clean <- expr_data[, colSums(is.na(expr_data)) < nrow(expr_data) * 0.5]
          if (ncol(expr_clean) > 1) {
            pca_result <- prcomp(expr_clean, center = TRUE, scale. = TRUE)
            plot(pca_result$x[,1], pca_result$x[,2], 
                 main = "Sample PCA", xlab = "PC1", ylab = "PC2", pch = 16)
          }
        }
      } else {
        plot(1, 1, type = "n", xlab = "", ylab = "", main = "No data available for sample assessment")
      }
    })
    
    # Gene filtering plots
    output$gene_plots <- renderPlot({
      if (!is.null(data()) && !is.null(data()$expr)) {
        expr_data <- data()$expr
        
        par(mfrow = c(2, 2))
        
        # 1. Gene variance distribution
        gene_vars <- apply(expr_data, 2, var, na.rm = TRUE)
        hist(gene_vars, main = "Gene Variance Distribution", 
             xlab = "Variance", breaks = 30, col = "lightcoral")
        
        # 2. Gene mean expression
        gene_means <- colMeans(expr_data, na.rm = TRUE)
        hist(gene_means, main = "Gene Mean Expression", 
             xlab = "Mean Expression", breaks = 30, col = "lightblue")
        
        # 3. Missing data by gene
        missing_by_gene <- colSums(is.na(expr_data))
        hist(missing_by_gene, main = "Missing Data by Gene",
             xlab = "Missing Count", breaks = 30, col = "lightyellow")
        
        # 4. CV vs Mean plot
        gene_cv <- sqrt(gene_vars) / gene_means
        plot(gene_means, gene_cv, main = "Coefficient of Variation vs Mean",
             xlab = "Mean Expression", ylab = "CV", pch = 16, col = "purple")
      } else {
        plot(1, 1, type = "n", xlab = "", ylab = "", main = "No data available for gene assessment")
      }
    })
  })
}
