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

## Load necessary libraries and datasets.
library(shiny)
library(AnomalyDetection)
library(lubridate)
library(dplyr)
library(maps)
library(ggplot2)

## Get the data (loading it later for faster initial load)
dat <- read.csv("data/hazmat_year_month.csv")

## States lookup table (to deal w/maps subsetting issue)
states_lookup <- data.frame()
states_lookup[1:50,] <- NA
states_lookup$State <- state.name
states_lookup$State.Abb <- state.abb

## Factorize state
dat$State <- as.factor(dat$State)

# Currently, in order to make this all work, we have to filter out those territories not in the
# states_lookup dataset. We'll fully map everything out later (between dat, mapState$States, and state abbreviations)]

## Get months and convert to Posix.
dat$Year.Month = paste(dat$Year.Month,'01',sep='-')
dat$Year.Month = as.POSIXct(strptime(dat$Year.Month, "%Y-%m-%d"))

## For later
dat2 <- data.frame(State = character(), Year.Month = as.POSIXlt(character()), Report.Number = integer())

## Create empty dataframe
res_df <- data.frame(timestamp = as.POSIXlt(character()), anoms = integer(), state = character())

## So as not to corrupt local testing
res_df2 <- data.frame()

## Load the map polygons and reformat names a bit (for cross ref)
mapStates <- map("state", fill = TRUE, plot = FALSE)
mapStates$names <- sub(":main","", mapStates$names)

## Pre-popped data frame, in line w/maps' "states" name ordering and proper shading in Leaflet
anom_map_states <- data.frame(State = character(), State.Abb = character(), Incidents = integer(),
                              Median = integer(), Low = integer(), High = integer())
anom_map_states[1:length(mapStates$names),] <- NA
anom_map_states$State <- mapStates$names
anom_map_states$State.Abb <- as.character(anom_map_states$State.Abb)
anom_map_states[anom_map_states$State %in% tolower(states_lookup$State), "State.Abb"] <- states_lookup[tolower(states_lookup$State) %in% 
                                                                                                           mapStates$names, "State.Abb"]
anom_map_states$Incidents <- 0

## To load up anomaly plots
res_plots <- list()

## Initiate Shiny Server instance.
shinyServer(
    function(input, output){
        
        ## React to the selected date/month by subsetting to chosen month - 5 years before, then running
        ## anomaly detection and filtering to this month. 
        the_anoms <- reactive({
            
            ## To format any date selected to the first of that month
            ## (for proper ref w/dataset) - Temp solution, until I can create a sort of 'month picker' for Shiny
            the_first <- input$selectdate
            day(the_first) <- 1
            
            ## Have to create 5 years back date as character because base won't take in
            yrs_back_5 <- as.Date(the_first) - years(5)
            dat2 <- dat[(dat$Year.Month >= as.character(yrs_back_5)) & (dat$Year.Month <= as.character(the_first)),]
            
            ## Run each state's data through anomaly detection
            for(i in 1:length(levels(dat2$State))){
                res <- AnomalyDetectionTs(dat2[dat2$State %in% levels(dat2$State)[i],c("Year.Month","Report.Number")], max_anoms=0.05,
                                          direction='pos', plot=T)
                per_state <- res$anom
                per_state$state <- rep(levels(dat2$State)[i], nrow(per_state)) # Quick and dirty solution here.
                res_df <- rbind(res_df, per_state)
            }
            names(res_df)[2:3] <- c("Incidents","State")
            res_df2 <- res_df
            
            ## Filter to selected month's states.
            res_df2 <- res_df2[res_df2$timestamp %in% as.character(the_first), c("State", "Incidents")]
            if(nrow(res_df2) > 0){
                sum_stats <- summarise(group_by(dat2[dat2$State %in% res_df2$State,], State), Median = median(Report.Number), 
                                       Low = min(Report.Number), High = max(Report.Number))
                res_df2 <- cbind(res_df2, sum_stats[,-1])
            }
            res_df2
            
        })
        
        
        ## Extract plot, from stored plots, that's reactive to map/state selection
        anom_plot <- reactive({
            
            if(is.null(input$theMAP_shape_click$id)){
                
                wait_message <- paste("Awaiting state selection...")
                
                ggplot() + 
                    annotate("text", x = -5:0, y = 0:5, size=8, label = "") + 
                    annotate("text", x = -2.5, y = 2.5, label = wait_message) +
                    
                    theme_bw() + theme(panel.grid.major=element_blank(), panel.grid.minor=element_blank()) +
                    xlab("Years (-5 ---> | Selected Year)") + ylab("Incidents")
                
            } else {
                
                ## Lookup state abbreviation
                selected_state <- states_lookup$State.Abb[tolower(states_lookup$State) %in% input$theMAP_shape_click$id]
                
                ## Reformat selected date to 1st of the month
                the_first <- input$selectdate
                day(the_first) <- 1
                
                ## Have to create 5 years back date as character because base won't take in
                yrs_back_5 <- as.Date(the_first) - years(5)
                dat2 <- dat[(dat$Year.Month >= as.character(yrs_back_5)) & (dat$Year.Month <= as.character(the_first)),]
                
                ## Run selected state's data through anomaly detection, to get plots
                state_anom <- AnomalyDetectionTs(dat2[dat2$State %in% selected_state, c("Year.Month","Report.Number")], 
                                                max_anoms=0.05, direction='pos', plot=T)
                print(state_anom$plot)
            }
            
        })

        ## Show anomolous states (preview / proof of concept)
        output$anonSTATES <- renderTable({the_anoms()}, include.rownames=FALSE)
        
        ## Show map
        output$theMAP <- renderLeaflet({
            
            ## Replace zeroed out states dataframe w/anomalous states' values where states match
            anom_map_states[anom_map_states$State.Abb %in% the_anoms()$State, -1] <- the_anoms()
            
            ## Polygons and layerIds from mapStates
            leaflet(data = mapStates) %>% addTiles() %>%
            addPolygons(fillColor = "#cc0000", fillOpacity = anom_map_states$Incidents * .01, 
                        layerId = mapStates$names, stroke = FALSE)
            
            })
        
        # Render timeline + anomalies plot for selected month
        output$plotANOM <- renderPlot({anom_plot()}, height = 280)
        
        # Render reactive anomaly plot heading UI
        output$plotHEAD <- renderUI({
            
                if(is.null(input$theMAP_shape_click$id)){
                    print(h4(style="color:#000000;", icon("clock-o", lib="font-awesome"), "Incident Timeline for State (Month - 5yrs)"))
                             
                } else {
                    print(h4(style="color:#000000;", icon("clock-o", lib="font-awesome"), 
                             paste("Incident Timeline for", states_lookup$State[tolower(states_lookup$State) %in% input$theMAP_shape_click$id],
                                   "(Month - 5yrs)")))
                }
            
            })
        
        # Render reactive news heading UI
        output$newsHEAD <- renderUI({
            
            if(is.null(input$theMAP_shape_click$id)){
                
                print(h4(style="color:#000000;", icon("newspaper-o", lib="font-awesome"), "Hazmat News for Selected State @ Month"))
                
            } else {
                
                print(h4(style="color:#000000;", icon("newspaper-o", lib="font-awesome"), 
                         paste("Hazmat News for", states_lookup$State[tolower(states_lookup$State) %in% input$theMAP_shape_click$id], "@ Month")))
            }
            
        })
  
        }
    )

