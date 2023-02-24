#Project ID: 2021-06 Estimates 2020 QC
#Author: Purva Singh
# Project SME: Rachel Cortes (EDAM)
# This script is for 'part b' of test 1,2,3,4,5,9,and 10 in the test plan- comparing y-o-y change in the 2020 estimates
# The test plan can be found here: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc=%7B93d68e8d-b118-4932-ad8a-676a6eaa6727%7D&action=edit&wd=target%28Untitled%20Section.one%7Cc92109e3-f882-46aa-b8de-d792c848c78f%2FTest%20Plan%7C334fc90e-fa5e-4158-b204-8ff549abc103%2F%29 


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

### Part 4: Analysis-- Comparing 2019 and 2020 estimates

#1. Region

# household population--2020 
pop_region<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(pop_region, old= "population", new= "est_hhpop")

# gq population-2020 
gqpop_region<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(gqpop_region, old= "population", new= "est_gqpop")

# household--2020
hh_region<- hh%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, households)

setnames(hh_region, old= "households", new= "est_hh")

# housing units--2020
hu_region<- hu%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_region, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))

# merging the region dfs 

region<- Reduce(function(x, y) merge(x, y, by="yr_id"), list(pop_region, gqpop_region, hh_region, hu_region))


# creating new columns to observe differences between vintages

region_final<- region%>%
  mutate(
    hhpop_diff= est_hhpop-lag(est_hhpop,1), 
    gqpop_diff= est_gqpop-lag(est_gqpop,1), 
    hh_diff= est_hh-lag(est_hh,1), 
    hu_diff= est_units- lag(est_units,1), 
    unocc_diff= est_unoccupiable-lag(est_unoccupiable,1),
    vac_diff= est_vacancy-lag(est_vacancy,1),
    hhpop_yoy= hhpop_diff/est_hhpop, 
    gqpop_yoy= gqpop_diff/est_gqpop, 
    hh_yoy= hh_diff/est_hh, 
    hu_yoy= hu_diff/est_units, 
    unocc_yoy= unocc_diff/est_unoccupiable,
    vac_yoy= vac_diff/est_vacancy)


region_final[region_final== "NaN"]<- "NA"

#2. Jurisdiction 

# household population--2020 
pop_jur<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(pop_jur, old= "population", new= "est_hhpop")

# gq population--2020
gqpop_jur<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(gqpop_jur, old= "population", new= "est_gqpop")


# household--2020
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


# merging all jurisdiction dataframes into one 

jurisdiction<- Reduce(function(x, y) merge(x, y, by= c("yr_id", "jurisdiction"), all= TRUE), list(pop_jur, gqpop_jur, hh_jur, hu_jur))

# creating new columns to observe differences between vintages

jurisdiction_final<- jurisdiction%>%
  group_by(jurisdiction)%>%
  mutate(
    hhpop_diff= est_hhpop-lag(est_hhpop,1), 
    gqpop_diff= est_gqpop-lag(est_gqpop,1), 
    hh_diff= est_hh-lag(est_hh,1), 
    hu_diff= est_units- lag(est_units,1), 
    unocc_diff= est_unoccupiable-lag(est_unoccupiable,1),
    vac_diff= est_vacancy-lag(est_vacancy,1),
    hhpop_yoy= hhpop_diff/est_hhpop, 
    gqpop_yoy= gqpop_diff/est_gqpop, 
    hh_yoy= hh_diff/est_hh, 
    hu_yoy= hu_diff/est_units, 
    unocc_yoy= unocc_diff/est_unoccupiable,
    vac_yoy= vac_diff/est_vacancy)




jurisdiction_final[jurisdiction_final== "NaN"]<- "NA"




#3. CPA

# household population--2020 
pop_cpa<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, population)

setnames(pop_cpa, old= "population", new= "est_hhpop")

# gq population--2020
gqpop_cpa<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, population)

setnames(gqpop_cpa, old= "population", new= "est_gqpop")

# household--2020
hh_cpa<- hh%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, households, )

setnames(hh_cpa, old= "households", new= "est_hh")

# housing units-2020
hu_cpa<- hu%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_cpa, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))



# merging all jurisdiction dataframes into one 

cpa<- Reduce(function(x, y) merge(x, y, by= c("yr_id", "jurisdiction", "cpa"), all= TRUE), list(pop_cpa, gqpop_cpa, hh_cpa, hu_cpa))


# creating new columns to observe differences between vintages

cpa_final<- cpa%>%
  group_by(cpa, jurisdiction)%>%
  mutate(
    hhpop_diff= est_hhpop-lag(est_hhpop,1), 
    gqpop_diff= est_gqpop-lag(est_gqpop,1), 
    hh_diff= est_hh-lag(est_hh,1), 
    hu_diff= est_units- lag(est_units,1), 
    unocc_diff= est_unoccupiable-lag(est_unoccupiable,1),
    vac_diff= est_vacancy-lag(est_vacancy,1),
    hhpop_yoy= hhpop_diff/est_hhpop, 
    gqpop_yoy= gqpop_diff/est_gqpop, 
    hh_yoy= hh_diff/est_hh, 
    hu_yoy= hu_diff/est_units, 
    unocc_yoy= unocc_diff/est_unoccupiable,
    vac_yoy= vac_diff/est_vacancy)


cpa_final[cpa_final== "NaN"]<- "NA"




### Part 5: Generating output and saving it into the folder 

estimates_yoy<- createWorkbook()
addWorksheet(estimates_yoy, sheetName = "Region")
addWorksheet(estimates_yoy, sheetName = "Jurisdiction")
addWorksheet(estimates_yoy, sheetName = "CPA")
writeData(estimates_yoy,"Region", region_final)
writeData(estimates_yoy,"Jurisdiction", jurisdiction_final)
writeData(estimates_yoy,"CPA", cpa_final)
saveWorkbook(estimates_yoy, file= "Estimates2020_yoy.xlsx", overwrite = TRUE)





