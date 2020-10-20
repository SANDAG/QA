# 
# This report summarizes select QA findings of the 2020 Revised Baseline Forecast (2020-30).
# 
# Tests included in this report are:
#   
# Test #3: Household Units (Performance Analysis)
# 
# Thorough descriptions of these tests may be found here: 
# https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={7ac53c05-1e9c-464c-b316-9b679615bd91}&action=edit&wd=target%28Test%20Plan.one%7C40ba6e56-16f1-4da3-a23e-ac683c60f891%2FOverview%7C39181d19-c080-4a9e-ad76-e2a94c751c42%2F%29


#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

#load required packages
require(data.table)
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
                  ,[jurisdiction_id]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  GROUP BY [mgra_id]
                         ,[mgra]
                         ,[series]
                         ,[zip]
                         ,[cpa]
                         ,[jurisdiction]
                         ,[jurisdiction_id]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)
#select only series 14
d_mgra<- subset(d_mgra,d_mgra$series==14)
#aggregate to mgra level (not mgra_id)
#d_mgra<- d_mgra %>% distinct(mgra, .keep_all = TRUE)

#load reference table used by Nick to apply changes to household units
input_hhunits<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [eir_scenario_id]
      ,[parcel_id]
      ,[lu_2018]
      ,[mgra]
      ,[cap_jurisdiction_id]
      ,[capacity_2]
      ,[dm_cap]
      ,[eir_cap]
      ,[site_id]
      ,[site_id2]
      ,[capacity_3]
      ,[scenario_cap]
      ,[baseline_cap]
      ,[cap_priority]
      ,[startdate]
      ,[compdate]
  FROM [urbansim].[urbansim].[eir_parcel]
  WHERE [eir_scenario_id]=1"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#load adu data
input_adu<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [version_id]
      ,[jur_id]
      ,[parcel_id]
      ,[type]
      ,[name]
      ,[du]
      ,[ID]
  FROM [urbansim].[urbansim].[additional_capacity]
  WHERE [version_id]=111 and [type]='adu'"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#load r_baseline forecast household data
datasource_id<- 39
hh <- readDB("../queries/households.sql",datasource_id)

#select only years of interest from SCS forecast dataset
hh<-subset(hh, hh$yr_id==2018 | hh$yr_id==2050)

#convert to data table
hh<-as.data.table(hh)

#check subtotals 
hh_50<-subset(hh, hh$yr_id==2050)
sum(hh_50$units)

#merge in [mgra] variable to allow for crosswalk to input data
hh<-merge(hh,
          d_mgra[ , c("mgra_id", "mgra", "jurisdiction", "jurisdiction_id")],
          by= "mgra_id")


#aggregate forecast data to the [mgra] (not [mgra_id]) level for analysis
hh_agg<-hh[ , list(
  mgra_id,
  mgra,
  datasource_id,
  yr_id,
  units,
  jurisdiction,
  jurisdiction_id),
  by="mgra"]

#check subtotals
hh_agg_18<-subset(hh_agg, hh_agg$yr_id==2018)
hh_agg_50<-subset(hh_agg, hh_agg$yr_id==2050)
sum(hh_agg_18$units)
sum(hh_agg_50$units)

#create aggregate table by mgra for 2016 and 2050
hh_agg<-as.data.table(hh_agg)
hh_reshape<- hh_agg[, list(
  units_2018=units[yr_id==2018],
  units_2050=units[yr_id==2050]),
  by="jurisdiction_id"]

hh_reshape2<- aggregate(hh_reshape,
                        by=list(hh_reshape$jurisdiction_id),
                        FUN=sum)
#check subtotals
sum(hh_reshape2$units_2050)

#merge input housing units and adu
input<-merge(input_hhunits,
             input_adu,
             by="parcel_id",
             all=TRUE)

#collapse jurisdiction_id into one variable
input[is.na(cap_jurisdiction_id),
       cap_jurisdiction_id := jur_id]

#create input table aggregated to jurisdiction level
input_agg<-input[,list(
  capacity_2=sum(capacity_2, na.rm=TRUE),
  capacity_3=sum(capacity_3, na.rm=TRUE),
  du=sum(du, na.rm=TRUE)),
  by="cap_jurisdiction_id"]


#merge forecast output data to inputs data
hh_merged<-merge(hh_reshape2,
                 input_agg,
                 by.x= "Group.1",
                 by.y= "cap_jurisdiction_id",
                 all=TRUE)

#check subtotals
sum(hh_merged$units_2050)

#calculate difference between 2050 and 2016 units
hh_merged$N_diff<- hh_merged$units_2050-hh_merged$units_2018

#add input units types together
hh_merged$input_total<- hh_merged$capacity_3+hh_merged$du+hh_merged$capacity_2

#apply flag to indicate relationship between expected change and actual change in units
hh_merged$change[hh_merged$N_diff==hh_merged$input_total]<- "Exact capacity change"
hh_merged$change[hh_merged$N_diff<hh_merged$input_total]<- "Less than capacity"
hh_merged$change[hh_merged$N_diff>hh_merged$input_total]<- "Greater than capacity"
hh_merged$change[hh_merged$N_diff==0]<- "No Change"

#merge in jurisdiction names
jur_list<-d_mgra[,c("jurisdiction", "jurisdiction_id")]
jur_list<-unique(jur_list)

hh_final<-merge(hh_merged,
                jur_list,
                by.x="Group.1",
                by.y="jurisdiction_id",
                all.y=FALSE)


#save out data file
write.csv(hh_final, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//Revised Baseline//housing_units_2018base.csv")

########################################################################################################
