

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
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=GeoDepot; trusted_connection=true')



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
     FROM [GeoDepot].[gis].[LUDU2019]"
)
odbcClose(channel) 



channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=RM; trusted_connection=true')

ludu_2020 <- sqlQuery(channel, 
                 "SELECT [OBJECTID]
      ,[LCKey]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID]
FROM  [RM].[dbo].[DRAFT_LUDU2020POINTS]"
)
odbcClose(channel) 

ludu_merge$du_dif<- ludu_merge$du20-ludu_merge$du19


##merge 2020 to 2019 on subParcel?
ludu_2020$test <-NULL
ludu_2020$subParcel_test <- NULL
ludu_merge <- merge(ludu_2020, 
                    ludu_2019, 
                    by = "subParcel", 
                    suffixes = c("20","19"), 
                    all = TRUE)

## Test 9: subset matched file where du was 0 and is not >0 and lu did not change
test9 <- subset(ludu_merge, 
                     ludu_merge$du20>0 & ludu_merge$du19==0 & ludu_merge$lu20==ludu_merge$lu19)
table(test9$lu20)

#save out file where land use was expected to change and did not
write.csv(test9, 
          'C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-41 Land Use Inventory Update//Results//Test#9 lu to du checks 2019-2020.csv', 
          row.names = FALSE)

## Test 10: Check for negative DU trend 2019 to 2020 by MGRA.  
test10<-subset(ludu_merge, du_dif<0)

test10_a<- test10 %>% 
  dplyr::select(MGRA1420, lu20, du20, lu19, du19,du_dif)

test10_a<-aggregate(.~MGRA1420, data=test10_a, sum)
  
write.csv(test10, 
          'C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-41 Land Use Inventory Update//Results//Test#10 negative dus 2019-2020.csv', 
          row.names = FALSE)

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
    FROM [RM].[dbo].[DRAFT_LUDU2020POINTS]
    where DU > 0 AND LU IN (1400,1401,1402,1403,1404,1409)" #Jail/Prison, Dorms, Military, Monastery, Other GQ facility
)

no_gq2<- subset(ludu_2020, (ludu_2020$du>0 & (ludu_2020$lu==1400 | ludu_2020$lu==1401 | ludu_2020$lu==1402 |
                                                ludu_2020$lu==1403 | ludu_2020$lu==1404 |ludu_2020$lu==1409)))

## Test 12: check that no records exists for du on hotel, motel, resort lu types
no_hotel <- sqlQuery(channel, 
                     "SELECT [OBJECTID]
      ,[LCKey]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID]
FROM  [RM].[dbo].[DRAFT_LUDU2020POINTS]
    where DU > 0 AND LU IN (1500, 1501,1502,1503)" #Hotel, Motel, Resort
)

no_hotel2<- subset(ludu_2020, (ludu_2020$du>0 & (ludu_2020$lu==1500 | ludu_2020$lu==1501 | ludu_2020$lu==1502 |
                                                ludu_2020$lu==1503)))

## Test 13: check that no records exists for du on vacant lu types
no_vacant <- sqlQuery(channel, 
                      "SELECT [OBJECTID]
      ,[LCKey]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID]
FROM  [RM].[dbo].[DRAFT_LUDU2020POINTS]
    where DU > 0 AND LU IN (9101)" #Vacant and Undeveloped Land
)

no_vacant2<- subset(ludu_2020, (ludu_2020$du>0 & ludu_2020$lu==9101))

## Test 14: Confirm dus increase over time
test14a <- subset(ludu_merge, 
                ludu_merge$du_dif>0)

length(test14a$parcelID20)/length(ludu_merge$parcelID20)

test14b <- subset(ludu_merge, 
                 ludu_merge$du_dif==0)

length(test14b$parcelID20)/length(ludu_merge$parcelID20)

## Test 16: Determine number of lu codes changing over time 

test16 <- subset(ludu_merge, 
              ludu_merge$lu20!=ludu_merge$lu19)

length(test16$parcelID20)/length(ludu_merge$parcelID20)
