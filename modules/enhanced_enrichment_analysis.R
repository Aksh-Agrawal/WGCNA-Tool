# Enhanced Enrichment Analysis Module
# ===================================

enhancedEnrichmentAnalysisUI <- function(id) {
  ns <- NS(id)
  
  tagList(
    fluidRow(
      # Configuration panel
      column(4,
        wellPanel(
          h4("🧬 Enrichment Configuration", style = "color: #4a5568;"),
          
          selectInput(ns("module"), "Select Module:",
                     choices = NULL,
                     selected = NULL),
          
          selectInput(ns("organism"), "Organism Database:",
                     choices = list(
                       "Human (Homo sapiens)" = "org.Hs.eg.db",
                       "Mouse (Mus musculus)" = "org.Mm.eg.db",
                       "Rat (Rattus norvegicus)" = "org.Rn.eg.db",
                       "Fly (Drosophila)" = "org.Dm.eg.db",
                       "Yeast (Saccharomyces)" = "org.Sc.sgd.db"
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
                       "Ensembl ID" = "ENSEMBL",
                       "RefSeq ID" = "REFSEQ"
                     ),
                     selected = "SYMBOL"),
          
          numericInput(ns("pvalue_cutoff"), "P-value Cutoff:",
                      value = 0.05, min = 0.001, max = 0.1, step = 0.001),
          
          numericInput(ns("qvalue_cutoff"), "Q-value Cutoff:",
                      value = 0.2, min = 0.01, max = 0.5, step = 0.01),
          
          br(),
          actionButton(ns("run_enrich"), "🚀 Run Enrichment", 
                      class = "btn-primary btn-block"),
          
          br(),
          conditionalPanel(
            condition = "output.enrichment_done",
            ns = ns,
            downloadButton(ns("download_enrichment"), "📥 Download Results", 
                          class = "btn-success btn-block")
          )
        )
      ),
      
      # Results panel
      column(8,
        conditionalPanel(
          condition = "output.enrichment_done",
          ns = ns,
          
          tabsetPanel(
            tabPanel("📊 Enrichment Table",
              br(),
              DT::DTOutput(ns("enrich_table"))
            ),
            
            tabPanel("📈 Visualization",
              br(),
              fluidRow(
                column(6,
                  h5("Dot Plot"),
                  plotOutput(ns("dot_plot"), height = "400px")
                ),
                column(6,
                  h5("Bar Plot"),
                  plotOutput(ns("bar_plot"), height = "400px")
                )
              )
            ),
            
            tabPanel("📋 Gene Lists",
              br(),
              verbatimTextOutput(ns("gene_lists"))
            ),
            
            tabPanel("📄 Summary Report",
              br(),
              verbatimTextOutput(ns("enrichment_summary"))
            )
          )
        ),
        
        conditionalPanel(
          condition = "!output.enrichment_done",
          ns = ns,
          div(
            style = "text-align: center; padding: 100px; color: #999;",
            icon("dna", style = "font-size: 48px;"),
            h4("Select a module and run enrichment analysis", 
               style = "margin-top: 20px; color: #718096;")
          )
        )
      )
    )
  )
}

enrichmentAnalysisServer <- function(id, wgcna_results) {
  moduleServer(id, function(input, output, session) {
    
    # Check if required packages are available
    required_packages <- c("clusterProfiler", "enrichplot", "ggplot2")
    missing_packages <- setdiff(required_packages, rownames(installed.packages()))
    
    if (length(missing_packages) > 0) {
      showNotification(
        paste("Missing packages for enrichment analysis:", paste(missing_packages, collapse = ", ")),
        type = "warning", duration = 10
      )
    }
    
    # Reactive values for results
    enrichment_results <- reactiveVal(NULL)
    
    # Update module choices when WGCNA results are available
    observe({
      req(wgcna_results())
      
      results <- wgcna_results()
      if (!is.null(results$net)) {
        module_colors <- WGCNA::labels2colors(results$net$colors)
        unique_modules <- sort(unique(module_colors))
        
        # Create choices with module sizes
        module_sizes <- table(module_colors)
        choices <- setNames(unique_modules, 
                           paste0(unique_modules, " (", module_sizes[unique_modules], " genes)"))
        
        updateSelectInput(session, "module", choices = choices)
      }
    })
    
    # Run enrichment analysis
    observeEvent(input$run_enrich, {
      req(input$module, wgcna_results())
      
      if (length(missing_packages) > 0) {
        showNotification("Cannot run enrichment analysis: missing required packages", 
                        type = "error")
        return()
      }
      
      showNotification("Running enrichment analysis...", type = "message")
      
      tryCatch({
        # Load required libraries
        library(clusterProfiler)
        library(enrichplot)
        library(ggplot2)
        
        results <- wgcna_results()
        module_colors <- WGCNA::labels2colors(results$net$colors)
        
        # Get genes in selected module
        module_genes <- names(results$net$colors)[module_colors == input$module]
        
        if (length(module_genes) < 5) {
          showNotification("Module too small for enrichment analysis (minimum 5 genes)", 
                          type = "warning")
          return()
        }
        
        # Get background genes (all genes in analysis)
        universe <- names(results$net$colors)
        
        # Run GO enrichment
        ego <- enrichGO(
          gene = module_genes,
          universe = universe,
          OrgDb = input$organism,
          ont = input$ontology,
          pAdjustMethod = "BH",
          pvalueCutoff = input$pvalue_cutoff,
          qvalueCutoff = input$qvalue_cutoff,
          keyType = input$keytype,
          readable = TRUE
        )
        
        # Check if enrichment analysis returned results
        if (is.null(ego)) {
          showNotification("Enrichment analysis failed - check gene IDs and organism settings", 
                          type = "warning")
          enrichment_results(NULL)
          return()
        }
        
        if (is.null(ego) || nrow(ego@result) == 0) {
          showNotification("No significant enrichment found with current parameters", 
                          type = "warning")
          enrichment_results(NULL)
          return()
        }
        
        # Store results
        enrichment_results(list(
          ego = ego,
          module = input$module,
          genes = module_genes,
          parameters = list(
            organism = input$organism,
            ontology = input$ontology,
            keytype = input$keytype,
            pvalue_cutoff = input$pvalue_cutoff,
            qvalue_cutoff = input$qvalue_cutoff
          )
        ))
        
        showNotification(
          paste("Enrichment analysis completed:", 
                if (!is.null(ego) && nrow(ego@result) > 0) nrow(ego@result) else 0, 
                "terms found"), 
          type = "message"
        )
        
      }, error = function(e) {
        showNotification(paste("Error in enrichment analysis:", e$message), 
                        type = "error", duration = 10)
        enrichment_results(NULL)
      })
    })
    
    # Enrichment status
    output$enrichment_done <- reactive({
      !is.null(enrichment_results())
    })
    outputOptions(output, "enrichment_done", suspendWhenHidden = FALSE)
    
    # Enrichment results table
    output$enrich_table <- DT::renderDT({
      req(enrichment_results())
      
      results <- enrichment_results()
      
      # Check if ego object exists and has results
      if (is.null(results$ego) || nrow(results$ego@result) == 0) {
        return(NULL)
      }
      
      ego_df <- results$ego@result
      
      # Select and format columns
      display_df <- ego_df[, c("ID", "Description", "GeneRatio", "BgRatio", 
                              "pvalue", "p.adjust", "qvalue", "Count")]
      
      # Format p-values
      display_df$pvalue <- format(display_df$pvalue, scientific = TRUE, digits = 3)
      display_df$p.adjust <- format(display_df$p.adjust, scientific = TRUE, digits = 3)
      display_df$qvalue <- format(display_df$qvalue, scientific = TRUE, digits = 3)
      
      DT::datatable(
        display_df,
        options = list(
          pageLength = 15,
          scrollX = TRUE,
          dom = 'Bfrtip',
          buttons = c('copy', 'csv', 'excel')
        ),
        extensions = 'Buttons',
        caption = paste("GO enrichment results for", results$module, "module")
      )
    })
    
    # Dot plot
    output$dot_plot <- renderPlot({
      req(enrichment_results())
      
      tryCatch({
        results <- enrichment_results()
        
        # Check if ego object exists and has results
        if (!is.null(results$ego) && nrow(results$ego@result) > 0) {
          # Show top 20 terms
          p <- dotplot(results$ego, showCategory = 20) + 
            ggtitle(paste("GO Enrichment -", results$module, "Module")) +
            theme_minimal()
          print(p)
        } else {
          plot.new()
          text(0.5, 0.5, "No enrichment results to display", 
               cex = 1.2, col = "gray")
        }
      }, error = function(e) {
        plot.new()
        text(0.5, 0.5, paste("Error creating plot:", e$message), 
             cex = 1.2, col = "red")
      })
    })
    
    # Bar plot
    output$bar_plot <- renderPlot({
      req(enrichment_results())
      
      tryCatch({
        results <- enrichment_results()
        
        # Check if ego object exists and has results
        if (!is.null(results$ego) && nrow(results$ego@result) > 0) {
          # Show top 15 terms
          p <- barplot(results$ego, showCategory = 15) + 
            ggtitle(paste("GO Enrichment -", results$module, "Module")) +
            theme_minimal()
          print(p)
        } else {
          plot.new()
          text(0.5, 0.5, "No enrichment results to display", 
               cex = 1.2, col = "gray")
        }
      }, error = function(e) {
        plot.new()
        text(0.5, 0.5, paste("Error creating plot:", e$message), 
             cex = 1.2, col = "red")
      })
    })
    
    # Gene lists
    output$gene_lists <- renderText({
      req(enrichment_results())
      
      results <- enrichment_results()
      
      # Check if ego object exists and has results
      if (is.null(results$ego) || nrow(results$ego@result) == 0) {
        return("No enriched terms found.")
      }
      
      ego_df <- results$ego@result
      
      if (nrow(ego_df) > 0) {
        # Show top 10 terms with their genes
        top_terms <- head(ego_df, 10)
        
        gene_info <- sapply(1:nrow(top_terms), function(i) {
          term <- top_terms[i, ]
          genes <- unlist(strsplit(term$geneID, "/"))
          paste0(
            term$Description, " (", term$ID, "):\n",
            paste(genes, collapse = ", "), "\n"
          )
        })
        
        paste(
          paste("=== Gene Lists for", results$module, "Module ==="),
          "",
          paste(gene_info, collapse = "\n"),
          sep = "\n"
        )
      } else {
        "No enriched terms found."
      }
    })
    
    # Summary report
    output$enrichment_summary <- renderText({
      req(enrichment_results())
      
      results <- enrichment_results()
      
      # Check if ego object exists and has results
      if (is.null(results$ego) || nrow(results$ego@result) == 0) {
        return(paste(
          "=== Enrichment Analysis Summary ===",
          "",
          paste("Module analyzed:", results$module),
          paste("Number of genes in module:", length(results$genes)),
          paste("Organism database:", results$parameters$organism),
          paste("Gene Ontology:", results$parameters$ontology),
          paste("Gene ID type:", results$parameters$keytype),
          "",
          "=== Analysis Parameters ===",
          paste("P-value cutoff:", results$parameters$pvalue_cutoff),
          paste("Q-value cutoff:", results$parameters$qvalue_cutoff),
          "",
          "=== Results Summary ===",
          "No significant enrichment found.",
          "",
          paste("Analysis completed:", Sys.time()),
          sep = "\n"
        ))
      }
      
      ego_df <- results$ego@result
      
      paste(
        "=== Enrichment Analysis Summary ===",
        "",
        paste("Module analyzed:", results$module),
        paste("Number of genes in module:", length(results$genes)),
        paste("Organism database:", results$parameters$organism),
        paste("Gene Ontology:", results$parameters$ontology),
        paste("Gene ID type:", results$parameters$keytype),
        "",
        "=== Analysis Parameters ===",
        paste("P-value cutoff:", results$parameters$pvalue_cutoff),
        paste("Q-value cutoff:", results$parameters$qvalue_cutoff),
        "",
        "=== Results Summary ===",
        paste("Total enriched terms:", nrow(ego_df)),
        if (nrow(ego_df) > 0) {
          paste(
            paste("Most significant term:", ego_df$Description[1]),
            paste("Best p-value:", format(ego_df$pvalue[1], scientific = TRUE, digits = 3)),
            paste("Terms with p < 0.01:", sum(ego_df$pvalue < 0.01)),
            paste("Terms with q < 0.05:", sum(ego_df$qvalue < 0.05)),
            sep = "\n"
          )
        } else {
          "No significant enrichment found."
        },
        "",
        paste("Analysis completed:", Sys.time()),
        sep = "\n"
      )
    })
    
    # Download handler
    output$download_enrichment <- downloadHandler(
      filename = function() {
        req(enrichment_results())
        paste("enrichment_", enrichment_results()$module, "_", Sys.Date(), ".xlsx", sep = "")
      },
      content = function(file) {
        req(enrichment_results())
        
        results <- enrichment_results()
        
        # Check if ego object exists and has results
        if (is.null(results$ego) || nrow(results$ego@result) == 0) {
          # Create empty file with message
          write.csv(data.frame(Message = "No enrichment results found"), 
                   gsub("\\.xlsx$", ".csv", file), row.names = FALSE)
          return()
        }
        
        # Write results to Excel file
        if (requireNamespace("openxlsx", quietly = TRUE)) {
          openxlsx::write.xlsx(results$ego@result, file)
        } else {
          # Fallback to CSV
          write.csv(results$ego@result, gsub("\\.xlsx$", ".csv", file), row.names = FALSE)
        }
      }
    )
    
    return(enrichment_results)
  })
}
