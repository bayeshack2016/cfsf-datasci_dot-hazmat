# Hazmat Incident Data Prep
# by Jude Calvillo
# -------------------------------

## Load necessary libraries
library(dplyr)
library(lubridate)

## Read in data
incidents <- read.csv("../Bayes-Hack_DoT-Hazmat/IncidentReports.csv")
print(dim(incidents))

## Filter out rows with duplicate report numbers. These additional rows are useful for incident details,
## but they could mislead our data munging and analysis. I.E. Let's keep this to one incident per report.
incidents <- incidents[!duplicated(incidents$Report.Number),]

## Let's keep only those columns we need.
incidents <- incidents[,c("Incident.State","Date.of.Incident")]

## Convert Date of Incident to useful format, then change all days to "1", because Twitter anomaly detection
## package doesn't recognize purely monthly formats.
incidents$Date.of.Incident <- as.Date(incidents$Date.of.Incident, format = "%m/%d/%Y")
day(incidents$Date.of.Incident) <- 1

## Preview the data
print(head(incidents))

## Rename columns to what Server.R ultimately uses.
names(incidents) <- c("State","Year.Month")

## Group by state, then by date.
incidents <- as.data.frame(summarise(group_by(incidents, State, Year.Month), Report.Number = n()))

## Time-series hack: Make sure each state has an incident count for every month in our records, even if that's
## only zero. We do this by generating a sequence of months
first_month <- min(as.character(incidents$Year.Month))
last_month <- max(as.character(incidents$Year.Month))
all_months <- as.data.frame(
    seq(as.Date(first_month), as.Date(last_month), by = "month")
)
names(all_months)[1] <- "Month"

## For all months between the first month in the data set and the last month in the data set, check to
## ensure that each state has a record of at least zero. If not, then add records where necessary.
for(i in 1:length(levels(incidents$State))){

    ## Subset to current state
    inci_state <- incidents[incidents$State %in% levels(incidents$State)[i],]

    ## If a state subset doesn't include a month from 'all months' dataframe/vector, then add a row
    ## for that month.
    fill_months <- all_months$Month[!(all_months$Month %in% as.Date(inci_state$Year.Month))]

    if(length(fill_months) > 0){

        ## Quick hack for getting format + enough rows for new fill month values
        inci_state_fill <- tail(incidents, length(fill_months))

        ## Replace new rows' State, Year.Months, and Report.Numbers, w/fill months and 0, respectively.
        inci_state_fill$State <- levels(incidents$State)[i]
        inci_state_fill$Year.Month <- as.Date(fill_months)
        inci_state_fill$Report.Number <- 0

        ## Bind to main dataframe
        incidents <- rbind(incidents, inci_state_fill)

    }
    
}

## Reorder Incidents and change Year.Month to Posix, just to make things pretty
incidents <- incidents[order(incidents$State, as.Date(incidents$Year.Month)),]

## Remove incidents without an assigned state (for now)
incidents <- incidents[!(incidents$State %in% ""),]
print(head(incidents))

## Write Prepped Data
write.csv(incidents, "data/hazmat_year_month.csv", row.names = F)