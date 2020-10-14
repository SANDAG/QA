# This report summarizes select QA findings of the 2020 SCS Forecast V2 review (2020-06).
# 
# Tests included in this report are:
#   
# Test #10: Median Income (Information Item)
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

#load data table from database
datasource_id1<-35
datasource_id2<- 39
jur_med_inc_35 <- readDB("../queries/median_income_jur_ds_id.sql",datasource_id1)
jur_med_inc_38 <- readDB("../queries/median_income_jur_ds_id.sql",datasource_id2)

#set datasource_id variable for each data table
jur_med_inc_35$datasource_id<-35
jur_med_inc_38$datasource_id<-39

#combine datatables into one table for export
jur_med_inc<- rbind(jur_med_inc_35,
                    jur_med_inc_38)

#export into csv for PowerBI
write.csv(jur_med_inc,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/med_income.csv")
