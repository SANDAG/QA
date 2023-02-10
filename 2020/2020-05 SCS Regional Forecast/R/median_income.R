# This report summarizes select QA findings of the 2020 SCS Forecast review (2020-05).
# 
# Tests included in this report are:
#   
# Test #10: Median Income (Information Item)
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
datasource_id1<-35
datasource_id2<- 36
jur_med_inc_35 <- readDB("../queries/median_income_jur_ds_id.sql",datasource_id1)
jur_med_inc_36 <- readDB("../queries/median_income_jur_ds_id.sql",datasource_id2)

#set datasource_id variable for each data table
jur_med_inc_35$datasource_id<-35
jur_med_inc_36$datasource_id<-36

#combine datatables into one table for export
jur_med_inc<- rbind(jur_med_inc_35,
                    jur_med_inc_36)

#export into csv for PowerBI
write.csv(jur_med_inc,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/SCS/R/output/med_income.csv")
