#Purpose: 2021-06 Estimates for 2020 - Compare totals against total populations
#Author: Kelsie Telson


## Step 0: Set up

#load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "reshape2", 
              "stringr","tidyverse")
pkgTest(packages)

library("readxl")
library("openxlsx")

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))


#load data from data base      
channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=estimates; trusted_connection=true')

#2020 sex estimates
sex_2020 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[sex_id]
                  ,[population]
                  FROM [estimates].[est_2020_01].[dw_sex]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

sex_2020<- sex_2020[ ,list(
  population=sum(population)),
  by="yr_id"]

#2020 ethn estimates
ethn_2020 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[ethnicity_id]
                  ,[population]
                  FROM [estimates].[est_2020_01].[dw_ethnicity]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

ethn_2020<- ethn_2020[ ,list(
  population=sum(population)),
  by="yr_id"]

#2020 Age estimates
age_2020 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[age_group_id]
                  ,[population]
                  FROM [estimates].[est_2020_01].[dw_age]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

age_2020<- age_2020[ ,list(
  population=sum(population)),
  by="yr_id"]

#2020 population estimates
population <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [yr_id]
                  ,sum([population]) as pop
                  FROM [estimates].[est_2020_01].[dw_population]
                         GROUP BY [yr_id]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## Step 1: Test breakout tables against population tables
sex_2020==population #pass
ethn_2020==population #pass
age_2020==population #pass


