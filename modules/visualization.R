visualizationUI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("dendrogram")),
    plotOutput(ns("module_trait"))
  )
}

visualizationServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    output$dendrogram <- renderPlot({
      req(wgcna_results())
      plotDendroAndColors(wgcna_results()$net$dendrograms[[1]],
                          labels2colors(wgcna_results()$net$colors),
                          "Module colors",
                          dendroLabels = FALSE, hang = 0.03)
    })

    output$module_trait <- renderPlot({
      req(wgcna_results())
      MEs <- wgcna_results()$net$MEs
      traits <- wgcna_results()$traits
      cor_res <- cor(MEs, traits, use = "p")
      pheatmap::pheatmap(cor_res, cluster_rows = FALSE, cluster_cols = FALSE)
    })
  })
}
