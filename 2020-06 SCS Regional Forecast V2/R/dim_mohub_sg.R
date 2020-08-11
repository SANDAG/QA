#Purpose: Script to produce dimension table of mgras that identifies within and outside of mobility hubs
#Author: Kelsie Telson


#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

#load required packages
require(data.table)
source("readSQL.R")
source("common_functions.R")
source("mohub_smartgrowth.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#retrieve primary mgra dimension table
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[mgra_id]
                  ,[jurisdiction]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  WHERE [series]=13
                  GROUP BY [mgra]
                          ,[mgra_id]
                         ,[jurisdiction]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#add flag to mobility hub/smart growth list
mgra_list$scs_flag<-1

#merge all mgras with mobility hub/smart growth list
dim_mohub_sg<-merge(d_mgra,
                    mgra_list,
                    by="mgra",
                    all.x=TRUE)

#saveout table
write.csv(dim_mohub_sg, "C://Users//kte//OneDrive - San Diego Association of Governments//QA temp//SCS//dim_mohub_sg.csv")
