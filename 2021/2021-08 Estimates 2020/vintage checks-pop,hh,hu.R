#Project ID: 2021-06 Estimates 2020 QC
#Author: Purva Singh
# Project SME: Rachel Cortes (EDAM)
# This script is for 'part c' of test 1,2,3,4,5,9,and 10 in the test plan- comparing SANDAG estimates between 2019 and 2020 versions and identify areas with percent by category changes >5%  [yr 2019, 2020]   
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


# loading the estimates 2019 pop, housing, and household datasets from the database--for vintage comparison 
# NOTE: Rachel C. (SME for this project) requested to use the demographic warehouse tables for vintage comparison with 2019 tables 

channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=demographic_warehouse; trusted_connection=true')

pop_db_19<- sqlQuery(channel, "SELECT * 
    FROM [demographic_warehouse].[fact].[population]
    WHERE datasource_id=33") 
hu_db_19<- sqlQuery(channel, "SELECT * 
    FROM [demographic_warehouse].[fact].[housing]
    WHERE datasource_id=33") 

odbcClose(channel)


### Part 3: Preparing the data for analysis

# merging pop, hh, and hu with mgra dataset on mgra_id for aggregation--2020 estimates

pop<- merge(pop_db, mgra, by= "mgra_id", all= TRUE)
hh<- merge(hh_db, mgra, by= "mgra_id", all= TRUE)
hu<- merge(hu_db, mgra, by= "mgra_id", all= TRUE)

# merging pop and hu with mgra dataset on mgra_id for aggregation--2019 estimates for vintage comparison

pop_19<- merge(pop_db_19, mgra, by= "mgra_id", all= TRUE)
hu_19<- merge(hu_db_19, mgra, by= "mgra_id", all= TRUE)

rm(pop_db, hh_db, hu_db, pop_db_19, hu_db_19)

### Part 4: Analysis-- Comparing 2019 and 2020 estimates

#1. Region

# household population--2020 
pop_region<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(pop_region, old= "population", new= "est_hhpop")

# household population--2019
pop_region_19<- pop_19%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(pop_region_19, old= "population", new= "est19_hhpop")

# gq population-2020 
gqpop_region<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(gqpop_region, old= "population", new= "est_gqpop")

# gq population-2019
gqpop_region_19<- pop_19%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, population)

setnames(gqpop_region_19, old= "population", new= "est19_gqpop")

# household--2020
hh_region<- hh%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, households)

setnames(hh_region, old= "households", new= "est_hh")

# household--2019 (occuped will be households)
hh_region_19<- hu_19%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(yr_id, occupied)

setnames(hh_region_19, old= "occupied", new= "est19_hh")

# housing units--2020
hu_region<- hu%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_region, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))

# housing units--2019
hu_region_19<- hu_19%>%
  group_by(yr_id)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_region_19, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est19_units","est19_unoccupiable", "est19_occupied", "est19_vacancy"))

# merging the region dfs 

region<- Reduce(function(x, y) merge(x, y, by="yr_id", all=TRUE), list(pop_region, pop_region_19,gqpop_region, gqpop_region_19, hh_region, hh_region_19, hu_region, hu_region_19))


# creating new columns to observe differences between vintages

region_final<- region%>%
  mutate(
    hhpopdiff= est_hhpop-est19_hhpop,
    hhpopperdiff= (hhpopdiff*100)/est19_hhpop, 
    gqpopdiff= est_gqpop- est19_gqpop,
    gqpopperdiff= (gqpopdiff*100)/est19_gqpop,
    hhdiff= est_hh- est19_hh, 
    hhperdiff= (hhdiff*100)/est19_hh,
    hudiff= est_units- est19_units,
    huperdiff= (hudiff*100)/est19_units,
    unoccdiff= est_unoccupiable- est19_unoccupiable,
    unoccperdiff= (unoccdiff*100)/est19_unoccupiable,
    vacdiff= est_vacancy- est19_vacancy,
    vacperdiff= (vacdiff*100)/est19_vacancy
  )%>%
  mutate_at(c("hhpopperdiff","gqpopperdiff", "hhperdiff", "huperdiff", "unoccperdiff", "vacperdiff" ), round, 2)

region_final[region_final== "NaN"]<- "NA"



#2. Jurisdiction 

# household population--2020 
pop_jur<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(pop_jur, old= "population", new= "est_hhpop")

# household population--2019
pop_jur19<- pop_19%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(pop_jur19, old= "population", new= "est19_hhpop")

# gq population--2020
gqpop_jur<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(gqpop_jur, old= "population", new= "est_gqpop")

# gq population--2019
gqpop_jur19<- pop_19%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, population)

setnames(gqpop_jur19, old= "population", new= "est19_gqpop")


# household--2020
hh_jur<- hh%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id, households, )

setnames(hh_jur, old= "households", new= "est_hh")

# household--2019

hh_jur19<- hu_19%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(jurisdiction, yr_id,occupied )

setnames(hh_jur19, old= "occupied", new= "est19_hh")


# housing units
hu_jur<- hu%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_jur, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))

# housing units-2019
hu_jur19<- hu_19%>%
  group_by(yr_id, jurisdiction)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_jur19, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est19_units","est19_unoccupiable", "est19_occupied", "est19_vacancy"))


# merging all jurisdiction dataframes into one 

jurisdiction<- Reduce(function(x, y) merge(x, y, by= c("yr_id", "jurisdiction"), all= TRUE), list(pop_jur, pop_jur19,gqpop_jur, gqpop_jur19, hh_jur, hh_jur19, hu_jur, hu_jur19))

# creating new columns to observe differences between vintages

jurisdiction_final<- jurisdiction%>%
  mutate(
    hhpopdiff= est_hhpop-est19_hhpop,
    hhpopperdiff= hhpopdiff/est19_hhpop, 
    gqpopdiff= est_gqpop- est19_gqpop,
    gqpopperdiff= gqpopdiff/est19_gqpop,
    hhdiff= est_hh- est19_hh, 
    hhperdiff= hhdiff/est19_hh,
    hudiff= est_units- est19_units,
    huperdiff= hudiff/est19_units,
    unoccdiff= est_unoccupiable- est19_unoccupiable,
    unoccperdiff= unoccdiff/est19_unoccupiable,
    vacdiff= est_vacancy- est19_vacancy,
    vacperdiff= vacdiff/est19_vacancy
  )%>%
  mutate_at(c("hhpopperdiff","gqpopperdiff", "hhperdiff", "huperdiff", "unoccperdiff", "vacperdiff" ), round, 2)

jurisdiction_final[jurisdiction_final== "NaN"]<- "NA"




#3. CPA

# household population--2020 
pop_cpa<- pop%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, population)

setnames(pop_cpa, old= "population", new= "est_hhpop")

# household population--2019
pop_cpa19<- pop_19%>%
  filter(housing_type_id== 1)%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, population)

setnames(pop_cpa19, old= "population", new= "est19_hhpop")

# gq population--2020
gqpop_cpa<- pop%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, population)

setnames(gqpop_cpa, old= "population", new= "est_gqpop")

# gq population--2019
gqpop_cpa19<- pop_19%>%
  filter(housing_type_id!= 1)%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, population)

setnames(gqpop_cpa19, old= "population", new= "est19_gqpop")


# household--2020
hh_cpa<- hh%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id, households, )

setnames(hh_cpa, old= "households", new= "est_hh")

# household--2019

hh_cpa19<- hu_19%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(cpa, jurisdiction, yr_id,occupied )

setnames(hh_cpa19, old= "occupied", new= "est19_hh")


# housing units-2020
hu_cpa<- hu%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_cpa, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est_units","est_unoccupiable", "est_occupied", "est_vacancy"))

# housing units-2019
hu_cpa19<- hu_19%>%
  group_by(yr_id, jurisdiction, cpa)%>%
  summarise_if(is.numeric, sum)%>%
  select(-c(mgra_id, structure_type_id,zip))

setnames(hu_cpa19, old= c("units","unoccupiable", "occupied", "vacancy"), new= c("est19_units","est19_unoccupiable", "est19_occupied", "est19_vacancy"))


# merging all jurisdiction dataframes into one 

cpa<- Reduce(function(x, y) merge(x, y, by= c("yr_id", "jurisdiction", "cpa"), all= TRUE), list(pop_cpa, pop_cpa19,gqpop_cpa, gqpop_cpa19, hh_cpa, hh_cpa19, hu_cpa, hu_cpa19))


# creating new columns to observe differences between vintages

cpa_final<- cpa%>%
  mutate(
    hhpopdiff= est_hhpop-est19_hhpop,
    hhpopperdiff= hhpopdiff/est19_hhpop, 
    gqpopdiff= est_gqpop- est19_gqpop,
    gqpopperdiff= gqpopdiff/est19_gqpop,
    hhdiff= est_hh- est19_hh, 
    hhperdiff= hhdiff/est19_hh,
    hudiff= est_units- est19_units,
    huperdiff= hudiff/est19_units,
    unoccdiff= est_unoccupiable- est19_unoccupiable,
    unoccperdiff= unoccdiff/est19_unoccupiable,
    vacdiff= est_vacancy- est19_vacancy,
    vacperdiff= vacdiff/est19_vacancy
  )%>%
  mutate_at(c("hhpopperdiff","gqpopperdiff", "hhperdiff", "huperdiff", "unoccperdiff", "vacperdiff" ), round, 2)

cpa_final[cpa_final== "NaN"]<- "NA"






### Part 5: Generating output and saving it into the folder 

estimates_vintage_check<- createWorkbook()
addWorksheet(estimates_vintage_check, sheetName = "Region")
addWorksheet(estimates_vintage_check, sheetName = "Jurisdiction")
addWorksheet(estimates_vintage_check, sheetName = "CPA")
writeData(estimates_vintage_check,"Region", region_final)
writeData(estimates_vintage_check,"Jurisdiction", jurisdiction_final)
writeData(estimates_vintage_check,"CPA", cpa_final)
saveWorkbook(estimates_vintage_check, file= "Estimates2020_2019.xlsx", overwrite = TRUE)


#### need to check if the T drive data and database data are same 

# loading the DOF population data from T drive: 

tab_names<- excel_sheets(path= "T:\\socioec\\socioec_data_test\\CA_DOF\\Estimates\\E-5_2020_Internet_Version.xlsx")

dof<- lapply(tab_names, function(x) read_excel(path = "T:\\socioec\\socioec_data_test\\CA_DOF\\Estimates\\E-5_2020_Internet_Version.xlsx", sheet = x))

