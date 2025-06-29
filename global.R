# Global.R - Centralized configuration and setup
# ==============================================

# Load required libraries with error handling
required_packages <- c(
  "shiny", "shinydashboard", "shinyWidgets", "plotly", "DT",
  "ggplot2", "RColorBrewer", "viridis"
)

# Optional packages for enhanced functionality
optional_packages <- c(
  "WGCNA", "clusterProfiler", "enrichplot", "pheatmap",
  "corrplot", "gplots", "gridExtra", "shinycssloaders", 
  "shinyjs", "waiter", "fresh"
)

# Function to safely load packages without forced installation
safe_load_packages <- function(packages, required = TRUE) {
  loaded <- character(0)
  failed <- character(0)
  
  for (pkg in packages) {
    if (require(pkg, character.only = TRUE, quietly = TRUE)) {
      loaded <- c(loaded, pkg)
    } else {
      failed <- c(failed, pkg)
      if (required) {
        message(paste("Required package", pkg, "not available. Please install it manually."))
      } else {
        message(paste("Optional package", pkg, "not available. Some features may be limited."))
      }
    }
  }
  
  if (length(loaded) > 0) {
    message(paste("Loaded packages:", paste(loaded, collapse = ", ")))
  }
  if (length(failed) > 0 && any(packages %in% required_packages)) {
    message(paste("Failed to load packages:", paste(failed, collapse = ", ")))
  }
  
  return(list(loaded = loaded, failed = failed))
}

# Load required packages (only load if already installed)
req_result <- safe_load_packages(required_packages, required = TRUE)

# Load optional packages (only load if already installed)
opt_result <- safe_load_packages(optional_packages, required = FALSE)

# Global options
options(
  stringsAsFactors = FALSE,
  shiny.maxRequestSize = 100*1024^2,  # 100MB file upload limit
  warn = -1,  # Suppress warnings for cleaner output
  repos = c(CRAN = "https://cran.rstudio.com/")  # Set CRAN mirror
)

# WGCNA options (if available)
if (requireNamespace("WGCNA", quietly = TRUE)) {
  WGCNA::allowWGCNAThreads()
}

# Color palettes for consistent theming
app_colors <- list(
  primary = "#3c8dbc",
  secondary = "#367fa9", 
  success = "#00a65a",
  info = "#00c0ef",
  warning = "#f39c12",
  danger = "#dd4b39",
  light = "#f4f4f4",
  dark = "#222d32"
)

# Custom theme for ggplot (if available)
if (requireNamespace("ggplot2", quietly = TRUE)) {
  theme_wgcna <- function() {
    ggplot2::theme_minimal() +
      ggplot2::theme(
        plot.title = ggplot2::element_text(size = 14, face = "bold", hjust = 0.5),
        axis.title = ggplot2::element_text(size = 12),
        axis.text = ggplot2::element_text(size = 10),
        legend.title = ggplot2::element_text(size = 11, face = "bold"),
        legend.text = ggplot2::element_text(size = 10),
        panel.grid.minor = ggplot2::element_blank(),
        panel.border = ggplot2::element_rect(colour = "grey90", fill = NA, size = 0.5)
      )
  }
}

# Utility functions (only if dependencies are available)
if (file.exists("utils/helper_functions.R")) {
  tryCatch({
    source("utils/helper_functions.R", local = TRUE)
  }, error = function(e) {
    message("Helper functions not loaded")
  })
}

if (file.exists("utils/validation_functions.R")) {
  tryCatch({
    source("utils/validation_functions.R", local = TRUE)
  }, error = function(e) {
    message("Validation functions not loaded")
  })
}

if (file.exists("utils/plot_functions.R")) {
  tryCatch({
    source("utils/plot_functions.R", local = TRUE)
  }, error = function(e) {
    message("Plot functions not loaded")
  })
  
  # Load helper functions
  tryCatch({
    source("utils/helper_functions.R", local = TRUE)
  }, error = function(e) {
    message("Helper functions not loaded")
  })
  
  # Load validation functions
  tryCatch({
    source("utils/validation_functions.R", local = TRUE)
  }, error = function(e) {
    message("Validation functions not loaded")
  })
}
