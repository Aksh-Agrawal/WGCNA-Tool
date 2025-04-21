dataUploadUI <- function(id) {
  ns <- NS(id)
  tagList(
    fileInput(ns("expression_data"), "Upload Expression Matrix (.csv)"),
    fileInput(ns("sample_data"), "Upload Sample Annotation (.csv)")
  )
}

dataUploadServer <- function(id) {
  moduleServer(id, function(input, output, session) {
    expression_data <- reactive({
      req(input$expression_data)
      read.csv(input$expression_data$datapath, row.names = 1)
    })

    sample_data <- reactive({
      req(input$sample_data)
      read.csv(input$sample_data$datapath, row.names = 1)
    })

    return(list(expr = expression_data, sample = sample_data))
  })
}
