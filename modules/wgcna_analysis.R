wgcnaAnalysisUI <- function(id) {
  ns <- NS(id)
  tagList(
    numericInput(ns("power"), "Soft Threshold Power:", value = 6, min = 1, max = 20),
    actionButton(ns("run_wgcna"), "Run WGCNA"),
    verbatimTextOutput(ns("modules_found"))
  )
}

wgcnaAnalysisServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    library(WGCNA)
    options(stringsAsFactors = FALSE)

    results <- reactiveVal()

    observeEvent(input$run_wgcna, {
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
    })

    return(results)
  })
}
