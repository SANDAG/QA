
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
where run_id = 491
group by parcel_id, year_simulation
order by parcel_id, year_simulation"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

scs_parcel<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [site_id]
      ,[parcel_id]
      ,[capacity_3]
      ,[siteid]
      ,[sitename]
      ,[startdate]
      ,[compdate]
      ,[scenario_id]
  FROM [urbansim].[urbansim].[scs_scheduled_development]
  WHERE [scenario_id]=2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#Test 5a confirm that NAVWAR is included in SCS output data
test5a<- scs_parcel[site_id==19020 | site_id==19021]

#Test 5b confirm input capacity (scs_parcel) to output (urban_sim)
#aggregate and merge input and output files by parcel_id
sum(scs_parcel$capacity_3, na.rm=TRUE)
length(unique(scs_parcel$parcel_id))

#create year of completion variable
scs_parcel$comp_year<-substring(scs_parcel$compdate,1,4)

scs_parcel$comp_year[scs_parcel$comp_year==" "]<-"2050"

#sum(scs_parcel$capacity_3, na.rm=TRUE)
scs_agg1<- aggregate(capacity_3~parcel_id,data=scs_parcel,sum)
#scs_agg2<- aggregate(capacity_3~parcel_id,data=scs_parcel,sum)
sum(scs_agg1$capacity_3, na.rm=TRUE)
#sum(scs_agg2$capacity_3)
#scs_agg<- merge(scs_agg1, scs_agg2, by="parcel_id", all=TRUE)

sum(urban_sim$unit_change, na.rm=TRUE)
urb_agg<- aggregate(unit_change~parcel_id, data=urban_sim,sum)
sum(urb_agg$unit_change, na.rm=TRUE)

merged<- merge(scs_agg1, urb_agg,by="parcel_id", all=TRUE)
sum(merged$capacity_3, na.rm=TRUE)
sum(merged$unit_change, na.rm=TRUE)
#create flag for inconsistencies
merged$flag[merged$capacity_3!=merged$unit_change]<-"Not equal"
merged$flag[merged$capacity_3==merged$unit_change]<-"Equal"
merged$flag[is.na(merged$unit_change)]<-"No change in output"
merged$flag[is.na(merged$capacity_3)&!is.na(merged$unit_chage)]<-"Change without input"
table(merged$flag)

years<-aggregate(comp_year~parcel_id, data=scs_parcel, max)

final<- merge(merged,
              years,
              by="parcel_id",
              all.x=TRUE)
sum(final$capacity_3, na.rm=TRUE)
sum(final$unit_change, na.rm=TRUE)

#save out data file
write.csv(final, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//scheduled_development.csv")

#write.csv(urban_sim, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//urban_sim.csv")
#write.csv(scs_parcel, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//scs_parcel.csv")