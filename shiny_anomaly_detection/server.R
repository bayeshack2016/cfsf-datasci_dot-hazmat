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

## Load necessary libraries and datasets.
library(shiny)
library(AnomalyDetection)
# library(ggplot2) # I MIGHT have to use GGplot later.
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
                              direction='both', plot=T)
    per_state <- res$anom
    per_state$state <- rep(levels(dat$State)[i], nrow(per_state)) # Quick and dirty solution here.
    res_df <- rbind(res_df, per_state)
}

## Initiate Shiny Server instance.
shinyServer(
    function(input, output){
    
        ## Simply show the user the value they chose.
        output$selectNUM <- renderText({paste(input$month, "MONTH")})
        
        ## Render first plot (basic anomaly plot for the last / feature state)
        output$plotANOM <- renderPlot({res$plot})
  
        }
    )

