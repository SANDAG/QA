#Project ID: 2021-06 Estimates 2020 QC
#Author: Purva Singh
# Project SME: Rachel Cortes (EDAM)
# This script is for 'part a' of test 1,2,3,4,5,9,and 10 of the test plan- comparing SANDAG estimates to dof estimates. 
### The test plan can be found here: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc=%7B93d68e8d-b118-4932-ad8a-676a6eaa6727%7D&action=edit&wd=target%28Untitled%20Section.one%7Cc92109e3-f882-46aa-b8de-d792c848c78f%2FTest%20Plan%7C334fc90e-fa5e-4158-b204-8ff549abc103%2F%29 


### Part 1: Setting up the R environment and loading packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse", "rio")
pkgTest(packages)

### Part 2: Loading the required datasets

# loading the DOF data from the database 

channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=socioec_data; trusted_connection=true')

dof<- sqlQuery(channel, "SELECT * 
  FROM [socioec_data].[ca_dof].[population_housing_estimates]
  WHERE vintage_yr= 2020 AND county_name = 'San Diego'")  

odbcClose(channel)

# loading the mgra dim table from the database

channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=estimates; trusted_connection=true')

mgra<- sqlQuery(channel, "SELECT [mgra_id], [cpa], [jurisdiction], [zip] 
    FROM [estimates].[est_2020_01].[mgra_id]")  

# loading the estimates 2020 pop, housing, and household datasets from the database 
pop_db<- sqlQuery(channel, "SELECT * 
    FROM [estimates].[est_2020_01].[dw_population]") 
hh_db<- sqlQuery(channel, "SELECT * 
    FROM [estimates].[est_2020_01].[dw_households]") 
hu_db<- sqlQuery(channel, "SELECT * 
    FROM [estimates].[est_2020_01].[dw_housing]") 
odbcClose(channel)


### Part 3: Preparing the data for analysis

# merging pop, hh, and hu with mgra dataset on mgra_id for aggregation--2020 estimates

pop<- merge(pop_db, mgra, by= "mgra_id", all= TRUE)
hh<- merge(hh_db, mgra, by= "mgra_id", all= TRUE)
hu<- merge(hu_db, mgra, by= "mgra_id", all= TRUE)

rm(pop_db, hh_db, hu_db)

### Part 4: Analysis-- Comparing DOF data with estimates 2020 data

#1. Region

# DOF Estimates (NOTE: DOF number of households is "occupied")

dof_region<- dof%>%
  filter(area_type== "County" & summary_type== "Total")

# household population 
pop_region<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(pop_region, old= "population", new= "est_pop")

# gq population 
gqpop_region<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(gqpop_region, old= "population", new= "est_gqpop")

# household
hh_region<- hh%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, households)
  
setnames(hh_region, old= "households", new= "est_hh")

# housing units
hu_region<- hu%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_region, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))

#
dof_est_region<- merge(dof_region, pop_region, by.x= "est_yr", by.y = "yr_id", all= TRUE)
  
dof_est_region<- merge(dof_est_region, hh_region, by.x= "est_yr", by.y = "yr_id", all= TRUE)

dof_est_region<- merge(dof_est_region, hu_region, by.x= "est_yr", by.y = "yr_id", all= TRUE)

dof_est_region<- merge(dof_est_region, gqpop_region, by.x= "est_yr", by.y = "yr_id", all= TRUE)


#2. Jurisdiction 

# dof

dof_jur<- dof%>%
  filter(area_type== "City")

# household population 
pop_jur<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(pop_jur, old= "population", new= "est_pop")

# gq population 
gqpop_jur<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(gqpop_jur, old= "population", new= "est_gqpop")


# household
hh_jur<- hh%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, households, )

setnames(hh_jur, old= "households", new= "est_hh")

# housing units
hu_jur<- hu%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_jur, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))

# merging into a single dataframe
dof_est_jur<- merge(dof_jur, pop_jur, by.x= c("est_yr", "area_name"), by.y = c("yr_id", "jurisdiction"), all= TRUE)

dof_est_jur<- merge(dof_est_jur, hh_jur, by.x= c("est_yr", "area_name"), by.y = c("yr_id", "jurisdiction"), all= TRUE)

dof_est_jur<- merge(dof_est_jur, hu_jur, by.x= c("est_yr", "area_name"), by.y = c("yr_id", "jurisdiction"), all= TRUE)

### Part 5: Generating output and saving it into the folder 

estimates_dof_check<- createWorkbook()
addWorksheet(estimates_dof_check, sheetName = "Region")
addWorksheet(estimates_dof_check, sheetName = "Jurisdiction")
writeData(estimates_dof_check,"Region", dof_est_region)
writeData(estimates_dof_check,"Jurisdiction", dof_est_jur)
saveWorkbook(estimates_dof_check, file= "Estimates2020_DOF_check.xlsx", overwrite = TRUE)
