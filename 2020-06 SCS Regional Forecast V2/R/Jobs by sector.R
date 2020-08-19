# This script was developed for test 7 of the Revised SCS forecast QA [DS 38]. 
## Test 7 has three parts: 
## a) Region level comparison of jobs by sector between DS 35 and 38
## b) Jurisdiction level comparison of jobs by sector between DS 35 and 38
## c) CPA level comparison of jobs by sector between DS 35 and 38
## d) Priority Area Analysis (Mobility Hub+ Smart Growth) of Jobs and Jobs by sector


##########

## Setting up the R environment 
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../queries/readSQL.R")
source("mohub_smartgrowth.R")


##loading necessary packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl")
pkgTest(packages)

## setting the output folders

outputfile <- paste("JobsbySector_SCS_QA_v2",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-06 SCS Regional Forecast V2\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))

#Loading the data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

jobs_38<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [jobs_id], [datasource_id], [yr_id], [mgra_id],[employment_type_id], [jobs]
                  FROM [demographic_warehouse].[fact].[jobs]
                         WHERE datasource_id= 38"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

jobs_35<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [jobs_id], [datasource_id], [yr_id], [mgra_id],[employment_type_id], [jobs]
                  FROM [demographic_warehouse].[fact].[jobs]
                         WHERE datasource_id= 35"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


dim_mgra_cpa<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id],[mgra], [series],[cpa], [region], [jurisdiction], [jurisdiction_id]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                         WHERE series=14"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

dim_mgra<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id],[mgra], [series], [region], [jurisdiction], [jurisdiction_id]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                         WHERE series=14"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


dim_jobs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [employment_type_id],[full_name], [civilian] 
                  FROM [demographic_warehouse].[dim].[employment_type]
                         "),
                  stringsAsFactors = FALSE), 
  stringsAsFactors = FALSE)

odbcClose(channel)

## Loading input files from urbansim database 

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=urbansim; trusted_connection=true')


scs_parcel<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [urbansim].[urbansim].[scs_parcel]
                         WHERE scenario_id=2"),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)


mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                         FROM [urbansim].[ref].[scs_mgra_xref]
                         WHERE mohub_version_id =2"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

sched_dev_parcel<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [urbansim].[urbansim].[non_res_sched_dev_parcel_scs_2]"),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)

sched_dev_site<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [site_id]
      ,[parcel_id]
      ,[capacity_3]
      ,[sfu_effective_adj]
      ,[mfu_effective_adj]
      ,[editor]
      ,[civGQ]
      ,[civemp_imputed]
      ,[sector_id]
      ,[civemp_notes]
       FROM [urbansim].[urbansim].[non_res_sched_dev_parcel_scs_2]"),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)


odbcClose(channel)


## merging dim_job with job_36 and job_35 to replace employment type id with employment type full names

jobs_35.1<- merge(jobs_35, dim_jobs, by.x = "employment_type_id", by.y = "employment_type_id", all = TRUE )
jobs_38.1<- merge(jobs_38, dim_jobs, by.x = "employment_type_id", by.y = "employment_type_id", all = TRUE )

jobs35.2<- jobs_35.1%>%
  select(-c(jobs_id, civilian))

jobs38.2<- jobs_38.1%>%
  select(-c(jobs_id, civilian))

setnames(jobs38.2, old = "full_name", new= "employment_type")
setnames(jobs35.2, old = "full_name", new= "employment_type")

jobs_35<- jobs35.2
jobs_38<- jobs38.2

rm(jobs_35.1, jobs_38.1, jobs35.2, jobs38.2)

jobs_35.1<- merge(jobs_35, dim_mgra, by.x = "mgra_id", by.y = "mgra_id", all = TRUE )
jobs_38.1<- merge(jobs_38, dim_mgra, by.x = "mgra_id", by.y = "mgra_id", all = TRUE )

jobs_35.2<-  jobs_35.1%>%
  select(-region)
jobs_38.2<- jobs_38.1%>%
  select(-region)

jobs_35<- jobs_35.2
jobs_38<- jobs_38.2

rm(jobs_35.1, jobs_38.1, jobs_35.2, jobs_38.2)

# merging jobs_36 and jobs_35 

#changing variable names before merge for distinction

setnames(jobs_38, old = "jobs", new= "jobs_38")
setnames(jobs_35, old = "jobs", new= "jobs_35")

jobs<- merge(jobs_35, jobs_38, by.x = c("mgra_id", "employment_type_id", "employment_type", "jurisdiction", "yr_id", "series", 
                                        "mgra", "jurisdiction_id"), by.y=  c("mgra_id", "employment_type_id", "employment_type", "jurisdiction", "yr_id", "series", 
                                                                             "mgra", "jurisdiction_id"), all= TRUE)
jobs<- jobs%>%
  select(-c(datasource_id.x, datasource_id.y))


## Test 7a.Region level comparison of absolute and % share of jobs by sector between DS 35 and DS 36


jobs_region_abs<-jobs%>%
  mutate(job_diff= jobs_38- jobs_35)%>%
  group_by (yr_id, employment_type_id, employment_type)%>%
  summarise_at(vars(jobs_35, jobs_38, job_diff), funs(sum))

jobs_region_total<- jobs%>%
  group_by(yr_id)%>%
  summarise_at(vars(jobs_35, jobs_38), funs(sum))

setnames(jobs_region_total, old= c("jobs_35", "jobs_38"), new= c("total_jobs_35", "total_jobs_38"))

jobs_region_Share<- merge(jobs_region_abs, jobs_region_total, by.x = "yr_id", by.y = "yr_id", all = TRUE)

jobs_region_Share<- jobs_region_Share%>%
  select(-job_diff)%>%
  mutate(prop_35= jobs_35/total_jobs_35,
         prop_38= jobs_38/total_jobs_38)


jobs_region_Share<- jobs_region_Share%>%
  group_by(employment_type, employment_type_id)%>%
  mutate(inc_change_38= jobs_38- lag(jobs_38), 
         inc_change_35= jobs_35- lag(jobs_35))


## Test 7b.Jurisdiction level comparison of absolute and % share of jobs by sector between DS 35 and DS 38


jobs_jur_abs<-jobs%>%
  mutate(job_diff= jobs_38- jobs_35)%>%
  group_by (yr_id,employment_type_id, employment_type, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(jobs_35, jobs_38, job_diff), funs(sum))
  
jobs_jur_total<- jobs%>%
  group_by(yr_id, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(jobs_35, jobs_38), funs(sum))

setnames(jobs_jur_total, old= c("jobs_35", "jobs_38"), new= c("total_jur_jobs_35", "total_jur_jobs_38"))

jobs_jur_share<- merge(jobs_jur_abs, jobs_region_total, by.x = "yr_id", by.y = "yr_id", all = TRUE)

jobs_jur_share<- merge(jobs_jur_share, jobs_jur_total, by.x = c("yr_id","jurisdiction_id", "jurisdiction"), by.y = c("yr_id","jurisdiction_id", "jurisdiction"), all = TRUE)

jobs_jur_share<- jobs_jur_share%>%
  select(-job_diff)%>%
  mutate(prop_total_35= jobs_35/total_jobs_35,
         prop_total_38= jobs_38/total_jobs_38,
         prop_jur_35= jobs_35/total_jur_jobs_35,
         prop_jur_38= jobs_38/total_jur_jobs_38)


jobs_jur_share<- jobs_jur_share%>%
  group_by(employment_type, employment_type_id, jurisdiction_id, jurisdiction)%>%
  mutate(inc_change_38= jobs_38- lag(jobs_38), 
         inc_change_35= jobs_35- lag(jobs_35))

## Test 7c. CPA level analysis

jobs_cpa<- merge(jobs, dim_mgra_cpa, by = c("mgra", "mgra_id", "jurisdiction", "jurisdiction_id"), all = TRUE)

jobs_cpa_total<- jobs_cpa%>%
  group_by(cpa, yr_id, jurisdiction, jurisdiction_id)%>%
  summarize_at(vars(jobs_35, jobs_38), funs(sum))

jobs_cpa_share<- jobs_cpa%>%
  group_by(cpa, yr_id, jurisdiction, jurisdiction_id, employment_type, employment_type_id)%>%
  summarize_at(vars(jobs_35, jobs_38), funs(sum))

jobs_pri_cpa<- merge(jobs_cpa, dim_mohub_sg, by= c("mgra", "mgra_id", "jurisdiction"), all= TRUE)

jobs_pri_cpa[is.na(jobs_pri_cpa)]<- 0

jobs_pri_cpa_in<- jobs_pri_cpa%>%
  filter(scs_flag== 1)

jobs_pri_cpa_in<- jobs_pri_cpa_in%>%
  group_by(cpa, yr_id, jurisdiction, jurisdiction_id, employment_type, employment_type_id)%>%
  summarize_at(vars(jobs_35, jobs_38), funs(sum))

jobs_pri_cpa_out<- jobs_pri_cpa%>%
  filter(scs_flag== 0)

jobs_pri_cpa_out<- jobs_pri_cpa_out%>%
  group_by(cpa, yr_id, jurisdiction, jurisdiction_id, employment_type, employment_type_id)%>%
  summarize_at(vars(jobs_35, jobs_38), funs(sum))
  
jobs_pri_cpa_share<- merge(jobs_pri_cpa_in, jobs_pri_cpa_out, by = c( "yr_id", "employment_type", "cpa", "jurisdiction"),all = TRUE)
setnames(jobs_pri_cpa_share, old= c("jobs_35.x","jobs_35.y","jobs_38.x", "jobs_38.y"), new = c("jobs_35_in","jobs_35_out", "jobs_38_in","jobs_38_out"))

jobs_pri_cpa_total<- jobs_pri_cpa_share%>%
  group_by(yr_id, cpa, jurisdiction)%>%
  summarise_at(vars(jobs_35_in, jobs_35_out, jobs_38_in, jobs_38_out), funs(sum))


## Test 7d. Priority Area Analysis 

## Step 1. Combining jobs_35 and jobs_38

jobs_pri<- merge(jobs_35, jobs_38, by = c("mgra_id", "employment_type", "employment_type_id", "yr_id", "jurisdiction"), all= TRUE)

## Step 2. COmbining jobs_pri with dim_mohub_sg

jobs_pri<- merge(jobs_pri, dim_mohub_sg, by = c("mgra_id", "jurisdiction"), all= TRUE)

## Step 3. Region level Analysis

jobs_pri_region<- jobs_pri%>%
  group_by(yr_id, employment_type, employment_type_id, scs_flag)%>%
  summarise_at(vars(jobs_35, jobs_38), funs(sum))

jobs_pri_region[is.na(jobs_pri_region)]<- 0

jobs_pri_region_in<- jobs_pri_region%>%
  filter(scs_flag== 1)

jobs_pri_region_out<- jobs_pri_region%>%
  filter(scs_flag== 0)

jobs_pri_region<- merge(jobs_pri_region_in, jobs_pri_region_out, by = c("yr_id", "employment_type", "employment_type_id"), all = TRUE)
setnames(jobs_pri_region, old= c("jobs_35.x","jobs_35.y","jobs_38.x", "jobs_38.y"), new = c("jobs_35_in","jobs_35_out", "jobs_38_in","jobs_38_out"))

jobs_pri_region_final<- merge(jobs_pri_region, jobs_region_total, by = "yr_id", all = TRUE)

jobs_pri_reg_total<- jobs_pri_region_final%>%
  group_by(yr_id)%>%
  summarise_at(vars(jobs_35_in, jobs_35_out, jobs_38_in, jobs_38_out), funs(sum))

jobs_pri_reg_total<- merge(jobs_pri_reg_total, jobs_region_total, by = "yr_id", all = TRUE)

## Step 4. Jurisdiction level analysis

jobs_pri_jur<- jobs_pri%>%
  group_by(yr_id, employment_type, employment_type_id, scs_flag, jurisdiction)%>%
  summarise_at(vars(jobs_35, jobs_38), funs(sum))

jobs_pri_jur[is.na(jobs_pri_jur)]<- 0

jobs_pri_jur_in<- jobs_pri_jur%>%
  filter(scs_flag== 1)

jobs_pri_jur_out<- jobs_pri_jur%>%
  filter(scs_flag== 0)

jobs_pri_jur<- merge(jobs_pri_jur_in, jobs_pri_jur_out, by = c("yr_id", "employment_type", "employment_type_id", "jurisdiction"), all = TRUE)
setnames(jobs_pri_jur, old= c("jobs_35.x","jobs_35.y","jobs_38.x", "jobs_38.y"), new = c("jobs_35_in","jobs_35_out", "jobs_38_in","jobs_38_out"))


jobs_pri_jur_final<- merge(jobs_pri_jur, jobs_jur_total, by = c("yr_id","jurisdiction"), all = TRUE)

jobs_pri_jur_total<- jobs_pri_jur_final%>%
  group_by(yr_id, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(jobs_35_in, jobs_35_out, jobs_38_in, jobs_38_out), funs(sum))

jobs_pri_jur_total<- merge(jobs_pri_jur_total, jobs_jur_total, by= c("yr_id", "jurisdiction"), all = TRUE)


#################################################

#saving and formatting output


wb1 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

total_region= addWorksheet(wb1, "TotalJobs_Region", tabColour = "purple")
writeData(wb1, "TotalJobs_Region", jobs_region_total)
addStyle(wb1,total_region, style = headerStyle, rows = 1, cols = 1: ncol(jobs_region_total), gridExpand = TRUE)
  
total_jur= addWorksheet(wb1, "TotalJobs_Jur", tabColour = "red")
writeData(wb1, "TotalJobs_Jur", jobs_jur_total)
addStyle(wb1,total_jur, style = headerStyle, rows = 1, cols = 1: ncol(jobs_jur_total), gridExpand = TRUE)

region = addWorksheet(wb1, "JobsbySector_Region", tabColour = "yellow")
writeData(wb1, "JobsbySector_Region", jobs_region_Share)
addStyle(wb1,region, style = headerStyle, rows = 1, cols = 1: ncol(jobs_region_Share), gridExpand = TRUE)

jurisdiction = addWorksheet(wb1, "JobsbySector_Jurisdiction", tabColour = "cyan")
writeData(wb1, "JobsbySector_Jurisdiction", jobs_jur_share)
addStyle(wb1,jurisdiction, style = headerStyle, rows = 1, cols = 1: ncol(jobs_jur_share), gridExpand = TRUE)

pri_region= addWorksheet(wb1, "PriorityArea_Region", tabColour = "orange")
writeData(wb1, "PriorityArea_Region", jobs_pri_reg_total) 
addStyle(wb1,pri_region, style = headerStyle, rows = 1, cols = 1: ncol(jobs_pri_reg_total), gridExpand = TRUE)

pri_jur= addWorksheet(wb1, "PriorityArea_Jur", tabColour = "green")
writeData(wb1, "PriorityArea_Jur", jobs_pri_jur_total) 
addStyle(wb1,pri_jur, style = headerStyle, rows = 1, cols = 1: ncol(jobs_pri_jur_total), gridExpand = TRUE)

pri_reg_sector= addWorksheet(wb1, "PriorityArea_Region_Sector", tabColour = "orange")
writeData(wb1, "PriorityArea_Region_Sector", jobs_pri_region_final) 
addStyle(wb1,pri_reg_sector, style = headerStyle, rows = 1, cols = 1: ncol(jobs_pri_region_final), gridExpand = TRUE)

pri_jur_sector= addWorksheet(wb1, "PriorityArea_Jur_Sector", tabColour = "green")
writeData(wb1, "PriorityArea_Jur_Sector", jobs_pri_jur_final) 
addStyle(wb1,pri_jur_sector, style = headerStyle, rows = 1, cols = 1: ncol(jobs_pri_jur_final), gridExpand = TRUE)

cpa_total= addWorksheet(wb1, "TotalJobs_CPA", tabColour = "red")
writeData(wb1, "TotalJobs_CPA", jobs_cpa_total) 
addStyle(wb1,cpa_total, style = headerStyle, rows = 1, cols = 1: ncol(jobs_cpa_total), gridExpand = TRUE)

cpa_share= addWorksheet(wb1, "JobsbySector_CPA", tabColour = "blue")
writeData(wb1, "JobsbySector_CPA", jobs_cpa_share) 
addStyle(wb1,cpa_share, style = headerStyle, rows = 1, cols = 1: ncol(jobs_cpa_share), gridExpand = TRUE)

cpa_pri_total= addWorksheet(wb1, "PriorityArea_CPA", tabColour = "yellow")
writeData(wb1, "PriorityArea_CPA", jobs_pri_cpa_total) 
addStyle(wb1,cpa_pri_total, style = headerStyle, rows = 1, cols = 1: ncol(jobs_pri_cpa_total), gridExpand = TRUE)

cpa_pri_share= addWorksheet(wb1, "PriorityArea_CPA_Sector", tabColour = "red")
writeData(wb1, "PriorityArea_CPA_Sector", jobs_pri_cpa_share) 
addStyle(wb1,cpa_pri_share, style = headerStyle, rows = 1, cols = 1: ncol(jobs_pri_cpa_share), gridExpand = TRUE)

saveWorkbook(wb1, outfile,overwrite=TRUE)





