## Hazmat Incident Anomaly Detection App (R + Shiny + Leaflet) for the U.S. Dept. of Transportation
## By Jude Calvillo (Data Science Working Group @ Code for San Francisco)
##
## Status: August 14, 2016:
## ---------------------
## v1.7 - News feed API incorporated. News search query and formatting refinements remain.
## 
## - About 95% done now! 
## - Map interactivity complete and per-state anomaly plotting complete.
## - News feed API (Microsoft Cognitive Services) now incorporated. 
## - Have to refine my use of advanced operators in news feed request URL.
## - Have to refine formatting of news results for UI (MS's API offers HTML formatting). 
## - I should probably embed the news into a scrolling widget.
## 
## - For the future: Since Shiny doesn't offer a month picker widget, if we want to make the month selection
##   quicker and easier to understand, we'll have to use straight HTML/javascript. This jQuery UI seems
##   perfect for the job: https://kidsysco.github.io/jquery-ui-month-picker/
##       - For my own notes: Pay particular attention to the Month Format and Month Parsing options...
##              - https://api.jqueryui.com/datepicker/##utility-formatDate (we want to extract the month
##                in ISO format: $.datepicker.parseDate( "yy-mm-dd", "2007-01-26" );)
## 
## - Also for the future: Some U.S. territories, like Puerto Rico, are in the DoT's hazmat incident report
##   records, but, of course, they're not within the contiguous United States. If Dan @ DoT confirms that
##   they'd also like to see anomolous territories in this app, we'll need a different polygons dataset
##   (i.e. not "state" from 'maps' library).
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
              label = paste('Step 1: Select Month'),
              
              # # temp default val and date range (because our data pull only goes up to April, 2016, ...for now)
              # value = as.Date(cut(Sys.Date(), "month")) - months(6),
              # min = Sys.Date() - 1825, max = as.Date(cut(Sys.Date(), "month")) - months(6), 
              
              # the REAL val and date range (once we have the data)
              value = as.Date(cut(Sys.Date(), "month")) - months(1),
              min = Sys.Date() - 1825, max = as.Date(cut(Sys.Date(), "month")) - months(1),
              
              format = paste0("mm/", "01", "/yy"),
              startview = 'year'),
    h2(" "),
    h4(icon("truck", lib="font-awesome"),"Anomalous States"),
    tableOutput("anonSTATES"),
    h2(" "),
    h2(" "),
    p(style="font-weight:bold;","Step 2: Select State for Context >"),
    h2(" ")
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
           tableOutput("newsCONTENT")
            # includeHTML("www/rss-feed_sample.html")
           ),
    column(12, "Developed by", a("Jude Calvillo", href="http://linkd.in/vVlpXA"), "-", a("Data Science Working Group @ Code for San Francisco", 
                                                                                         href="http://datascience.codeforsanfrancisco.org"),
            h2(" "),
            h2(" "))
    )
  )
)
