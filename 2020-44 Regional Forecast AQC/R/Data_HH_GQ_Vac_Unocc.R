setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../queries/readSQL.R")
source("common_functions.R")

# Loading the packages
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)

readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}

## Loading data

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

## 1. dim.mgra table 

dim_mgra<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id],[mgra],[cpa], [series], [region], [jurisdiction], [jurisdiction_id]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  WHERE series=14"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## 2. RHNA table
rhna<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT * 
                  FROM [urbansim].[ref].[rhna_6th_housing_cycle]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## 3. Forecast Output tables- DS 38

ds_id=38

## group quarter- region, jurisdiction
gq_sql = getSQL("../Queries/group_quarter_w_description.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq_38<-sqlQuery(channel,gq_sql)

## jurisdiction,cpa,mgra_id,zip dimension table
jur_sql = getSQL("../Queries/mgra_denormalize2.sql")
jur_sql <- gsub("ds_id", ds_id,jur_sql)
jur_38<-sqlQuery(channel,jur_sql)

## housing table-- mgra level
mgra_sql = getSQL("../Queries/households.sql")
mgra_sql <- gsub("ds_id", ds_id,mgra_sql)
mgra_38<-sqlQuery(channel,mgra_sql)

## housing table-- jurisdiction level
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh_38<-sqlQuery(channel,hh_sql)

## population
mgra_pop_38<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [demographic_warehouse].[fact].[population]
                          WHERE datasource_id = 38 and housing_type_id =1 "),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)

## 4. Forecast Output tables- DS 35

ds_id2=35

## households-- jurisdiction level 
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id2,hh_sql)
hh_35<-sqlQuery(channel,hh_sql)

## group quarter

gq_sql = getSQL("../Queries/group_quarter_w_description.sql")
gq_sql <- gsub("ds_id", ds_id2,gq_sql)
gq_35<-sqlQuery(channel,gq_sql)

##households--mgra level
mgra_sql = getSQL("../Queries/households.sql")
mgra_sql <- gsub("ds_id", ds_id2,mgra_sql)
mgra_35<-sqlQuery(channel,mgra_sql)

## population-- mgra level

mgra_pop_35<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [demographic_warehouse].[fact].[population]
                          WHERE datasource_id = 35 and housing_type_id =1 "),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)



## 5. SCS output file--mgra_id level

hh_scs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                         FROM [urbansim].[urbansim].[urbansim_lite_output] 
                         WHERE run_id = 491"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## 6. SCS Input file 

scs_parcel<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [urbansim].[urbansim].[scs_parcel]
                          WHERE scenario_id=2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## 7. SCS XREF Table-- contains scenario_cap column
mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                         FROM [urbansim].[ref].[scs_mgra_xref]
                         WHERE mohub_version_id = 2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

## 8. Loading Jurisdiction ids for creating cross walk with urbansim parcel table 

jur_dt<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT DISTINCT jurisdiction, jurisdiction_id
                          FROM [demographic_warehouse].[dim].[mgra_denormalize]
                          WHERE series = 14 "),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)

odbcClose(channel)

# 9. DOF

dof<- read_excel("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-05 SCS Forecast 2020\\Data\\P1_County_1yr.xlsx", sheet = "Population by County")

dof<- dof[c(2,40),]
colnames(dof)<- dof[1,]
dof<- dof[, c("2016", "2018", "2020", "2025", "2030", "2035", "2040", "2045", "2050")]
dof<- as.data.frame(dof)
dof<- dof %>% 
  rownames_to_column() %>% ## from tidyverse
  gather(variable, value, -rowname) %>% 
  spread(rowname, value)
dof<- dof[,-1]
colnames(dof)

setnames(dof, old=c("1","2"), new=c("yr_id", "dof_pop"))
