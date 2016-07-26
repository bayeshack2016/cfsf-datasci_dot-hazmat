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

## Load necessary libraries and datasets.
library(shiny)
library(AnomalyDetection)
library(leaflet)
library(maps)

## Get the data (loading it later for faster initial load)
dat <- read.csv("data/hazmat_year_month.csv")

## Factorize state
dat$State <- as.factor(dat$State)

## Get months and convert to Posix.
dat$Year.Month = paste(dat$Year.Month,'01',sep='-')
dat$Year.Month = as.POSIXct(strptime(dat$Year.Month, "%Y-%m-%d"))

## Create empty dataframe
res_df <- data.frame()

## Run each state's data through anomaly detection
for(i in 1:length(levels(dat$State))){
    res <- AnomalyDetectionTs(dat[dat$State %in% levels(dat$State)[i],c("Year.Month","Report.Number")], max_anoms=0.05, 
                              direction='pos', plot=T)
    per_state <- res$anom
    per_state$state <- rep(levels(dat$State)[i], nrow(per_state)) # Quick and dirty solution here.
    res_df <- rbind(res_df, per_state)
}

## List anomolous states
names(res_df)[2:3] <- c("Incidents","State")
res_df2 <- head(res_df[c(3,2)]) # just for testing

## Select and render the map
mapStates = map("state", fill = TRUE, plot = FALSE)
the_map <- leaflet(data = mapStates) %>% addTiles() %>%
    addPolygons(fillColor = "#cc0000", fillOpacity = res_df2$Incidents * .01, stroke = FALSE)

## Initiate Shiny Server instance.
shinyServer(
    function(input, output){
        
        ## Simply show the user the value they chose.
        output$selectMONTH <- renderText({paste("For", months(as.Date(input$selectdate)), 
                                                        format(input$selectdate, "%Y"))})
        
        ## Show anomolous states (preview / proof of concept)
        output$anonSTATES <- renderTable({res_df2})
        
        ## Show map
        output$theMAP <- renderLeaflet({the_map})
        
        ## Render first plot (basic anomaly plot for the last / feature state)
        output$plotANOM <- renderPlot({res$plot}, height = 280)
  
        }
    )

