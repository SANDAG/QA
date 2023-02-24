#Purpose: 2021-06 Estimates for 2020 - Age
#Note: Version 2 of Estimates Run
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

#2020 Age estimates
age_2020 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[age_group_id]
                  ,[population]
                  FROM [estimates].[est_2020_02].[dw_age]"),
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

age_dim <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [age_group_id]
                  ,[name]
                         FROM [demographic_warehouse].[dim].[age_group]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


#merge geographies into data table
age_2020 <- merge(age_2020,
                  mgra_dim,
                  by= "mgra_id")

age_2020 <- merge(age_2020,
                  age_dim,
                  by= "age_group_id")

rm(mgra_dim,age_dim)


##Step 1: Create data tables for each geography
age_2020_reg<- age_2020[ ,list(
  population=sum(population)),
  by=c("yr_id","age_group_id","name")]

age_2020_reg<- age_2020_reg %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)

age_2020_reg$region_id <- "San Diego County"

age_2020_jur <- age_2020[, list(
  population = sum(population)),
  by = c("yr_id","jurisdiction", "jurisdiction_id", "age_group_id","name")]

age_2020_jur<- age_2020_jur %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)

age_2020_cpa <- age_2020[, list(
  population = sum(population)),
  by = c("yr_id","cpa", "cpa_id", "age_group_id","name")]

age_2020_cpa<- age_2020_cpa %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)

age_2020_zip <- age_2020[, list(
  population = sum(population)),
  by = c("yr_id","zip", "age_group_id","name")]

age_2020_zip<- age_2020_zip %>% 
  pivot_wider(names_from= yr_id,
              values_from= population)


##Step 2: Apply test functions and review results
test_prop_reg<-est_test_prop_5(age_2020_reg,"region_id") #0 records flagged
test_prop_jur<-est_test_prop_5(age_2020_jur,"jurisdiction_id") #1 records flagged
test_prop_cpa<-est_test_prop_5(age_2020_cpa,"cpa_id") #16 records flagged
test_prop_zip<-est_test_prop_5(age_2020_zip,"zip") #8 records flagged

test_abso_reg<-est_test_abso_5(age_2020_reg,"region_id","age_group_id") #6 records flagged
test_abso_jur<-est_test_abso_5(age_2020_jur,"jurisdiction_id","age_group_id") #280 records flagged
test_abso_cpa<-est_test_abso_5(age_2020_cpa,"cpa_id","age_group_id") #1516 records flagged
test_abso_zip<-est_test_abso_5(age_2020_zip,"zip","age_group_id") #1977 records flagged



test_prop_reg_10<-est_test_prop_10(age_2020_reg,"region_id") #0 records flagged
test_prop_jur_10<-est_test_prop_10(age_2020_jur,"jurisdiction_id") #0 records flagged
test_prop_cpa_10<-est_test_prop_10(age_2020_cpa,"cpa_id") #16 records flagged
test_prop_zip_10<-est_test_prop_10(age_2020_zip,"zip") #8 records flagged

test_abso_reg_10<-est_test_abso_10(age_2020_reg,"region_id","age_group_id") #0 records flagged
test_abso_jur_10<-est_test_abso_10(age_2020_jur,"jurisdiction_id","age_group_id") #127 records flagged
test_abso_cpa_10<-est_test_abso_10(age_2020_cpa,"cpa_id","age_group_id") #1182 records flagged
test_abso_zip_10<-est_test_abso_10(age_2020_zip,"zip","age_group_id") #1392 records flagged


##Step 3: Save out flagged records
wb1 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

PropReg_5 = addWorksheet(wb1, "Prop_Reg_5")
writeData(wb1, "Prop_Reg_5", test_prop_reg)

PropJur_5 = addWorksheet(wb1, "Prop_Jur_5")
writeData(wb1, "Prop_Jur_5", test_prop_jur)

PropCPA_5 = addWorksheet(wb1, "Prop_CPA_5")
writeData(wb1, "Prop_CPA_5", test_prop_cpa)

PropZIP_5 = addWorksheet(wb1, "Prop_ZIP_5")
writeData(wb1, "Prop_ZIP_5", test_prop_zip)

AbsoReg_5 = addWorksheet(wb1, "Abso_Reg_5")
writeData(wb1, "Abso_Reg_5", test_abso_reg)

AbsoJur_5 = addWorksheet(wb1, "Abso_Jur_5")
writeData(wb1, "Abso_Jur_5", test_abso_jur)

AbsoCPA_5 = addWorksheet(wb1, "Abso_CPA_5")
writeData(wb1, "Abso_CPA_5", test_abso_cpa)

AbsoZIP_5 = addWorksheet(wb1, "Abso_ZIP_5")
writeData(wb1, "Abso_ZIP_5", test_abso_zip)



PropReg_10 = addWorksheet(wb1, "Prop_Reg_10")
writeData(wb1, "Prop_Reg_10", test_prop_reg_10)

PropJur_10 = addWorksheet(wb1, "Prop_Jur_10")
writeData(wb1, "Prop_Jur_10", test_prop_jur_10)

PropCPA_10 = addWorksheet(wb1, "Prop_CPA_10")
writeData(wb1, "Prop_CPA_10", test_prop_cpa_10)

PropZIP_10 = addWorksheet(wb1, "Prop_ZIP_10")
writeData(wb1, "Prop_ZIP_10", test_prop_zip_10)

AbsoReg_10 = addWorksheet(wb1, "Abso_Reg_10")
writeData(wb1, "Abso_Reg_10", test_abso_reg_10)

AbsoJur_10 = addWorksheet(wb1, "Abso_Jur_10")
writeData(wb1, "Abso_Jur_10", test_abso_jur_10)

AbsoCPA_10 = addWorksheet(wb1, "Abso_CPA_10")
writeData(wb1, "Abso_CPA_10", test_abso_cpa_10)

AbsoZIP_10 = addWorksheet(wb1, "Abso_ZIP_10")
writeData(wb1, "Abso_ZIP_10", test_abso_zip_10)

saveWorkbook(wb1, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-35 Estimates 2020_V2 QC//Output//age_Est2020_v2.xlsx", overwrite = TRUE)


#clean up
rm(list = ls())


