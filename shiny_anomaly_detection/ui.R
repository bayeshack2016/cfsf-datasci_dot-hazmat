## Shiny + R Anomaly App for the U.S. Dept. of Transportation
## By Jude Calvillo (Data Science Working Group @ Code for San Francisco)
##
## Status: July 23, 2016:
## ---------------------
## v1.1 - Just initiating app dev
##
## - Initiating server and UI R scripts.
## - Need to conceptualize UI and immediately deliverable features before continuing w/UI.
##   I should be doing this over the weekend.
##
## ----------------------------------
##

library(shiny)

shinyUI(pageWithSidebar(
headerPanel("U.S. Dept. of Transportation: Hazmat Anomaly Detector"),
    sidebarPanel(
        p("This app helps DoT executives identify which states exhibited hazmat incident totals that
          were -truly- anomalous to their respective norms. Please select your month of concern below.
          More state-by-state features, and greater date-range granularity, will be added asap."),
        dateInput('selectdate',
                  label = paste('Select Month (default = last month)'),
                  value = as.character(Sys.Date()),
                  min = Sys.Date() - 365, max = Sys.Date(),
                  format = "mm/yy",
                  startview = 'year'),
        h2(" "),
        h4(icon("truck", lib="font-awesome"),"Anomalous States"),
        h4(verbatimTextOutput("selectMONTH")),
        tableOutput("anonSTATES")
        ),
    mainPanel(
        h3(icon("map-o", lib="font-awesome"),"Anomalous States Heatmap (by relative incident count)"),
        plotOutput("plotANOM")
    )
  )
)

