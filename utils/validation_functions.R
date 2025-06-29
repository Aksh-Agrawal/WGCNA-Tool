# Validation Functions for WGCNA Tool
# ====================================

# Check if required packages are available
check_required_packages <- function() {
  required <- c("WGCNA", "clusterProfiler", "enrichplot", "ggplot2", "plotly")
  missing <- setdiff(required, rownames(installed.packages()))
  
  if (length(missing) > 0) {
    return(list(
      valid = FALSE, 
      message = paste("Missing packages:", paste(missing, collapse = ", "))
    ))
  }
  
  return(list(valid = TRUE, message = "All required packages available"))
}

# Validate network parameters
validate_wgcna_parameters <- function(power, min_module_size, merge_cut_height) {
  errors <- c()
  
  if (power < 1 || power > 30) {
    errors <- c(errors, "Power must be between 1 and 30")
  }
  
  if (min_module_size < 5) {
    errors <- c(errors, "Minimum module size should be at least 5")
  }
  
  if (merge_cut_height < 0.1 || merge_cut_height > 0.9) {
    errors <- c(errors, "Merge cut height must be between 0.1 and 0.9")
  }
  
  if (length(errors) > 0) {
    return(list(valid = FALSE, message = paste(errors, collapse = "; ")))
  }
  
  return(list(valid = TRUE, message = "Parameters validated"))
}

# Check data compatibility between expression and traits
check_data_compatibility <- function(expr_data, trait_data) {
  expr_samples <- colnames(expr_data)
  trait_samples <- rownames(trait_data)
  
  common_samples <- intersect(expr_samples, trait_samples)
  
  if (length(common_samples) < 3) {
    return(list(
      valid = FALSE, 
      message = "Insufficient sample overlap between expression and trait data"
    ))
  }
  
  overlap_percentage <- length(common_samples) / max(length(expr_samples), length(trait_samples)) * 100
  
  return(list(
    valid = TRUE, 
    message = paste0("Sample overlap: ", length(common_samples), " samples (", 
                    round(overlap_percentage, 1), "%)")
  ))
}

# Validate file format and content
validate_file_format <- function(file_path, expected_type = "csv") {
  if (!file.exists(file_path)) {
    return(list(valid = FALSE, message = "File does not exist"))
  }
  
  file_ext <- tools::file_ext(file_path)
  if (tolower(file_ext) != expected_type) {
    return(list(valid = FALSE, message = paste("Expected", expected_type, "file, got", file_ext)))
  }
  
  file_size <- file.info(file_path)$size
  if (file_size == 0) {
    return(list(valid = FALSE, message = "File is empty"))
  }
  
  if (file_size > 100 * 1024^2) {  # 100MB limit
    return(list(valid = FALSE, message = "File too large (>100MB)"))
  }
  
  return(list(valid = TRUE, message = "File format validated"))
}

# Check for potential issues in expression data
check_expression_quality <- function(expr_data) {
  issues <- c()
  
  # Check for zero variance genes
  zero_var_genes <- which(apply(expr_data, 1, var, na.rm = TRUE) == 0)
  if (length(zero_var_genes) > 0) {
    issues <- c(issues, paste(length(zero_var_genes), "genes with zero variance"))
  }
  
  # Check for extremely low expression genes
  low_expr_genes <- which(apply(expr_data, 1, max, na.rm = TRUE) < 0.1)
  if (length(low_expr_genes) > nrow(expr_data) * 0.5) {
    issues <- c(issues, "Many genes with very low expression")
  }
  
  # Check for outlier samples
  sample_means <- colMeans(expr_data, na.rm = TRUE)
  outlier_samples <- which(abs(scale(sample_means)) > 3)
  if (length(outlier_samples) > 0) {
    issues <- c(issues, paste(length(outlier_samples), "potential outlier samples"))
  }
  
  if (length(issues) > 0) {
    return(list(
      quality = "warning", 
      message = paste("Potential issues:", paste(issues, collapse = "; "))
    ))
  }
  
  return(list(quality = "good", message = "Expression data quality looks good"))
}

# Validate enrichment analysis parameters
validate_enrichment_parameters <- function(organism, ontology, pvalue_cutoff, qvalue_cutoff) {
  errors <- c()
  
  valid_organisms <- c("org.Hs.eg.db", "org.Mm.eg.db", "org.Rn.eg.db", "org.Dm.eg.db", "org.Sc.sgd.db")
  if (!organism %in% valid_organisms) {
    errors <- c(errors, "Invalid organism database")
  }
  
  valid_ontologies <- c("BP", "MF", "CC")
  if (!ontology %in% valid_ontologies) {
    errors <- c(errors, "Invalid ontology type")
  }
  
  if (pvalue_cutoff <= 0 || pvalue_cutoff > 1) {
    errors <- c(errors, "P-value cutoff must be between 0 and 1")
  }
  
  if (qvalue_cutoff <= 0 || qvalue_cutoff > 1) {
    errors <- c(errors, "Q-value cutoff must be between 0 and 1")
  }
  
  if (length(errors) > 0) {
    return(list(valid = FALSE, message = paste(errors, collapse = "; ")))
  }
  
  return(list(valid = TRUE, message = "Enrichment parameters validated"))
}
