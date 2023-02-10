

#function to load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}

#identify packages to be loaded
packages <- c("sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","tidyverse", "readxl", "frequency", "ggplot2", "lubridate")
#confirm packages are read in
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

options(stringsAsFactors=FALSE)

#open channel to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=ws; trusted_connection=true')

#read in ludu 2019 data - exclude shape variable for efficiency
ludu_2019 <- sqlQuery(channel, 
                 "SELECT [OBJECTID]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID] 
FROM  [WS].[dbo].[LUDU2019]"
)


#read in ludu 2018 data - exclude shape variable for efficiency
ludu_2020 <- sqlQuery(channel, 
                      "[OBJECTID]
      ,[LCKey]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID]
  FROM [RM].[dbo].[DRAFT_LUDU2020]"
)

##merge 2020 to 2019 on subParcel?
ludu$test <-NULL
ludu$subParcel_test <- NULL
ludu_merge <- merge(ludu, 
                    ludu_2018, 
                    by = "subParcel", 
                    suffixes = c("19","18"), 
                    all = TRUE)

## Test 9: subset matched file where du was 0 and is not >0 and lu did not change
ludu_merge <- subset(ludu_merge, 
                     ludu_merge$du19>0 & ludu_merge$du18==0 & ludu_merge$lu19==ludu_merge$lu18)
table(ludu_merge$lu19)

#save out file where land use was expected to change and did not
write.csv(ludu_merge, 
          'M:\\Technical Services\\QA Documents\\Projects\\LUDU 2019\\results\\Test#9 lu to du checks 2018-2019.csv', 
          row.names = FALSE)

## TODO Test 10: Check for negative DU trend 2019 to 2020 by MGRA.  

## Test 11: check that no records exists for du on gq lu types
no_gq <- sqlQuery(channel, 
                  "SELECT [OBJECTID]
        ,[subParcel]
        ,[parcelID]
        ,[apn8]
        ,[lu]
        ,[du]
        ,[genOwnID]
        ,[MGRA14]
        ,[regionID]
    FROM [WS].[dbo].[LUDU2019DRAFT]
    where DU > 0 AND LU IN (1401,1402,1403,1404,1409)"
)

## Test 12: check that no records exists for du on hotel, motel, resort lu types
no_hotel <- sqlQuery(channel, 
                     "SELECT [OBJECTID]
        ,[subParcel]
        ,[parcelID]
        ,[apn8]
        ,[lu]
        ,[du]
        ,[genOwnID]
        ,[MGRA14]
        ,[regionID]
    FROM [WS].[dbo].[LUDU2019DRAFT]
    where DU > 0 AND LU IN (1501,1502,1503)"
)

## Test 13: check that no records exists for du on vacant lu types
no_vacant <- sqlQuery(channel, 
                      "SELECT [OBJECTID]
        ,[subParcel]
        ,[parcelID]
        ,[apn8]
        ,[lu]
        ,[du]
        ,[genOwnID]
        ,[MGRA14]
        ,[regionID]
    FROM [WS].[dbo].[LUDU2019DRAFT]
    where DU > 0 AND LU IN (9101)"
)

## Test 14: Confirm dus increase over time
