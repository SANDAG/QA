#Purpose: 2021-06 Estimates for 2020 - Vintage Comparison
#Note: Version 2 of Estimates Run
#Author: Kelsie Telson

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
library("arsenal")

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=estimates; trusted_connection=true')


##Retrieve 2020 data
#2020 Age estimates

age_2020_1 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[age_group_id]
                  ,[population]
                  FROM [estimates].[est_2020_01].[dw_age]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

age_2020_2 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[age_group_id]
                  ,[population]
                  FROM [estimates].[est_2020_02].[dw_age]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#2020 ethn estimates
ethn_2020_1 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[ethnicity_id]
                  ,[population]
                  FROM [estimates].[est_2020_02].[dw_ethnicity]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

ethn_2020_2 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[ethnicity_id]
                  ,[population]
                  FROM [estimates].[est_2020_02].[dw_ethnicity]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#2020 sex estimates
sex_2020_1 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[sex_id]
                  ,[population]
                  FROM [estimates].[est_2020_01].[dw_sex]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

sex_2020_2 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[sex_id]
                  ,[population]
                  FROM [estimates].[est_2020_02].[dw_sex]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#2020 hh_income estimates
hhinc_2020_1 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[income_group_id]
                  ,[households]
                  FROM [estimates].[est_2020_01].[dw_household_income]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

hhinc_2020_2 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[income_group_id]
                  ,[households]
                  FROM [estimates].[est_2020_02].[dw_household_income]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

##Retrieve 2019 data
#2019 Age estimates
age_2019 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[age_group_id]
                  ,[population]
                  FROM [demographic_warehouse].[fact].[age]
                         WHERE [datasource_id]=33"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#2019 ethn estimates
ethn_2019 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[ethnicity_id]
                  ,[population]
                  FROM [demographic_warehouse].[fact].[ethnicity]
                         WHERE [datasource_id]=33"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#2019 sex estimates
sex_2019 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[sex_id]
                  ,[population]
                  FROM [demographic_warehouse].[fact].[sex]
                         WHERE [datasource_id]=33"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#2019 hh_income estimates
hhinc_2019 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[income_group_id]
                  ,[households]
                  FROM [demographic_warehouse].[fact].[household_income]
                         WHERE [datasource_id]=33"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

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



##Merge tables and clean up
age<- merge(age_2020_1,
            age_2020_2,
            by=c("mgra_id","yr_id","age_group_id"),
            all=TRUE)
age_2020<- merge(age,
            mgra_dim,
            by="mgra_id")

age_2019<- merge(age_2019,
                 mgra_dim,
                 by="mgra_id")

age_reg_2020<- age_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","age_group_id")]

age_jur_2020<- age_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","age_group_id","jurisdiction")]

age_cpa_2020<- age_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","age_group_id","cpa")]

age_reg_2019<- age_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","age_group_id")]

age_jur_2019<- age_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","age_group_id","jurisdiction")]

age_cpa_2019<- age_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","age_group_id","cpa")]


ethn<- merge(ethn_2020_1,
             ethn_2020_2,
            by=c("mgra_id","yr_id","ethnicity_id"),
            all=TRUE)

ethn_2020<- merge(ethn,
            mgra_dim,
            by="mgra_id")

ethn_2019<- merge(ethn_2019,
             mgra_dim,
             by="mgra_id")

ethn_reg_2020<- ethn_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","ethnicity_id")]

ethn_jur_2020<- ethn_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","ethnicity_id","jurisdiction")]

ethn_cpa_2020<- ethn_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","ethnicity_id","cpa")]

ethn_reg_2019<- ethn_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","ethnicity_id")]

ethn_jur_2019<- ethn_2019[ ,list(
  population.2020_1=sum(population)),
  by=c("yr_id","ethnicity_id","jurisdiction")]

ethn_cpa_2019<- ethn_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","ethnicity_id","cpa")]


sex<- merge(sex_2020_1,
            sex_2020_2,
             by=c("mgra_id","yr_id","sex_id"),
             all=TRUE)
sex_2020<- merge(sex,
             mgra_dim,
             by="mgra_id")

sex_2019<- merge(sex_2019,
                 mgra_dim,
                 by="mgra_id")

sex_reg_2020<- sex_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","sex_id")]

sex_jur_2020<- sex_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","sex_id","jurisdiction")]

sex_cpa_2020<- sex_2020[ ,list(
  population.2020_1=sum(population.x),
  population.2020_2=sum(population.y)),
  by=c("yr_id","sex_id","cpa")]

sex_reg_2019<- sex_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","sex_id")]

sex_jur_2019<- sex_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","sex_id","jurisdiction")]

sex_cpa_2019<- sex_2019[ ,list(
  population.2019=sum(population)),
  by=c("yr_id","sex_id","cpa")]

hhinc<- merge(hhinc_2020_1,
              hhinc_2020_2,
            by=c("mgra_id","yr_id","income_group_id"),
            all=TRUE)
hhinc_2020<- merge(hhinc,
            mgra_dim,
            by="mgra_id")

hhinc_2019<- merge(hhinc_2019,
                   mgra_dim,
                   by="mgra_id")

hhinc_reg_2020<- hhinc_2020[ ,list(
  households.2020_1=sum(households.x),
  households.2020_2=sum(households.y)),
  by=c("yr_id","income_group_id")]

hhinc_jur_2020<- hhinc_2020[ ,list(
  households.2020_1=sum(households.x),
  households.2020_2=sum(households.y)),
  by=c("yr_id","income_group_id","jurisdiction")]

hhinc_cpa_2020<- hhinc_2020[ ,list(
  households.2020_1=sum(households.x),
  households.2020_2=sum(households.y)),
  by=c("yr_id","income_group_id","cpa")]

hhinc_reg_2019<- hhinc_2019[ ,list(
  households.2019=sum(households)),
  by=c("yr_id","income_group_id")]

hhinc_jur_2019<- hhinc_2019[ ,list(
  households.2019=sum(households)),
  by=c("yr_id","income_group_id","jurisdiction")]

hhinc_cpa_2019<- hhinc_2019[ ,list(
  households.2019=sum(households)),
  by=c("yr_id","income_group_id","cpa")]


#Saveout Data
wb1 = createWorkbook()

Reg_2020 = addWorksheet(wb1, "Reg_2020")
writeData(wb1, "Reg_2020", age_reg_2020)

Jur_2020 = addWorksheet(wb1, "Jur_2020")
writeData(wb1, "Jur_2020", age_jur_2020)

CPA_2020 = addWorksheet(wb1, "CPA_2020")
writeData(wb1, "CPA_2020", age_cpa_2020)

Reg_2019 = addWorksheet(wb1, "Reg_2019")
writeData(wb1, "Reg_2019", age_reg_2019)

Jur_2019 = addWorksheet(wb1, "Jur_2019")
writeData(wb1, "Jur_2019", age_jur_2019)

CPA_2019 = addWorksheet(wb1, "CPA_2019")
writeData(wb1, "CPA_2019", age_cpa_2019)


saveWorkbook(wb1, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-35 Estimates 2020_V2 QC//Output//age_2019_2020.xlsx", overwrite = TRUE)


wb2 = createWorkbook()

Reg_2020 = addWorksheet(wb2, "Reg_2020")
writeData(wb2, "Reg_2020", ethn_reg_2020)

Jur_2020 = addWorksheet(wb2, "Jur_2020")
writeData(wb2, "Jur_2020", ethn_jur_2020)

CPA_2020 = addWorksheet(wb2, "CPA_2020")
writeData(wb2, "CPA_2020", ethn_cpa_2020)

Reg_2019 = addWorksheet(wb2, "Reg_2019")
writeData(wb2, "Reg_2019", ethn_reg_2019)

Jur_2019 = addWorksheet(wb2, "Jur_2019")
writeData(wb2, "Jur_2019", ethn_jur_2019)

CPA_2019 = addWorksheet(wb2, "CPA_2019")
writeData(wb2, "CPA_2019", ethn_cpa_2019)


saveWorkbook(wb2, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-35 Estimates 2020_V2 QC//Output//ethnicity_2019_2020.xlsx", overwrite = TRUE)


wb3 = createWorkbook()

Reg_2020 = addWorksheet(wb3, "Reg_2020")
writeData(wb3, "Reg_2020", sex_reg_2020)

Jur_2020 = addWorksheet(wb3, "Jur_2020")
writeData(wb3, "Jur_2020", sex_jur_2020)

CPA_2020 = addWorksheet(wb3, "CPA_2020")
writeData(wb3, "CPA_2020", sex_cpa_2020)

Reg_2019 = addWorksheet(wb3, "Reg_2019")
writeData(wb3, "Reg_2019", sex_reg_2019)

Jur_2019 = addWorksheet(wb3, "Jur_2019")
writeData(wb3, "Jur_2019", sex_jur_2019)

CPA_2019 = addWorksheet(wb3, "CPA_2019")
writeData(wb3, "CPA_2019", sex_cpa_2019)

saveWorkbook(wb3, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-35 Estimates 2020_V2 QC//Output//sex_2019_2020.xlsx", overwrite = TRUE)


wb4 = createWorkbook()

Reg_2020 = addWorksheet(wb4, "Reg_2020")
writeData(wb4, "Reg_2020", hhinc_reg_2020)

Jur_2020 = addWorksheet(wb4, "Jur_2020")
writeData(wb4, "Jur_2020", hhinc_jur_2020)

CPA_2020 = addWorksheet(wb4, "CPA_2020")
writeData(wb4, "CPA_2020", hhinc_cpa_2020)

Reg_2019 = addWorksheet(wb4, "Reg_2019")
writeData(wb4, "Reg_2019", hhinc_reg_2019)

Jur_2019 = addWorksheet(wb4, "Jur_2019")
writeData(wb4, "Jur_2019", hhinc_jur_2019)

CPA_2019 = addWorksheet(wb4, "CPA_2019")
writeData(wb4, "CPA_2019", hhinc_cpa_2019)

saveWorkbook(wb4, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-35 Estimates 2020_V2 QC//Output//hhinc_2019_2020.xlsx", overwrite = TRUE)


