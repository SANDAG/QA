
# This report summarizes select QA findings of the 2020 SCS Forecast review (2020-05).
# 
# Tests included in this report are:
#   
# Test #5: Scheduled Development (Information Item)
# 
# Thorough descriptions of these tests may be found here: 
# https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={17b5d132-f152-49f3-8c62-0b2791a26dd4}&action=edit&wd=target%28Test%20Plan.one%7Cdb0a3336-7736-46dc-afd0-8707889af1a0%2FOverview%7C5e8c7ac7-61e5-40fa-8d9c-6ae544b57ed1%2F%29


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

#load data table from database
urban_sim<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT 
    parcel_id
    ,year_simulation
    ,sum(unit_change) as unit_change
FROM [urbansim].[urbansim].[urbansim_lite_output]
where run_id = 477
group by parcel_id, year_simulation
order by parcel_id, year_simulation"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

scs_parcel<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [parcel_id]
      ,[mgra]
      ,[mohub]
      ,[tier]
      ,[score]
      ,[subtier]
      ,[cap_scs]
      ,[cap_jurisdiction_id]
      ,[capacity_3]
      ,[scs_site_id]
      ,[startdate]
      ,[compdate]
      ,[scenario_cap]
      ,[cap_priority]
  FROM [urbansim].[urbansim].[scs_parcel]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#Test 5a confirm that NAVWAR is included in SCS output data
test5a<- non_res_sched_dev[siteid==19020 | siteid==19021]
test5a<- scs_parcel[scs_site_id==19020 | scs_site_id==19021]

#Test 5b confirm input capacity (scs_parcel) to output (urban_sim)
#aggregate and merge input and output files by parcel_id
sum(scs_parcel$scenario_cap)
sum(scs_parcel$capacity_3)
scs_agg1<- aggregate(scenario_cap~parcel_id,data=scs_parcel,sum)
scs_agg2<- aggregate(capacity_3~parcel_id,data=scs_parcel,sum)
sum(scs_agg1$scenario_cap)
sum(scs_agg2$capacity_3)
scs_agg<- merge(scs_agg1, scs_agg2, by="parcel_id", all=TRUE)

sum(urban_sim$unit_change)
urb_agg<- aggregate(unit_change~parcel_id, data=urban_sim,sum)
sum(urb_agg$unit_change)

merged<- merge(scs_agg, urb_agg,by="parcel_id", all=TRUE)
sum(merged$scenario_cap)
sum(merged$unit_change)
#create flag for inconsistencies
merged$flag[merged$scenario_cap!=merged$unit_change]<-"Not equal"
merged$flag[merged$scenario_cap==merged$unit_change]<-"Equal"
merged$flag[is.na(merged$unit_change)]<-"No change in output"
table(merged$flag)

merged$flag2[is.na(merged$capacity_3)& is.na(merged$unit_change)]<-"No cap3, no unit change"
merged$flag2[is.na(merged$capacity_3)& !is.na(merged$unit_change)]<-"Unit change, no cap3"
merged$flag2[merged$capacity_3==merged$unit_change]<-"Cap3 and Unit Change Equal"

final<- merge(merged,
              scs_parcel[, c("parcel_id","mgra","cap_jurisdiction_id","tier")],
              by="parcel_id")
sum(final$scenario_cap)
sum(final$unit_change)
table(final$flag,final$tier)

#save out data file
write.csv(final, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//scheduled_development.csv")

write.csv(urban_sim, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//urban_sim.csv")
write.csv(scs_parcel, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//scs_parcel.csv")

scs_dates<- aggregate(scenario_cap~parcel_id+compdate2,data=scs_parcel,sum)
date_check<-merge(urb_dates,
                  scs_dates,
                  by.x=c("parcel_id","year_simulation"),
                  by.y=c("parcel_id","compdate2"))

write.csv(date_check, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//date_check.csv")
