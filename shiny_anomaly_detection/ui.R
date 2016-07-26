## Shiny + R Anomaly App for the U.S. Dept. of Transportation
## By Jude Calvillo (Data Science Working Group @ Code for San Francisco)
##
## Status: July 26, 2016:
## ---------------------
## v1.12 - Starting to add functionality and interactivity
##
## - UI's tableOutput now working and soon to be reactive
## - SERVER's Leaflet map rendering now working, with variable polygon opacity, and soon to be reactive
## - Need to make both of the above reactive to user's month selection
## - Need to make state-specific incident timeline and summary (bottom columns) reactive to user's 
##   Leaflat map clicks
##
## ----------------------------------
##

library(shiny)
library(leaflet)

shinyUI(pageWithSidebar(
headerPanel("U.S. Dept. of Transportation: Hazmat Incident Anomaly Detector"),
sidebarPanel(
    p("This app helps DoT executives identify which states exhibited monthly hazmat incident totals that
      were -truly- anomalous to their respective norms. Please select your month of concern below.
      More state-by-state features."),
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
    # verbatimTextOutput("anonSTATES")
    ),
mainPanel(
    h3(icon("map-o", lib="font-awesome"),"Anomalous States Heatmap"),
    leafletOutput("theMAP"),
    h2(" "),
    column(6, h4(icon("clock-o", lib="font-awesome"),"Selected State's Incident Timeline"),
            plotOutput("plotANOM")),
    column(6, h4(icon("info", lib="font-awesome"),"Selected State's Summary Info"),
            h2(" "), 
            p("This area will soon display some summary stats, like total and average incident counts for the last year (vs. total and average for other states)"))
    )
  )
)

