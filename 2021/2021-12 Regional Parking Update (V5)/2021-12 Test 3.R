#Project ID: 2021-12
#Purpose: Test 3 in Test Plan- https://sandag.sharepoint.com/:o:/g/qaqc/EulxFso4msxFlF5iuFJyTlABrxoSUBdic5kAgknmoMcYaw?e=JApYdX
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

### Retrieve and prep source file
access_time_lookup<- read.xlsx("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Reference//MT and MM Phasing by Hub_ForModeling_7-20-20 - Copy.xlsx",
                               startRow = 2) #to resolve formatting issues, [Build.-.Access.Time.(minutes)]
                                              #was modified in raw Excel to have "n/a" changed to blank

colnames(access_time_lookup)[4]<- "MicroAccess"

access_time_lookup$Micromobility.Phase.Year<-as.numeric(access_time_lookup$Micromobility.Phase.Year)



### Retrieve MGRA to MoHub mapping file

channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=WS; trusted_connection=true')

mgra_mohubs<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [MGRA]
      ,[MoHubName]
      ,[MoHubType]
  FROM [ws].[dbo].[MGRA13_in_MoHub_Amoeba_Edits_V5]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#change dataframes to datatables
list2env(eapply(.GlobalEnv, function(x) {if(is.data.frame(x)) {setDT(x)} else {x}}), .GlobalEnv)


### Merge MGRAs and expected access time

mgra_mohubs_access<- merge(mgra_mohubs,
                           access_time_lookup[,c("Mobility.Hub","Micromobility.Phase.Year","MicroAccess")],
                           by.x="MoHubName",
                           by.y="Mobility.Hub")



### Merge expected access time with data 
mgra_input_2016<- merge(mgra13_based_input2016_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2018<- merge(mgra13_based_input2018_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2020<- merge(mgra13_based_input2020_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2023<- merge(mgra13_based_input2023_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2025<- merge(mgra13_based_input2025_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2026<- merge(mgra13_based_input2026_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2029<- merge(mgra13_based_input2029_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2030<- merge(mgra13_based_input2030_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2032<- merge(mgra13_based_input2032_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2035<- merge(mgra13_based_input2035_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2040<- merge(mgra13_based_input2040_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2045<- merge(mgra13_based_input2045_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

mgra_input_2050<- merge(mgra13_based_input2050_05_np,
                        mgra_mohubs_access,
                        by.x="mgra",
                        by.y="MGRA",
                        all.x=TRUE)

###  Create function to compare MicroAccessTime values

check_microaccess <- function(data){
  
  data$MicroAccessTime<- as.numeric(data$MicroAccessTime)
  
  data$MicroAccess[is.na(data$MicroAccess)]<-120  #Replace value for MoHubs with NA as 120 (default)

  data$Micromobility.Phase.Year[is.na(data$Micromobility.Phase.Year)]<-2020 #Replace value for MoHubs with NA as 2020 for default calculations
  
  flag<- subset(data, MicroAccessTime != MicroAccess)
return(flag)}



### Apply function to test each year
test2016<-check_microaccess(mgra_input_2016)
test2016<- subset(test2016, Micromobility.Phase.Year<=2016)

test2018<-check_microaccess(mgra_input_2018)
test2018<- subset(test2018, Micromobility.Phase.Year<=2018)

test2020<-check_microaccess(mgra_input_2020)
test2020<- subset(test2020, Micromobility.Phase.Year<=2020)

test2023<-check_microaccess(mgra_input_2023)
test2023<- subset(test2023, Micromobility.Phase.Year<=2023)

test2025<-check_microaccess(mgra_input_2025)
test2025<- subset(test2025, Micromobility.Phase.Year<=2025)

test2026<-check_microaccess(mgra_input_2026)
test2026<- subset(test2026, Micromobility.Phase.Year<=2026)

test2030<-check_microaccess(mgra_input_2030)
test2030<- subset(test2030, Micromobility.Phase.Year<=2030)

test2032<-check_microaccess(mgra_input_2032)
test2032<- subset(test2032, Micromobility.Phase.Year<=2032)

test2035<-check_microaccess(mgra_input_2035)
test2035<- subset(test2035, Micromobility.Phase.Year<=2035)

test2040<-check_microaccess(mgra_input_2040)
test2040<- subset(test2040, Micromobility.Phase.Year<=2040)

test2045<-check_microaccess(mgra_input_2045)
test2045<- subset(test2045, Micromobility.Phase.Year<=2045)

test2050<-check_microaccess(mgra_input_2050)
test2050<- subset(test2050, Micromobility.Phase.Year<=2050)

### Save out results
write.csv(test2016,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2016 Flagged.csv")
write.csv(test2018,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2018 Flagged.csv")
write.csv(test2020,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2020 Flagged.csv")
write.csv(test2023,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2023 Flagged.csv")
write.csv(test2025,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2025 Flagged.csv")
write.csv(test2026,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2026 Flagged.csv")
write.csv(test2029,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2029 Flagged.csv")
write.csv(test2030,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2030 Flagged.csv")
write.csv(test2032,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2032 Flagged.csv")
write.csv(test2035,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2035 Flagged.csv")
write.csv(test2040,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2040 Flagged.csv")
write.csv(test2045,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2045 Flagged.csv")
write.csv(test2050,"C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2021//2021-12 Parking Update V5//Results//Test 3//Test 2050 Flagged.csv")

