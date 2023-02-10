### Author: Kelsie Telson and Purva Singh
### Project: 2020- 32 Regional Plan Parking (Part 1)

### Part 1: Setting up the R environment and loading required packages


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("readSQL.R")
source("common_functions.R")


# Loading the packages
packages <- c("arsenal", "data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)

readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}

### Part 2: Loading the data


## 1. dim.mgra table: MGRA dimension table with attributes for reference  

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

dim_mgra<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id],[mgra],[cpa], [series], [region], [jurisdiction], [jurisdiction_id]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  WHERE series=14"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


mgra_list<- as.data.table(unique(dim_mgra$mgra))
mgra_list<-rename(mgra_list, mgra= V1)

## 2. priced: MGRAs with [pricing_requirements_scenario_id] = 1 and [mgra_scenario_id] = 1


priced<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra], [mgra_Scenario_id],[pricing_requirements_scenario_id]
      ,[mobility_hub_name]
      ,[mobility_hub_type]
      ,[PriceLoc2025]
      ,[PriceLoc2035]
      ,[PriceLoc2050]
      ,[PriceHr2025]
      ,[PriceHr2035]
      ,[PriceHr2050]
      ,[PriceDay2025]
      ,[PriceDay2035]
      ,[PriceDay2050]
      ,[PriceMon2025]
      ,[PriceMon2035]
      ,[PriceMon2050]
      ,[baseline_req_priced_mgra]
      ,[baseline_req_non_priced_mgra]
      ,[annual_chg_2036_to_2050_priced_mgra]
      ,[annual_chg_2036_to_2050_non_priced_mgra]
      FROM [sql2014b8].[RTP2021].[dbo].[mgra_parking] 
      WHERE [pricing_requirements_scenario_id] = 1 AND [mgra_Scenario_id] = 1"),
      stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## 3. Non-priced: MGRAs that appear in mobility hubs but are not listed in the priced table are considered 'non-priced'
mohub_np<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra],[City], [Transit], [MoHubName], [MoHubType], [TransitServices] 
                  FROM [sql2014b8].[rm].[dbo].[mgra13_in_mohub_amoeba_edits_v5]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


## 4. No-Parking: All other MGRAs (not in this table and not in mobility hubs) are not updated from the baseline.
##                Nick created this table to consolidate the above 3 steps into one place (1 row per MGRA)

np_out<- data.table::as.data.table(
  RODBC::sqlQuery(channel, 
                  paste0("SELECT *
                           FROM [sql2014a8].[ws].[dbo].[noz_parking_mgra_info]" ),
                           stringsAsFactors= FALSE),
  stringsAsFactors= FALSE)

odbcClose(channel)

### Part 3: QC tests and Analysis

## Part 1: Internal Consistency check- merging priced and non-priced and comparing with the np_out

# check 1: to check which mgras from mohub are NON-PRICED  
check1<- mohub_np%>%
  filter(!mgra %in% priced$mgra)

## adding a flag to priced and check1 (mohub non-priced)

priced$p.flag<- 1
check1$nonpricedmohub.flag<- 0

# merging priced + check 1 to create an exhaustive list and then compare with noz
all_mgra<- merge (priced, check1, by = 'mgra', all= TRUE )


# adding flags to np_out to compare
np_out<- np_out%>%
  mutate(flag= case_when((is.na(mohubname) & is.na(PriceLoc2025)) ~3, 
                         (!is.na(mohubname) & is.na (PriceLoc2025)) ~ 0, 
                         TRUE ~ 1))
# comparing priced mgras with mgras flagged as 1 in np_out

np_out_priced<- np_out%>%
  filter(flag== 1)%>%
  arrange(mgra)

priced<- priced%>%
  arrange(mgra)

identical(np_out_priced$mgra, priced$mgra)   ## TRUE

# comparing mobility hub non-priced mgras with check 1 mgras 

np_out_mohub_np<- np_out%>%
  filter(flag== 0)%>%
  arrange(mgra)

check1<- check1%>%
  arrange(mgra)

identical(np_out_mohub_np$mgra, check1$mgra) ## TRUE

# comparing non-mohub non-priced mgra (flagged as 3) with [dim-mgra- all_mgra]

np_out_nonmohub_np<- np_out%>%
  filter(flag== 3)%>%
  arrange(mgra)

non_mohub_np<- mgra_list%>%
  filter(!mgra %in% all_mgra$mgra)%>%
  arrange(mgra)

identical(np_out_nonmohub_np$mgra, non_mohub_np$mgra) ## TRUE




