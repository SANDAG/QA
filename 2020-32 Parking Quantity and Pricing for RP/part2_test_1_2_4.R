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

#Step 0: Set up working data table
parking2035<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2035_02_np.csv")
parking2050<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_02_np.csv")

parking2035<-as.data.table(parking2035)
parking2050<-as.data.table(parking2050)

parking2050<-as.data.table(parking2050[,list("mgra"=mgra,"emp_2050"=emp_total,"h_oth_50"=hstallsoth,"h_sam_50"=hstallssam,"d_oth_50"=dstallsoth,
                            "d_sam_50"=dstallssam, "m_oth_50"=mstallsoth, "m_sam_50"=mstallssam)])
parking2035<-as.data.table(parking2035[,list("mgra"=mgra,"emp_2035"=emp_total,"h_oth_35"=hstallsoth,"h_sam_35"=hstallssam,"d_oth_35"=dstallsoth,
                                             "d_sam_35"=dstallssam, "m_oth_35"=mstallsoth, "m_sam_35"=mstallssam)])

test4<-merge(parking2050,
             parking2035,
             by="mgra"
             )


#Step 1: correct values for baseline_req_mgra 
#1a: pull in pricing table and original series data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=RTP2021; trusted_connection=true')
np_out<- data.table::as.data.table(
  RODBC::sqlQuery(channel, 
                  paste0("SELECT *
                           FROM [sql2014a8].[ws].[dbo].[noz_parking_mgra_info]" ),
                  stringsAsFactors= FALSE),
  stringsAsFactors= FALSE)

odbcClose(channel)

s1_parking2050<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_01.csv")

#1b: merge in conditional variable
test4<- merge(test4,
                    np_out[,c("mgra","baseline_req_pricing")],
                    by="mgra")

#1c: merge in series 1 stall values
test4<-merge(test4,
                   s1_parking2050[,c("mgra","hstallsoth", "hstallssam",
                                     "dstallsoth","dstallssam","mstallsoth",
                                     "mstallssam")],
                   by="mgra")


#1d: for mgras with baseline_req_pricing=0 or null, replace values with those in 01 series file
test4[baseline_req_pricing=="0", h_oth := hstallsoth]
test4[baseline_req_pricing=="0", h_sam := hstallssam]
test4[baseline_req_pricing=="0", d_oth := dstallsoth]
test4[baseline_req_pricing=="0", d_sam := dstallssam]
test4[baseline_req_pricing=="0", m_oth := mstallsoth]
test4[baseline_req_pricing=="0", m_sam := mstallssam]
test4[is.na(baseline_req_pricing), h_oth := hstallsoth]
test4[is.na(baseline_req_pricing), h_sam := hstallssam]
test4[is.na(baseline_req_pricing), d_oth := dstallsoth]
test4[is.na(baseline_req_pricing), d_sam := dstallssam]
test4[is.na(baseline_req_pricing), m_oth := mstallsoth]
test4[is.na(baseline_req_pricing), m_sam := mstallssam]

#Step 2: test to determine if each stall type in 2050 is less than or equal to 2035
test4_a<- test4 %>%
  filter(h_oth_50>h_oth_35) #62 failures
test4_b<- test4 %>%
  filter(h_sam_50>h_sam_35) #62 failures
test4_c<- test4 %>%
  filter(d_oth_50>d_oth_35) #62 failures
test4_d<- test4 %>%
  filter(d_sam_50>d_sam_35) #62 failures
test4_e<- test4 %>%
  filter(m_oth_50>m_oth_35) #62 failures
test4_f<- test4 %>%
  filter(d_sam_50>d_sam_35) #62 failures

#Step 3: save output
write.csv(test4_a, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Results//test4.csv")

##Test 5

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
parking2025<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2025_02_np.csv")
parking2035<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2035_02_np.csv")
parking2050<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_02_np.csv")

parking2025<-as.data.table(parking2025)
parking2035<-as.data.table(parking2035)
parking2050<-as.data.table(parking2050)

parking2050<-as.data.table(parking2050[,list("mgra"=mgra,"emp_2050"=emp_total,"h_oth_50"=hstallsoth,"h_sam_50"=hstallssam,"d_oth_50"=dstallsoth,
                                             "d_sam_50"=dstallssam, "m_oth_50"=mstallsoth, "m_sam_50"=mstallssam)])
parking2035<-as.data.table(parking2035[,list("mgra"=mgra,"emp_2035"=emp_total,"h_oth_35"=hstallsoth,"h_sam_35"=hstallssam,"d_oth_35"=dstallsoth,
                                             "d_sam_35"=dstallssam, "m_oth_35"=mstallsoth, "m_sam_35"=mstallssam)])

parking2025<-as.data.table(parking2025[,list("mgra"=mgra,"emp_2025"=emp_total)])

test5<-merge(parking2050,
             parking2035,
             by="mgra"
)

test5<-merge(test5,
             parking2025,
             by="mgra"
)

test5<- merge(test5,
              np_out[,c("mgra","baseline_req_pricing","annual_chg_2036_2050")],
              by="mgra")



#Step 2: Define functions for decay formula and stall change formula

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
test5_emp_inc<- test5 %>%
  filter(emp_2050>emp_2035)
test5_emp_dec<- test5 %>%
  filter(emp_2050<=emp_2035)


#Step 4: Apply decay functions to working data tables

#increased employment/constant employment
test5_inc<- test5_emp_inc[, list(
  mgra=mgra,
  h_oth=decay(base_stalls = test5_emp_inc$h_oth_35, annual_change = test5_emp_inc$annual_chg_2036_2050,
                     current_year=2050, comp_year=2035),
  h_sam=decay(base_stalls = test5_emp_inc$h_sam_35, annual_change = test5_emp_inc$annual_chg_2036_2050,
                       current_year=2050, comp_year=2035),
  d_oth=decay(base_stalls = test5_emp_inc$d_oth_35, annual_change = test5_emp_inc$annual_chg_2036_2050,
                       current_year=2050, comp_year=2035),
  d_sam=decay(base_stalls = test5_emp_inc$d_sam_35, annual_change = test5_emp_inc$annual_chg_2036_2050,
                      current_year=2050, comp_year=2035),
  m_oth=decay(base_stalls = test5_emp_inc$m_oth_35, annual_change = test5_emp_inc$annual_chg_2036_2050,
                      current_year=2050, comp_year=2035),
  m_sam=decay(base_stalls = test5_emp_inc$m_sam_35, annual_change = test5_emp_inc$annual_chg_2036_2050,
                      current_year=2050, comp_year=2035)
  )]


#decreased employment
test5_dec<- 
  test5_emp_dec[, list(
    mgra=mgra,
    h_oth=decay(base_stalls = decay_emp_dec(base_stalls = test5_emp_dec$h_oth_35, 
                                          current_emp= test5_emp_dec$emp_2050,
                                          base_emp = test5_emp_dec$emp_2035,
                                          baseline_req_mgra=test5_emp_dec$baseline_req_pricing),
              annual_change = test5_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
    h_sam=decay(base_stalls = decay_emp_dec(base_stalls = test5_emp_dec$h_sam_35, 
                                          current_emp= test5_emp_dec$emp_2050,
                                          base_emp = test5_emp_dec$emp_2035,
                                          baseline_req_mgra=test5_emp_dec$baseline_req_pricing),
              annual_change = test5_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
    d_oth=decay(base_stalls = decay_emp_dec(base_stalls = test5_emp_dec$d_oth_35, 
                                          current_emp= test5_emp_dec$emp_2050,
                                          base_emp = test5_emp_dec$emp_2035,
                                          baseline_req_mgra=test5_emp_dec$baseline_req_pricing),
              annual_change = test5_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
    d_sam=decay(base_stalls = decay_emp_dec(base_stalls = test5_emp_dec$d_sam_35, 
                                          current_emp= test5_emp_dec$emp_2050,
                                          base_emp = test5_emp_dec$emp_2035,
                                          baseline_req_mgra=test5_emp_dec$baseline_req_pricing),
              annual_change = test5_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
    m_oth=decay(base_stalls = decay_emp_dec(base_stalls = test5_emp_dec$m_oth_35, 
                                          current_emp= test5_emp_dec$emp_2050,
                                          base_emp = test5_emp_dec$emp_2035,
                                          baseline_req_mgra=test5_emp_dec$baseline_req_pricing),
              annual_change = test5_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035),
    m_sam=decay(base_stalls = decay_emp_dec(base_stalls = test5_emp_dec$m_sam_35, 
                                          current_emp= test5_emp_dec$emp_2050,
                                          base_emp = test5_emp_dec$emp_2035,
                                          baseline_req_mgra=test5_emp_dec$baseline_req_pricing),
              annual_change = test5_emp_dec$annual_chg_2036_2050,
              current_year=2050, 
              comp_year=2035)
)]


#Step 5: build table to merge and compare data into output table and sort by mgra
test5_merged<-as.data.table(rbind(test5_inc,
                    test5_dec))
test5_merged<- test5_merged[order(mgra),]


#Step 6: compare calculated values to output table
test5_final<- merge(test5_merged,
                    parking2050,
                    by="mgra")

#Step 7: round calculated values to nearest whole number
test5_final<- ceiling(test5_final)

#Step 8: correct values for baseline_req_mgra 
#8a: pull in original series data
s1_parking2050<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_01.csv")

#8b: merge in conditional variable
test5_final<- merge(test5_final,
                    np_out[,c("mgra","baseline_req_pricing")],
                    by="mgra")

#8c: merge in series 1 stall values
test5_final<-merge(test5_final,
                   s1_parking2050[,c("mgra","hstallsoth", "hstallssam",
                                     "dstallsoth","dstallssam","mstallsoth",
                                     "mstallssam")],
                   by="mgra")


#8d: for mgras with baseline_req_pricing=0 or null, replace values with those in 01 series file
test5_final[baseline_req_pricing=="0", h_oth := hstallsoth]
test5_final[baseline_req_pricing=="0", h_sam := hstallssam]
test5_final[baseline_req_pricing=="0", d_oth := dstallsoth]
test5_final[baseline_req_pricing=="0", d_sam := dstallssam]
test5_final[baseline_req_pricing=="0", m_oth := mstallsoth]
test5_final[baseline_req_pricing=="0", m_sam := mstallssam]
test5_final[is.na(baseline_req_pricing), h_oth := hstallsoth]
test5_final[is.na(baseline_req_pricing), h_sam := hstallssam]
test5_final[is.na(baseline_req_pricing), d_oth := dstallsoth]
test5_final[is.na(baseline_req_pricing), d_sam := dstallssam]
test5_final[is.na(baseline_req_pricing), m_oth := mstallsoth]
test5_final[is.na(baseline_req_pricing), m_sam := mstallssam]

#Step 9: generate test results
table(test5_final$h_oth==test5_final$h_oth_50)
table(test5_final$h_sam==test5_final$h_sam_50)
table(test5_final$d_oth==test5_final$d_oth_50)
table(test5_final$d_sam==test5_final$d_sam_50)
table(test5_final$m_oth==test5_final$m_oth_50)
table(test5_final$m_sam==test5_final$m_sam_50)


#Step 10: generate list of MGRAs failing test in any stall category 
test5_a<- test5_final %>%
  filter(test5_final$h_oth!=test5_final$h_oth_50)
test5_b<- test5_final %>%
  filter(test5_final$h_sam!=test5_final$h_sam_50)
test5_c<- test5_final %>%
  filter(test5_final$d_oth!=test5_final$d_oth_50)
test5_d<- test5_final %>%
  filter(test5_final$d_sam!=test5_final$d_sam_50)
test5_e<- test5_final %>%
  filter(test5_final$h_oth!=test5_final$h_oth_50)
test5_f<- test5_final %>%
  filter(test5_final$m_sam!=test5_final$m_sam_50)

#Step 11: save out failures for each stall type 
wb= createWorkbook()

test5a <- addWorksheet(wb, "h_oth",tabColour="purple")
writeData(wb,test5a, test5_a)

test5b <- addWorksheet(wb, "h_sam",tabColour="red")
writeData(wb,test5b, test5_b)

test5c <- addWorksheet(wb, "d_oth",tabColour="green")
writeData(wb,test5c, test5_c)

test5d <- addWorksheet(wb, "d_sam",tabColour="yellow")
writeData(wb,test5d, test5_d)

test5e <- addWorksheet(wb, "m_oth",tabColour="orange")
writeData(wb,test5e, test5_e)

test5f<- addWorksheet(wb, "m_sam",tabColour="cyan")
writeData(wb,test5f, test5_f)

saveWorkbook(wb, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Results//test5.xlsx",overwrite=TRUE)

             