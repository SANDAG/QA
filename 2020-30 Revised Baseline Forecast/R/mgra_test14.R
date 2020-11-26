## Test 14: Experimental Item: MGRA level exploratory analysis
## Author: Purva Singh


## Part 1: Setting up the R environment, source files, and packages and output folder


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
source("../queries/readSQL.R")
source("common_functions.R")
source("Data_HH_GQ_Vac_Unocc.R")  ## This is where the mgra and pop data come from
odbcClose(channel)
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

# Creating path for saving results
outputfile <- paste("HH_Pop_GQ_Vacancy","_DS_39","_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-30 Revised Baseline Forecast\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))


## Part 2: Loading the data and preparing it for analysis

# merging dim_mgra with mgra_39 for further analysis

mgra_pop_39<- merge(mgra_pop_39, dim_mgra, by = "mgra_id", all= TRUE)

mgra_pop_39.2<- mgra_pop_39%>%
  select(mgra_id, population, yr_id, mgra)%>%
  group_by(mgra, yr_id)%>%    
  summarise_at(vars(population), sum)%>%
  spread(yr_id, population)

setnames(mgra_pop_39.2, old=c("2016", "2018", "2020", "2025", "2030", "2035", "2040", "2045", "2050"), 
         new=c("pop.2016", "pop.2018", "pop.2020", "pop.2025", "pop.2030", "pop.2035", "pop.2040", "pop.2045", "pop.2050"))

# Scheduled development data for creating SD flags 


### urbansim_lite_output
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

urban_sim<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT 
    parcel_id
    ,year_simulation
    ,sum(unit_change) as unit_change
FROM [urbansim].[urbansim].[urbansim_lite_output]
where run_id = 495 and capacity_type='sch'
group by parcel_id, year_simulation
order by parcel_id, year_simulation"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

### scheduled_development_parcel
rev_base_parcel<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [site_id]
      ,[parcel_id]
      ,[capacity_3]
FROM [urbansim].[urbansim].[scheduled_development_parcel]
                         WHERE [capacity_3] IS NOT NULL"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

### parcel
parcel_mgra<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT 
    [parcel_id]
    ,[mgra_id]
FROM [urbansim].[urbansim].[parcel]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

### employment scheduled development 
sch_dev1<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0(" SELECT 
 [siteid]
,[parcel_id]
,[capacity_3]
,[sfu_effective_adj]
,[mfu_effective_adj]
,[civGQ]
,[civemp_imputed]
,[sector_id]
FROM [urbansim].[urbansim].[non_res_sched_dev_parcel_scs_2v2]"),
stringsAsFactors = FALSE),
stringsAsFactors = FALSE)

odbcClose(channel) 

sch_dev2<- merge(sch_dev1, parcel_mgra, by = "parcel_id", all.x = TRUE)

sch_dev<- sch_dev2%>%
  group_by(mgra_id)%>%
  summarise_at(vars(capacity_3, civemp_imputed), funs(sum))

setnames(sch_dev, old= "mgra_id", new= "mgra")


### Part 3: Analysis

## merging mgra and scheduled development data 

mgra_pop_39.3<- merge(mgra_pop_39.2, sch_dev, by = "mgra", all = "TRUE")


## cond1= when all population values are zero but capacity 3 and civemp_imputed is not 0

cond1<- mgra_pop_39.3%>%
  filter(pop.2016== 0 & pop.2018==0 & pop.2020== 0 & pop.2025== 0 & pop.2030==0 & pop.2035==0 & pop.2040==0 & pop.2045==0 & pop.2050== 0)%>%
  filter(capacity_3!= 0 | civemp_imputed != 0)

## cond2= when 2016 or 2018 pop is 0 and 2020 is not--71

cond2<- mgra_pop_39.3%>%
  filter (pop.2016== 0 & pop.2018==0 & pop.2020!= 0)

## cond3=when 2035 is not 0 but 2040, 2045, and 2050 is -- 0 

cond3<- mgra_pop_39.3%>%
  filter (pop.2035!= 0 & pop.2040==0 & pop.2045== 0 & pop.2050 == 0)

## cond4= when any of the values is zero (except mgras in cond1)
cond4<- subset(mgra_pop_39.3, !(mgra %in% cond1$mgra))

cond4<- cond4%>%
  filter(pop.2016== 0 | pop.2018==0 | pop.2020== 0 | pop.2025== 0 | pop.2030==0 | pop.2035==0 | pop.2040==0 | pop.2045==0 | pop.2050== 0)
  

cond4$pop.mean<- apply(cond4[,2:10], 1, mean) 


## cond5== where % increase between increments is more than 100%

# First we remove mgras where all zero populations
all_null<- mgra_pop_39.3%>%
  filter(pop.2016== 0 & pop.2018==0 & pop.2020== 0 & pop.2025== 0 & pop.2030==0 & pop.2035==0 & pop.2040==0 & pop.2045==0 & pop.2050== 0)
cond5<- subset(mgra_pop_39.3, !(mgra %in% all_null$mgra))
cond5<- cond5%>%
  mutate(diff.2018= pop.2018- pop.2016,
         diff.2020= pop.2020- pop.2018,
         diff.2025= pop.2025- pop.2020,
         diff.2030= pop.2030- pop.2025,
         diff.2035= pop.2035- pop.2030,
         diff.2040= pop.2040- pop.2035,
         diff.2045= pop.2045- pop.2040,
         diff.2050= pop.2050- pop.2045, 
         inc.2018= ((pop.2018/pop.2016)-1)*100,
         inc.2020= ((pop.2020/pop.2018)-1)*100,
         inc.2025= ((pop.2025/pop.2020)-1)*100,
         inc.2030= ((pop.2030/pop.2025)-1)*100,
         inc.2035= ((pop.2035/pop.2030)-1)*100,
         inc.2040= ((pop.2040/pop.2035)-1)*100,
         inc.2045= ((pop.2045/pop.2040)-1)*100,
         inc.2050= ((pop.2050/pop.2045)-1)*100)%>%
  filter(inc.2018> 100 | inc.2020> 100|inc.2025> 100| inc.2030> 100|inc.2035> 100 | inc.2040> 100 | inc.2045> 100 | inc.2050> 100)%>%
  filter (diff.2018> 500 | diff.2020> 500|diff.2025> 500| diff.2030> 500|diff.2035> 500 | diff.2040> 500 | diff.2045> 500 | diff.2050> 500)%>%
  select(c(1:12))
        
# Filtering cond 5 into those mgras with pop 0 in 2016, 2018, and 2020 

cond5.1<-cond5%>%
  filter(pop.2016== 0 & pop.2018==0 & pop.2020== 0)

# Filtering cond 5 into those mgras with pop 0 in 2016, 2018, 2020, 2025, 2030, and 2035  (There are other combinations too)

cond5.2<- cond5%>%
  filter(pop.2016== 0 & pop.2018==0 & pop.2020== 0 & pop.2025== 0 & pop.2030==0 & pop.2035==0 & pop.2040!=0 & pop.2045!=0 & pop.2050!= 0)


## cond 6-- viewing  mgras with capacity_3 >0

cond6<- mgra_pop_39.3%>%
  filter(capacity_3>0)

### Part 4: Saving the results


write.csv(cond6, "C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-30 Revised Baseline Forecast\\Results\\mgra_test14_cond6.csv")









  

  
  