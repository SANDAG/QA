#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[mohub]
                  ,[score]
                  ,[tier]
                  ,[special_cap]
                         FROM [urbansim].[ref].[scs_mgra_xref]
                         WHERE [mohub_version_id] = 2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

tier<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [scenario_id]
,[lu_2018]
,[parcel_id]
,[mgra]
,[cap_jurisdiction_id]
,[capacity_2]
,[mohub]
,[tier]
,[score]
,[subtier]
,[cap_scs]
,[site_id]
,[scs_site_id]
,[startdate]
,[compdate]
,[capacity_3]
,[scenario_cap]
,[cap_priority]
FROM [urbansim].[urbansim].[scs_parcel]
WHERE [scenario_id]=2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

write.csv(tier, "C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/SCS/R/output/mohubs_tiers_parcel.csv")



tier_agg<- aggregate(scenario_cap~mgra,data=tier,sum)
tier_agg2<-merge(tier_agg,
                 tier[, c("mgra","parcel_id", "tier", "mohub")],
                 by= "parcel_id",
                 all.x=TRUE)
tier_agg3<-as.data.table(unique(tier_agg2))

x<-tier_agg3[duplicated(tier_agg3$mgra)]
tier_check<-merge(x[,"mgra"],
                  tier_agg3,
                  by="mgra")
write.csv(tier_check, "C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/SCS/R/output/duplicate_tiers.csv")


mohubs_tier<-merge(mohubs,
                   tier_agg2,
                   by="mgra")

odbcClose(channel)


write.csv(mohubs_tier, "C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/SCS/R/output/mohubs_tiers.csv")
