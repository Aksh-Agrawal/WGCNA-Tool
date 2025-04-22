# UI
wgcnaAnalysisUI <- function(id) {
  ns <- NS(id)
  tagList(
    numericInput(ns("power"), "Soft Threshold Power:", value = 6, min = 1, max = 20),
    actionButton(ns("run_wgcna"), "Run WGCNA"),
    DT::DTOutput(ns("modules_found"))
  )
}

# Server
wgcnaAnalysisServer <- function(id, data) {
  moduleServer(id, function(input, output, session) {
    library(WGCNA)
    library(DT)
    options(stringsAsFactors = FALSE)
    
    # Explicitly use WGCNA's correlation to avoid unexpected args
    cor <- WGCNA::cor
    
    results <- reactiveVal()
    
    observeEvent(input$run_wgcna, {
      datExpr <- t(data$expr())
      
      # Choose power (optional: plot can be added later)
      powers <- 1:20
      sft <- pickSoftThreshold(datExpr, powerVector = powers, verbose = 5)
      
      # Module detection
      net <- blockwiseModules(
        datExpr,
        power = input$power,
        TOMType = "unsigned",
        minModuleSize = 30,
        reassignThreshold = 0,
        mergeCutHeight = 0.25,
        numericLabels = TRUE,
        pamRespectsDendro = FALSE,
        saveTOMs = FALSE,
        verbose = 3,
        corFnc = WGCNA::cor,                   # ✅ Fix here
        corOptions = list(use = "p")           # ✅ Robust against missing values
      )
      
      
      # Save result for downstream use
      results(list(
        net = net,
        expr = datExpr,
        traits = data$sample()
      ))
      
      # Format and display module summary
      module_summary <- data.frame(
        ModuleColor = labels2colors(net$colors)
      ) |>
        dplyr::count(ModuleColor) |>
        dplyr::arrange(desc(n)) |>
        dplyr::rename(GeneCount = n)
      
      output$modules_found <- DT::renderDataTable({
        DT::datatable(
          module_summary,
          options = list(pageLength = 10),
          rownames = FALSE
        )
      })
    })
    
    return(results)
  })
}
