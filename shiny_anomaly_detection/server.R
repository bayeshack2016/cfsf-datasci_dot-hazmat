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

## Load necessary libraries and datasets.
library(shiny)
library(AnomalyDetection)
library(lubridate)
library(dplyr)
library(maps)

## Get the data (loading it later for faster initial load)
dat <- read.csv("data/hazmat_year_month.csv")

## Factorize state
dat$State <- as.factor(dat$State)

# Currently, in order to make this all work, we have to filter out those territories not in the
# states_lookup dataset. We'll map everything out later (between dat, mapState$States, and state abbreviations)
# ! Wait. This doesn't really work, either. Ok, coming soon!
# dat <- dat[dat$State %in% state.abb,]

## Get months and convert to Posix.
dat$Year.Month = paste(dat$Year.Month,'01',sep='-')
dat$Year.Month = as.POSIXct(strptime(dat$Year.Month, "%Y-%m-%d"))

## For later
dat2 <- data.frame(State = character(), Year.Month = as.POSIXlt(character()), Report.Number = integer())

## Create empty dataframe
res_df <- data.frame(timestamp = as.POSIXlt(character()), anoms = integer(), state = character())

## So as not to corrupt local testing
res_df2 <- data.frame()

## States lookup table (to deal w/maps subsetting issue)
states_lookup <- data.frame()
states_lookup[1:50,] <- NA
states_lookup$State <- state.name
states_lookup$State.Abb <- state.abb

## Load the map polygons and reformat names a bit (for cross ref)
mapStates <- map("state", fill = TRUE, plot = FALSE)
mapStates$names <- sub(":main","", mapStates$names)

# ## Pre-popped data frame, in line w/maps' "states" name ordering and proper shading in Leaflet
# anom_map_states <- data.frame(State = character(), State.Abb = character(), Incidents = integer(),
#                               Median = integer(), Low = integer(), High = integer())
# anom_map_states[1:50,] <- NA
# anom_map_states$State <- state.name
# anom_map_states$State.Abb <- state.abb
# anom_map_states$Incidents <- 0

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
            
            ## To format any date selected to the first of that month
            ## (for proper ref w/dataset) - Temp solution, until I can create a sort of 'month picker' for Shiny
            the_first <- input$selectdate
            day(the_first) <- 1
            
            ## Have to create 5 years back date as character because base won't take in
            yrs_back_5 <- as.Date(the_first) - years(5)
            dat2 <- dat[(dat$Year.Month >= as.character(yrs_back_5)) & (dat$Year.Month <= as.character(the_first)),]
            
            ## Run selected state's data through anomaly detection, to get plots
            sel_state <- AnomalyDetectionTs(dat2[dat2$State %in% input$selectstate, c("Year.Month","Report.Number")], max_anoms=0.05,
                                            direction='pos', plot=T)
            print(sel_state$plot)
            
        })

        ## Show anomolous states (preview / proof of concept)
        output$anonSTATES <- renderTable({the_anoms()}, include.rownames=FALSE)
        
        ## Show map
        output$theMAP <- renderLeaflet({
            
            ## Replace zeroed out states dataframe w/anomalous states' values where states match
            anom_map_states[anom_map_states$State.Abb %in% the_anoms()$State, -1] <- the_anoms()
            
            
#             ##!! Left to do Order anom map states DF to match mapStates' states order
#             anom_map_states <- anom_map_states[order()]
            
            leaflet(data = mapStates) %>% addTiles() %>%
            addPolygons(fillColor = "#cc0000", fillOpacity = anom_map_states$Incidents * .01, stroke = FALSE)
            
            })
        
        # Render timeline + anomalies plot for selected month
        output$plotANOM <- renderPlot({anom_plot()}, height = 280)
  
        }
    )

