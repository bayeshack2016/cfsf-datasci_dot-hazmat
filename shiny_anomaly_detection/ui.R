## Shiny + R Anomaly App for the U.S. Dept. of Transportation
## By Jude Calvillo (Data Science Working Group @ Code for San Francisco)
##
## Status: August 10, 2016:
## ---------------------
## v1.5 - Leaflet/map plotting issues fixed. Just need to add map interactivity now (and news!)
##
## - UI's tableOutput now reactive and includes summary stats.
## - I'd like to now include a news feed in the area formerly dedicated to summary stats, one that shows 
##   hazmat-related news stories from the anomolous states for the selected month. :)
## - Applied a bootstrap theme to pretty things up a bit, BUT it's hurt the readability of the date input.
## - Apparently, there's no such thing as a purely by "month" date input widget, which makes date selection 
##   a little confusing. For now, any date selected gets converted to the first of that month.
## - Anomolous state-specific and date-range specific timeline plot, with anomalies highlighted, 
##   now reactive to user input.
## - Leaflet map rendering and anomalous state filling now working properly (yay!).
## - Need to 'interact' with user's Leaflet map selection for specifying state to plot and summarize.
## - Using state.abb for testing reactive input to state specific anomaly detection and plotting, BUT
##   there seems to be a bug: only some states produce a plot. Hopefully, that's just due to some mismatch
##   between the state.abb values and the State values in dat/dat2 (main data frames).
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
              label = paste('Select Month (for testing, try 07/01/14)'),
              value = as.Date(cut(Sys.Date(), "month")) - months(1),
              min = Sys.Date() - 1825, max = as.Date(cut(Sys.Date(), "month")) - months(1), 
              format = paste0("mm/", "01", "/yy"),
              startview = 'year'),
    h2(" "),
    h4(icon("truck", lib="font-awesome"),"Anomalous States"),
    tableOutput("anonSTATES"),
    selectInput('selectstate', label = "Select State (test)", choices = state.abb) # temporary, for testing
    ),
mainPanel(
    h3(style="color:#000000;", icon("map-o", lib="font-awesome"),"Anomalous States Heatmap"),
    leafletOutput("theMAP"),
    h2(" "),
    column(6, h4(style="color:#000000;", icon("clock-o", lib="font-awesome"),"Incident Timeline for State (Month - 5yrs)"),
            plotOutput("plotANOM")),
    column(6, h4(style="color:#000000;", icon("info", lib="font-awesome"),"Hazmat News for Selected State + Month"),
            h2(" "), 
            p(style="color:#000000;", "This area will soon display a feed of hazmat-related news from the selected state and for the given month. This should provide explanatory context.")),
    column(12, "Developed by", a("Jude Calvillo", href="http://linkd.in/vVlpXA"), "-", a("Data Science Working Group @ Code for San Francisco", href="http://datascience.codeforsanfrancisco.org"),
            h2(" "),
            h2(" "))
    )
  )
)
