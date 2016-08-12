## Shiny + R Anomaly App for the U.S. Dept. of Transportation
## By Jude Calvillo (Data Science Working Group @ Code for San Francisco)
##
## Status: August 11, 2016:
## ---------------------
## v1.6 - Just news left.
##
## - About 90% done now! Map interactivity complete, thereby updating anomaly plotting and UI.
## - Just need to integrate a news feed drawn from an API query (e.g. "hazmat incident/accident"
##   + selected state + selected month).
##
## ----------------------------------
##

library(shiny)
library(leaflet)
library(lubridate)

shinyUI(fluidPage(theme = "style2.css",
                  # Customizing background.
                  list(tags$head(tags$style("body {background-image: url('http://www.sovereignmarket.com/app-assets/tunnel-background_dot9.jpg');
                  color: #333333; center repeat-x;}"))),
fluidRow(
    div(h1(" "), align="center"),
    div(
        h1(img(src="dot-logo2s.png", align="absmiddle"),
           "U.S. Dept. of Transportation: Hazmat Incident Anomaly Detector"), align="center"),
    div(h1(" "), align="center")
    ),
sidebarPanel(
    style = "background:transparent;border-color:#ffffff;box-shadow: 10px 10px 10px #cccccc;",
    p("This app helps DoT executives identify which states exhibited monthly hazmat incident totals that
      were -truly- anomalous to their respective norms. Please select your month of concern below."),
    dateInput('selectdate',
              label = paste('Select Month'),
              value = as.Date(cut(Sys.Date(), "month")) - months(1),
              min = Sys.Date() - 1825, max = as.Date(cut(Sys.Date(), "month")) - months(1), 
              format = paste0("mm/", "01", "/yy"),
              startview = 'year'),
    h2(" "),
    h4(icon("truck", lib="font-awesome"),"Anomalous States"),
    tableOutput("anonSTATES")
    ),
mainPanel(
    h3(style="color:#000000;", icon("map-o", lib="font-awesome"),"Anomalous States Heatmap"),
    leafletOutput("theMAP"),
    h2(" "),
    column(6, uiOutput("plotHEAD"),
            plotOutput("plotANOM")),
    column(6, uiOutput("newsHEAD"),
           h2(" "),
           h2(" "),
           p("Awaiting state selection...")
            # includeHTML("www/rss-feed_sample.html")
           ),
    column(12, "Developed by", a("Jude Calvillo", href="http://linkd.in/vVlpXA"), "-", a("Data Science Working Group @ Code for San Francisco", 
                                                                                         href="http://datascience.codeforsanfrancisco.org"),
            h2(" "),
            h2(" "))
    )
  )
)
