### Author: Purva Singh
### Project: 2020- 44 2020-44 Regional Forecast AQC
### Purpose: Apply validation tests to output data to ensure conformity with parameters specified in the Test Plan
### Related Documents: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={65dc7eb6-3ac3-4140-96b7-25c09e5f502d}&action=edit&wd=target%28Test%20Plan.one%7C8d0200b0-42be-45fb-92dd-16395ee1c99c%2FTest%20Plan%7Cfd152376-3142-43da-acf5-0d4073bc605b%2F%29 

### Part 1: Setting up the R environment and loading required packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Loading the packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)


### Part 2: Loading the data

#1. Loading the abm_mgra13_based_input_np

channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=isam; trusted_connection=true')

## population


pop_region<- sqlQuery(channel, 
                      "SELECT count([perid]) as persons,[yr]
                       FROM  [isam].[xpef33].[abm_syn_persons]
                       GROUP BY [yr]")

pop_region$yr_id<- pop_region$yr-1
## households

hh_region_persons<- sqlQuery(channel, 
                      "SELECT count(DISTINCT([hhid])) as hh,[yr]
                       FROM  [isam].[xpef33].[abm_syn_persons]
                       GROUP BY [yr]")


hh_region_hhs<- sqlQuery(channel, 
                     "SELECT count(DISTINCT([hhid])) as hh,[yr]
                       FROM  [isam].[xpef33].[abm_syn_households]
                       GROUP BY [yr]")

hh_region<- merge(hh_region_persons, hh_region_hhs, by= "yr", all= TRUE)

hh_region<- hh_region%>%
  mutate(diff= hh_region$hh.x- hh_region$hh.y, 
         yr_id= yr-1)



## jobs
mgra_np <- sqlQuery(channel, 
                    "SELECT * 
FROM  [isam].[xpef33].[abm_mgra13_based_input_np]"
)

odbcClose(channel)

jobs_region<- mgra_np%>%
  select(emp_total, yr)%>%
  group_by(yr)%>%
  summarise_at(vars(emp_total), sum)

setnames(jobs_region, old = "yr", new= "yr_id")


region_aqc<- merge(jobs_region, pop_region, by = "yr_id", all =  TRUE)


region_aqc<- merge(region_aqc, hh_region, by = "yr_id", all =  TRUE)

region_aqc<- region_aqc%>%
  select(yr_id, emp_total, persons, hh.x)

## adding DS38 numbers

write.xlsx(region_aqc,"C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Results//test 8//region.xlsx")
