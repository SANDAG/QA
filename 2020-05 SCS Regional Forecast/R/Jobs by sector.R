# This script was developed for test 7 of the SCS forecast QA [DS 36]. 
##Test 7 has three parts: 
## a) Region level comparison of jobs by sector between DS 35 and 36
## b) Jurisdiction level comparison of jobs by sector between DS 35 and 36
## c) Mobility hub (within and outside mohub) compairson of jobs by sector at jurisdiction level between DS 35 and 36 



##########

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

## setting the working directory and output folders

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../queries/readSQL.R")

options(stringsAsFactors=FALSE)


outputfile <- paste("JobsbySector_SCS_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\Documents\\GitHub\\QA\\2020-05 SCS Regional Forecast\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))

#Loading the data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#dim.mgra table 

jobs_36<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [jobs_id], [datasource_id], [yr_id], [mgra_id],[employment_type_id], [jobs]
                  FROM [demographic_warehouse].[fact].[jobs]
                         WHERE datasource_id= 36"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

jobs_35<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [jobs_id], [datasource_id], [yr_id], [mgra_id],[employment_type_id], [jobs]
                  FROM [demographic_warehouse].[fact].[jobs]
                         WHERE datasource_id= 35"),
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
                          FROM [urbansim].[urbansim].[scs_parcel]"),
                  stringsAsFactors = FALSE),
  
  stringsAsFactors = FALSE)


mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                         FROM [urbansim].[ref].[scs_mgra_xref]"),
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
jobs_36.1<- merge(jobs_36, dim_jobs, by.x = "employment_type_id", by.y = "employment_type_id", all = TRUE )

jobs35.2<- jobs_35.1%>%
  select(-c(jobs_id, civilian))

jobs36.2<- jobs_36.1%>%
  select(-c(jobs_id, civilian))

setnames(jobs36.2, old = "full_name", new= "employment_type")
setnames(jobs35.2, old = "full_name", new= "employment_type")

jobs_35<- jobs35.2
jobs_36<- jobs36.2

rm(jobs_35.1, jobs_36.1, jobs35.2, jobs36.2)

jobs_35.1<- merge(jobs_35, dim_mgra, by.x = "mgra_id", by.y = "mgra_id", all = TRUE )
jobs_36.1<- merge(jobs_36, dim_mgra, by.x = "mgra_id", by.y = "mgra_id", all = TRUE )

jobs_35.2<-  jobs_35.1%>%
  select(-region)
jobs_36.2<- jobs_36.1%>%
  select(-region)

jobs_35<- jobs_35.2
jobs_36<- jobs_36.2

rm(jobs_35.1, jobs_36.1, jobs_35.2, jobs_36.2)

# merging jobs_36 and jobs_35 

#changing variable names before merge for distinction

setnames(jobs_36, old = "jobs", new= "jobs_36")
setnames(jobs_35, old = "jobs", new= "jobs_35")

jobs<- merge(jobs_35, jobs_36, by.x = c("mgra_id", "employment_type_id", "employment_type", "jurisdiction", "yr_id", "series", 
                                        "mgra", "jurisdiction_id"), by.y=  c("mgra_id", "employment_type_id", "employment_type", "jurisdiction", "yr_id", "series", 
                                                                             "mgra", "jurisdiction_id"), all= TRUE)
jobs<- jobs%>%
  select(-c(datasource_id.x, datasource_id.y))


## Test 7a.Region level comparison of absolute and % share of jobs by sector between DS 35 and DS 36


jobs_region_abs<-jobs%>%
  mutate(job_diff= jobs_36- jobs_35)%>%
  group_by (yr_id, employment_type_id, employment_type)%>%
  summarise_at(vars(jobs_35, jobs_36, job_diff), funs(sum))

jobs_region_total<- jobs%>%
  group_by(yr_id)%>%
  summarise_at(vars(jobs_35, jobs_36), funs(sum))

setnames(jobs_region_total, old= c("jobs_35", "jobs_36"), new= c("total_jobs_35", "total_jobs_36"))

jobs_region_Share<- merge(jobs_region_abs, jobs_region_total, by.x = "yr_id", by.y = "yr_id", all = TRUE)

jobs_region_Share<- jobs_region_Share%>%
  select(-job_diff)%>%
  mutate(prop_35= jobs_35/total_jobs_35,
         prop_36= jobs_36/total_jobs_36)




## Test 7b.Jurisdiction level comparison of absolute and % share of jobs by sector between DS 35 and DS 36


jobs_jur_abs<-jobs%>%
  mutate(job_diff= jobs_36- jobs_35)%>%
  group_by (yr_id,employment_type_id, employment_type, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(jobs_35, jobs_36, job_diff), funs(sum))
  
jobs_jur_total<- jobs%>%
  group_by(yr_id, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(jobs_35, jobs_36), funs(sum))

setnames(jobs_jur_total, old= c("jobs_35", "jobs_36"), new= c("total_jur_jobs_35", "total_jur_jobs_36"))

jobs_jur_share<- merge(jobs_jur_abs, jobs_region_total, by.x = "yr_id", by.y = "yr_id", all = TRUE)

jobs_jur_share<- merge(jobs_jur_share, jobs_jur_total, by.x = c("yr_id","jurisdiction_id", "jurisdiction"), by.y = c("yr_id","jurisdiction_id", "jurisdiction"), all = TRUE)

jobs_jur_share<- jobs_jur_share%>%
  select(-job_diff)%>%
  mutate(prop_total_35= jobs_35/total_jobs_35,
         prop_total_36= jobs_36/total_jobs_36,
         prop_jur_35= jobs_35/total_jur_jobs_35,
         prop_jur_36= jobs_36/total_jur_jobs_36)


## Test 7c.Mobility Hub comparison of absolute and % share of jobs by sector between DS 35 and DS 36 (at jurisdiction level)

#Step 1. group mgra_ids by mgra

jobs_mgra<- jobs%>%
  group_by(mgra, yr_id, jurisdiction, jurisdiction_id, employment_type, employment_type_id)%>%
  summarise_at(vars(jobs_35, jobs_36), funs(sum))

#Step 2.combining mohub and jobs files on mgra to get tiers for each mgra but first we need to 

jobs_mgra<- merge(jobs_mgra, mohubs, by.x = c("mgra"), by.y = ("mgra"), all = TRUE)

jobs_mohub<- jobs_mgra%>%
  mutate(mohub_status= case_when(tier == 1~1, 
                                 tier== 2 ~ 1, 
                                 TRUE ~ 0))


jobs_mohub<- jobs_mohub%>%
  select(- c(score, mohub,tier))%>%
  group_by(yr_id, jurisdiction, jurisdiction_id, mohub_status, employment_type, employment_type_id )%>%
  summarise_at(vars(jobs_35, jobs_36), funs(sum))


### Step 3: merge the mohub= 0,1


jobs_mohub_1<- subset(jobs_mohub, mohub_status == 1)
jobs_mohub_0<- subset(jobs_mohub, mohub_status == 0)

setnames(jobs_mohub_0, old= c("jobs_35", "jobs_36"), new = c("jobs_35_out", "jobs_36_out"))
setnames(jobs_mohub_1, old= c("jobs_35", "jobs_36"), new = c("jobs_35_in", "jobs_36_in"))

jobs_mohub<- merge(jobs_mohub_1, jobs_mohub_0, by.x = c("yr_id", "jurisdiction", "jurisdiction_id", "employment_type_id", "employment_type"),
                   by.y = c("yr_id", "jurisdiction", "jurisdiction_id","employment_type_id", "employment_type"), all= TRUE)

jobs_mohub<- jobs_mohub%>%
  select(-c(mohub_status.x, mohub_status.y))

jobs_mohub<- merge(jobs_mohub, jobs_jur_total,  by.x = c("yr_id","jurisdiction_id", "jurisdiction"), by.y = c("yr_id","jurisdiction_id", "jurisdiction"), all = TRUE) 

jobs_mohub<- merge(jobs_mohub, jobs_region_total, by.x = "yr_id", by.y = "yr_id", all = TRUE)

### Step 4: calculating the portions
jobs_mohub<- jobs_mohub%>%
  mutate(prop_total_35_in= jobs_35_in/total_jobs_35,
         prop_total_35_out= jobs_35_out/total_jobs_35,
         prop_total_36_in= jobs_36_in/total_jobs_36,
         prop_total_36_out= jobs_36_out/total_jobs_36,
         prop_jur_35_in= jobs_35_in/total_jur_jobs_35,
         prop_jur_35_out= jobs_35_out/total_jur_jobs_35,
         prop_jur_36_in= jobs_36_in/total_jur_jobs_36,
         prop_jur_36_out= jobs_36_out/total_jur_jobs_36)
         
#################################################

#saving and formatting output


wb1 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

region = addWorksheet(wb1, "JobsbySector_Region", tabColour = "red")
writeData(wb1, "JobsbySector_Region", jobs_region_Share)
addStyle(wb1,region, style = headerStyle, rows = 1, cols = 1: ncol(jobs_region_Share), gridExpand = TRUE)

jurisdiction = addWorksheet(wb1, "JobsbySector_Jurisdiction", tabColour = "cyan")
writeData(wb1, "JobsbySector_Jurisdiction", jobs_jur_share)
addStyle(wb1,jurisdiction, style = headerStyle, rows = 1, cols = 1: ncol(jobs_jur_share), gridExpand = TRUE)

mohub= addWorksheet(wb1, "Jobs_Mohub", tabColour = "orange")
writeData(wb1, "Jobs_Mohub", jobs_mohub)
addStyle(wb1,mohub, style = headerStyle, rows = 1, cols = 1: ncol(jobs_mohub), gridExpand = TRUE)

saveWorkbook(wb1, outfile,overwrite=TRUE)



