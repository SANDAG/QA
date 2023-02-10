# 
# This report summarizes select QA findings of the 2020 SCS Forecast V2 review (2020-06).
# 
# Tests included in this report are:
#   
# Test #3: Household Units (Performance Analysis)
# 
# Thorough descriptions of these tests may be found here: 


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
                  paste0("SELECT [parcel_id]
      ,[mgra]
      ,[mohub]
      ,[tier]
      ,[score]
      ,[subtier]
      ,[cap_scs]
      ,[cap_jurisdiction_id]
      ,[scs_site_id]
      ,[startdate]
      ,[compdate]
      ,[scenario_cap]
      ,[cap_priority]
  FROM [urbansim].[urbansim].[scs_parcel]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#load SCS forecast household data
datasource_id<- 38
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


#aggregate SCS forecast data to the [mgra] (not [mgra_id]) level for analysis
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
sum(hh_agg_50$units)

#create aggregate table by mgra for 2016 and 2050
hh_agg<-as.data.table(hh_agg)
hh_reshape<- hh_agg[, list(
  units_2018=units[yr_id==2018],
  units_2050=units[yr_id==2050]),
  by="mgra"]

hh_reshape2<- aggregate(hh_reshape,
                        by=list(hh_reshape$mgra),
                        FUN=sum)
#check subtotals
sum(hh_reshape2$units_2050)

#merge in jurisdiction
# hh_reshape3<- merge(hh_reshape2,
#                    d_mgra[ , c("mgra","jurisdiction")],
#                    by="mgra")

#check subtotals
sum(hh_reshape$units_2050)

#wrangle hh_inputs to have one record per mgra for merging
hh_inputs_agg<-aggregate(scenario_cap ~mgra+tier, data=input_hhunits, sum)

#merge scs forecast data to inputs data
hh_merged<-merge(hh_reshape2,
                 hh_inputs_agg,
                 by.x= "Group.1",
                 by.y= "mgra",
                 all.x=TRUE)

#check subtotals
sum(hh_merged$units_2050)

#calculate difference between 2050 and 2016 units
hh_merged$N_diff<- hh_merged$units_2050-hh_merged$units_2018

#apply flag to indicate relationship between expected change and actual change in units
hh_merged$change[hh_merged$N_diff==hh_merged$scenario_cap]<- "Exact capacity change"
hh_merged$change[hh_merged$N_diff<hh_merged$scenario_cap]<- "Less than capacity"
hh_merged$change[hh_merged$N_diff>hh_merged$scenario_cap]<- "Greater than capacity"
hh_merged$change[hh_merged$N_diff==0]<- "No Change"


#save out data file
write.csv(hh_merged, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//housing_units_mgra_2018base.csv")

########################################################################################################

#Generate output aggregated at the jurisdiction level
hh_agg_jur<- aggregate(units~jurisdiction_id+yr_id, data=hh,sum)
input_agg_jur<-aggregate(scenario_cap ~cap_jurisdiction_id, data=input_hhunits, sum)

hh_jur<- dcast(hh_agg_jur, jurisdiction_id~yr_id, value.var="units")

#check totals
sum(hh_jur$`2050`)

#merge in scs capacity
hh_jur<- merge(hh_jur,
               input_agg_jur,
               by.x="jurisdiction_id",
               by.y="cap_jurisdiction_id")

#calculate difference between 2050 and 2016 units
hh_jur$N_diff<- hh_jur$`2050`-hh_jur$`2018`

#apply flag to indicate relationship between expected change and actual change in units
hh_jur$change[hh_jur$N_diff==hh_jur$scenario_cap]<- "Exact capacity change"
hh_jur$change[hh_jur$N_diff<hh_jur$scenario_cap]<- "Less than capacity"
hh_jur$change[hh_jur$N_diff>hh_jur$scenario_cap]<- "Greater than capacity"
hh_jur$change[hh_jur$N_diff==0]<- "No Change"

#save out data file
write.csv(hh_jur, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//housing_units_jur_2018base.csv")



#clean up
rm(list="hh", "d_mgra", "hh_agg", "hh_inputs_agg", "hh_reshape", "input_hhunits")
