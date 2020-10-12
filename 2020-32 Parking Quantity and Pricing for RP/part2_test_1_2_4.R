### Author: Kelsie Telson
### Project: 2020- 32 Regional Plan Parking
### Purpose: Apply validation tests to output data to ensure conformity with parameters specified in the Test Plan
### Related Documents: https://sandag.sharepoint.com/:w:/r/qaqc/_layouts/15/Doc.aspx?sourcedoc=%7B0C5A8EC9-1D5D-4DA5-A3CA-C642DC64AD7B%7D&file=Test%20Plan%20-%20Test%20Procedure%20Draft.docx&action=default&mobileredirect=true

### Part 1: Setting up the R environment and loading required packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("readSQL.R")
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

### Part 2: Loading the data
parking2016<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2016_02_np.csv")
parking2025<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2025_02_np.csv")
parking2035<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2035_02_np.csv")
parking2050<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_02_np.csv")


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
parking2035$hstallsoth_dif<- parking2035$hstallsoth-parking2025$hstallsoth
parking2035$hstallssam_dif<- parking2035$hstallssam-parking2025$hstallssam
parking2035$dstallsoth_dif<- parking2035$dstallsoth-parking2025$dstallsoth
parking2035$dstallssam_dif<- parking2035$dstallssam-parking2025$dstallssam
parking2035$mstallsoth_dif<- parking2035$mstallsoth-parking2025$mstallsoth
parking2035$mstallssam_dif<- parking2035$mstallssam-parking2025$mstallssam

#Step 1: determine instances of job loss for each file
#2025
test2_2025<- parking2025 %>%
  filter(emp_total<parking2016$emp_total)
#2035
test2_2035<- parking2035 %>%
  filter(emp_total<parking2025$emp_total)

#Step 2: define function to return cases where stalls decrease
test2<- function(data,
                 col) {
  
  test_2<-data %>%
    filter(col<0)
  
  print(test_2$mgra)
}

#Step 3: apply Test 2 function to all stall types in 2025 and 2035.
# List MGRAs that fail

#2025
test2(data=test2_2025, col=test2_2025$hstallsoth_dif) #pass
test2(data=test2_2025, col=test2_2025$hstallssam_dif) #pass
test2(data=test2_2025, col=test2_2025$dstallsoth_dif) #pass
test2(data=test2_2025, col=test2_2025$dstallssam_dif) #pass
test2(data=test2_2025, col=test2_2025$mstallsoth_dif) #pass
test2(data=test2_2025, col=test2_2025$mstallssam_dif) #pass

#2035
test2(data=test2_2035, col=test2_2035$hstallsoth_dif) #pass
test2(data=test2_2035, col=test2_2035$hstallssam_dif) #pass
test2(data=test2_2035, col=test2_2035$dstallsoth_dif) #pass
test2(data=test2_2035, col=test2_2035$dstallssam_dif) #pass
test2(data=test2_2035, col=test2_2035$mstallsoth_dif) #pass
test2(data=test2_2035, col=test2_2035$mstallssam_dif) #pass



##Test 4

#Step 0: load pricing table
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=RTP2021; trusted_connection=true')
np_out<- data.table::as.data.table(
  RODBC::sqlQuery(channel, 
                  paste0("SELECT *
                           FROM [sql2014a8].[ws].[dbo].[noz_parking_mgra_info]" ),
                  stringsAsFactors= FALSE),
  stringsAsFactors= FALSE)

odbcClose(channel)

#Step 1: Set up working data table/
#Assess employment total change between two year increments
parking2050<-as.data.table(parking2050)

test4<- parking2050[ ,list(
  mgra=parking2050$mgra,
  emp_2050=parking2050$emp_total,
  emp_2035=parking2035$emp_total,
  emp_2025=parking2025$emp_total,
  parkarea_2035=parking2035$parkarea,
  parkarea_2050=parking2050$parkarea,
  emp_dif=parking2050$emp_total-parking2035$emp_total,
  h_oth_35=parking2035$hstallsot,
  h_sam_35=parking2035$hstallssam,
  d_oth_35=parking2035$dstallsoth,
  d_sam_35=parking2035$dstallssam,
  m_oth_35=parking2035$mstallsoth,
  m_sam_35=parking2035$mstallssam,
  h_oth_50=parking2050$hstallsot,
  h_sam_50=parking2050$hstallssam,
  d_oth_50=parking2050$dstallsoth,
  d_sam_50=parking2050$dstallssam,
  m_oth_50=parking2050$mstallsoth,
  m_sam_50=parking2050$mstallssam)]

test4<- merge(test4,
              np_out[,c("mgra","baseline_req_pricing","annual_chg_2036_2050")],
              by="mgra")

#Step 2: Define function that considers employment change and then applies appropriate decay formula

#function for cases with increased employment
decay<- function(base_stalls,
                 annual_change,
                 current_year,
                 comp_year) {
  decay=base_stalls*((1+annual_change)^(current_year-comp_year))

return(decay)
}


#function for cases with decreased employment
decay_emp_dec<- function(base_stalls,
                        current_emp,
                        base_emp,
                        baseline_req_mgra) {
  decay=(base_stalls+(current_emp-base_emp))*(300/baseline_req_mgra)
  
  return(decay)
}



#Step 3: split data by cases that observed employment increases vs decreases/no change
test4_emp_inc<- test4 %>%
  filter(emp_2050>emp_2035)
test4_emp_dec<- test4 %>%
  filter(emp_2050<=emp_2035)


#Step 4: Apply decay functions to working data tables

#increased employment
test4_inc<- test4_emp_inc[, list(
  mgra=mgra,
  h_oth=decay(base_stalls = test4_emp_inc$h_oth_35, annual_change = test4_emp_inc$annual_chg_2036_2050,
                     current_year=2050, comp_year=2035),
  h_sam=decay(base_stalls = test4_emp_inc$h_sam_35, annual_change = test4_emp_inc$annual_chg_2036_2050,
                       current_year=2050, comp_year=2035),
  d_oth=decay(base_stalls = test4_emp_inc$d_oth_35, annual_change = test4_emp_inc$annual_chg_2036_2050,
                       current_year=2050, comp_year=2035),
  d_sam=decay(base_stalls = test4_emp_inc$d_sam_35, annual_change = test4_emp_inc$annual_chg_2036_2050,
                      current_year=2050, comp_year=2035),
  m_oth=decay(base_stalls = test4_emp_inc$m_oth_35, annual_change = test4_emp_inc$annual_chg_2036_2050,
                      current_year=2050, comp_year=2035),
  m_sam=decay(base_stalls = test4_emp_inc$m_sam_35, annual_change = test4_emp_inc$annual_chg_2036_2050,
                      current_year=2050, comp_year=2035)
  )]


#decreased/constant employment
test4_dec<- test4_emp_dec[, list(
  mgra=mgra,
  h_oth=decay(base_stalls = decay_emp_dec(base_stalls = test4_emp_dec$h_oth_35, 
                                          current_emp= test4_emp_dec$emp_2035,
                                          base_emp = test4_emp_dec$emp_2025,
                                          baseline_req_mgra=test4_emp_dec$baseline_req_pricing),
              annual_change = test4_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
  h_sam=decay(base_stalls = decay_emp_dec(base_stalls = test4_emp_dec$h_sam_35, 
                                          current_emp= test4_emp_dec$emp_2035,
                                          base_emp = test4_emp_dec$emp_2025,
                                          baseline_req_mgra=test4_emp_dec$baseline_req_pricing),
              annual_change = test4_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
  d_oth=decay(base_stalls = decay_emp_dec(base_stalls = test4_emp_dec$d_oth_35, 
                                          current_emp= test4_emp_dec$emp_2035,
                                          base_emp = test4_emp_dec$emp_2025,
                                          baseline_req_mgra=test4_emp_dec$baseline_req_pricing),
              annual_change = test4_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
  d_sam=decay(base_stalls = decay_emp_dec(base_stalls = test4_emp_dec$d_sam_35, 
                                          current_emp= test4_emp_dec$emp_2035,
                                          base_emp = test4_emp_dec$emp_2025,
                                          baseline_req_mgra=test4_emp_dec$baseline_req_pricing),
              annual_change = test4_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
  m_oth=decay(base_stalls = decay_emp_dec(base_stalls = test4_emp_dec$m_oth_35, 
                                          current_emp= test4_emp_dec$emp_2035,
                                          base_emp = test4_emp_dec$emp_2025,
                                          baseline_req_mgra=test4_emp_dec$baseline_req_pricing),
              annual_change = test4_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
  m_sam=decay(base_stalls = decay_emp_dec(base_stalls = test4_emp_dec$m_sam_35, 
                                          current_emp= test4_emp_dec$emp_2035,
                                          base_emp = test4_emp_dec$emp_2025,
                                          baseline_req_mgra=test4_emp_dec$baseline_req_pricing),
              annual_change = test4_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035)
)]


#Step 5: build table to merge and compare data into output table
test4_merged<-as.data.table(rbind(test4_inc,
                    test4_dec))



#Step 6: compare calculated values to output table
test4_final<- test4_merged[, list(
  mgra=test4_merged$mgra,
  h_oth_tst=test4_merged$h_oth==parking2050$hstallsoth,
  h_sam_tst=test4_merged$h_sam==parking2050$hstallssam,
  d_oth_tst=test4_merged$d_oth==parking2050$dstallsoth,
  d_sam_tst=test4_merged$d_sam==parking2050$dstallssam,
  m_oth_tst=test4_merged$m_oth==parking2050$mstallsoth,
  m_sam_tst=test4_merged$m_sam==parking2050$mstallssam)
  ]

#Step 7: generate test results
table(test4_final$h_oth_tst)
table(test4_final$h_sam_tst)
table(test4_final$h_oth_tst)
table(test4_final$d_oth_tst)
table(test4_final$d_sam_tst)
table(test4_final$m_oth_tst)
table(test4_final$m_sam_tst)


#Step 8: generate list of MGRAs failing test in any stall category 
test4_failures<-test4_final %>%
  filter(h_oth_tst==FALSE|h_sam_tst==FALSE|d_oth_tst==FALSE|d_sam_tst==FALSE|m_oth_tst==FALSE|m_sam_tst==FALSE)

