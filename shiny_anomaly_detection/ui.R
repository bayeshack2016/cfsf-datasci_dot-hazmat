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
headerPanel("DoT Hazmat Anomaly Detector"),
    sidebarPanel(
        p("This app helps DoT executives identify which states exhibited a hazmat incident frequency that was
            was anomalous to their respective norms."),
        sliderInput("month", label ="Random Slider :)", value = 1, min = 1, max = 12)
        ),
    mainPanel(
        h3(icon("truck", lib="font-awesome"),"Last Month's Anomalous States"),
        h4(verbatimTextOutput("selectNUM")),
        plotOutput("plotANOM")
    )
  )
)

