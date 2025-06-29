# Helper Functions for WGCNA Tool
# =================================

# Data validation and processing functions
validate_expression_data <- function(data) {
  if (is.null(data) || nrow(data) == 0 || ncol(data) == 0) {
    return(list(valid = FALSE, message = "Empty data provided"))
  }
  
  # Check for minimum dimensions
  if (nrow(data) < 10) {
    return(list(valid = FALSE, message = "Minimum 10 genes required"))
  }
  
  if (ncol(data) < 4) {
    return(list(valid = FALSE, message = "Minimum 4 samples required"))
  }
  
  # Check for numeric data
  numeric_cols <- sapply(data, is.numeric)
  if (!all(numeric_cols)) {
    return(list(valid = FALSE, message = "All expression values must be numeric"))
  }
  
  # Check for excessive missing values
  missing_percent <- sum(is.na(data)) / (nrow(data) * ncol(data)) * 100
  if (missing_percent > 50) {
    return(list(valid = FALSE, message = paste("Too many missing values:", round(missing_percent, 1), "%")))
  }
  
  return(list(valid = TRUE, message = "Data validation passed"))
}

# Sample annotation validation
validate_sample_data <- function(sample_data, expression_data) {
  if (is.null(sample_data) || nrow(sample_data) == 0) {
    return(list(valid = FALSE, message = "Empty sample annotation provided"))
  }
  
  # Check sample overlap
  expr_samples <- colnames(expression_data)
  annot_samples <- rownames(sample_data)
  overlap <- intersect(expr_samples, annot_samples)
  
  if (length(overlap) < 4) {
    return(list(valid = FALSE, message = "Less than 4 samples overlap between expression and annotation data"))
  }
  
  overlap_percent <- length(overlap) / length(expr_samples) * 100
  if (overlap_percent < 80) {
    return(list(valid = FALSE, message = paste("Low sample overlap:", round(overlap_percent, 1), "%")))
  }
  
  return(list(valid = TRUE, message = paste("Sample validation passed.", length(overlap), "samples overlap")))
}

# Outlier detection function
detect_outliers <- function(datExpr, z_threshold = 3) {
  # Calculate sample connectivity
  adj <- adjacency(datExpr, power = 1, type = "unsigned")
  k <- apply(adj, 1, sum) - 1  # Subtract 1 to exclude self-connectivity
  
  # Z-score based outlier detection
  z_scores <- abs(scale(k))
  outliers <- which(z_scores > z_threshold)
  
  return(list(
    outliers = outliers,
    connectivity = k,
    z_scores = as.numeric(z_scores)
  ))
}

# Power estimation improvement
estimate_optimal_power <- function(datExpr, powers = 1:20, networkType = "unsigned") {
  sft <- pickSoftThreshold(datExpr, 
                          powerVector = powers, 
                          verbose = 0, 
                          networkType = networkType)
  
  # If no power is suggested, use heuristics
  if (is.na(sft$powerEst)) {
    # Find power where scale-free fit R^2 > 0.8
    fit_indices <- sft$fitIndices
    good_powers <- fit_indices[fit_indices$SFT.R.sq > 0.8, ]
    
    if (nrow(good_powers) > 0) {
      # Choose the lowest power that achieves good fit
      suggested_power <- min(good_powers$Power)
    } else {
      # Fallback to power where fit starts declining
      max_fit_idx <- which.max(fit_indices$SFT.R.sq)
      suggested_power <- fit_indices$Power[max_fit_idx]
    }
  } else {
    suggested_power <- sft$powerEst
  }
  
  return(list(
    sft = sft,
    suggested_power = suggested_power,
    fit_data = sft$fitIndices
  ))
}

# Module summary statistics
calculate_module_stats <- function(net, datExpr) {
  module_colors <- labels2colors(net$colors)
  modules <- unique(module_colors)
  
  stats_list <- lapply(modules, function(mod) {
    module_genes <- which(module_colors == mod)
    
    if (length(module_genes) > 1) {
      module_expr <- datExpr[, module_genes]
      
      # Calculate module eigengene
      ME <- moduleEigengenes(module_expr, rep(1, length(module_genes)))$eigengenes[,1]
      
      # Calculate intramodular connectivity
      adj_module <- adjacency(module_expr, type = "unsigned")
      connectivity <- apply(adj_module, 1, sum) - 1
      
      return(data.frame(
        Module = mod,
        Size = length(module_genes),
        MeanConnectivity = mean(connectivity),
        MaxConnectivity = max(connectivity),
        MEVariance = var(ME),
        stringsAsFactors = FALSE
      ))
    } else {
      return(data.frame(
        Module = mod,
        Size = length(module_genes),
        MeanConnectivity = 0,
        MaxConnectivity = 0,
        MEVariance = 0,
        stringsAsFactors = FALSE
      ))
    }
  })
  
  return(do.call(rbind, stats_list))
}

# Format file size for display
format_file_size <- function(size_bytes) {
  if (size_bytes < 1024) {
    return(paste(size_bytes, "B"))
  } else if (size_bytes < 1024^2) {
    return(paste(round(size_bytes/1024, 1), "KB"))
  } else if (size_bytes < 1024^3) {
    return(paste(round(size_bytes/1024^2, 1), "MB"))
  } else {
    return(paste(round(size_bytes/1024^3, 1), "GB"))
  }
}

# Progress bar updates with meaningful messages
update_progress <- function(session, id, value, title = NULL, detail = NULL) {
  if (!is.null(title)) {
    updateProgressBar(session, id, value = value, title = title)
  }
  if (!is.null(detail)) {
    showNotification(detail, type = "message", duration = 2)
  }
}

# Safe file reading with error handling
safe_read_csv <- function(file_path, row_names = TRUE, ...) {
  tryCatch({
    if (row_names) {
      data <- read.csv(file_path, row.names = 1, check.names = FALSE, ...)
    } else {
      data <- read.csv(file_path, check.names = FALSE, ...)
    }
    
    # Remove empty rows/columns
    data <- data[rowSums(is.na(data)) < ncol(data), ]
    data <- data[, colSums(is.na(data)) < nrow(data)]
    
    return(list(success = TRUE, data = data, message = "File loaded successfully"))
  }, error = function(e) {
    return(list(success = FALSE, data = NULL, message = paste("Error reading file:", e$message)))
  })
}

# Generate summary report
generate_analysis_summary <- function(results) {
  if (is.null(results)) return("No analysis results available")
  
  summary_text <- paste(
    "=== WGCNA Analysis Summary ===",
    "",
    paste("Analysis Date:", Sys.time()),
    paste("Soft Threshold Power:", results$power_used),
    paste("Total Genes Analyzed:", ncol(results$expr)),
    paste("Total Samples:", nrow(results$expr)),
    paste("Modules Detected:", length(unique(labels2colors(results$net$colors)))),
    "",
    "=== Module Statistics ===",
    sep = "\n"
  )
  
  # Add module breakdown
  module_colors <- labels2colors(results$net$colors)
  module_table <- table(module_colors)
  module_breakdown <- paste(names(module_table), ":", module_table, "genes", collapse = "\n")
  
  final_summary <- paste(summary_text, module_breakdown, sep = "\n")
  return(final_summary)
}
