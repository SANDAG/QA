#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16; database=demographic_warehouse; trusted_connection=true')


households<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [yr]
      ,[mgra]
      ,count([hhid]) as hh
      ,[hinccat1]
      ,[hworkers]
      ,[veh]
      ,[persons]
  FROM [isam].[xpef33].[abm_syn_households]
  GROUP BY [yr]
      ,[mgra]
      ,[hinccat1]
      ,[hworkers]
      ,[veh]
      ,[persons]
  ORDER BY [yr]
      ,[mgra]
      ,[hinccat1]
      ,[hworkers]
      ,[veh]
      ,[persons]"),
                  stringsAsFactors = FALSE))


#retreive tables using sql code
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[jurisdiction]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  WHERE [series]=14
                  GROUP BY [mgra]
                         ,[jurisdiction]"),
                  stringsAsFactors = FALSE))

library(dplyr)
dim_mgra<-d_mgra %>% group_by(mgra) %>% mutate(counter = row_number(mgra))

dim_test<- dim_mgra %>% 
  tidyr::pivot_wider(id_cols=mgra,
                     names_from=counter,
                     names_prefix="jurisdiction_",
                     values_from=jurisdiction,
                     values_fill=NA)



library(data.table)

y<- merge(households,
          dim_test,
          by="mgra",
          allow.cartesian = TRUE,
          all.x=TRUE)


y$jurisdiction<- ifelse(is.na(y$jurisdiction_2), y$jurisdiction_1, "Mixed")

final<- y[,list(
  hh= sum(hh),
  hworkers=sum(hworkers),
  veh=sum(veh),
  persons=sum(persons)
),
  by=c("jurisdiction", "yr","hinccat1")]

#saveout merged table
write.csv(final, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Results//PowerBI//households_jur.csv")
