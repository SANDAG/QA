

#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#pull xref table. Note: Nick acknowledges 38 MGRAS missing from this table that appear in 
#[ws].[dbo].[MGRA13_in_MoHub_Amoeba_Edits_V5] table, but states these missing mgras have no capacity.
xref<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[mohub]
                  ,[special_cap]
                         FROM [urbansim].[ref].[scs_mgra_xref]
                         WHERE [mohub_version_id] = 2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#retrieve mohub list used by Grace
ws_mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [MGRA]
      ,[MoHubName]
      ,[MoHubType]
  FROM [ws].[dbo].[MGRA13_in_MoHub_Amoeba_Edits_V5]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#combine tables to get full list of mgras in mobility hubs or smartgrowth areas
mgra_list<-merge(xref,
                 ws_mohubs,
                 by.x="mgra",
                 by.y="MGRA",
                 all.x=TRUE)

wrong<-merge(xref,
                 ws_mohubs,
                 by.x="mgra",
                 by.y="MGRA")

mgra_list<- subset(mgra_list, !is.na(mohub)|special_cap==1)

x<-subset(mgra_list, !(mgra %in% wrong$mgra))
x$flag<-1
y<-merge(d_mgra,
                    x,
                    by="mgra",
                    all.x=TRUE)


#clean up
odbcClose(channel)
rm(xref,ws_mohubs,maindir,packages,channel, wrong)

