# ==============================================================================
# Shiny app
# date of creation: January 2022 - June 2022
# authors: Julius Fenn, University of Freiburg
# ==============================================================================

############################################################################
# load packages, data, inline CSS, modules, functions
############################################################################
########################################
# load packages
########################################
library(shiny)
# library(shinyWidgets)
library(shinyjs)


# library(shinycssloaders) %>% withSpinner(color="#0dc5c1")

library(tidyverse)
library(lubridate)

library(magrittr)

library(rjson) # write JSON files
library(jsonlite) # read JSON files



library(igraph)

library(sortable)

library(vroom)
library(xlsx)


library(irr)


library(stargazer)

# library(qdap)
library(qdap, include.only = c('syn')) # include multiple functions
library(qdapDictionaries)


########################################
# load additional data
########################################


########################################
# inline CSS
########################################
css <- "
.nav li a.disabled {
background-color: #aaa !important;
color: #333 !important;
cursor: not-allowed !important;
border-color: #aaa !important;
}

#draw-plotR img:hover {
        transform: scale(1.5);
    }
"


jscode <-
  '
$(document).ready(function() {
$( "#downloadButton" ).click(function() {
  document.getElementById("downloadData").click();
});
});
'


#

########################################
# load functions
########################################
# create files
source("./www/functions_CAM/create_CAMfiles.R", encoding = "utf-8")
source("./www/functions_CAM/create_ValenceFiles.R", encoding = "utf-8")
# > fix Valence data
source("./www/functions_CAM/fix_ValenceData.R", encoding = "utf-8")


# draw CAMs
source("./www/functions_CAM/draw_CAM.R", encoding = "utf-8")

# compute network indicators
source("./www/functions_CAM/compute_indicatorsCAM.R", encoding = "utf-8")


# helper functions for protocol
source("./www/functions_CAM/protocolFunctions.R", encoding = "utf-8")

# create wordlists
source("./www/functions_CAM/create_wordlist2.R", encoding = "utf-8")

# compute reliabilities
source("./www/functions_CAM/compute_Reliabilities.R", encoding = "utf-8")

# create create_ListSynonyms
source("./www/functions_CAM/create_ListSynonyms.R", encoding = "utf-8")


# summary functions
source("./www/functions_CAM/summaryFunctions.R", encoding = "utf-8")

# slice CAMs
source("./www/functions_CAM/slice_CAM.R", encoding = "utf-8")




########################################
# load modules
########################################
# upload data
source("./www/modules/uploadUI.R", local = TRUE)
source("./www/modules/uploadServer.R", local = TRUE)

# draw data
source("./www/modules/drawUI.R", local = TRUE)
source("./www/modules/drawServer.R", local = TRUE)



########
# preprocessing
########
# summarize terms
source("./www/modules/summarizeTermsUI.R", local = TRUE)
source("./www/modules/summarizeTermsServer.R", local = TRUE)
# > additional functions
source("./www/modules/functions_bucketlists.R", local = TRUE)




# not summarized terms
source("./www/modules/notSummarizedTermsUI.R", local = TRUE)
source("./www/modules/notSummarizedTermsServer.R", local = TRUE)

# reliability
source("./www/modules/reliabilityUI.R", local = TRUE)
source("./www/modules/reliabilityServer.R", local = TRUE)

########
# analysis
########
# network indicators
source("./www/modules/networkIndicatorsUI.R", local = TRUE)
source("./www/modules/networkIndicatorsServer.R", local = TRUE)

# Word Outputs - overall
source("./www/modules/wordOutputs_overallUI.R", local = TRUE)
source("./www/modules/wordOutputs_overallServer.R", local = TRUE)



############################################################################
# define UI, server, runApp
############################################################################
## download function


### UI
ui <- fluidPage(
  ## include CSS
  includeCSS("www/css/css_file.css"),
  shinyjs::useShinyjs(),
  shinyjs::inlineCSS(css),

  tags$script(jscode),
  downloadButton("downloadData", label = "Download"),

  navbarPage(
    title = "CAM app",
    id = "tabs",
    tabPanel("upload data", {
      fluidPage(uploadUI("upload"))
    }),

    tabPanel("draw CAM", {
      fluidPage(drawUI("draw"))
    }),
    ########################################
    # preprocessing
    ########################################
    tabPanel("summarize terms", {
      fluidPage(summarizeTermsUI("summarizeTerms"))
    }),
    tabPanel("non-summarized terms", {
      fluidPage(notSummarizedTermsUI("notSummarizedTerms"))
    }),
    tabPanel("reliability", {
      fluidPage(reliabilityUI("reliability"))
    }),
    ########################################
    # analysis
    ########################################
    tabPanel("network indicators", {
        fluidPage(networkIndicatorsUI("networkIndicators"))
    }),
        navbarMenu(
        "word outputs",
        tabPanel("by words overall", {
            fluidPage(
      fluidPage(wordOutputs_overallUI("wordOutputs_overall"))
            )
        }),
        tabPanel("by single words", {
            fluidPage(
      # fluidPage(networkIndicatorsUI("networkIndicators"))
            )
        }),
    ),
        tabPanel("summarize CAMs", {
      # fluidPage(networkIndicatorsUI("networkIndicators"))
    }),
       tabPanel("similarity algorithms", {
      # fluidPage(networkIndicatorsUI("networkIndicators"))
    }),
       tabPanel("slice CAMs", {
      # fluidPage(networkIndicatorsUI("networkIndicators"))
    }),
       tabPanel("report", {
      # fluidPage(networkIndicatorsUI("networkIndicators"))
    }),
      tags$script(
        HTML(
          "var header = $('.navbar > .container-fluid');
                              header.append('<div style=\"float:right; padding-top: 8px\"><button id=\"downloadButton\" type=\"button\" class=\"btn btn-primary action-button\">Download data</button></div>')"
        ),

      )
    )
  )


  ### server
  server <- function(input, output, session) {
    ## elements to hide
    shinyjs::hide(id = "downloadData") # always hide (workaround actionButton)

    ## elements to disable
    #> not implemented
    # shinyjs::disable(selector = '.navbar-nav a[data-value="word2vec"')
    hideTab(inputId = "tabs", target = "draw CAM")
    #> preprocessing
    hideTab(inputId = "tabs", target = "summarize terms")
    hideTab(inputId = "tabs", target = "non-summarized terms")
    hideTab(inputId = "tabs", target = "reliability")

    #> analysis
    hideTab(inputId = "tabs", target = "network indicators")
    hideTab(inputId = "tabs", target = "word outputs")
    hideTab(inputId = "tabs", target = "summarize CAMs")
    hideTab(inputId = "tabs", target = "similarity algorithms")
    hideTab(inputId = "tabs", target = "slice CAMs")
    hideTab(inputId = "tabs", target = "report")

    ## global variable for protocol
    # https://community.rstudio.com/t/best-practices-for-global-external-variables-used-in-a-module/5820/2
    session.id <-
      reactive({
        as.character(floor(runif(1) * 1e10))
      }) ## create session ID

    globals <- reactiveValues(
      clickedButton = NULL,
      condition = NULL,

      protocol = list(
        sessionID = NULL,
        software = NULL,
        cleanValence = FALSE,
        deletedCAMs = NULL,
        currentCAMs = NULL,
        approximateMatching = NULL,
        searchTerms = NULL,
        findSynonyms = NULL,
        modelwordVec = NULL
# analysis part # ???
      ),

      dataCAM = NULL,
      drawnCAM = NULL,
      dataCAMsummarized = NULL,

      usedWords = list(),
      detailedProtocolAM = NULL,
      detailedProtocolST = NULL,
      detailedProtocolSynonyms = NULL,
      detailedProtocolword2vec = NULL,
# analysis part #
dataNetworkIndicators = NULL, 

      # counter = NULL,
      # summarizedData = NULL,

      # wordlist for Raters AND wordlist overall rated by raters
      wordlistRaters = NULL,
      wordlistOverallRated = NULL
    )

    ## set up download function:
    output$downloadData <- downloadHandler(
      filename = function() {
        paste(
          str_replace_all(
            string = str_remove_all(string = as.character(as.POSIXct(Sys.time(
            ))), pattern = "-|:"),
            pattern = " ",
            replacement = "_"
          ),
          "_",
          session.id(),
          ".zip",
          sep = ""
        )
      },
      content = function(fname) {
        fs <- c()
        tmpdir <- tempdir()
        setwd(tempdir()) # possible errors in Shiny ?!


        # print(globals$protocol)
        print(unique(globals$condition))

        ## add files
        if ("uploadedData" %in% globals$condition) {
          print("uploadedData - check")
          ## CAM_nodes_raw
          path <- paste0("CAM_nodes_raw", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$dataCAM()[[1]], path)
          ## CAM_connectors_raw
          path <- paste0("CAM_connectors_raw", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$dataCAM()[[2]], path)
          ## CAM_merged_raw
          path <- paste0("CAM_merged_raw", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$dataCAM()[[3]], path)
        }

        if ("drawnCAMs" %in% globals$condition) {
          print("drawnCAMs - check")
          ## CAM_nodes_raw
          path <- paste0("CAMs_drawn", ".rds")
          fs <- c(fs, path)
          saveRDS(object = globals$drawnCAM, path)
        }


        ### preprocessing part ###
        if ("approximateMatching" %in% globals$condition ||
        "searchTerms" %in% globals$condition ||
        "findSynonyms" %in% globals$condition ||
        "word2vec" %in% globals$condition) {
          print("approximateMatching OR searchTerms OR findSynonyms - check")
          ## CAM_nodes_clean
          path <- paste0("CAM_nodes_clean", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$dataCAMsummarized[[1]], path)
        }


        if ("approximateMatching" %in% globals$condition) {
          ## approximateMatching protocol
          print("long protocol approximate matching - check")
          path <- paste0("approximateMatching_protocol", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$detailedProtocolAM, path)
        }


        if ("searchTerms" %in% globals$condition) {
          ## approximateMatching protocol
          print("long protocol search terms - check")
          path <- paste0("searchTerms_protocol", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$detailedProtocolST, path)
        }

        if ("findSynonyms" %in% globals$condition) {
          ## approximateMatching protocol
          print("long protocol find synonyms - check")
          path <- paste0("findSynonyms_protocol", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$detailedProtocolSynonyms, path)
        }

        if ("word2vec" %in% globals$condition) {
          ## approximateMatching protocol
          print("long protocol word2vec - check")
          path <- paste0("word2vec_protocol", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$detailedProtocolword2vec, path)
        }


        if ("wordlistRatersCreated" %in% globals$condition) {
          print("wordlistRatersCreated - check")
          ## wordlist raters as txt file
          path <- paste0("wordlist_raters", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$wordlistRaters, path)

          ## wordlist raters as xlsx file
          path <- paste0("wordlist_raters", ".xlsx")
          fs <- c(fs, path)
          xlsx::write.xlsx2(globals$wordlistRaters, path, row.names = FALSE)
        }


        if ("wordlistOverallRated" %in% globals$condition) {
          print("wordlistOverallRated - check")
          ## wordlist raters as txt file
          path <- paste0("wordlist_overallRated", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$wordlistOverallRated, path)

          ## wordlist raters as xlsx file
          path <- paste0("wordlist_overallRated", ".xlsx")
          fs <- c(fs, path)
          xlsx::write.xlsx2(globals$wordlistOverallRated, path, row.names = FALSE)
        }


### analysis part ###
        if ("networkIndicators" %in% globals$condition) {
                    print("networkIndicators - check")
          ## networkIndicators as txt file
          path <- paste0("networkIndicators", ".txt")
          fs <- c(fs, path)
          vroom::vroom_write(globals$dataNetworkIndicators, path)

          ## networkIndicators as xlsx file
          path <- paste0("networkIndicators", ".xlsx")
          fs <- c(fs, path)
          xlsx::write.xlsx2(globals$dataNetworkIndicators, path, row.names = FALSE)



          ## networkIndicators APA table
          print("networkIndicators APA table - check !!!!")
        }




        ## + add description file
        path <- paste0("description file", ".txt")
        fs <- c(fs, path)

        ## change description file
        write(
          "protocol: contains all the steps you have done (upload this file plus your raw dataset to continue your preprocessing / analysis)",
          path
        )

        if ("uploadedData" %in% globals$condition) {
          write(
            "\nCAM_nodes_raw: contains the data of all nodes included in the CAM dataset",
            path,
            append = TRUE
          )
          write(
            "CAM_connectors_raw: contains the data of all connectors included in the CAM dataset",
            path,
            append = TRUE
          )
          write(
            "CAM_merged_raw: contains the merged data of all nodes and connectors included in the CAM dataset",
            path,
            append = TRUE
          )
        } else{
          write("it seems that you have uploaded no or the wrong dataset", path)
        }

        if ("drawnCAMs" %in% globals$condition) {
          write(
            "\nCAMs_drawn: contains the data of your drawn CAMs in .rds format (can be directly loaded by R)",
            path,
            append = TRUE
          )
        }

      if ("approximateMatching" %in% globals$condition ||
        "searchTerms" %in% globals$condition ||
        "findSynonyms" %in% globals$condition ||
        "word2vec" %in% globals$condition) {
          write(
            "\nCAM_nodes_clean: contains the data of all SUMMARIZED nodes included in the CAM dataset (see variable text_summarized)",
            path,
            append = TRUE
          )

          if ("approximateMatching" %in% globals$condition) {
          write(
            "\napproximateMatching_protocol: a more detailed protocol including summary statistics of your summarizing steps regarding approximate matching",
            path,
            append = TRUE
          )
        }

        if ("searchTerms" %in% globals$condition) {
          write(
            "\nsearchTerms_protocol: a more detailed protocol including summary statistics of your summarizing steps regarding search terms (regular expressions)",
            path,
            append = TRUE
          )
        }


        if ("findSynonyms" %in% globals$condition) {
          write(
            "\nfindSynonyms_protocol: a more detailed protocol including summary statistics of your summarizing steps regarding finding synonyms (database driven)",
            path,
            append = TRUE
          )
        }

        if ("word2vec" %in% globals$condition) {
          write(
            "\nword2vec_protocol: a more detailed protocol including summary statistics of your summarizing steps regarding word2vec (database driven)",
            path,
            append = TRUE
          )
        }
          }


        if ("wordlistRatersCreated" %in% globals$condition) {
        write(
            "\nwordlist_raters: .txt file of wordlist, which you can forward to the raters",
            path,
            append = TRUE
          )

        write(
            "wordlist_raters: .xlsx (Excel) file of wordlist, which you can forward to the raters",
            path,
            append = TRUE
          )
        }


        if ("wordlistOverallRated" %in% globals$condition) {
        write(
            "\nwordlist_overallRated: .txt file of overall wordlist, which have been rated by your raters",
            path,
            append = TRUE
          )

        write(
            "wordlist_overallRated: .xlsx (Excel) file of overall wordlist, which have been rated by your raters",
            path,
            append = TRUE
          )
        }



                if ("networkIndicators" %in% globals$condition) {
        write(
            "\nnetworkIndicators: .txt file of all computed network indicators",
            path,
            append = TRUE
          )

        write(
            "networkIndicators: .xlsx (Excel) file of all computed network indicators",
            path,
            append = TRUE
          )
        }


        ## add protocol
        #> add unique session id
        if (is.null(globals$protocol$sessionID)) {
          globals$protocol$sessionID <- session.id()
        } else{
          # if(!globals$protocol$sessionID %in% session.id()){}
          globals$protocol$sessionID <-
            c(globals$protocol$sessionID, session.id())
        }

        ## + add protocol file
        path <- paste0("protocol", ".txt")
        fs <- c(fs, path)
               write(toJSON(globals$protocol), path)
       #  write(jsonlite::toJSON(globals$protocol), path)
       # write(rjson::toJSON(globals$protocol), path)
      #jsonlite::write_json(x = globals$protocol, path = path)



        zip(zipfile = fname, files = fs)
      },
      contentType = "application/zip"
    )





    ########################################
    # single modules
    ########################################
    globals$dataCAM <-
      uploadServer("upload", parent = session, globals) ## add parent session for navbar navigation

    globals$drawnCAM <-
      drawServer("draw",
                 dataCAM = globals$dataCAM, # to define requirements
                 parent = session,
                 globals)



      ########
# preprocessing
########

#        dataCAM = globals$dataCAM,
#       drawnCAM = globals$drawnCAM,

      summarizeTermsServer(
        "summarizeTerms",
        dataCAM = globals$dataCAM,
        drawnCAM = globals$drawnCAM,
        parent = session,
        globals
      )


      notSummarizedTermsServer(
        "notSummarizedTerms",
        dataCAM = globals$dataCAM,
        drawnCAM = globals$drawnCAM,
        parent = session,
        globals
      )

      reliabilityServer(
        "reliability",
        dataCAM = globals$dataCAM,
        drawnCAM = globals$drawnCAM,
        parent = session,
        globals
      )


########
# analysis
########
      networkIndicatorsServer(
        "networkIndicators",
        dataCAM = globals$dataCAM,
        drawnCAM = globals$drawnCAM,
        parent = session,
        globals
      )


      wordOutputs_overallServer(
        "wordOutputs_overall",
        dataCAM = globals$dataCAM,
        drawnCAM = globals$drawnCAM,
        parent = session,
        globals
      )

  }




  ### run app
 # shinyApp(ui, server)
  runApp(shinyApp(ui, server), launch.browser = TRUE)
