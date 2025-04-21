# WGCNA Shiny Tool

This Shiny app allows you to perform Weighted Gene Co-expression Network Analysis (WGCNA) with a user-friendly interface. Inspired by IDEP, this tool provides:

- Expression data upload
- Sample trait data integration
- WGCNA network and module detection
- GO enrichment analysis on modules
- Visualization of dendrogram and module-trait heatmaps

## Folder Structure
```
WGCNA_Tool/
├── app.R
├── modules/
│   ├── data_upload.R
│   ├── wgcna_analysis.R
│   ├── enrichment_analysis.R
│   └── visualization.R
├── data/
│   ├── sample_expression.csv
│   └── sample_traits.csv
└── README.md
```

## How to Run
1. Open RStudio
2. Open `app.R`
3. Click 'Run App'

## Dependencies
Install these packages if not already installed:
```r
install.packages(c("shiny", "shinydashboard", "data.table", "DT", "pheatmap"))
if (!requireNamespace("BiocManager", quietly = TRUE)) install.packages("BiocManager")
BiocManager::install(c("WGCNA", "clusterProfiler", "org.Hs.eg.db"))
```

## Sample Files
- `data/sample_expression.csv`: Expression matrix with genes as rows
- `data/sample_traits.csv`: Sample metadata for trait association

## Author
*Built for academic and research use. Customize further as needed.*
