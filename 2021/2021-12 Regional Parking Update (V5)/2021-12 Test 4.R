#Project ID: 2021-12
#Purpose: Test 4 in Test Plan- https://sandag.sharepoint.com/:o:/g/qaqc/EulxFso4msxFlF5iuFJyTlABrxoSUBdic5kAgknmoMcYaw?e=JApYdX
#Author: Kelsie Telson

###Set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)


library("readxl")
library("openxlsx")
library("data.table")
library("dplyr")
library("stringr")
library(RODBC)

library(plyr)
library(readr)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)

###Retrieve data files

## Retrieve xpef33 files 
filenames_33 <- list.files(path="T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//",
                           pattern="*_np.csv")

##Create list of data frame names without the ".csv" part 
names_33 <-substr(filenames_33,1,28)

###Load all files
for(i in names_33){
  filepath <- file.path("T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//",paste(i,".csv",sep=""))
  assign(paste(i,"33",sep="_"), read.csv(filepath)[,c("mgra", "hstallsoth",	"hstallssam",	"dstallsoth",	"dstallssam",	"mstallsoth",	"mstallssam", "hparkcost", "dparkcost", "mparkcost", "MicroAccessTime")])
}

## Retrieve xpef32 files 
filenames_32 <- list.files(path="T://socioec//Current_Projects//XPEF33//abm_csv//new_parking//",
                           pattern="*_np.csv")

##Create list of data frame names without the ".csv" part 
names_32 <-substr(filenames_33,1,28)

###Load all files
for(i in names_32){
  filepath <- file.path("T://socioec//Current_Projects//XPEF32//abm_csv//new_parking//",paste(i,".csv",sep=""))
  assign(paste(i,"32",sep="_"), read.csv(filepath)[,c("mgra", "hstallsoth",	"hstallssam",	"dstallsoth",	"dstallssam",	"mstallsoth",	"mstallssam", "hparkcost", "dparkcost", "mparkcost", "MicroAccessTime")])
}


### Apply test to compare objects for each year

#2016
identical(mgra13_based_input2016_05_np_32,mgra13_based_input2016_05_np_33)
all.equal(mgra13_based_input2016_05_np_32,mgra13_based_input2016_05_np_33)

#2018
identical(mgra13_based_input2018_05_np_32,mgra13_based_input2018_05_np_33)
all.equal(mgra13_based_input2018_05_np_32,mgra13_based_input2018_05_np_33)

#2020
identical(mgra13_based_input2020_05_np_32,mgra13_based_input2020_05_np_33)
all.equal(mgra13_based_input2020_05_np_32,mgra13_based_input2020_05_np_33)

#2023
identical(mgra13_based_input2023_05_np_32,mgra13_based_input2023_05_np_33)
all.equal(mgra13_based_input2023_05_np_32,mgra13_based_input2023_05_np_33)

#2025
identical(mgra13_based_input2025_05_np_32,mgra13_based_input2025_05_np_33)
all.equal(mgra13_based_input2025_05_np_32,mgra13_based_input2025_05_np_33)

#2026
identical(mgra13_based_input2026_05_np_32,mgra13_based_input2026_05_np_33)
all.equal(mgra13_based_input2026_05_np_32,mgra13_based_input2026_05_np_33)

#2029
identical(mgra13_based_input2029_05_np_32,mgra13_based_input2029_05_np_33)
all.equal(mgra13_based_input2029_05_np_32,mgra13_based_input2029_05_np_33)

#2030
identical(mgra13_based_input2030_05_np_32,mgra13_based_input2030_05_np_33)
all.equal(mgra13_based_input2030_05_np_32,mgra13_based_input2030_05_np_33)

#2032
identical(mgra13_based_input2032_05_np_32,mgra13_based_input2032_05_np_33)
all.equal(mgra13_based_input2032_05_np_32,mgra13_based_input2032_05_np_33)

#2035
identical(mgra13_based_input2035_05_np_32,mgra13_based_input2035_05_np_33)
all.equal(mgra13_based_input2035_05_np_32,mgra13_based_input2035_05_np_33)

#2040
identical(mgra13_based_input2040_05_np_32,mgra13_based_input2040_05_np_33)
all.equal(mgra13_based_input2040_05_np_32,mgra13_based_input2040_05_np_33)

#2045
identical(mgra13_based_input2045_05_np_32,mgra13_based_input2045_05_np_33)
all.equal(mgra13_based_input2045_05_np_32,mgra13_based_input2045_05_np_33)

#2050
identical(mgra13_based_input2050_05_np_32,mgra13_based_input2050_05_np_33)
all.equal(mgra13_based_input2050_05_np_32,mgra13_based_input2050_05_np_33)


### Create udf to provide descriptives for differences between forecast versions

describe_differences<- function(data1,data2) {
  newdata<- merge(data1,
                  data2,
                  by="mgra")
  
  newdata$hstalloth_dif <- newdata$hstallsoth.y-newdata$hstallsoth.x
  newdata$hstallsam_dif <- newdata$hstallssam.y-newdata$hstallssam.x
  newdata$dstalloth_dif <- newdata$dstallsoth.y-newdata$dstallsoth.x
  newdata$dstallsam_dif <- newdata$dstallssam.y-newdata$dstallssam.x
  newdata$mstalloth_dif <- newdata$mstallsoth.y-newdata$mstallsoth.x
  newdata$mstallsam_dif <- newdata$mstallssam.y-newdata$mstallssam.x
  
  newdata<- newdata[,22:27]
  
  return(as.data.table(summary(newdata)))
  
}


## Genereate descriptives for each year
Descriptives2016<- describe_differences(mgra13_based_input2016_05_np_32,mgra13_based_input2016_05_np_33)
Descriptives2018<- describe_differences(mgra13_based_input2018_05_np_32,mgra13_based_input2018_05_np_33)
Descriptives2020<- describe_differences(mgra13_based_input2020_05_np_32,mgra13_based_input2020_05_np_33)
Descriptives2023<- describe_differences(mgra13_based_input2023_05_np_32,mgra13_based_input2023_05_np_33)
Descriptives2025<- describe_differences(mgra13_based_input2025_05_np_32,mgra13_based_input2025_05_np_33)
Descriptives2026<- describe_differences(mgra13_based_input2026_05_np_32,mgra13_based_input2026_05_np_33)
Descriptives2029<- describe_differences(mgra13_based_input2029_05_np_32,mgra13_based_input2029_05_np_33)
Descriptives2030<- describe_differences(mgra13_based_input2030_05_np_32,mgra13_based_input2030_05_np_33)
Descriptives2032<- describe_differences(mgra13_based_input2032_05_np_32,mgra13_based_input2032_05_np_33)
Descriptives2035<- describe_differences(mgra13_based_input2035_05_np_32,mgra13_based_input2035_05_np_33)
Descriptives2040<- describe_differences(mgra13_based_input2040_05_np_32,mgra13_based_input2040_05_np_33)
Descriptives2045<- describe_differences(mgra13_based_input2045_05_np_32,mgra13_based_input2045_05_np_33)
Descriptives2050<- describe_differences(mgra13_based_input2050_05_np_32,mgra13_based_input2050_05_np_33)

## Save Out
wb1 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

summary2016 = addWorksheet(wb1, "2016")
writeData(wb1, "2016", Descriptives2016)

summary2018 = addWorksheet(wb1, "2018")
writeData(wb1, "2018", Descriptives2018)

summary2020 = addWorksheet(wb1, "2020")
writeData(wb1, "2020", Descriptives2020)

summary2023 = addWorksheet(wb1, "2023")
writeData(wb1, "2023", Descriptives2023)

summary2025 = addWorksheet(wb1, "2025")
writeData(wb1, "2025", Descriptives2025)

summary2026 = addWorksheet(wb1, "2026")
writeData(wb1, "2026", Descriptives2026)

summary2029 = addWorksheet(wb1, "2029")
writeData(wb1, "2029", Descriptives2029)

summary2030 = addWorksheet(wb1, "2030")
writeData(wb1, "2030", Descriptives2030)

summary2032 = addWorksheet(wb1, "2032")
writeData(wb1, "2032", Descriptives2032)

summary2035 = addWorksheet(wb1, "2035")
writeData(wb1, "2035", Descriptives2035)

summary2040 = addWorksheet(wb1, "2040")
writeData(wb1, "2040", Descriptives2040)

summary2045 = addWorksheet(wb1, "2045")
writeData(wb1, "2045", Descriptives2045)

summary2050 = addWorksheet(wb1, "2050")
writeData(wb1, "2050", Descriptives2050)

saveWorkbook(wb1, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 4 Descriptives of Difference by Year.xlsx",overwrite=TRUE)
