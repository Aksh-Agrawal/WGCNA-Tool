# Enhanced Plotting Functions for WGCNA Tool
# ==========================================

# Enhanced dendrogram plotting
plot_enhanced_dendrogram <- function(net, colors = NULL, main = "Module Dendrogram", 
                                   hang = 0.03, cex_labels = 0.6) {
  if (is.null(colors)) {
    colors <- labels2colors(net$colors)
  }
  
  # Create the plot
  plotDendroAndColors(
    net$dendrograms[[1]], 
    colors,
    "Module colors",
    dendroLabels = FALSE, 
    hang = hang,
    addGuide = TRUE, 
    guideHang = 0.05,
    main = main,
    cex.colorLabels = cex_labels
  )
}

# Enhanced module-trait correlation heatmap
plot_module_trait_heatmap <- function(MEs, traits, method = "pearson", 
                                    title = "Module-Trait Relationships") {
  # Calculate correlations
  moduleTraitCor <- cor(MEs, traits, use = "pairwise.complete.obs", method = method)
  moduleTraitPvalue <- corPvalueStudent(moduleTraitCor, nrow(MEs))
  
  # Create text matrix for significance
  textMatrix <- paste(signif(moduleTraitCor, 2), "\n(",
                     signif(moduleTraitPvalue, 1), ")", sep = "")
  dim(textMatrix) <- dim(moduleTraitCor)
  
  # Enhanced heatmap
  par(mar = c(6, 8.5, 3, 3))
  labeledHeatmap(
    Matrix = moduleTraitCor,
    xLabels = names(traits),
    yLabels = names(MEs),
    ySymbols = names(MEs),
    colorLabels = FALSE,
    colors = blueWhiteRed(50),
    textMatrix = textMatrix,
    setStdMargins = FALSE,
    cex.text = 0.8,
    zlim = c(-1, 1),
    main = paste(title, "\n(correlation/p-value)")
  )
}

# Scale-free topology plot
plot_scale_free_topology <- function(sft_data, power_used = NULL) {
  par(mfrow = c(1, 2))
  cex1 = 0.9
  
  # Scale-free topology fit index
  plot(sft_data$fitIndices[,1], -sign(sft_data$fitIndices[,3])*sft_data$fitIndices[,2],
       xlab = "Soft Threshold (power)", 
       ylab = "Scale Free Topology Model Fit, signed R^2",
       type = "n", main = paste("Scale independence"))
  text(sft_data$fitIndices[,1], -sign(sft_data$fitIndices[,3])*sft_data$fitIndices[,2],
       labels = sft_data$fitIndices[,1], cex = cex1, col = "red")
  
  # Add horizontal line at R^2 = 0.8
  abline(h = 0.8, col = "blue", lty = 2)
  
  # Highlight chosen power
  if (!is.null(power_used)) {
    idx <- which(sft_data$fitIndices[,1] == power_used)
    if (length(idx) > 0) {
      points(power_used, -sign(sft_data$fitIndices[idx,3])*sft_data$fitIndices[idx,2],
             col = "green", pch = 19, cex = 1.5)
    }
  }
  
  # Mean connectivity plot
  plot(sft_data$fitIndices[,1], sft_data$fitIndices[,5],
       xlab = "Soft Threshold (power)", 
       ylab = "Mean Connectivity", 
       type = "n", main = paste("Mean connectivity"))
  text(sft_data$fitIndices[,1], sft_data$fitIndices[,5], 
       labels = sft_data$fitIndices[,1], cex = cex1, col = "red")
  
  if (!is.null(power_used)) {
    idx <- which(sft_data$fitIndices[,1] == power_used)
    if (length(idx) > 0) {
      points(power_used, sft_data$fitIndices[idx,5],
             col = "green", pch = 19, cex = 1.5)
    }
  }
}

# Module size distribution plot
plot_module_sizes <- function(net_colors, title = "Module Size Distribution") {
  module_colors <- labels2colors(net_colors)
  module_sizes <- table(module_colors)
  
  # Create a more informative bar plot
  par(mar = c(8, 4, 4, 2))
  bp <- barplot(sort(module_sizes, decreasing = TRUE),
                las = 2, 
                col = names(sort(module_sizes, decreasing = TRUE)),
                main = title,
                ylab = "Number of Genes",
                xlab = "")
  
  # Add value labels on bars
  text(bp, sort(module_sizes, decreasing = TRUE) + max(module_sizes) * 0.02,
       labels = sort(module_sizes, decreasing = TRUE), 
       cex = 0.8, pos = 3)
}

# Network connectivity plot
plot_connectivity_distribution <- function(connectivity_data, module_colors) {
  # Create data frame for plotting
  plot_data <- data.frame(
    Connectivity = connectivity_data,
    Module = labels2colors(module_colors)
  )
  
  # Box plot by module
  ggplot(plot_data, aes(x = Module, y = Connectivity, fill = Module)) +
    geom_boxplot(alpha = 0.7) +
    scale_fill_identity() +
    theme_wgcna() +
    labs(
      title = "Connectivity Distribution by Module",
      x = "Module",
      y = "Intramodular Connectivity"
    ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# Gene significance scatter plot
plot_gene_significance <- function(gene_significance, module_membership, 
                                 module_color, trait_name) {
  # Filter for specific module
  module_genes <- which(module_color == "blue")  # Example: blue module
  
  if (length(module_genes) > 10) {
    plot_data <- data.frame(
      MM = module_membership[module_genes],
      GS = gene_significance[module_genes]
    )
    
    # Calculate correlation
    cor_val <- cor(plot_data$MM, plot_data$GS, use = "complete.obs")
    
    ggplot(plot_data, aes(x = MM, y = GS)) +
      geom_point(alpha = 0.6, color = "blue") +
      geom_smooth(method = "lm", se = TRUE, color = "red") +
      theme_wgcna() +
      labs(
        title = paste("Gene Significance vs Module Membership\n", 
                     "Module:", module_color, "| Trait:", trait_name),
        subtitle = paste("Correlation =", round(cor_val, 3)),
        x = "Module Membership",
        y = "Gene Significance"
      )
  }
}

# Interactive network plot using plotly
create_interactive_network <- function(TOM, module_colors, top_genes = 100) {
  # Select top connected genes
  connectivity <- rowSums(TOM)
  top_indices <- order(connectivity, decreasing = TRUE)[1:min(top_genes, length(connectivity))]
  
  # Subset TOM
  TOM_subset <- TOM[top_indices, top_indices]
  colors_subset <- module_colors[top_indices]
  
  # Create network layout (simplified)
  if (nrow(TOM_subset) > 2) {
    # Multi-dimensional scaling for layout
    dist_matrix <- as.dist(1 - TOM_subset)
    coords <- cmdscale(dist_matrix, k = 2)
    
    # Create edge list for strong connections
    threshold <- quantile(TOM_subset[upper.tri(TOM_subset)], 0.95)
    edges <- which(TOM_subset > threshold & upper.tri(TOM_subset), arr.ind = TRUE)
    
    # Prepare data for plotly
    edge_trace <- data.frame(
      x = c(rbind(coords[edges[,1], 1], coords[edges[,2], 1], NA)),
      y = c(rbind(coords[edges[,1], 2], coords[edges[,2], 2], NA))
    )
    
    node_trace <- data.frame(
      x = coords[, 1],
      y = coords[, 2],
      color = labels2colors(colors_subset),
      text = paste("Gene", 1:nrow(coords)),
      connectivity = connectivity[top_indices]
    )
    
    # Create plotly network
    p <- plot_ly() %>%
      add_trace(
        data = edge_trace,
        x = ~x, y = ~y,
        type = 'scatter', mode = 'lines',
        line = list(width = 0.5, color = 'rgba(125,125,125,0.3)'),
        hoverinfo = 'none',
        showlegend = FALSE
      ) %>%
      add_trace(
        data = node_trace,
        x = ~x, y = ~y,
        type = 'scatter', mode = 'markers',
        marker = list(
          size = ~sqrt(connectivity) * 3,
          color = ~color,
          line = list(width = 1, color = 'white')
        ),
        text = ~text,
        hovertemplate = '<b>%{text}</b><br>Connectivity: %{marker.size}<extra></extra>',
        showlegend = FALSE
      ) %>%
      layout(
        title = "Gene Co-expression Network",
        showlegend = FALSE,
        xaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE),
        yaxis = list(showgrid = FALSE, zeroline = FALSE, showticklabels = FALSE)
      )
    
    return(p)
  }
  
  return(NULL)
}

# Enhanced correlation plot
create_correlation_plot <- function(cor_matrix, title = "Correlation Matrix") {
  corrplot(cor_matrix,
           method = "color",
           type = "upper",
           order = "hclust",
           tl.cex = 0.8,
           tl.col = "black",
           tl.srt = 45,
           col = colorRampPalette(c("blue", "white", "red"))(200),
           title = title,
           mar = c(0,0,2,0))
}
