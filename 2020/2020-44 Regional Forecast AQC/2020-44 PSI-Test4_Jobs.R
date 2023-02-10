### Project: 2020- 44 2020-44 Regional Forecast AQC
## Test 4: MGRA level exploratory analysis for Jobs
## Author: Purva Singh


### Part 1: Setting up the R environment, source files, and packages and output folder
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Loading the packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)


### Part 2: Loading the data and preparing it for analysis

## Database 1: ISAM: mgra_summary table
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=isam; trusted_connection=true')

## Table 1: abm_mgra13_based_input_np

mgra_np <- sqlQuery(channel, 
                    "SELECT * 
FROM  [isam].[xpef33].[abm_mgra13_based_input_np]"
)

odbcClose(channel)


## Database 2: Demographic Warehouse: dim_mgra
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

dim_mgra<- sqlQuery(channel, 
                    "SELECT * 
FROM  [demographic_warehouse].[dim].[mgra_denormalize]
WHERE series =14"
)

odbcClose(channel)

mgra_np_job<- mgra_np%>%
  select(mgra,yr, emp_total)%>%
  group_by(mgra, yr)%>%    
  summarise_at(vars(emp_total), sum)%>%
  spread(yr, emp_total)

setnames(mgra_np_job, old=c("2016", "2017", "2018", "2020", "2023","2025","2026","2029" ,"2030","2032" ,"2035", "2040", "2045", "2050"), 
         new=c("emp.2016", "emp.2017","emp.2018", "emp.2020","emp.2023" ,"emp.2025","emp.2026", "emp.2029","emp.2030","emp.2032", "emp.2035", "emp.2040", "emp.2045", "emp.2050"))

write.csv(mgra_np_job, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\mgra_np_job.csv")


# Scheduled development data for creating SD flags 

### Part 3: Analysis

## cond1= when all emp values are zero 

cond1_jobs<- mgra_np_job%>%
  filter(emp.2016== 0 & emp.2017== 0& emp.2018==0 & emp.2020== 0 & emp.2023== 0 & emp.2025== 0 & emp.2026== 0 &emp.2029== 0  &emp.2030==0 & emp.2032==0& emp.2035==0 & emp.2040==0 & emp.2045==0 & emp.2050== 0)


write.csv(cond1, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond1_pop0_w_units.csv")

## cond2= when 2016, 2017, 2018, 2020 emp is 0 and 2023 is not 0

cond2<- mgra_np_job%>%
  filter(!mgra %in% cond1_jobs$mgra)

cond2.jobs<- cond2%>%
  filter (emp.2016== 0 & emp.2017== 0 & emp.2018==0 & emp.2020== 0 & emp.2023 !=0)

write.csv(cond2.jobs, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond2_jobs.csv")


## cond3= when 2016, 2017, 2018, 2020, 2023, 2025 emp is 0 and 2026 is not 0

cond3.jobs<- mgra_np_job%>%
  filter (emp.2016== 0 & emp.2017== 0 & emp.2018==0 & emp.2020== 0 & emp.2023 ==0 
          & emp.2025 ==0 & emp.2026!=0)

write.csv(cond3.jobs, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond3_jobs.csv")


## cond4=when all yrs upto 2035 are 0 and then post that not 0 

cond4.jobs<- mgra_np_job%>%
  filter (emp.2016== 0 & emp.2017== 0 & emp.2018==0 & emp.2020== 0 & emp.2023 ==0 
          & emp.2025 ==0 & emp.2026 ==0 & emp.2029==0 & emp.2030==0 & emp.2032==0 
          & emp.2035 != 0 & emp.2040!=0 & emp.2045!= 0 & emp.2050 != 0)

write.csv(cond4.jobs, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond4_jobs.csv")


## cond5= when all yrs upto 2040 are not 0 and then post that 0 

cond5.jobs<- mgra_np_job%>%
  filter (emp.2016!= 0 & emp.2017!= 0 & emp.2018!=0 & emp.2020!= 0 & emp.2023 !=0 
          & emp.2025 !=0 & emp.2026 !=0 & emp.2029!=0 & emp.2030!=0 & emp.2032!=0 
          & emp.2035 != 0 & emp.2040==0 & emp.2045== 0 & emp.2050 == 0)

write.csv(cond5.jobs, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond5_jobs.csv")


## cond6= when any of the values is zero (except mgras in cond1 that is not all are zero)
cond6.jobs<- mgra_np_job%>%
  filter(!mgra %in% cond1_jobs$mgra)%>%
  filter ( emp.2020== 0 | emp.2023 ==0 
           | emp.2025 ==0 | emp.2026 ==0 | emp.2029==0 | emp.2030==0 | emp.2032==0 
           | emp.2035 == 0 | emp.2040==0 | emp.2045== 0 | emp.2050 == 0)

write.csv(cond6.jobs, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond6_jobs.csv")


## cond7== where % increase between increments is more than 100%

# First we remove mgras where all zero populations and then calculate the difference
cond7.jobs<- mgra_np_job%>%
  filter (!mgra %in% cond1_jobs$mgra)%>%
  mutate(diff.2017= emp.2017- emp.2016,
         diff.2018= emp.2018- emp.2017,
         diff.2020= emp.2020- emp.2018,
         diff.2023= emp.2023- emp.2020,
         diff.2025= emp.2025- emp.2023,
         diff.2026= emp.2026- emp.2025,
         diff.2029= emp.2029- emp.2026,
         diff.2030= emp.2030- emp.2025,
         diff.2032= emp.2032- emp.2030,
         diff.2035= emp.2035- emp.2032,
         diff.2040= emp.2040- emp.2035,
         diff.2045= emp.2045- emp.2040,
         diff.2050= emp.2050- emp.2045, 
         inc.2017= ((emp.2017/emp.2016)-1)*100,
         inc.2018= ((emp.2018/emp.2017)-1)*100,
         inc.2020= ((emp.2020/emp.2018)-1)*100,
         inc.2023= ((emp.2023/emp.2020)-1)*100,
         inc.2025= ((emp.2025/emp.2023)-1)*100,
         inc.2026= ((emp.2026/emp.2025)-1)*100,
         inc.2029= ((emp.2029/emp.2026)-1)*100,
         inc.2030= ((emp.2030/emp.2029)-1)*100,
         inc.2032= ((emp.2032/emp.2030)-1)*100,
         inc.2035= ((emp.2035/emp.2032)-1)*100,
         inc.2040= ((emp.2040/emp.2035)-1)*100,
         inc.2045= ((emp.2045/emp.2040)-1)*100,
         inc.2050= ((emp.2050/emp.2045)-1)*100)%>%
  mutate_if(is.numeric, round, 1)

cond7.jobs$emp.diff.mean<- apply(cond7.jobs[,16:28], 1, mean) 
cond7.jobs$emp.diff.med<- apply(cond7.jobs[,16:28], 1, median)
cond7.jobs$mean_med_diff<- cond7.jobs$emp.diff.mean- cond7.jobs$emp.diff.med

cond7.jobs%>%
  mutate_if(is.numeric, round,1)

# Adding scheduled developments to cond 7

# Loading the scheduled development dataset

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=urbansim; trusted_connection=true')


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
sch_dev_emp<- data.table::as.data.table(
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

sch_dev2<- merge(sch_dev_emp, parcel_mgra, by = "parcel_id", all.x = TRUE)

# mgra_id in the sch_dev file is actually mgra_id


sch_dev<- sch_dev2%>%
  group_by(mgra_id)%>%
  summarise_at(vars(capacity_3, civemp_imputed), sum)

cond7.jobs_sd<- merge(cond7.jobs, sch_dev, by.x = "mgra", by.y = "mgra_id", all = TRUE)  #  mgra_id sch dev is actually mgra

write.csv(cond7.jobs_sd, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond7_jobs_sch_dev.csv")



### Test for PowerBI- jobs by type Lemon Grove

mgra_np_jur<- merge(mgra_np, dim_mgra, by = "mgra", all= TRUE)

mgra_job_jur<- mgra_np_jur%>%
  group_by(jurisdiction, yr)%>%
  summarise_at(vars(emp_fed_mil), sum)

mgra_enroll_jur<- mgra_np_jur%>%
  group_by(jurisdiction, yr)%>%
  summarise_at(vars(enrollgradekto8, enrollgrade9to12, collegeenroll, 
                    othercollegeenroll, adultschenrl), sum)


write.csv(mgra_enroll_jur, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\enrollment_jur.csv")


colnames(mgra_np_jur)


mgra_np_jur_dup<- as.data.frame(duplicated(mgra_np_jur$))
