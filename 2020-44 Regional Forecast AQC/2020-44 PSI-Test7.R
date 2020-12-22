### Author: Purva Singh
### Project: 2020- 44 2020-44 Regional Forecast AQC
### Purpose: Apply validation tests to output data to ensure conformity with parameters specified in the Test Plan
### Related Documents: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={65dc7eb6-3ac3-4140-96b7-25c09e5f502d}&action=edit&wd=target%28Test%20Plan.one%7C8d0200b0-42be-45fb-92dd-16395ee1c99c%2FTest%20Plan%7Cfd152376-3142-43da-acf5-0d4073bc605b%2F%29 

### Part 1: Setting up the R environment and loading required packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("readSQL.R")
source("common_functions.R")
source("RP_Parking_PSI.R")

# Loading the packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)


### Part 2: Loading the data

#1. Loading the abm_mgra13_based_input_np

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=isam; trusted_connection=true')

mgra_np <- sqlQuery(channel, 
                    "SELECT * 
FROM  [isam].[xpef33].[abm_mgra13_based_input_np]"
)

odbcClose(channel)


channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=ws; trusted_connection=true')

np_out<- data.table::as.data.table(
  RODBC::sqlQuery(channel, 
                  paste0("SELECT *
                           FROM [sql2014a8].[ws].[dbo].[noz_parking_mgra_info]" ),
                  stringsAsFactors= FALSE),
  stringsAsFactors= FALSE)

odbcClose(channel)



#2. Loading the priced mgra data 


parking2016_raw<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2016_04_np.csv")


### Part 3: Applying QC testing

##Test 1: Checking if 2016 data matches for input_np and parking 2016


mgra_np_16<- mgra_np%>%
  filter(yr== 2016)%>%
  select(c(mgra, hstallsoth, hstallssam, hparkcost, numfreehrs, dstallsoth, dstallssam, dparkcost, mstallsoth, 
           mstallssam, mparkcost ))%>%
  arrange(mgra)


parking2016_csv<- parking2016_raw%>%
  select(c(mgra, hstallsoth, hstallssam, hparkcost, numfreehrs, dstallsoth, dstallssam, dparkcost, mstallsoth, 
           mstallssam, mparkcost ))%>%
  arrange(mgra)
  

compare_park<- as.data.frame(mgra_np_16== parking2016_csv)



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

parking2016<- mgra_np%>%
  filter(yr== 2016)
parking2017<- mgra_np%>%
  filter(yr== 2017)
parking2018<- mgra_np%>%
  filter(yr== 2018)
parking2020<- mgra_np%>%
  filter(yr== 2020)
parking2023<- mgra_np%>%
  filter(yr== 2023)
parking2025<- mgra_np%>%
  filter(yr== 2025)
parking2026<- mgra_np%>%
  filter(yr== 2026)
parking2029<- mgra_np%>%
  filter(yr== 2029)
parking2030<- mgra_np%>%
  filter(yr== 2030)
parking2032<- mgra_np%>%
  filter(yr== 2032)
parking2035<- mgra_np%>%
  filter(yr== 2035)



parkstall<- function(df){
  var_name<- substring(deparse(substitute(df)),8,) 
  df2<-df%>%
    select(mgra, emp_total,hstallsoth, hstallssam, dstallsoth, dstallssam, mstallsoth, mstallssam)%>%
    rename_with(~paste( .x, var_name,sep = ""))
}

emp_change2016<- parkstall(parking2016)
emp_change2017<- parkstall(parking2017)
emp_change2018<- parkstall(parking2018)
emp_change2020<- parkstall(parking2020)
emp_change2023<- parkstall(parking2023)
emp_change2025<- parkstall(parking2025)
emp_change2026<- parkstall(parking2026)
emp_change2029<- parkstall(parking2029)
emp_change2030<- parkstall(parking2030)
emp_change2032<- parkstall(parking2032)
emp_change2035<- parkstall(parking2035) 

#merging the three dataframes 
stalls<- merge(emp_change2016, emp_change2017, by.x= "mgra2016", by.y = "mgra2017", all= TRUE)
stalls<- merge(stalls, emp_change2018, by.x= "mgra2016", by.y = "mgra2018", all= TRUE)
stalls<- merge(stalls, emp_change2020, by.x= "mgra2016", by.y = "mgra2020", all= TRUE)
stalls<- merge(stalls, emp_change2023, by.x= "mgra2016", by.y = "mgra2023", all= TRUE)
stalls<- merge(stalls, emp_change2025, by.x= "mgra2016", by.y = "mgra2025", all= TRUE)
stalls<- merge(stalls, emp_change2026, by.x= "mgra2016", by.y = "mgra2026", all= TRUE)
stalls<- merge(stalls, emp_change2029, by.x= "mgra2016", by.y = "mgra2029", all= TRUE)
stalls<- merge(stalls, emp_change2030, by.x= "mgra2016", by.y = "mgra2030", all= TRUE)
stalls<- merge(stalls, emp_change2032, by.x= "mgra2016", by.y = "mgra2032", all= TRUE)
stalls<- merge(stalls, emp_change2035, by.x= "mgra2016", by.y = "mgra2035", all= TRUE)
stalls<- stalls%>%
  rename(mgra= mgra2016)

# merging stalls with baseline_price_req from noz
brp<- np_out%>%
  select(mgra, baseline_req_pricing)

stalls<- merge(stalls, brp, by = "mgra", all= TRUE)


##priced_stalls<- stalls%>%
##filter(mgra %in% priced$mgra)

##priced_baseline_req<- priced%>%
##select(mgra, baseline_req_priced_mgra, baseline_req_non_priced_mgra)

##priced_stalls<- merge(priced_stalls, priced_baseline_req, by = "mgra", all= TRUE)

## Case 1: When baseline_req_price =0, apply the same stall values as 2016

stalls_1<- stalls%>%
  filter(baseline_req_pricing== 0)

identical(stalls_1$hstallssam2016, stalls_1$hstallssam2017, stalls_1$hstallssam2018)
identical(stalls_1$hstallssam2016, stalls_1$hstallssam2020, stalls_1$hstallssam2023)
identical(stalls_1$hstallssam2016, stalls_1$hstallssam2025, stalls_1$hstallssam2026)
identical(stalls_1$hstallssam2016, stalls_1$hstallssam2029, stalls_1$hstallssam2030)
identical(stalls_1$hstallssam2016, stalls_1$hstallssam2032, stalls_1$hstallssam2035)


identical(stalls_1$hstallsoth2016, stalls_1$hstallsoth2023, stalls_1$hstallsoth2026) 
identical(stalls_1$hstallsoth2016, stalls_1$hstallsoth2017, stalls_1$hstallsoth2018) 
identical(stalls_1$hstallsoth2016, stalls_1$hstallsoth2020, stalls_1$hstallsoth2025) 
identical(stalls_1$hstallsoth2016, stalls_1$hstallsoth2029, stalls_1$hstallsoth2032) 
identical(stalls_1$hstallsoth2016, stalls_1$hstallsoth2030, stalls_1$hstallsoth2035) 


identical(stalls_1$dstallsoth2016, stalls_1$dstallsoth2017, stalls_1$dstallsoth2018)
identical(stalls_1$dstallsoth2016, stalls_1$dstallsoth2020, stalls_1$dstallsoth2023)
identical(stalls_1$dstallsoth2016, stalls_1$dstallsoth2025, stalls_1$dstallsoth2026)
identical(stalls_1$dstallsoth2016, stalls_1$dstallsoth2029, stalls_1$dstallsoth2030)
identical(stalls_1$dstallsoth2016, stalls_1$dstallsoth2032, stalls_1$dstallsoth2035)


identical(stalls_1$mstallsoth2016, stalls_1$mstallsoth2017, stalls_1$mstallsoth2018)
identical(stalls_1$mstallsoth2016, stalls_1$mstallsoth2020, stalls_1$mstallsoth2023)
identical(stalls_1$mstallsoth2016, stalls_1$mstallsoth2025, stalls_1$mstallsoth2026)
identical(stalls_1$mstallsoth2016, stalls_1$mstallsoth2029, stalls_1$mstallsoth2030)
identical(stalls_1$mstallsoth2016, stalls_1$mstallsoth2032, stalls_1$mstallsoth2035)


identical(stalls_1$mstallssam2016, stalls_1$mstallssam2017, stalls_1$mstallssam2018)
identical(stalls_1$mstallssam2016, stalls_1$mstallssam2020, stalls_1$mstallssam2023)
identical(stalls_1$mstallssam2016, stalls_1$mstallssam2025, stalls_1$mstallssam2026)
identical(stalls_1$mstallssam2016, stalls_1$mstallssam2029, stalls_1$mstallssam2030)
identical(stalls_1$mstallssam2016, stalls_1$mstallssam2032, stalls_1$mstallssam2035)

identical(stalls_1$dstallssam2016, stalls_1$dstallssam2017, stalls_1$dstallssam2018)
identical(stalls_1$dstallssam2016, stalls_1$dstallssam2020, stalls_1$dstallssam2023)
identical(stalls_1$dstallssam2016, stalls_1$dstallssam2025, stalls_1$dstallssam2026)
identical(stalls_1$dstallssam2016, stalls_1$dstallssam2029, stalls_1$dstallssam2030)
identical(stalls_1$dstallssam2016, stalls_1$dstallssam2032, stalls_1$dstallssam2035)

## Case 2: When baseline_req_price!= 0 and employment increases, apply the stall calc formulae

stalls_2_2023<- stalls%>%
  filter(baseline_req_pricing!= 0)%>% 
  mutate (emp_diff_2023= emp_total2023- emp_total2016, 
          emp_diff_2025= emp_total2025- emp_total2023)%>%
  filter( emp_diff_2023>0 )%>%
  mutate(
    h_other_23= (hstallsoth2016 + (emp_total2023 - emp_total2016)*(300/ baseline_req_pricing)),
    h_all_23= (hstallssam2016 + (emp_total2023 - emp_total2016)*(300/ baseline_req_pricing)), 
    m_other_23= (mstallsoth2016 + (emp_total2023 - emp_total2016)*(300/ baseline_req_pricing)), 
    m_all_23= (mstallssam2016 + (emp_total2023 - emp_total2016)*(300/ baseline_req_pricing)),
    d_other_23= (dstallsoth2016 + (emp_total2023 - emp_total2016)*(300/ baseline_req_pricing)), 
    d_all_23= (dstallssam2016 + (emp_total2023 - emp_total2016)*(300/ baseline_req_pricing)))%>%
  mutate_if(is.numeric,round,0)%>%
  mutate(check_hstallsoth2023= (h_other_23- hstallsoth2023),
         check_hstallssam2023=  (h_all_23- hstallssam2023),
         check_mstallsoth2023=(m_other_23- mstallsoth2023), 
         check_mstallssam2023= (m_all_23- mstallssam2023),
         check_dstallsoth2023=(d_other_23- dstallsoth2023),
         check_dstallssam2023=(d_all_23- dstallssam2023))

stalls_2_2026<- stalls%>%
  filter(baseline_req_pricing!= 0)%>% 
  mutate (emp_diff_2026_25= emp_total2025- emp_total2025, 
          emp_diff_2026= emp_total2026- emp_total2016)%>%
  filter( emp_diff_2026>0 )%>%
  mutate(
    h_other_26= (hstallsoth2016 + (emp_total2026 - emp_total2016)*(300/ baseline_req_pricing)),
    h_all_26= (hstallssam2016 + (emp_total2026 - emp_total2016)*(300/ baseline_req_pricing)), 
    m_other_26= (mstallsoth2016 + (emp_total2026 - emp_total2016)*(300/ baseline_req_pricing)), 
    m_all_26= (mstallssam2016 + (emp_total2026 - emp_total2016)*(300/ baseline_req_pricing)),
    d_other_26= (dstallsoth2016 + (emp_total2026 - emp_total2016)*(300/ baseline_req_pricing)), 
    d_all_26= (dstallssam2016 + (emp_total2026 - emp_total2016)*(300/ baseline_req_pricing)))%>%
  mutate_if(is.numeric,round,0)%>%
  mutate(check_hstallsoth2026= (h_other_26- hstallsoth2026),
         check_hstallssam2026=  (h_all_26- hstallssam2026),
         check_mstallsoth2026=(m_other_26- mstallsoth2026), 
         check_mstallssam2026= (m_all_26- mstallssam2026),
         check_dstallsoth2026=(d_other_26- dstallsoth2026),
         check_dstallssam2026=(d_all_26- dstallssam2026))


#### Case 3: When baseline_req_price!= 0 and employment decreases, apply the stall calc formulae

stalls_3_2023<- stalls%>%
  filter(baseline_req_pricing!= 0)%>% 
  mutate (emp_diff_2023= emp_total2023- emp_total2016)%>%
  filter( emp_diff_2023<=0 )%>%
  mutate(h_other_23= hstallsoth2023- hstallsoth2016,
         h_all_23= hstallssam2023- hstallssam2016, 
         m_other_23= mstallsoth2023- mstallsoth2016, 
         m_all_23= mstallssam2023- mstallssam2016,
         d_other_23= dstallsoth2023- dstallsoth2016, 
         d_all_23= dstallssam2023- dstallssam2016)

identical(stalls_3_2023$hstallsoth2023, stalls_3_2023$hstallsoth2026)


stalls_3_2026<- stalls%>%
  filter(baseline_req_pricing!= 0)%>% 
  mutate (emp_diff_2026= emp_total2026- emp_total2016)%>%
  filter( emp_diff_2026<=0 )%>%
  mutate( h_other_26= hstallsoth2026- hstallsoth2016,
          h_all_26= hstallssam2026- hstallssam2016, 
          m_other_26= mstallsoth2026- mstallsoth2016, 
          m_all_26= mstallssam2026- mstallssam2016,
          d_other_26= dstallsoth2026- dstallsoth2016, 
          d_all_26= dstallssam2026- dstallssam2016)


## writing out results for test 3

write.xlsx(stalls_2_2023, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-44 Regional Forecast AQC//Results//Parking//test3_V3_EMPINC_2023.xlsx")
write.xlsx(stalls_2_2026, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-44 Regional Forecast AQC//Results//Parking//test3_V3_EMPINC_2026.xlsx")
write.xlsx(stalls_3_2023, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-44 Regional Forecast AQC//Results//Parking//test3_V3_EMPDEC_2023.xlsx")
write.xlsx(stalls_3_2026, "C://Users//psi//OneDrive - San Diego Association of Governments//QA//QA//QA//2020-44 Regional Forecast AQC//Results//Parking//test3_V3_EMPDEC_2026.xlsx")


