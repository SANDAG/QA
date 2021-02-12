#Project ID: 2021-12
#Purpose: Test 2 in Test Plan- https://sandag.sharepoint.com/:o:/g/qaqc/EulxFso4msxFlF5iuFJyTlABrxoSUBdic5kAgknmoMcYaw?e=JApYdX
#Author: Kelsie Telson

###Set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)


library("readxl")
library("openxlsx")
library("data.table")
library("dplyr")
library("stringr")

library(plyr)
library(readr)

###Retrieve data files

## Retrieve _05 files 
filenames_05 <- list.files(path="T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//",
                        pattern="*_np.csv")

##Create list of data frame names without the ".csv" part 
names_05 <-substr(filenames_05,1,28)

###Load all files
for(i in names_05){
  filepath <- file.path("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//",paste(i,".csv",sep=""))
  assign(i, read.csv(filepath)[,c("mgra", "hparkcost", "dparkcost", "mparkcost", "MicroAccessTime")])
}

## Retrieve _04 files 
filenames_04 <- list.files(path="T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//",
                        pattern="*_np.csv")

##Create list of data frame names without the ".csv" part 
names_04 <-substr(filenames_04,1,28)

###Load all files
for(i in names_04){
  filepath <- file.path("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//old//",paste(i,".csv",sep=""))
  assign(i, read.csv(filepath)[,c("mgra", "hparkcost", "dparkcost", "mparkcost", "MicroAccessTime")])
}

#change dataframes to datatables
list2env(eapply(.GlobalEnv, function(x) {if(is.data.frame(x)) {setDT(x)} else {x}}), .GlobalEnv)


### Define function to apply changes to select variables

parking_changes<- function(data){
  data$hparkcost_n <- as.numeric(round(data$hparkcost/1.23272,6))
  data$dparkcost_n <- as.numeric(round(data$dparkcost/1.23272,5))
  data$mparkcost_n <- as.numeric(round((data$mparkcost/22)/1.23272,5))
  
  data<- subset(data, select = -c(2:4))
  
  setnames(data,
           c("hparkcost_n", "dparkcost_n", "mparkcost_n"),
           c("hparkcost","dparkcost","mparkcost"))
  
  setcolorder(data,
           c("mgra","hparkcost","dparkcost","mparkcost","MicroAccessTime"))
  
  return(data)}

### Define function to compare _04 files with _05 files

compare_versions<- function(data1, data2) {
  print(identical(data1,data2))
  
  test<- merge(data1, data2, by="mgra")
  test <- subset(test,hparkcost.x != hparkcost.y | dparkcost.x != dparkcost.y | mparkcost.x != mparkcost.y)
  return(test)
  
}

### Define function to round numeric variables for comparison

rounding_columns<- function(data) {
  data$hparkcost_n <- as.numeric(round(data$hparkcost,6))
  data$dparkcost_n <- as.numeric(round(data$dparkcost,5))
  data$mparkcost_n <- as.numeric(round(data$mparkcost,5))
  
  data<- subset(data, select = -c(2:4))
  
  setnames(data,
           c("hparkcost_n", "dparkcost_n", "mparkcost_n"),
           c("hparkcost","dparkcost","mparkcost"))
  
  setcolorder(data,
              c("mgra","hparkcost","dparkcost","mparkcost","MicroAccessTime"))
  
  return(data)
  }


##Complete computations on "_04" files
mgra13_based_input2016_04_np_c<- parking_changes(mgra13_based_input2016_04_np)
mgra13_based_input2018_04_np_c<- parking_changes(mgra13_based_input2018_04_np)
mgra13_based_input2020_04_np_c<- parking_changes(mgra13_based_input2020_04_np)
mgra13_based_input2023_04_np_c<- parking_changes(mgra13_based_input2023_04_np)
mgra13_based_input2025_04_np_c<- parking_changes(mgra13_based_input2025_04_np)
mgra13_based_input2026_04_np_c<- parking_changes(mgra13_based_input2026_04_np)
mgra13_based_input2029_04_np_c<- parking_changes(mgra13_based_input2029_04_np)
mgra13_based_input2030_04_np_c<- parking_changes(mgra13_based_input2030_04_np)
mgra13_based_input2032_04_np_c<- parking_changes(mgra13_based_input2032_04_np)
mgra13_based_input2035_04_np_c<- parking_changes(mgra13_based_input2035_04_np)
mgra13_based_input2040_04_np_c<- parking_changes(mgra13_based_input2040_04_np)
mgra13_based_input2045_04_np_c<- parking_changes(mgra13_based_input2045_04_np)
mgra13_based_input2050_04_np_c<- parking_changes(mgra13_based_input2050_04_np)


## Apply rounding function to "_05" files
rounding_columns(mgra13_based_input2050_05_np)

##Compare versions (_04 vs _05)
test2016<-compare_versions(mgra13_based_input2016_04_np_c,rounding_columns(mgra13_based_input2016_05_np))
test2018<-compare_versions(mgra13_based_input2018_04_np_c,rounding_columns(mgra13_based_input2018_05_np))
test2020<-compare_versions(mgra13_based_input2020_04_np_c,rounding_columns(mgra13_based_input2020_05_np))
test2023<-compare_versions(mgra13_based_input2023_04_np_c,rounding_columns(mgra13_based_input2023_05_np))
test2025<-compare_versions(mgra13_based_input2025_04_np_c,rounding_columns(mgra13_based_input2025_05_np))
test2026<-compare_versions(mgra13_based_input2026_04_np_c,rounding_columns(mgra13_based_input2026_05_np))
test2029<-compare_versions(mgra13_based_input2029_04_np_c,rounding_columns(mgra13_based_input2029_05_np))
test2030<-compare_versions(mgra13_based_input2030_04_np_c,rounding_columns(mgra13_based_input2030_05_np))
test2032<-compare_versions(mgra13_based_input2032_04_np_c,rounding_columns(mgra13_based_input2032_05_np))
test2035<-compare_versions(mgra13_based_input2035_04_np_c,rounding_columns(mgra13_based_input2035_05_np))
test2040<-compare_versions(mgra13_based_input2040_04_np_c,rounding_columns(mgra13_based_input2040_05_np))
test2045<-compare_versions(mgra13_based_input2045_04_np_c,rounding_columns(mgra13_based_input2045_05_np))
test2050<-compare_versions(mgra13_based_input2050_04_np_c,rounding_columns(mgra13_based_input2050_05_np))

### Save out files
write.csv(test2016,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2016 Flagged.csv")
write.csv(test2018,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2018 Flagged.csv")
write.csv(test2020,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2020 Flagged.csv")
write.csv(test2023,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2023 Flagged.csv")
write.csv(test2025,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2025 Flagged.csv")
write.csv(test2026,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2026 Flagged.csv")
write.csv(test2029,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2029 Flagged.csv")
write.csv(test2030,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2030 Flagged.csv")
write.csv(test2032,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2032 Flagged.csv")
write.csv(test2035,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2035 Flagged.csv")
write.csv(test2040,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2040 Flagged.csv")
write.csv(test2045,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2045 Flagged.csv")
write.csv(test2050,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 2//Test 2050 Flagged.csv")

