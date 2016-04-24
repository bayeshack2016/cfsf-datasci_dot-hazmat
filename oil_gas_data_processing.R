#
# Script for processing and combining data from 
# Bureau of Land Management, Oil and Gas Statistics
#   http://www.blm.gov/wo/st/en/prog/energy/oil_and_gas/statistics.html
#

library(dplyr)
library(gdata)
library(reshape2)

dat_folder <-    "./Bayes_Hack/Oil_gas/"
output_folder <- "./Bayes_Hack/Oil_gas/clean_data/"

file_list <- list.files(dat_folder, pattern = ".csv")

dat_file <- read.csv("Bayes_Hack/Oil_gas/num_producible_wells_Fed.csv", na.strings = "")

# get rid of X columns
#dat_file <- dat_file %>% select(-contains("X"))

for (file in file_list){
    dat_file <- read.csv(paste0(dat_folder, file))
    dat_file_commas <- apply(dat_file,2, FUN = function(x){gsub(",","", x)}) %>% as.data.frame()
    #write.csv(dat_file_commas, paste0(output_folder, file), row.names = F)
}
    



acres_leased_yr <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_acres_leased_each_yr.csv")
    head(acres_leased_yr)
    cols <- colnames(acres_leased_yr)
    cols_clean <- gsub("FY|\\.","", cols)
    names(acres_leased_yr) <- cols_clean
    #cols_clean_test <- sapply(cols_clean, function(x){paste0("acres_leased_yr_",x)}) %>% as.vector()
    acres_leased_yr_melt <- melt(acres_leased_yr, 
                                 variable.name = "year",
                                 value.name = "num_acres_leased_yr")
    acres_leased_yr_melt[is.na(acres_leased_yr_melt)]  <- 0                      

    rm(acres_leased_yr)

num_drill_permits_approved_yr <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_APDs_approved_Fed_lands.csv") %>%
                                    select(-FY.1984.1.)
    cols <- colnames(num_drill_permits_approved_yr)
    cols_clean <- gsub("FY|\\.[0-9]\\.|\\.","", cols)
    cols_clean
    names(num_drill_permits_approved_yr) <- cols_clean
    num_drill_permits_approved_yr_melt <- melt(num_drill_permits_approved_yr, 
                                               variable.name = "year",
                                               value.name = "num_drill_permits_approved_yr")
    num_drill_permits_approved_yr_melt[is.na(num_drill_permits_approved_yr_melt)] <- 0
    rm(num_drill_permits_approved_yr)
    
#test <- full_join(acres_leased_yr_melt, num_drill_permits_approved_yr_melt, by = c("GeographicState", "year"))


num_leases_in_effect <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_leases_in_effect.csv")
    cols <- colnames(num_leases_in_effect)
    cols_clean <- gsub("FY|\\.","", cols)
    cols_clean
    names(num_leases_in_effect) <- cols_clean    
    num_leases_in_effect_melt <- melt(num_leases_in_effect,
                                      variable.name = "year",
                                      value.name = "num_leases_in_effect")
    num_leases_in_effect_melt[is.na(num_leases_in_effect_melt)] <- 0
    rm(num_leases_in_effect)
    
    
num_new_leases_yr <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_leases_issued_each_yr.csv")    
    cols <- colnames(num_new_leases_yr)
    cols_clean <- gsub("FY|\\.","", cols)
    cols_clean
    names(num_new_leases_yr) <- cols_clean
    num_new_leases_yr_melt <- melt(num_new_leases_yr,
                                   variable.name = "year",
                                   value.name = "num_new_leases_yr")
    num_new_leases_yr_melt[is.na(num_new_leases_yr_melt)] <- 0
    rm(num_new_leases_yr)
    
num_of_producible_completions <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_of_producible_completions.csv") %>%
                                        select(-FY.1984)
    cols <- colnames(num_of_producible_completions)
    cols_clean <- gsub("FY|\\.[0-9]\\.|\\.","", cols)
    cols_clean 
    names(num_of_producible_completions) <- cols_clean
    num_of_producible_completions_melt <- melt(num_of_producible_completions,
                                               variable.name = "year",
                                               value.name = "num_of_producible_completions")
    num_of_producible_completions_melt[is.na(num_of_producible_completions_melt)] <- 0
    rm(num_of_producible_completions)
    
num_of_producible_wells <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_producible_wells_Fed.csv") %>%
    select(-FY.1984)
    cols <- colnames(num_of_producible_wells) 
    cols
    cols_clean <- gsub("FY|\\.[0-9]\\.|\\.","", cols)
    cols_clean
    names(num_of_producible_wells) <- cols_clean
    
    num_of_producible_wells_melt <- melt(num_of_producible_wells,
                                         variable.name = "year",
                                         value.name = "num_of_producible_wells")
    num_of_producible_wells_melt[is.na(num_of_producible_wells_melt)] <- 0
    rm(num_of_producible_wells)
    
num_producing_acres <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_producing_acres.csv") %>%
    select(-FY.1984)
    cols<- colnames(num_producing_acres)
    cols_clean <- gsub("FY|\\.","", cols)
    cols_clean
    names(num_producing_acres) <- cols_clean
    
    num_producing_acres_melt <- melt(num_producing_acres,
                                     variable.name = "year",
                                     value.name = "num_producing_acres")
    num_producing_acres_melt[is.na(num_producing_acres_melt)] <- 0
    rm(num_producing_acres)
    
num_producing_leases <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_producing_leases.csv") %>%
                        select(-FY.1984)
    cols <- colnames(num_producing_leases)
    cols
    cols_clean <- gsub("FY|\\.","", cols)
    cols_clean
    
    names(num_producing_leases) <- cols_clean
    num_producing_leases<- num_producing_leases %>%rename('2015' = X2015)
    num_producing_leases_melt <- melt(num_producing_leases,
                                      variable.name = "year",
                                      value.name = "num_producing_leases")
    num_producing_leases_melt[is.na(num_producing_leases_melt)] <- 0
    rm(num_producing_leases)
    
num_wells_spudded_yr <- read.csv("Bayes_Hack/Oil_gas/clean_data/num_wells_spudded_Fed.csv") %>%
    select(-FY.1984.1.)

    head(num_wells_spudded_yr)
    cols <- colnames(num_wells_spudded_yr)
    cols_clean <- gsub("FY|\\.[0-9]\\.|\\.","", cols)
    cols_clean
    names(num_wells_spudded_yr) <- cols_clean
    num_wells_spudded_yr_melt <- melt(num_wells_spudded_yr,
                                      variable.name = "year",
                                      value.name = "num_wells_spudded_yr")
    num_wells_spudded_yr_melt[is.na(num_wells_spudded_yr_melt)] <- 0
    rm(num_wells_spudded_yr)

num_acres_leased <- read.csv("Bayes_Hack/Oil_gas/clean_data/total_num_acres_leased.csv")
    
    cols <- colnames(num_acres_leased)
    cols_clean <- gsub("FY|\\.[0-9]\\.|\\.","", cols)
    cols_clean
    names(num_acres_leased) <- cols_clean
    num_acres_leased_melt <- melt(num_acres_leased,
                                  variable.name = "year",
                                  value.name = "num_acres_leased")
    rm(num_acres_leased)
    
    num_acres_leased_melt[is.na(num_acres_leased_melt)] <- 0
    
    
    
    
    all_variables <- full_join(acres_leased_yr_melt, 
                               num_acres_leased_melt, 
                               by = c("GeographicState", "year"))
    #all_variables<- full_join(all_variables,
                           #    num_drill_permits_approved_yr_melt,
                          #    by = c("GeographicState", "year"))
    all_variables<- full_join(all_variables,
                               num_leases_in_effect_melt,
                              by = c("GeographicState", "year"))
    all_variables<- full_join( all_variables,
                               num_new_leases_yr_melt,
                               by = c("GeographicState", "year"))
    all_variables<- full_join(all_variables,
                               num_of_producible_wells_melt,
                              by = c("GeographicState", "year"))
    
    all_variables <- full_join(all_variables,
                               num_of_producible_completions_melt,
                               by = c("GeographicState", "year"))
    
    all_variables<- full_join(all_variables,
                               num_producing_acres_melt,
                              by = c("GeographicState", "year"))
    
    all_variables <- full_join(all_variables,
                               num_producing_leases_melt,
                               by = c("GeographicState", "year"))
    
    all_variables <- full_join(all_variables,
                               num_wells_spudded_yr_melt,
                               by = c("GeographicState", "year"))
    
    
    all_variables <- all_variables %>% filter(year != 1984) %>%
                        rename(state = GeographicState) %>%
                        mutate(state = as.character(state))
    
    str(all_variables)
    write.csv(all_variables, "oil_gas_clean.csv", row.names = F)
    
    