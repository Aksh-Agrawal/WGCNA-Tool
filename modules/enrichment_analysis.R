
enrichmentAnalysisUI <- function(id) {
  ns <- NS(id)
  tagList(
    fluidRow(
      column(4,
             wellPanel(
               h4("🧬 Enrichment Parameters", style = "color: #3c8dbc;"),
               
               selectInput(ns("module"), "Select Module:",
                           choices = NULL,
                           selected = NULL),
               
               selectInput(ns("organism"), "Organism:",
                           choices = list(
                             "Human" = "org.Hs.eg.db",
                             "Mouse" = "org.Mm.eg.db",
                             "Rat" = "org.Rn.eg.db",
                             "Fly" = "org.Dm.eg.db",
                             "Yeast" = "org.Sc.sgd.db"
                           ),
                           selected = "org.Hs.eg.db"),
               
               selectInput(ns("ontology"), "Gene Ontology:",
                           choices = list(
                             "Biological Process" = "BP",
                             "Molecular Function" = "MF",
                             "Cellular Component" = "CC"
                           ),
                           selected = "BP"),
               
               selectInput(ns("keytype"), "Gene ID Type:",
                           choices = list(
                             "Gene Symbol" = "SYMBOL",
                             "Entrez ID" = "ENTREZID",
                             "Ensembl ID" = "ENSEMBL"
                           ),
                           selected = "SYMBOL"),
               
               numericInput(ns("pvalue_cutoff"), "P-value Cutoff:",
                            value = 0.05, min = 0.001, max = 0.1, step = 0.001),
               
               numericInput(ns("qvalue_cutoff"), "Q-value Cutoff:",
                            value = 0.2, min = 0.01, max = 0.5, step = 0.01),
               
               br(),
               actionButton(ns("run_enrich"), "🚀 Run Enrichment Analysis", 
                            class = "btn-primary btn-block"),
               
               br(),
               conditionalPanel(
                 condition = paste0("output['", ns("enrichment_done"), "']"),
                 downloadButton(ns("download_enrichment"), "Download Results", 
                                class = "btn-success btn-block")
               )
             )
      ),
      
      column(8,
             conditionalPanel(
               condition = paste0("output['", ns("enrichment_done"), "']"),
               tabsetPanel(
                 tabPanel("📊 Enrichment Table",
                          br(),
                          DT::DTOutput(ns("enrich_table"))
                 ),
                 tabPanel("📈 Dot Plot",
                          br(),
                          plotOutput(ns("dot_plot"), height = "600px")
                 ),
                 tabPanel("🎯 Gene-Concept Network",
                          br(),
                          plotOutput(ns("network_plot"), height = "600px")
                 ),
                 tabPanel("📋 Gene Lists",
                          br(),
                          verbatimTextOutput(ns("gene_lists"))
                 )
               )
             ),
             
             conditionalPanel(
               condition = paste0("!output['", ns("enrichment_done"), "']"),
               div(
                 style = "text-align: center; padding: 100px; color: #999;",
                 icon("dna", style = "font-size: 48px;"),
                 h4("Select a module and run enrichment analysis", style = "margin-top: 20px;")
               )
             )
      )
    )
  )
}

enrichmentAnalysisServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    library(clusterProfiler)
    library(enrichplot)
    library(ggplot2)
    
    enrichment_results <- reactiveVal()
    
    # Update module choices
    observe({
      req(wgcna_results())
      net <- wgcna_results()$net
      module_numbers <- sort(unique(net$colors))
      module_numbers <- module_numbers[module_numbers != 0]  # Remove grey module
      
      module_choices <- setNames(module_numbers, 
                                 paste("Module", labels2colors(module_numbers), 
                                       "(", table(net$colors)[as.character(module_numbers)], "genes)"))
      
      updateSelectInput(session, "module", choices = module_choices)
    })
    
    observeEvent(input$run_enrich, {
      req(wgcna_results(), input$module, input$organism)
      
      tryCatch({
        showNotification("Running enrichment analysis...", type = "message", duration = 3)
        
        # Get genes for selected module
        net <- wgcna_results()$net
        module_number <- as.numeric(input$module)
        module_genes <- names(net$colors[net$colors == module_number])
        
        if (length(module_genes) == 0) {
          showNotification("No genes found in selected module", type = "error")
          return()
        }
        
        # Load appropriate organism database
        organism_db <- get(input$organism)
        
        # Run GO enrichment
        ego <- enrichGO(
          gene = module_genes,
          OrgDb = organism_db,
          keyType = input$keytype,
          ont = input$ontology,
          pAdjustMethod = "BH",
          pvalueCutoff = input$pvalue_cutoff,
          qvalueCutoff = input$qvalue_cutoff,
          readable = TRUE,
          minGSSize = 5,
          maxGSSize = 500
        )
        
        # Run KEGG enrichment (if human)
        kegg_results <- NULL
        if (input$organism == "org.Hs.eg.db") {
          # Convert gene symbols to entrez IDs for KEGG
          entrez_genes <- bitr(module_genes, 
                               fromType = input$keytype, 
                               toType = "ENTREZID", 
                               OrgDb = organism_db)$ENTREZID
          
          if (length(entrez_genes) > 0) {
            kegg_results <- enrichKEGG(
              gene = entrez_genes,
              organism = 'hsa',
              pvalueCutoff = input$pvalue_cutoff,
              qvalueCutoff = input$qvalue_cutoff
            )
          }
        }
        
        # Store results
        enrichment_results(list(
          GO = ego,
          KEGG = kegg_results,
          module_genes = module_genes,
          module_color = labels2colors(module_number),
          parameters = list(
            module = module_number,
            organism = input$organism,
            ontology = input$ontology,
            pvalue_cutoff = input$pvalue_cutoff,
            qvalue_cutoff = input$qvalue_cutoff
          )
        ))
        
        showNotification(paste("Found", nrow(ego), "enriched GO terms"), 
                         type = "message", duration = 5)
        
      }, error = function(e) {
        showNotification(paste("Error in enrichment analysis:", e$message), 
                         type = "error", duration = 10)
      })
    })
    
    # Render enrichment table
    output$enrich_table <- DT::renderDT({
      req(enrichment_results())
      
      ego_df <- as.data.frame(enrichment_results()$GO)
      if (nrow(ego_df) > 0) {
        # Format the table
        ego_df$pvalue <- format(ego_df$pvalue, scientific = TRUE, digits = 3)
        ego_df$p.adjust <- format(ego_df$p.adjust, scientific = TRUE, digits = 3)
        ego_df$qvalue <- format(ego_df$qvalue, scientific = TRUE, digits = 3)
        
        DT::datatable(
          ego_df,
          options = list(
            pageLength = 20,
            scrollX = TRUE,
            dom = 'Bfrtip',
            buttons = c('copy', 'csv', 'excel')
          ),
          extensions = 'Buttons',
          rownames = FALSE,
          caption = paste("GO Enrichment Results for Module", 
                          enrichment_results()$module_color)
        )
      } else {
        DT::datatable(data.frame(Message = "No enriched terms found"), 
                      options = list(dom = 't'), rownames = FALSE)
      }
    })
    
    # Dot plot
    output$dot_plot <- renderPlot({
      req(enrichment_results())
      
      ego <- enrichment_results()$GO
      if (nrow(ego) > 0) {
        dotplot(ego, showCategory = min(20, nrow(ego))) + 
          ggtitle(paste("GO Enrichment - Module", enrichment_results()$module_color)) +
          theme(plot.title = element_text(hjust = 0.5, size = 14))
      } else {
        ggplot() + 
          annotate("text", x = 1, y = 1, label = "No enriched terms to plot", size = 6) +
          theme_void()
      }
    })
    
    # Network plot
    output$network_plot <- renderPlot({
      req(enrichment_results())
      
      ego <- enrichment_results()$GO
      if (nrow(ego) >= 5) {
        cnetplot(ego, showCategory = min(10, nrow(ego)), 
                 categorySize = "pvalue", foldChange = NULL) +
          ggtitle(paste("Gene-Concept Network - Module", enrichment_results()$module_color)) +
          theme(plot.title = element_text(hjust = 0.5, size = 14))
      } else {
        ggplot() + 
          annotate("text", x = 1, y = 1, 
                   label = "Need at least 5 enriched terms for network plot", size = 6) +
          theme_void()
      }
    })
    
    # Gene lists
    output$gene_lists <- renderText({
      req(enrichment_results())
      
      results <- enrichment_results()
      ego_df <- as.data.frame(results$GO)
      
      if (nrow(ego_df) > 0) {
        top_terms <- head(ego_df, 5)
        gene_info <- paste(
          paste("Module:", results$module_color),
          paste("Total genes in module:", length(results$module_genes)),
          "",
          "Top 5 Enriched Terms and Associated Genes:",
          "",
          paste(mapply(function(desc, genes) {
            paste(desc, ":", gsub("/", ", ", genes))
          }, top_terms$Description, top_terms$geneID), collapse = "\n\n"),
          sep = "\n"
        )
      } else {
        gene_info <- paste(
          paste("Module:", results$module_color),
          paste("Total genes in module:", length(results$module_genes)),
          "",
          "No enriched terms found with current parameters.",
          "",
          "Module genes:",
          paste(results$module_genes, collapse = ", "),
          sep = "\n"
        )
      }
      
      gene_info
    })
    
    # Download handler
    output$download_enrichment <- downloadHandler(
      filename = function() {
        paste("enrichment_results_module_", 
              enrichment_results()$module_color, "_", 
              Sys.Date(), ".xlsx", sep = "")
      },
      content = function(file) {
        results <- enrichment_results()
        
        # Create workbook with multiple sheets
        wb <- openxlsx::createWorkbook()
        
        # GO results
        openxlsx::addWorksheet(wb, "GO_Enrichment")
        openxlsx::writeData(wb, "GO_Enrichment", as.data.frame(results$GO))
        
        # KEGG results (if available)
        if (!is.null(results$KEGG) && nrow(results$KEGG) > 0) {
          openxlsx::addWorksheet(wb, "KEGG_Enrichment")
          openxlsx::writeData(wb, "KEGG_Enrichment", as.data.frame(results$KEGG))
        }
        
        # Module genes
        openxlsx::addWorksheet(wb, "Module_Genes")
        openxlsx::writeData(wb, "Module_Genes", 
                            data.frame(Gene = results$module_genes))
        
        # Parameters
        openxlsx::addWorksheet(wb, "Parameters")
        params_df <- data.frame(
          Parameter = names(results$parameters),
          Value = unlist(results$parameters)
        )
        openxlsx::writeData(wb, "Parameters", params_df)
        
        openxlsx::saveWorkbook(wb, file, overwrite = TRUE)
      }
    )
    
    output$enrichment_done <- reactive({
      !is.null(enrichment_results())
    })
    outputOptions(output, "enrichment_done", suspendWhenHidden = FALSE)
  })
}
