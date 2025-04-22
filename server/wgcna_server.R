# server/wgcna_server.R

wgcnaAnalysisServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    library(WGCNA)
    options(stringsAsFactors = FALSE)
    
    results <- reactiveVal()
    
    observeEvent(input$run_wgcna, {
      try({
        datExpr <- t(data$expr())
        
        powers <- c(1:20)
        sft <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)
        
        net <- blockwiseModules(datExpr, power = input$power, TOMType = "unsigned",
                                minModuleSize = 30, reassignThreshold = 0, mergeCutHeight = 0.25,
                                numericLabels = TRUE, pamRespectsDendro = FALSE, verbose = 3)
        
        results(list(net = net, traits = data$sample()))
        
        output$modules_found <- renderPrint({
          table(net$colors)
        })
        
      }, silent = FALSE)
    })
    
    return(results)
  })
}