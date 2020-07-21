#Purpose: 2018 Employment Inventory
#Author: Kelsie Telson

#load useful functions
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


connect_datawarehouse <- function() {
  
  # Connect to Datahub using RODBC package
  channel <- RODBC::odbcDriverConnect(
    paste0("driver={SQL Server}; server=sql2014b8;
             database=EMPCORE;
             trusted_connection=true"))
  
  # Return open RODBC connection
  return(channel)
}



packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- connect_datawarehouse()

#retrieve data from data warehouse
raw_dt <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("
SELECT [OBJECTID]
      ,[Status]
      ,[Score]
      ,[Match_type]
      ,[Match_addr]
      ,[emp_id]
      ,[dba]
      ,[address]
      ,[city]
      ,[zip]
      ,[emp1]
      ,[emp2]
      ,[emp3]
      ,[payroll]
      ,[naics]
      ,[own]
      ,[meei]
      ,[init]
      ,[end_]
      ,[react]
      ,[Run]
      ,[Check_]
      ,[flag]
      ,[Move]
      ,[Comment]
      ,[MGRA13]
      ,[SHAPE]
      ,[GDB_GEOMATTR_DATA]
  FROM [EMPCORE].[dbo].[CA_EDD_EMP2018]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)



raw_dt <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [OBJECTID]
      ,[emp_id]
      ,[sub_emp_id]
      ,[dba]
      ,[Comment]
      ,[Check_]
      ,[share]
      ,[MGRA13]
      ,[SHAPE]
      ,[GDB_GEOMATTR_DATA]
  FROM [EMPCORE].[dbo].[CA_EDD_EMP2018HQD]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)



#Test 2

summary(raw_dt)


