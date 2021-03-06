#LUDU QA
##see row 70 - is it ok that there are 8100 records with no assessor id


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
ludu <- sqlQuery(channel, 
                 "SELECT [OBJECTID]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID] 
FROM  [WS].[dbo].[LUDU2019DRAFT]"
)

#read in ludu 2018 data - exclude shape variable for efficiency
ludu_2018 <- sqlQuery(channel, 
                 "SELECT [OBJECTID]
      ,[subParcel]
      ,[parcelID]
      ,[apn8]
      ,[lu]
      ,[du]
      ,[genOwnID]
      ,[MGRA14]
      ,[regionID] 
FROM  [lis].[gis].[LUDU2018]"
)

head(ludu)

#check for objectid duplicates - none
dups_obj <- ludu %>%
  filter(duplicated(OBJECTID) | duplicated(OBJECTID, fromLast = TRUE))

#check subparcel values are 9 digits
class(ludu$subParcel)
summary(ludu$subParcel)
unique(ludu$subParcel)

#check parcelID values are 7 digits
class(ludu$parcelID)
summary(ludu$parcelID)

#compare subparcel to parcelid
##delete last two digits of subparcel to compare to parcel
ludu$subParcel_test <- str_sub(ludu$subParcel, end=-3)

head(ludu)
unique(nchar(ludu$subParcel))
unique(nchar(ludu$parcelID))
unique(nchar(ludu$subParcel_test))

ludu$test  <- as.integer(ludu$test)
class(ludu$parcelID)
class(ludu$subParcel_test)
identical(ludu$parcelID,ludu$test)

#check values for apn8
unique(nchar(ludu$apn8))
apn8_na <- subset(ludu, is.na(ludu$apn8))
length(unique(apn8_na$lu))
length(unique(apn8_na$genOwnID))

#check values for lu
unique(nchar(ludu$lu))
unique(ludu$lu)

#check values for du
summary(ludu$du)

#check values for genOwnID
(unique(ludu$genOwnID))
length(unique(ludu$genOwnID))
table(ludu$genOwnID)

#check mgra values
length(unique(ludu$MGRA14))
unique(nchar(ludu$MGRA14))


#check 2019 cases where du is >0 and was =0 in 2018. Did lu value change?

##merge 2019 to 2018 on subParcel?
ludu$test <-NULL
ludu$subParcel_test <- NULL
ludu_merge <- merge(ludu, ludu_2018, by = "subParcel", suffixes = c("19","18"), all = TRUE)

##subset matched file where du was 0 and is not >0 and lu did not change
ludu_merge <- subset(ludu_merge, ludu_merge$du19>0 & ludu_merge$du18==0 & ludu_merge$lu19==ludu_merge$lu18)
table(ludu_merge$lu19)

#save out file where land use was expected to change and did not
write.csv(ludu_merge, 'M:\\Technical Services\\QA Documents\\Projects\\LUDU 2019\\results\\Test#9 lu to du checks 2018-2019.csv', row.names = FALSE)

#check that no records exists for du on gq lu types
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

#check that no records exists for du on hotel, motel, resort lu types
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

#check that no records exists for du on vacant lu types
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


