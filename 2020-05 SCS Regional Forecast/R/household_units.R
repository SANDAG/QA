# 
# This report summarizes select QA findings of the 2020 SCS Forecast review (2020-05).
# 
# Tests included in this report are:
#   
# Test #3: Household Units (Performance Analysis)
# Test #5: Scheduled Development (Information Item)
# 
# Thorough descriptions of these tests may be found here: 
# https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={17b5d132-f152-49f3-8c62-0b2791a26dd4}&action=edit&wd=target%28Test%20Plan.one%7Cdb0a3336-7736-46dc-afd0-8707889af1a0%2FOverview%7C5e8c7ac7-61e5-40fa-8d9c-6ae544b57ed1%2F%29


#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

#load required packages
require(knitr)
require(compareGroups)
require(psych)
require(summarytools)
require(broom)
require(kableextra)
library(data.table)
source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#Test 3 Data Prep
#load mgra dimension table
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[mgra]
                  ,[series]
                  ,[zip]
                  ,[cpa]
                  ,[jurisdiction]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  GROUP BY [mgra_id]
                         ,[mgra]
                         ,[series]
                         ,[zip]
                         ,[cpa]
                         ,[jurisdiction]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)
#select only series 14
d_mgra<- subset(d_mgra,d_mgra$series==14)
#aggregate to mgra level (not mgra_id)
d_mgra<- d_mgra %>% distinct(mgra, .keep_all = TRUE)

#load reference table used by Nick to apply changes to household units
input_hhunits<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [parcel_id]
      ,[mgra]
      ,[mohub]
      ,[tier]
      ,[score]
      ,[subtier]
      ,[cap_scs]
      ,[scs_site_id]
      ,[startdate]
      ,[compdate]
      ,[scenario_cap]
      ,[cap_priority]
  FROM [urbansim].[urbansim].[scs_parcel]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#load SCS forecast household data
datasource_id<- 36
hh <- readDB("../queries/households.sql",datasource_id)

#select only years of interest from SCS forecast dataset
hh<-subset(hh, hh$yr_id==2016 | hh$yr_id==2050 )

#convert to data table
hh<-as.data.table(hh)

#check subtotals 
hh_50<-subset(hh, hh$yr_id==2050)
sum(hh_50$units)

#merge in [mgra] variable to allow for crosswalk to input data
hh<-merge(hh,
          d_mgra[ , c("mgra_id", "mgra", "jurisdiction")],
          by= "mgra_id")


#aggregate SCS forecast data to the [mgra] (not [mgra_id]) level for analysis
hh_agg<-hh[ , list(
  mgra_id,
  mgra,
  datasource_id,
  yr_id,
  units,
  jurisdiction),
  by=mgra]

#check subtotals
hh_agg_50<-subset(hh_agg, hh_agg$yr_id==2050)
sum(hh_agg_50$units)

#create aggregate table by mgra for 2016 and 2050
hh_reshape<- hh_agg[, list(
  jurisdiction= unique(jurisdiction),
  units_2016=units[yr_id==2016],
  units_2050=units[yr_id==2050]
),
by=mgra]

#check subtotals
sum(hh_reshape$units_2050)

#wrangle hh_inputs to have one record per mgra for merging
hh_inputs_agg<-aggregate(scenario_cap ~mgra+tier, data=input_hhunits, sum)

#merge scs forecast data to inputs data
hh_merged<-merge(hh_reshape,
                 hh_inputs_agg,
                 by= "mgra",
                 all.x=TRUE)

#calculate difference between 2050 and 2016 units
hh_merged$N_diff<- hh_merged$units_2050-hh_merged$units_2016

#apply flag to indicate relationship between expected change and actual change in units
hh_merged$change[hh_merged$N_diff==hh_merged$scenario_cap]<- "Exact capacity change"
hh_merged$change[hh_merged$N_diff<hh_merged$scenario_cap]<- "Less than capacity"
hh_merged$change[hh_merged$N_diff>hh_merged$scenario_cap]<- "Greater than capacity"
hh_merged$change[hh_merged$N_diff==0]<- "No Change"

#clean up
rm(list="hh", "d_mgra", "hh_agg", "hh_inputs_agg", "hh_reshape", "input_hhunits")

#save out data file
write.csv(hh_merged, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//housing_units.csv")
