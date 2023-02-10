# 
# This report summarizes select QA findings of the 2020 SCS Forecast review (2020-05).
# 
# Tests included in this report are:
#   
# Test #3: Household Units (Performance Analysis)
# 
# Thorough descriptions of these tests may be found here: 
# https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={17b5d132-f152-49f3-8c62-0b2791a26dd4}&action=edit&wd=target%28Test%20Plan.one%7Cdb0a3336-7736-46dc-afd0-8707889af1a0%2FOverview%7C5e8c7ac7-61e5-40fa-8d9c-6ae544b57ed1%2F%29


#assign ds_ids to compare 
datasource_id_1 <- 35
datasource_id_2 <- 39

#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')


## retrieve data from database 
# ds_id1
hh_1 <- readDB("../queries/households.sql",datasource_id_1)
jobs_1 <- readDB("../queries/jobs.sql",datasource_id_1)
income_1<- readDB("../queries/household_income.sql",datasource_id_1)
pop_1<- readDB("../queries/pop.sql",datasource_id_1)
age_1<- readDB("../queries/age.sql",datasource_id_1)
ethn_1<- readDB("../queries/ethnicity.sql",datasource_id_1)
# ds_id2
hh_2 <- readDB("../queries/households.sql",datasource_id_2)
jobs_2 <- readDB("../queries/jobs.sql",datasource_id_2)
income_2<- readDB("../queries/household_income.sql",datasource_id_2)
pop_2<- readDB("../queries/pop.sql",datasource_id_2)
age_2<- readDB("../queries/age.sql",datasource_id_2)
ethn_2<- readDB("../queries/ethnicity.sql",datasource_id_2)

mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[mohub]
                  ,[score]
                  ,[tier]
                         FROM [urbansim].[ref].[scs_mgra_xref]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

odbcClose(channel)

#merge data for each ds_id into one dataset
hh<- rbind(hh_1,
           hh_2)

income<- rbind(income_1,
           income_2)

jobs<- rbind(jobs_1,
           jobs_2)

pop<- rbind(pop_1,
           pop_2)

age<- rbind(age_1,
            age_2)

ethnicity<- rbind(ethn_1,
                  ethn_2)

#saveout data for PowerBI
write.csv(hh,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/hh.csv")

write.csv(jobs,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/jobs.csv")

write.csv(income,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/income.csv")

write.csv(pop,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/pop.csv")

write.csv(age,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/age.csv")

write.csv(ethnicity,"C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/ethnicity.csv")

write.csv(mohubs, "C:/Users/kte/OneDrive - San Diego Association of Governments/QA temp/Revised Baseline/R/mohubs_tiers.csv")
