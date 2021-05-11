#Purpose: 2021-06 Estimates for 2020 - Sex
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

source("udf_proportional_absolute_changes.R")

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

#MGRA table for each geography
mgra_dim <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[cpa]
                  ,[jurisdiction]
                  ,[zip]
                  ,[jurisdiction_id]
                  ,[cpa_id]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#merge geographies into data table
sex_2020 <- merge(sex_2020,
                   mgra_dim,
                   by= "mgra_id")

rm(mgra_dim)


##Step 1: Create data tables for each geography
sex_2020_reg<- sex_2020[ ,list(
  population=sum(population)),
  by=c("yr_id","sex_id")]

sex_2020_reg<- sex_2020_reg %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)

sex_2020_reg$region_id <- "San Diego County"

sex_2020_jur <- sex_2020[, list(
  population = sum(population)),
  by = c("yr_id","jurisdiction", "jurisdiction_id", "sex_id")]

sex_2020_jur<- sex_2020_jur %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)

sex_2020_cpa <- sex_2020[, list(
  population = sum(population)),
  by = c("yr_id","cpa", "cpa_id", "sex_id")]

sex_2020_cpa<- sex_2020_cpa %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)

sex_2020_zip <- sex_2020[, list(
  population = sum(population)),
  by = c("yr_id","zip", "sex_id")]

sex_2020_zip<- sex_2020_zip %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)


##Step 2: Apply test functions and review results
test_prop_reg<-est_test_prop(sex_2020_reg,"region_id") #0 records flagged
test_prop_jur<-est_test_prop(sex_2020_jur,"jurisdiction_id") #0 records flagged
test_prop_cpa<-est_test_prop(sex_2020_cpa,"cpa_id") #4 records flagged
test_prop_zip<-est_test_prop(sex_2020_zip,"zip") #6 records flagged

test_abso_reg<-est_test_abso(sex_2020_reg,"region_id","sex_id") #0 records flagged
test_abso_jur<-est_test_abso(sex_2020_jur,"jurisdiction_id","sex_id") #1 records flagged
test_abso_cpa<-est_test_abso(sex_2020_cpa,"cpa_id","sex_id") #63 records flagged
test_abso_zip<-est_test_abso(sex_2020_zip,"zip","sex_id") #64 records flagged


##Step 3: Save out flagged records
wb1 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

PropReg = addWorksheet(wb1, "Prop_Reg")
writeData(wb1, "Prop_Reg", test_prop_reg)

PropJur = addWorksheet(wb1, "Prop_Jur")
writeData(wb1, "Prop_Jur", test_prop_jur)

PropCPA = addWorksheet(wb1, "Prop_CPA")
writeData(wb1, "Prop_CPA", test_prop_cpa)

PropZIP = addWorksheet(wb1, "Prop_ZIP")
writeData(wb1, "Prop_ZIP", test_prop_zip)

AbsoReg = addWorksheet(wb1, "Abso_Reg")
writeData(wb1, "Abso_Reg", test_abso_reg)

AbsoJur = addWorksheet(wb1, "Abso_Jur")
writeData(wb1, "Abso_Jur", test_abso_jur)

AbsoCPA = addWorksheet(wb1, "Abso_CPA")
writeData(wb1, "Abso_CPA", test_abso_cpa)

AbsoZIP = addWorksheet(wb1, "Abso_ZIP")
writeData(wb1, "Abso_ZIP", test_abso_zip)

saveWorkbook(wb1, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-08 Estimates QC//Output//sex_Est2020.xlsx")

