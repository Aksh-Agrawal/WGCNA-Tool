# 🧬 Enhanced WGCNA Analysis Platform

A comprehensive, user-friendly Shiny application for Weighted Gene Co-expression Network Analysis (WGCNA) with advanced features, modern UI, and extensive quality control.

## ✨ Key Features

### 🚀 **Enhanced User Experience**

- **Modern, Responsive UI** with gradient themes and smooth animations
- **Comprehensive Dashboard** with intuitive navigation
- **Real-time Progress Tracking** for long-running analyses
- **Interactive Visualizations** using plotly and enhanced graphics
- **Advanced Error Handling** with user-friendly messages

### 📊 **Advanced Data Management**

- **Smart File Upload** with automatic format detection
- **Comprehensive Quality Control** with outlier detection
- **Data Preprocessing** with filtering and normalization options
- **Sample Dataset Integration** for testing and learning
- **Flexible Input Formats** (CSV, TSV with various separators)

### ⚙️ **Enhanced WGCNA Analysis**

- **Automatic Power Estimation** with scale-free topology analysis
- **Optimized Performance** with multi-threading and memory management
- **Blockwise Analysis** for large datasets (>5,000 genes)
- **Advanced Parameter Tuning** with real-time suggestions
- **Comprehensive Result Validation** and quality metrics

### 🧬 **Functional Enrichment**

- **Multi-organism Support** (Human, Mouse, Rat, Fly, Yeast)
- **Multiple Ontologies** (BP, MF, CC)
- **Advanced Visualization** with dot plots, bar plots, and networks
- **Interactive Results Tables** with filtering and export options
- **Gene List Management** with detailed annotations

### 📈 **Rich Visualizations**

- **Interactive Dendrograms** with customizable parameters
- **Module-Trait Heatmaps** with correlation statistics
- **Network Property Analysis** with scale-free topology plots
- **Publication-Ready Figures** with high-resolution export
- **Customizable Color Schemes** and layout options

### 📋 **Comprehensive Export**

- **Multiple File Formats** (CSV, Excel, RData, PDF, HTML)
- **Automated Report Generation** with analysis summaries
- **Batch Downloads** for all results
- **Executive Summaries** for stakeholders
- **Reproducible Analysis Records** with parameter tracking

## 🏗️ **Enhanced Architecture**

```
WGCNA-Tool/
├── 📄 app.R                          # Main application with enhanced UI
├── 🌐 global.R                       # Global configuration and dependencies
├── 📖 README.md                      # Comprehensive documentation
├── 📁 modules/                       # Modular components
│   ├── enhanced_data_upload.R        # Advanced data upload with QC
│   ├── enhanced_wgcna_analysis.R     # Optimized WGCNA with auto-tuning
│   ├── enhanced_enrichment_analysis.R # Multi-organism enrichment
│   ├── enhanced_visualization.R      # Interactive plotting suite
│   ├── quality_control.R            # Comprehensive QC dashboard
│   └── results_export.R             # Advanced export capabilities
├── 🛠️ utils/                         # Utility functions
│   ├── helper_functions.R           # Data processing utilities
│   ├── validation_functions.R       # Input validation
│   └── plot_functions.R            # Enhanced plotting functions
├── 📊 data/                         # Sample datasets
│   ├── sample_expression.csv        # Small test dataset (~1K genes)
│   ├── sample_traits.csv           # Corresponding traits
│   ├── expression_matrix_large.csv  # Large dataset (~5K genes)
│   └── sample_annotation_large.csv  # Large dataset annotations
└── 🔗 rsconnect/                   # Deployment configuration
```

## 🚀 **Quick Start Guide**

### 1️⃣ **Installation & Setup**

```r
# Install required packages
install.packages(c("shiny", "shinydashboard", "shinyWidgets",
                   "plotly", "DT", "ggplot2", "RColorBrewer"))

# Install Bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install(c("WGCNA", "clusterProfiler", "enrichplot",
                       "org.Hs.eg.db", "org.Mm.eg.db"))

# Optional packages for enhanced features
install.packages(c("corrplot", "pheatmap", "viridis", "shinycssloaders"))
```

### 2️⃣ **Launch Application**

```r
# Method 1: Run from RStudio
# Open app.R and click 'Run App'

# Method 2: Command line
shiny::runApp()

# Method 3: Run in browser mode
shiny::runApp(launch.browser = TRUE)
```

### 3️⃣ **Using Sample Data**

The application includes built-in sample datasets:

- **Small Dataset**: ~1,000 genes, 20 samples (good for testing)
- **Large Dataset**: ~5,000 genes, 50 samples (realistic analysis)

Click the "Load Sample Dataset" buttons in the Data Upload tab to get started immediately.

## 📋 **Data Requirements**

### 📊 **Expression Matrix**

- **Format**: CSV/TSV with headers
- **Structure**: Genes as rows, samples as columns
- **Values**: Numeric expression data (preferably log2-transformed)
- **Size**: Minimum 10 genes × 4 samples
- **Missing Data**: <20% recommended

**Example structure:**

```
Gene,Sample1,Sample2,Sample3,Sample4
GENE1,5.2,4.8,6.1,5.5
GENE2,3.1,3.5,2.9,3.8
GENE3,7.2,7.8,7.1,7.5
```

### 📝 **Sample Annotation**

- **Format**: CSV/TSV with headers
- **Structure**: Samples as rows, traits as columns
- **Matching**: Sample IDs must match expression matrix columns
- **Traits**: Both continuous and categorical supported

**Example structure:**

```
Sample,Age,Gender,Treatment,Response
Sample1,25,Male,Control,Low
Sample2,30,Female,Treated,High
Sample3,28,Male,Treated,Medium
```

## ⚙️ **Analysis Workflow**

### 🔍 **Step 1: Data Upload & Quality Control**

1. Upload expression matrix and sample annotation
2. Review data quality metrics and outlier detection
3. Apply preprocessing (outlier removal, gene filtering)
4. Validate data compatibility and completeness

### 🌐 **Step 2: Network Construction**

1. **Power Selection**: Use auto-estimation or manual tuning
2. **Module Detection**: Configure minimum module size and merge threshold
3. **Network Type**: Choose unsigned, signed, or signed hybrid
4. **Advanced Options**: Threading, block size, correlation method

### 🧬 **Step 3: Functional Analysis**

1. Select modules of interest from the results
2. Choose organism database (Human, Mouse, Rat, etc.)
3. Configure enrichment parameters (p-value, q-value thresholds)
4. Explore GO terms and pathway associations

### 📊 **Step 4: Visualization & Export**

1. Generate interactive dendrograms and heatmaps
2. Analyze network properties and module characteristics
3. Create publication-ready figures
4. Export comprehensive results and reports

## 🎛️ **Parameter Guide**

### 🔌 **Soft Threshold Power**

- **Purpose**: Controls network connectivity stringency
- **Range**: 1-30 (typically 6-12 for unsigned, 12-20 for signed)
- **Auto-estimation**: Uses scale-free topology criterion (R² > 0.8)
- **Impact**: Higher values = sparser, more specific networks

### 📦 **Module Size Parameters**

- **Minimum Module Size**: 5-200 genes (default: 30)
  - Larger: Fewer, more robust modules
  - Smaller: More modules, potentially less stable
- **Merge Cut Height**: 0.1-0.9 (default: 0.25)
  - Lower: Keep more separate modules
  - Higher: Merge more similar modules

### 🌐 **Network Types**

- **Unsigned**: Treats positive and negative correlations equally
- **Signed**: Distinguishes between positive and negative correlations
- **Signed Hybrid**: Hybrid approach for better module preservation

## 🔧 **Troubleshooting**

### 🚨 **Common Issues**

**Memory Errors (Large Datasets)**

- Enable blockwise analysis (automatic for >5,000 genes)
- Increase R memory limit: `memory.limit(size = 8000)`
- Filter low-variance genes before analysis
- Use correlation-based gene filtering

**No Modules Detected**

- Lower the soft threshold power (try 3-6)
- Reduce minimum module size to 10-20
- Check data normalization and quality
- Ensure sufficient sample size (>15 recommended)

**Slow Performance**

- Enable multi-threading in advanced options
- Use blockwise analysis for large datasets
- Disable TOM file saving if not needed
- Consider pre-filtering genes by variance

**Enrichment Analysis Errors**

- Verify gene ID format matches selected type
- Check internet connection for database access
- Ensure organism database is installed
- Try relaxing significance thresholds

### 🔧 **Performance Optimization**

**For Large Datasets (>20,000 genes):**

```r
# Recommended preprocessing
expr_data <- expr_data[apply(expr_data, 1, var) > 0.1, ]  # Filter low variance
expr_data <- expr_data[!apply(expr_data, 1, function(x) sum(is.na(x)) > 0.2), ]  # Remove high missing
```

**Memory Settings:**

```r
# Increase memory allocation
options(java.parameters = "-Xmx8g")  # For rJava-dependent packages
memory.limit(size = 16000)  # Windows only
```

## 📚 **Advanced Features**

### 🔬 **Quality Control Dashboard**

- Comprehensive data quality assessment
- Outlier detection with multiple methods
- Sample-sample correlation analysis
- Gene expression distribution analysis
- Interactive quality plots

### 📈 **Enhanced Visualizations**

- Interactive network plots with plotly
- Customizable color schemes and themes
- High-resolution export options
- Animated transitions and hover effects
- Comparative analysis plots

### 📊 **Export & Reporting**

- Automated HTML and PDF report generation
- Excel workbooks with multiple sheets
- R workspace files for reproducibility
- Publication-ready figure exports
- Executive summary generation

## 🤝 **Contributing**

We welcome contributions! Here's how to get involved:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/amazing-feature`)
3. **Commit** your changes (`git commit -m 'Add amazing feature'`)
4. **Push** to the branch (`git push origin feature/amazing-feature`)
5. **Open** a Pull Request

### 🐛 **Bug Reports**

Please include:

- R version and operating system
- Package versions (`sessionInfo()`)
- Data characteristics (size, format)
- Error messages and steps to reproduce

### 💡 **Feature Requests**

We're always looking to improve! Suggest new features by opening an issue with:

- Clear description of the proposed feature
- Use case and benefits
- Implementation ideas (if any)

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 **Support**

- **Issues**: [GitHub Issues](https://github.com/your-repo/wgcna-tool/issues)
- **Documentation**: This README and in-app help
- **Examples**: Check the `data/` folder for sample datasets

## 🙏 **Acknowledgments**

- **WGCNA Team**: Peter Langfelder and Steve Horvath for the WGCNA package
- **Bioconductor**: For the comprehensive bioinformatics ecosystem
- **R Community**: For the amazing packages that make this possible
- **Shiny Team**: For the fantastic web framework

## 📊 **Citation**

If you use this tool in your research, please cite:

```
Enhanced WGCNA Analysis Platform (2025)
A comprehensive Shiny application for weighted gene co-expression network analysis
GitHub: https://github.com/your-repo/wgcna-tool
```

And the original WGCNA paper:

```
Langfelder P, Horvath S (2008) WGCNA: an R package for weighted correlation
network analysis. BMC Bioinformatics 9: 559
```

---

🚀 **Ready to explore your gene networks?** Launch the application and start discovering biological insights!

---

_Last updated: December 2024 | Version: 2.0 Enhanced_
