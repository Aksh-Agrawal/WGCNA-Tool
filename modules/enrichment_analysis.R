enrichmentAnalysisUI <- function(id) {
  ns <- NS(id)
  tagList(
    textInput(ns("module"), "Module Number (e.g., 1):"),
    actionButton(ns("run_enrich"), "Run Enrichment"),
    dataTableOutput(ns("enrich_table"))
  )
}

enrichmentAnalysisServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    library(clusterProfiler)
    library(org.Hs.eg.db)

    observeEvent(input$run_enrich, {
      req(wgcna_results())
      net <- wgcna_results()$net
      module_number <- as.numeric(input$module)
      module_genes <- names(net$colors[net$colors == module_number])

      ego <- enrichGO(gene = module_genes,
                      OrgDb = org.Hs.eg.db,
                      keyType = "SYMBOL",
                      ont = "BP",
                      pAdjustMethod = "BH",
                      qvalueCutoff = 0.05,
                      readable = TRUE)

      output$enrich_table <- renderDataTable({
        as.data.frame(ego)
      })
    })
  })
}
