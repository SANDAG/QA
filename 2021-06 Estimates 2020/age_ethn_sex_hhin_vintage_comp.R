#Purpose: 2021-06 Estimates for 2020 - Vintage Comparison
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
age_2020 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[age_group_id]
                  ,[population]
                  FROM [estimates].[est_2020_01].[dw_age]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

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

#2020 hh_income estimates
hhinc_2020 <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[yr_id]
                  ,[income_group_id]
                  ,[households]
                  FROM [estimates].[est_2020_01].[dw_household_income]"),
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
age<- merge(age_2020,
            age_2019,
            by=c("mgra_id","yr_id","age_group_id"),
            all=TRUE)
age<- merge(age,
            mgra_dim,
            by="mgra_id")

age_reg<- age[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","age_group_id")]

age_jur<- age[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","age_group_id","jurisdiction")]

age_cpa<- age[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","age_group_id","cpa")]

age_zip<- age[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","age_group_id","zip")]

rm(age_2020,age_2019,age)

ethn<- merge(ethn_2020,
             ethn_2019,
            by=c("mgra_id","yr_id","ethnicity_id"),
            all=TRUE)
ethn<- merge(ethn,
            mgra_dim,
            by="mgra_id")

ethn_reg<- ethn[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","ethnicity_id")]

ethn_jur<- ethn[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","ethnicity_id","jurisdiction")]

ethn_cpa<- ethn[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","ethnicity_id","cpa")]

ethn_zip<- ethn[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","ethnicity_id","zip")]

rm(ethn_2020,ethn_2019,ethn)

sex<- merge(sex_2020,
            sex_2019,
             by=c("mgra_id","yr_id","sex_id"),
             all=TRUE)
sex<- merge(sex,
             mgra_dim,
             by="mgra_id")

sex_reg<- sex[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","sex_id")]

sex_jur<- sex[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","sex_id","jurisdiction")]

sex_cpa<- sex[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","sex_id","cpa")]

sex_zip<- sex[ ,list(
  population.2020=sum(population.x),
  population.2019=sum(population.y)),
  by=c("yr_id","sex_id","zip")]

rm(sex_2020,sex_2019,sex)

hhinc<- merge(hhinc_2020,
              hhinc_2019,
            by=c("mgra_id","yr_id","income_group_id"),
            all=TRUE)
hhinc<- merge(hhinc,
            mgra_dim,
            by="mgra_id")

hhinc_reg<- hhinc[ ,list(
  households.2020=sum(households.x),
  households.2019=sum(households.y)),
  by=c("yr_id","income_group_id")]

hhinc_jur<- hhinc[ ,list(
  households.2020=sum(households.x),
  households.2019=sum(households.y)),
  by=c("yr_id","income_group_id","jurisdiction")]

hhinc_cpa<- hhinc[ ,list(
  households.2020=sum(households.x),
  households.2019=sum(households.y)),
  by=c("yr_id","income_group_id","cpa")]

hhinc_zip<- hhinc[ ,list(
  households.2020=sum(households.x),
  households.2019=sum(households.y)),
  by=c("yr_id","income_group_id","zip")]


rm(hhinc_2020,hhinc_2019,hhinc)

##Calculate % change
pct_change <- function(current,previous){
  result <- ((current-previous)/previous)*100
  return(result)
}

age_reg$pct_change<- pct_change(age_reg$population.2020,age_reg$population.2019)
age_reg<- age_reg %>% select(-(population.2020:population.2019))
#age_reg<- subset(age_reg,pct_change>5|pct_change< -5)
age_reg <- age_reg %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)

age_jur$pct_change<- pct_change(age_jur$population.2020,age_jur$population.2019)
age_jur<- age_jur %>% select(-(population.2020:population.2019))
#age_jur<- subset(age_jur,pct_change>5|pct_change< -5)
age_jur <- age_jur %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)

age_cpa$pct_change<- pct_change(age_cpa$population.2020,age_cpa$population.2019)
age_cpa<- age_cpa %>% select(-(population.2020:population.2019))
#age_cpa<- subset(age_cpa,pct_change>5|pct_change< -5)
age_cpa <- age_cpa %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


age_zip$pct_change<- pct_change(age_zip$population.2020,age_zip$population.2019)
age_zip<- age_zip %>% select(-(population.2020:population.2019))
#age_zip<- subset(age_zip,pct_change>5|pct_change< -5)
age_zip <- age_zip %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


ethn_reg$pct_change<- pct_change(ethn_reg$population.2020,ethn_reg$population.2019)
ethn_reg<- ethn_reg %>% select(-(population.2020:population.2019))
#ethn_reg<- subset(ethn_reg,pct_change>5|pct_change< -5)
ethn_reg <- ethn_reg %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)

ethn_jur$pct_change<- pct_change(ethn_jur$population.2020,ethn_jur$population.2019)
ethn_jur<- ethn_jur %>% select(-(population.2020:population.2019))
#ethn_jur<- subset(ethn_jur,pct_change>5|pct_change< -5)
ethn_jur <- ethn_jur %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)

ethn_cpa$pct_change<- pct_change(ethn_cpa$population.2020,ethn_cpa$population.2019)
ethn_cpa<- ethn_cpa %>% select(-(population.2020:population.2019))
#ethn_cpa<- subset(ethn_cpa,pct_change>5|pct_change< -5)
ethn_cpa <- ethn_cpa %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


ethn_zip$pct_change<- pct_change(ethn_zip$population.2020,ethn_zip$population.2019)
ethn_zip<- ethn_zip %>% select(-(population.2020:population.2019))
#ethn_zip<- subset(ethn_zip,pct_change>5|pct_change< -5)
ethn_zip <- ethn_zip %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


sex_reg$pct_change<- pct_change(sex_reg$population.2020,sex_reg$population.2019)
sex_reg<- sex_reg %>% select(-(population.2020:population.2019))
#sex_reg<- subset(sex_reg,pct_change>5|pct_change< -5)
sex_reg <- sex_reg %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


sex_jur$pct_change<- pct_change(sex_jur$population.2020,sex_jur$population.2019)
sex_jur<- sex_jur %>% select(-(population.2020:population.2019))
#sex_jur<- subset(sex_jur,pct_change>5|pct_change< -5)
sex_jur <- sex_jur %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


sex_cpa$pct_change<- pct_change(sex_cpa$population.2020,sex_cpa$population.2019)
sex_cpa<- sex_cpa %>% select(-(population.2020:population.2019))
#sex_cpa<- subset(sex_cpa,pct_change>5|pct_change< -5)
sex_cpa <- sex_cpa %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


sex_zip$pct_change<- pct_change(sex_zip$population.2020,sex_zip$population.2019)
sex_zip<- sex_zip %>% select(-(population.2020:population.2019))
#sex_zip<- subset(sex_zip,pct_change>5|pct_change< -5)
sex_zip <- sex_zip %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


hhinc_reg$pct_change<- pct_change(hhinc_reg$households.2020,hhinc_reg$households.2019)
hhinc_reg<- hhinc_reg %>% select(-(households.2020:households.2019))
#hhinc_reg<- subset(hhinc_reg,pct_change>5|pct_change< -5)
hhinc_reg <- hhinc_reg %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


hhinc_jur$pct_change<- pct_change(hhinc_jur$households.2020,hhinc_jur$households.2019)
hhinc_jur<- hhinc_jur %>% select(-(households.2020:households.2019))
#hhinc_jur<- subset(hhinc_jur,pct_change>5|pct_change< -5)
hhinc_jur <- hhinc_jur %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


hhinc_cpa$pct_change<- pct_change(hhinc_cpa$households.2020,hhinc_cpa$households.2019)
hhinc_cpa<- hhinc_cpa %>% select(-(households.2020:households.2019))
#hhinc_cpa<- subset(hhinc_cpa,pct_change>5|pct_change< -5)
hhinc_cpa <- hhinc_cpa %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


hhinc_zip$pct_change<- pct_change(hhinc_zip$households.2020,hhinc_zip$households.2019)
hhinc_zip<- hhinc_zip %>% select(-(households.2020:households.2019))
#hhinc_zip<- subset(age_zip,pct_change>5|pct_change< -5)
hhinc_zip <- hhinc_zip %>% 
  pivot_wider(names_from= yr_id,
              values_from= pct_change)


#Saveout Data
wb1 = createWorkbook()

Reg = addWorksheet(wb1, "Reg")
writeData(wb1, "Reg", age_reg)


Jur = addWorksheet(wb1, "Jur")
writeData(wb1, "Jur", age_jur)

CPA = addWorksheet(wb1, "CPA")
writeData(wb1, "CPA", age_cpa)

ZIP = addWorksheet(wb1, "ZIP")
writeData(wb1, "ZIP", age_zip)

cellStyle <- createStyle(fontColour = "#9C5700", bgFill = "#FFEB9C")
cellStyle2 <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")
conditionalFormatting(wb1, sheet = "Reg", cols = 2:ncol(age_reg), rows=2:nrow(age_reg), rule = ">5", style = cellStyle)
conditionalFormatting(wb1, sheet = "Jur", cols = 3:ncol(age_jur), rows=2:nrow(age_jur), rule = ">5", style = cellStyle)
conditionalFormatting(wb1, sheet = "CPA", cols = 3:ncol(age_cpa), rows=2:nrow(age_cpa), rule = ">5", style = cellStyle)
conditionalFormatting(wb1, sheet = "ZIP", cols = 3:ncol(age_zip), rows=2:nrow(age_zip), rule = ">5", style = cellStyle)
conditionalFormatting(wb1, sheet = "Reg", cols = 2:ncol(age_reg), rows=2:nrow(age_reg), rule = "<-5", style = cellStyle)
conditionalFormatting(wb1, sheet = "Jur", cols = 3:ncol(age_jur), rows=2:nrow(age_jur), rule = "<-5", style = cellStyle)
conditionalFormatting(wb1, sheet = "CPA", cols = 3:ncol(age_cpa), rows=2:nrow(age_cpa), rule = "<-5", style = cellStyle)
conditionalFormatting(wb1, sheet = "ZIP", cols = 3:ncol(age_zip), rows=2:nrow(age_zip), rule = "<-5", style = cellStyle)
conditionalFormatting(wb1, sheet = "Reg", cols = 2:ncol(age_reg), rows=2:nrow(age_reg), rule = ">10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "Jur", cols = 3:ncol(age_jur), rows=2:nrow(age_jur), rule = ">10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "CPA", cols = 3:ncol(age_cpa), rows=2:nrow(age_cpa), rule = ">10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "ZIP", cols = 3:ncol(age_zip), rows=2:nrow(age_zip), rule = ">10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "Reg", cols = 2:ncol(age_reg), rows=2:nrow(age_reg), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "Jur", cols = 3:ncol(age_jur), rows=2:nrow(age_jur), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "CPA", cols = 3:ncol(age_cpa), rows=2:nrow(age_cpa), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb1, sheet = "ZIP", cols = 3:ncol(age_zip), rows=2:nrow(age_zip), rule = "<-10", style = cellStyle2)
saveWorkbook(wb1, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-08 Estimates QC//Output//age_vintage.xlsx", overwrite = TRUE)


wb2 = createWorkbook()

Reg = addWorksheet(wb2, "Reg")
writeData(wb2, "Reg", ethn_reg)

Jur = addWorksheet(wb2, "Jur")
writeData(wb2, "Jur", ethn_jur)

CPA = addWorksheet(wb2, "CPA")
writeData(wb2, "CPA", ethn_cpa)

ZIP = addWorksheet(wb2, "ZIP")
writeData(wb2, "ZIP", ethn_zip)

cellStyle <- createStyle(fontColour = "#9C5700", bgFill = "#FFEB9C")
cellStyle10 <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")
conditionalFormatting(wb2, sheet = "Reg", cols = 2:ncol(ethn_reg), rows=2:nrow(ethn_reg), rule = ">5", style = cellStyle)
conditionalFormatting(wb2, sheet = "Jur", cols = 3:ncol(ethn_jur), rows=2:nrow(ethn_jur), rule = ">5", style = cellStyle)
conditionalFormatting(wb2, sheet = "CPA", cols = 3:ncol(ethn_cpa), rows=2:nrow(ethn_cpa), rule = ">5", style = cellStyle)
conditionalFormatting(wb2, sheet = "ZIP", cols = 3:ncol(ethn_zip), rows=2:nrow(ethn_zip), rule = ">5", style = cellStyle)
conditionalFormatting(wb2, sheet = "Reg", cols = 2:ncol(ethn_reg), rows=2:nrow(ethn_reg), rule = "<-5", style = cellStyle)
conditionalFormatting(wb2, sheet = "Jur", cols = 3:ncol(ethn_jur), rows=2:nrow(ethn_jur), rule = "<-5", style = cellStyle)
conditionalFormatting(wb2, sheet = "CPA", cols = 3:ncol(ethn_cpa), rows=2:nrow(ethn_cpa), rule = "<-5", style = cellStyle)
conditionalFormatting(wb2, sheet = "ZIP", cols = 3:ncol(ethn_zip), rows=2:nrow(ethn_zip), rule = "<-5", style = cellStyle)
conditionalFormatting(wb2, sheet = "Reg", cols = 2:ncol(ethn_reg), rows=2:nrow(ethn_reg), rule = ">10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "Jur", cols = 3:ncol(ethn_jur), rows=2:nrow(ethn_jur), rule = ">10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "CPA", cols = 3:ncol(ethn_cpa), rows=2:nrow(ethn_cpa), rule = ">10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "ZIP", cols = 3:ncol(ethn_zip), rows=2:nrow(ethn_zip), rule = ">10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "Reg", cols = 2:ncol(ethn_reg), rows=2:nrow(ethn_reg), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "Jur", cols = 3:ncol(ethn_jur), rows=2:nrow(ethn_jur), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "CPA", cols = 3:ncol(ethn_cpa), rows=2:nrow(ethn_cpa), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb2, sheet = "ZIP", cols = 3:ncol(ethn_zip), rows=2:nrow(ethn_zip), rule = "<-10", style = cellStyle2)
saveWorkbook(wb2, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-08 Estimates QC//Output//ethnicity_vintage.xlsx", overwrite = TRUE)


wb3 = createWorkbook()

Reg = addWorksheet(wb3, "Reg")
writeData(wb3, "Reg", sex_reg)

Jur = addWorksheet(wb3, "Jur")
writeData(wb3, "Jur", sex_jur)

CPA = addWorksheet(wb3, "CPA")
writeData(wb3, "CPA", sex_cpa)

ZIP = addWorksheet(wb3, "ZIP")
writeData(wb3, "ZIP", sex_zip)

cellStyle <- createStyle(fontColour = "#9C5700", bgFill = "#FFEB9C")
cellStyle10 <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")
conditionalFormatting(wb3, sheet = "Reg", cols = 2:ncol(sex_reg), rows=2:nrow(sex_reg), rule = ">5", style = cellStyle)
conditionalFormatting(wb3, sheet = "Jur", cols = 3:ncol(sex_jur), rows=2:nrow(sex_jur), rule = ">5", style = cellStyle)
conditionalFormatting(wb3, sheet = "CPA", cols = 3:ncol(sex_cpa), rows=2:nrow(sex_cpa), rule = ">5", style = cellStyle)
conditionalFormatting(wb3, sheet = "ZIP", cols = 3:ncol(sex_zip), rows=2:nrow(sex_zip), rule = ">5", style = cellStyle)
conditionalFormatting(wb3, sheet = "Reg", cols = 2:ncol(sex_reg), rows=2:nrow(sex_reg), rule = "<-5", style = cellStyle)
conditionalFormatting(wb3, sheet = "Jur", cols = 3:ncol(sex_jur), rows=2:nrow(sex_jur), rule = "<-5", style = cellStyle)
conditionalFormatting(wb3, sheet = "CPA", cols = 3:ncol(sex_cpa), rows=2:nrow(sex_cpa), rule = "<-5", style = cellStyle)
conditionalFormatting(wb3, sheet = "ZIP", cols = 3:ncol(sex_zip), rows=2:nrow(sex_zip), rule = "<-5", style = cellStyle)
conditionalFormatting(wb3, sheet = "Reg", cols = 2:ncol(sex_reg), rows=2:nrow(sex_reg), rule = ">10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "Jur", cols = 3:ncol(sex_jur), rows=2:nrow(sex_jur), rule = ">10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "CPA", cols = 3:ncol(sex_cpa), rows=2:nrow(sex_cpa), rule = ">10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "ZIP", cols = 3:ncol(sex_zip), rows=2:nrow(sex_zip), rule = ">10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "Reg", cols = 2:ncol(sex_reg), rows=2:nrow(sex_reg), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "Jur", cols = 3:ncol(sex_jur), rows=2:nrow(sex_jur), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "CPA", cols = 3:ncol(sex_cpa), rows=2:nrow(sex_cpa), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb3, sheet = "ZIP", cols = 3:ncol(sex_zip), rows=2:nrow(sex_zip), rule = "<-10", style = cellStyle2)
saveWorkbook(wb3, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-08 Estimates QC//Output//sex_vintage.xlsx", overwrite = TRUE)


wb4 = createWorkbook()

Reg = addWorksheet(wb4, "Reg")
writeData(wb4, "Reg", hhinc_reg)

Jur = addWorksheet(wb4, "Jur")
writeData(wb4, "Jur", hhinc_jur)

CPA = addWorksheet(wb4, "CPA")
writeData(wb4, "CPA", hhinc_cpa)

ZIP = addWorksheet(wb4, "ZIP")
writeData(wb4, "ZIP", hhinc_zip)

cellStyle <- createStyle(fontColour = "#9C5700", bgFill = "#FFEB9C")
cellStyle10 <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")
conditionalFormatting(wb4, sheet = "Reg", cols = 2:ncol(hhinc_reg), rows=2:nrow(hhinc_reg), rule = ">5", style = cellStyle)
conditionalFormatting(wb4, sheet = "Jur", cols = 3:ncol(hhinc_jur), rows=2:nrow(hhinc_jur), rule = ">5", style = cellStyle)
conditionalFormatting(wb4, sheet = "CPA", cols = 3:ncol(hhinc_cpa), rows=2:nrow(hhinc_cpa), rule = ">5", style = cellStyle)
conditionalFormatting(wb4, sheet = "ZIP", cols = 3:ncol(hhinc_zip), rows=2:nrow(hhinc_zip), rule = ">5", style = cellStyle)
conditionalFormatting(wb4, sheet = "Reg", cols = 2:ncol(hhinc_reg), rows=2:nrow(hhinc_reg), rule = "<-5", style = cellStyle)
conditionalFormatting(wb4, sheet = "Jur", cols = 3:ncol(hhinc_jur), rows=2:nrow(hhinc_jur), rule = "<-5", style = cellStyle)
conditionalFormatting(wb4, sheet = "CPA", cols = 3:ncol(hhinc_cpa), rows=2:nrow(hhinc_cpa), rule = "<-5", style = cellStyle)
conditionalFormatting(wb4, sheet = "ZIP", cols = 3:ncol(hhinc_zip), rows=2:nrow(hhinc_zip), rule = "<-5", style = cellStyle)
conditionalFormatting(wb4, sheet = "Reg", cols = 2:ncol(hhinc_reg), rows=2:nrow(hhinc_reg), rule = ">10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "Jur", cols = 3:ncol(hhinc_jur), rows=2:nrow(hhinc_jur), rule = ">10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "CPA", cols = 3:ncol(hhinc_cpa), rows=2:nrow(hhinc_cpa), rule = ">10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "ZIP", cols = 3:ncol(hhinc_zip), rows=2:nrow(hhinc_zip), rule = ">10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "Reg", cols = 2:ncol(hhinc_reg), rows=2:nrow(hhinc_reg), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "Jur", cols = 3:ncol(hhinc_jur), rows=2:nrow(hhinc_jur), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "CPA", cols = 3:ncol(hhinc_cpa), rows=2:nrow(hhinc_cpa), rule = "<-10", style = cellStyle2)
conditionalFormatting(wb4, sheet = "ZIP", cols = 3:ncol(hhinc_zip), rows=2:nrow(hhinc_zip), rule = "<-10", style = cellStyle2)
saveWorkbook(wb4, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-08 Estimates QC//Output//hhinc_vintage.xlsx", overwrite = TRUE)


