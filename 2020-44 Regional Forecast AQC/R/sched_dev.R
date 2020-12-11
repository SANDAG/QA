
# This report summarizes select QA findings of the 2020 SCS Forecast review (2020-06).
# 
# Tests included in this report are:
#   
# Test #5: Scheduled Development (Information Item)
# 
 

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
where run_id = 495 and capacity_type='sch'
group by parcel_id, year_simulation
order by parcel_id, year_simulation"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

rev_base_parcel<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [site_id]
      ,[parcel_id]
      ,[capacity_3]
      ,[compdate]
  FROM [urbansim].[urbansim].[scheduled_development_parcel]
                         WHERE [capacity_3] IS NOT NULL"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


#confirm input capacity to output (urban_sim)
#aggregate and merge input and output files by parcel_id
sum(rev_base_parcel$capacity_3, na.rm=TRUE) #precheck
agg1<- aggregate(capacity_3~parcel_id,data=rev_base_parcel,sum)
sum(agg1$capacity_3, na.rm=TRUE) #check to ensure transformation did not disturb data


sum(urban_sim$unit_change, na.rm=TRUE) #precheck
urb_agg<- aggregate(unit_change~parcel_id, data=urban_sim,sum)
sum(urb_agg$unit_change, na.rm=TRUE) #check to ensure transformation did not disturb data

#merge input and output data
merged<- merge(agg1, 
               urb_agg,
               by="parcel_id", 
               all=TRUE)
sum(merged$capacity_3, na.rm=TRUE)  #check to ensure transformation did not disturb data
sum(merged$unit_change, na.rm=TRUE) #check to ensure transformation did not disturb data

#create flag for inconsistencies
merged$flag[merged$capacity_3!=merged$unit_change]<-"Not equal"
merged$flag[merged$capacity_3==merged$unit_change]<-"Equal"
merged$flag[is.na(merged$unit_change)]<-"No change in output"
merged$flag[is.na(merged$capacity_3)&!is.na(merged$unit_chage)]<-"Change without input"
table(merged$flag)

#save out data file
write.csv(merged, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//Revised Baseline//scheduled_development.csv")
