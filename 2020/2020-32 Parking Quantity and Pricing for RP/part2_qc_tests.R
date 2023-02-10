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
016
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
         
           

write.csv(priced_stalls_1, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-32 Parking Quantity and Pricing for RP//test.csv")


## Test 5: Trend of parking rates: 

parkrates2016<- parking2016%>%
  select(mgra, hparkcost, dparkcost, mparkcost)%>%
  rename(hparkcost2016 = hparkcost, 
         dparkcost2016= dparkcost, 
         mparkcost2016= mparkcost)

parkrates2025<- parking2025%>%
  select(mgra, hparkcost, dparkcost, mparkcost)%>%
  rename(hparkcost2025 = hparkcost, 
         dparkcost2025= dparkcost, 
         mparkcost2025= mparkcost)

parkrates2035<- parking2035%>%
  select(mgra, hparkcost, dparkcost, mparkcost)%>%
  rename(hparkcost2035 = hparkcost, 
         dparkcost2035= dparkcost, 
         mparkcost2035= mparkcost)

parkrates2050<- parking2050%>%
  select(mgra, hparkcost, dparkcost, mparkcost)%>%
  rename(hparkcost2050 = hparkcost, 
         dparkcost2050= dparkcost, 
         mparkcost2050= mparkcost)

parkrates<- merge(parkrates2016, parkrates2025, by= "mgra", all = TRUE)
parkrates<- merge(parkrates, parkrates2035, by= "mgra", all = TRUE)
parkrates<- merge(parkrates, parkrates2050, by= "mgra", all = TRUE)

parkrates$hdiff2025<- parkrates$hparkcost2025- parkrates$hparkcost2016
parkrates$ddiff2025<- parkrates$dparkcost2025- parkrates$dparkcost2016
parkrates$mdiff2025<- parkrates$mparkcost2025- parkrates$mparkcost2016
parkrates$hdiff2035<- parkrates$hparkcost2035- parkrates$hparkcost2016
parkrates$ddiff2035<- parkrates$dparkcost2035- parkrates$dparkcost2016
parkrates$mdiff2035<- parkrates$mparkcost2035- parkrates$mparkcost2016
parkrates$hdiff2050<- parkrates$hparkcost2050- parkrates$hparkcost2016
parkrates$ddiff2050<- parkrates$dparkcost2050- parkrates$dparkcost2016
parkrates$mdiff2050<- parkrates$mparkcost2050- parkrates$mparkcost2016










