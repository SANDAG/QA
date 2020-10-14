### Author: Kelsie Telson and Purva Singh
### Project: 2020- 32 Regional Plan Parking
### Purpose: Apply validation tests to output data to ensure conformity with parameters specified in the Test Plan
### Related Documents: https://sandag.sharepoint.com/:w:/r/qaqc/_layouts/15/Doc.aspx?sourcedoc=%7B0C5A8EC9-1D5D-4DA5-A3CA-C642DC64AD7B%7D&file=Test%20Plan%20-%20Test%20Procedure%20Draft.docx&action=default&mobileredirect=true

### Part 1: Setting up the R environment and loading required packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("readSQL.R")
source("common_functions.R")
source("RP_Parking_PSI.R")

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

### Part 2: Loading the data

#1. Loading the priced mgra data 


parking2016<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2016_02_np.csv")
parking2025<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2025_02_np.csv")
parking2035<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2035_02_np.csv")
parking2050<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_02_np.csv")


### Part 3: Applying QC testing

##Test 1: Confirm parking stalls [parkarea] are equal to the baseline (2016)

#Step 0: define test 1 function
test1<- function(input1,
                 input2) {
  test<-ifelse(input1$parkarea==input2$parkarea,TRUE,FALSE)
  
  print(table(test))
}

#Step 1: apply test 1 function to all files
test1(input1=parking2016,input2=parking2025) #pass
test1(input1=parking2016,input2=parking2035) #pass
test1(input1=parking2016,input2=parking2050) #pass


##Test 2: Confirm no stalls are lost from negative employment growth 

#Step 0: append parking stall difference for each stall type
#2025
parking2025$hstallsoth_dif<- parking2025$hstallsoth-parking2016$hstallsoth
parking2025$hstallssam_dif<- parking2025$hstallssam-parking2016$hstallssam
parking2025$dstallsoth_dif<- parking2025$dstallsoth-parking2016$dstallsoth
parking2025$dstallssam_dif<- parking2025$dstallssam-parking2016$dstallssam
parking2025$mstallsoth_dif<- parking2025$mstallsoth-parking2016$mstallsoth
parking2025$mstallssam_dif<- parking2025$mstallssam-parking2016$mstallssam

#2035
parking2035$hstallsoth_dif<- parking2035$hstallsoth-parking2016$hstallsoth
parking2035$hstallssam_dif<- parking2035$hstallssam-parking2016$hstallssam
parking2035$dstallsoth_dif<- parking2035$dstallsoth-parking2016$dstallsoth
parking2035$dstallssam_dif<- parking2035$dstallssam-parking2016$dstallssam
parking2035$mstallsoth_dif<- parking2035$mstallsoth-parking2016$mstallsoth
parking2035$mstallssam_dif<- parking2035$mstallssam-parking2016$mstallssam

#Step 1: determine instances of job loss for each file
#2025
test2_2025<- parking2025 %>%
  filter(emp_total<parking2016$emp_total)
#2035
test2_2035<- parking2035 %>%
  filter(emp_total<parking2016$emp_total)
#2050
test2_2050<- parking2050 %>%
  filter(emp_total<parking2016$emp_total)

#TODO Step 2: define function to compare stall change 
test2<- function(data) {
  
  column_names<-c("hstallsoth_dif","hstallssam_dif", "dstallsoth_dif",
                  "dstallssam_dif", "mstallsoth_dif", "mstallssam_dif")
  
  for (i in column_names) {
    print(table(ifelse(data$column_names<0,TRUE,FALSE)))
  }
  
}

test2(data=test2_2025)

#TODO Step 2: for mgras where a decrease in employment is observed, confirm there were no stall decreases
test2(output=test2_2025$hstallsoth, base=parking2016$hstallsoth)
test2(output=test2_2035$hstallsoth, base=test2_2025$hstallsoth)
test2(output=test2_2035$hstallsoth, base=test2_2025$hstallsoth)


## Test 3: New stalls are calculated from the number of positive jobs added (in emp_total column) over the base year multiplied by (300/[baseline_req_mgra]). 
##  IMPORTANT NOTE: For the 6,725 MGRAs in that table, [baseline_req_priced_mgra] and [annual_chg_2036_to_2050_priced_mgra] are applied.
##  For other MGRAs in the mohubs but not in this list,[baseline_req_non_priced_mgra] and [annual_chg_2036_to_2050_non_priced_mgra] are applied. 
##  The ‘non_priced_mgra’ fields are unique for each mohub.
## Nick’s equation: 2016_parking_stalls + ((current_emp – 2016_emp) * (300 / baseline_req_mgra)) 

# Checking the range of baseline_req_priced_mgra and baseline_req_non_priced_mgra
range(priced$baseline_req_priced_mgra)   ## Range is 0 to 750
range(priced$baseline_req_non_priced_mgra)   ## Range is 0 to 588

# calculation employment change between 2025- 2016 and 2035 and 2025

# Function for extracting the relevant columns and renaming them for merge

parkstall<- function(df){
  var_name<- substring(deparse(substitute(df)),8,) 
  df2<-df%>%
    select(mgra, emp_total,hstallsoth, hstallssam, dstallsoth, dstallssam, mstallsoth, mstallssam)%>%
    rename_with(~paste( .x, var_name,sep = ""))
  }

emp_change2016<- parkstall(parking2016)
emp_change2025<- parkstall(parking2025)
emp_change2035<- parkstall(parking2035) 

#merging the three dataframes 
stalls<- merge(emp_change2016, emp_change2025, by.x= "mgra2016", by.y = "mgra2025", all= TRUE)
stalls<- merge(stalls, emp_change2035, by.x= "mgra2016", by.y = "mgra2035", all= TRUE)

stalls<- stalls%>%
  rename(mgra= mgra2016)

priced_stalls<- stalls%>%
  filter(mgra %in% priced$mgra)

priced_baseline_req<- priced%>%
  select(mgra, baseline_req_priced_mgra, baseline_req_non_priced_mgra)


priced_stalls<- merge(priced_stalls, priced_baseline_req, by = "mgra", all= TRUE)

priced_stalls_1<- priced_stalls%>%
filter(baseline_req_priced_mgra!= 0)%>% 
mutate (emp_diff_2025= emp_total2025- emp_total2016, 
emp_diff_2035= emp_total2035- emp_total2025)%>%
filter( emp_diff_2025>0 )%>%
mutate(
h_other_25= (hstallsoth2016 + (emp_total2025 - emp_total2016)*(300/ baseline_req_priced_mgra)),
h_all_25= (hstallssam2016 + (emp_total2025 - emp_total2016)*(300/ baseline_req_priced_mgra)), 
m_other_25= (mstallsoth2016 + (emp_total2025 - emp_total2016)*(300/ baseline_req_priced_mgra)), 
m_all_25= (mstallssam2016 + (emp_total2025 - emp_total2016)*(300/ baseline_req_priced_mgra)),
d_other_25= (dstallsoth2016 + (emp_total2025 - emp_total2016)*(300/ baseline_req_priced_mgra)), 
d_all_25= (dstallssam2016 + (emp_total2025 - emp_total2016)*(300/ baseline_req_priced_mgra)))%>%
mutate_if(is.numeric,round,0)%>%
  mutate(check_hstallsoth2025= (h_other_25== hstallsoth2025),
         check_hstallssam2025=  (h_all_25== hstallssam2025),
         check_mstallsoth2025=(m_other_25== mstallsoth2025), 
         check_mstallssam2025= (m_all_25== mstallssam2025),
         check_dstallsoth2025=(d_other_25== dstallsoth2025),
         check_dstallssam2025=(d_all_25== dstallssam2025))

priced_stalls_2<- priced_stalls%>%
  filter(baseline_req_priced_mgra== 0)%>%
  mutate(check= hstallsoth2025== hstallsoth2016)
         
           
write.csv(priced_stalls_1, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-32 Parking Quantity and Pricing for RP//test.csv")
write.csv(priced_stalls_2, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-32 Parking Quantity and Pricing for RP//test2.csv")


## Test 6: Trend of parking rates: 

## mgra_parking table
priced_parkrates<- priced%>%
  mutate(diff_hr_2050= PriceHr2050- PriceHr2035,
         diff_hr_2035= PriceHr2035- PriceHr2025,
         diff_day_2050= PriceDay2050- PriceDay2035, 
         diff_day_2035= PriceDay2035-PriceDay2025,
         diff_mon_2050= PriceMon2050- PriceMon2035, 
         diff_mon_2035= PriceMon2035-PriceMon2025, 
         diff_diff_hr= diff_hr_2050- diff_hr_2035, 
         diff_diff_day= diff_day_2050- diff_day_2035,
         diff_diff_mon= diff_mon_2050- diff_mon_2035,
         )%>%
mutate_if(is.numeric, round, 1)

check<- parking2050%>%
  filter(mgra== 3050)


park_anom<- priced_parkrates%>%
  filter(diff_mon_2050<diff_mon_2035)

## noz table
np_parkrates<- np_out%>%
  mutate(diff_hr_2050= PriceHr2050- PriceHr2035,
         diff_hr_2035= PriceHr2035- PriceHr2025,
         diff_day_2050= PriceDay2050- PriceDay2035, 
         diff_day_2035= PriceDay2035-PriceDay2025,
         diff_mon_2050= PriceMon2050- PriceMon2035, 
         diff_mon_2035= PriceMon2035-PriceMon2025, 
         diff_diff_hr= diff_hr_2050- diff_hr_2035, 
         diff_diff_day= diff_day_2050- diff_day_2035,
         diff_diff_mon= diff_mon_2050- diff_mon_2035,
  )%>%
  mutate_if(is.numeric, round, 1)

unique(np_parkrates$diff_diff_mon)

## results in noz and mgra_parking table are the same as noz file

write.csv(priced_parkrates, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-32 Parking Quantity and Pricing for RP//test6.csv")



## Checking Kelsie's formulae for test 5

s1_parking2050<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_01.csv")


parking2035_final<- parking2035%>%
  select(mgra, hstallssam, emp_total)%>%
  mutate(hstallssam2035= hstallssam,
         emp_total2035= emp_total)%>%
  select(-c(hstallssam,emp_total))

parking2050_final<- merge(parking2050, np_out, by= "mgra")
parking2050_final<- merge(parking2050_final, parking2035_final, by= "mgra")

## where baseline_req_parking = 0 or null -- no mismatches

sub1<- parking2050_final%>%
  filter(baseline_req_pricing== 0 | 
           baseline_req_pricing== "NA")

s1_parking2050_sub1<- s1_parking2050%>%
  filter(mgra %in% sub1$mgra)

identical(sub1$hstallsoth, s1_parking2050_sub1$hstallsoth)

## where baseline_req_parking != 0 or null and employment decreases or remains constant- 855 mismatches 

sub2<- parking2050_final%>%
  filter(baseline_req_pricing!= 0 | 
           baseline_req_pricing!= "NA")%>%
  filter(emp_total == emp_total2035| 
         emp_total< emp_total2035)%>%
  mutate(check = (hstallssam2035+((1+ annual_chg_2036_2050)^15)),
         check2= (hstallssam2035+((emp_total-emp_total2035)* (300/baseline_req_pricing))* ((1+ annual_chg_2036_2050)^15)),
         diff= check2- hstallssam)%>%
         filter(diff!= 0.0)

## where employment is increasing-- 3012 mgras mismatch 
sub3<- parking2050_final%>%
  filter(emp_total> emp_total2035)%>%
  filter(baseline_req_pricing!= 0 | 
           baseline_req_pricing!= "NA")%>%
  mutate(check = (hstallssam2035*((1+ annual_chg_2036_2050)^15)),
         diff= check- hstallssam)%>%
  filter(diff!= 0)
         


