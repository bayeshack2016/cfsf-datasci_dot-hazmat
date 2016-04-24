# DISCLAIMER - THIS IS AN UGLY YET BEAUTIFUL SCRIPT - ENJOY

library(dplyr)
library(plyr)
gdp <- read.csv("~/Documents/Data/Fun/gdp.csv")
View(gdp)

names <- names(gdp)
names(gdp) <- sub('X' , '', names)

gdp$industry <- sub('          ' , '' , gdp$Industry)

summary(gdp)

head(gdp)

gdp.clean <- select(gdp, 1:19)


library(reshape)

gdp.clean <- melt(gdp.clean, id=c("Fips","Area","IndCode","Industry"))

head(gdp.clean)

names <- names(gdp.clean)
names <- names(gdp.clean) <- sub('variable' , 'Year', names)
names <- names(gdp.clean) <- sub('value' , 'GDP', names)
names(gdp.clean)

head(gdp.clean , n=200)
str(gdp.clean)
# gdp.clean %>% mutate(GDP = GDP*1000000)

registeredvehicles2 <- read.csv("~/Documents/registeredvehicles.csv")
View(registeredvehicles)
summary(registeredvehicles)
str(registeredvehicles2)
head(registeredvehicles)
registeredvehicles2$YEAR <- as.factor(registeredvehicles2$YEAR)
registeredvehicles2$STATE <- sub('\xca' , '', registeredvehicles2$STATE)
registeredvehicles2$STATE <- sub('  ' , '', registeredvehicles2$STATE)
registeredvehicles$STATE <- sub(' ' , '', registeredvehicles$STATE)
registeredvehicles2$STATE

trim.trailing <- function (x) sub("\\s+$", "", registeredvehicles2$STATE)
registeredvehicles2$STATE <- trim.trailing(registeredvehicles2$STATE)

registeredvehicles <- registeredvehicles2
names <- names(registeredvehicles2)
names <- names(registeredvehicles) <- sub('YEAR' , 'Year', names)
names <- names(registeredvehicles) <- sub('STATE' , 'State', names)
names


head(registeredvehicles)
head(gdp.clean)

library(sqldf)

## inner join
df3 <- sqldf("SELECT a.* , b.*
             FROM registeredvehicles a
             LEFT JOIN 'gdp.clean' b  on (a.Year = b.Year AND a.State = b.Area)")
head(df3)
View(df3)

mergedWade <- merge(registeredvehicles, gdp.clean, by.registeredvehicles=c("Year", "State"), by.gdp.clean=c("Year", "Area"))
mergedWade2 <- left_join(registeredvehicles, gdp.clean, by = c("Year" = "Year", "State" = "Area"))
head(mergedWade2)
View(mergedWade2)


GDPANDMOTOR <- df3

write.csv(GDPANDMOTOR, file = "gdpandmotor.csv")



USStatePopulation <- read.csv("~/Documents/USStatePopulation.csv")
View(USStatePopulation)

names <- names(USStatePopulation)
names <- names(USStatePopulation) <- sub('X' , '', names)
names <- names(USStatePopulation) <- sub('Estimates.Base' , 'Population', names)
head(USStatePopulation)


USStatePopulation <- melt(USStatePopulation, id=c("State","Census","Population"))
head(USStatePopulation)
names <- names(USStatePopulation)
names <- names(USStatePopulation) <- sub('variable' , 'Year', names)
names <- names(USStatePopulation) <- sub('value' , 'Year_Population', names)
View(USStatePopulation)
population <- USStatePopulation
write.csv(USStatePopulation, file = "population.csv")

head(population)

head(df3)
df4 <- sqldf("SELECT a.* , b.* , c.*
             FROM registeredvehicles a
             LEFT JOIN 'gdp.clean' b  on (a.Year = b.Year AND a.State = b.Area)
             LEFT JOIN 'population' c  on (a.Year = c.Year AND a.State = c.State)")
head(df4)
ncol(df4)
select(df4 , 1:27)

mergedWade3 <- left_join(mergedWade2, population, by = c("Year" = "Year", "State" = "State"))
head(mergedWade3)
ncol(mergedWade3)
mergedWade4 <- select(mergedWade3 , 1:(ncol(mergedWade3)-3) , contains("Year_Population"))

Merge <- mergedWade4 %>%
  filter(!grepl('Oil and gas extraction', Industry)) %>%
  filter(!grepl('Dist. of Col.', State))

head(Merge , n=100)


write.csv(Merge, file = "population_gdp_vehicles.csv")


Inflation_Oil_Gas <- read.csv("~/Downloads/Inflation_Oil_Gas.csv")

head(Inflation_Oil_Gas)
str(Inflation_Oil_Gas)
Inflation_Oil_Gas$Year <- as.character(Inflation_Oil_Gas$Year)
str(Merge)
Merge2 <- left_join(Merge, Inflation_Oil_Gas, by = c("Year" = "Year", "State" = "State"))
head(Merge2)
str(Merge2)

write.csv(Merge2, file = "population_gdp_vehicles_inflation_oil_gas.csv")

Merge3 <- Merge2[, -which(names(Merge2) %in% c("State", "Industry","Year", "IndCode"))]
cor(Merge3)
M <- cor(Merge3)
library(corrplot)
corrplot(M,method="number")

state_name_map <- read.csv("~/Downloads/state_name_map.csv")
View(state_name_map)

MergedCode <- left_join(Merge2, state_name_map, by = c("State" = "State"))
head(MergedCode)
MergedCode2 <- MergedCode[, -which(names(MergedCode) %in% c("Abbreviation"))]


write.csv(MergedCode2, file = "KatherineMergeThis.csv")

largemerge_dropDC <- read.csv("~/Downloads/largemerge_dropDC.csv")
`oil_gas_stats_clean.(1)` <- read.csv("~/Downloads/oil_gas_stats_clean (1).csv")
`hazmat_incidents_by_state_and_year.(1)` <- read.csv("~/Downloads/hazmat_incidents_by_state_and_year (1).csv")
hazmat <- `hazmat_incidents_by_state_and_year.(1)`
View(hazmat)
oil <- `oil_gas_stats_clean.(1)`
trim.trailing <- function (x) sub("\\s+$", "", oil$state)
oil$state <- trim.trailing(oil$state)
head(oil)
head(largemerge_dropDC)
View(oil)
MergedOil <- left_join(oil, state_name_map, by = c("state" = "State"))
head(MergedOil)
View(MergedOil)
head(hazmat)
MergedOil <- MergedOil[, -which(names(MergedOil) %in% c("Abbreviation"))]
FinalMerge <- full_join(largemerge_dropDC, MergedOil, by = c("Year" = "year","Postal.Code" = "Postal.Code"))
head(FinalMerge)
str(FinalMerge)
View(FinalMerge)
FinalMerge <- FinalMerge[, -which(names(FinalMerge) %in% c("Industry", "IndCode"))]
FinalMerge2 <- outer_join(FinalMerge, hazmat, by = c("Postal.Code" = "State"))
head(FinalMerge2)
str(FinalMerge2)
summary(FinalMerge2)

write.csv(FinalMerge, file = "GoldenTable.csv", row.names = FALSE)

MergedOil <- filter(MergedOil , year >= 2000)
View(MergedOil)
View(largemerge_dropDC)
View(FinalMerge2)

all_data_merge <- read.csv("~/Downloads/all_data_merge.csv")
View(all_data_merge)
all_data_merge <- all_data_merge[, -which(names(all_data_merge) %in% c(""))]


d <- left_join(MergedOil, hazmat, by = c("Postal.Code" = "State", "year"))
View(d)
head(d,100)


MergedEmployment <- left_join(employment, state_name_map, by = c("State" = "State"))
View(MergedEmployment)

d <- left_join(d, MergedEmployment, by = c("Postal.Code" = "Postal.Code", "year" = "Year"))
View(d)
head(d,10)

d <- select(d , -state)

lm <- lm(number_of_hazardous_incidents~. , data = d)
summary(lm)
