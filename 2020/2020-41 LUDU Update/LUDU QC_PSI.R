### Project: 2020- 41 LUDU DRAFT 2020 QC
### Author: Purva Singh
h
### This script is for test 1 through 8 and 15 of the test plan. 
### The test plan can be found here: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc=%7BDBBBF7A2-5535-48D4-BE08-B36C3F188109%7D&file=2020-41%20Land%20Use%20Inventory%20QC%20Test%20Plan&action=edit&mobileredirect=true&wdorigin=Sharepoint&CT=1606843411646&OR=ItemsView 

### Part 1: Setting up the R environment and loading packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)

readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}

# Creating path for saving results
outputfile <- paste("LUDU_2020_QC_PSI",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-41 LUDU Update\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))


### Part 2: Loading the dataset
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=RM; trusted_connection=true')


# LUDU 2020 
ludu <- sqlQuery(channel, 
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


#LUDU 2019
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


### Part 3: Running the tests

## Test 1: ObjectID- check values are unique  
dups_obj <- ludu %>%
  filter(duplicated(OBJECTID) | duplicated(OBJECTID, fromLast = TRUE))

length(unique(ludu$OBJECTID))== length(ludu$OBJECTID)



# Test 2: check subparcel values are 9 digits-- this test was not included in this test plan as 
# subparcels were dropped
#class(ludu$subParcel)
#summary(ludu$subParcel)
#unique(ludu$subParcel)

## Test 3: check parcelID values are 7 digits

class(ludu$parcelID)  # integer class
range(ludu$parcelID)  # range for the parcelID shows negative values

ludu%>%
  filter(parcelID== 'NA')   # null values in parcel IDs

parcel_negative<- ludu%>%
  filter(parcelID<0)

parcel_dup<- ludu%>%
  filter(duplicated(ludu$parcelID))

parcel_dup_all<-ludu%>%
  filter(parcelID %in% parcel_dup$parcelID)

length(unique(parcel_dup_all$parcelID))


## Test 4: check if apn8 values are valid
length(unique(ludu$apn8))
apn_na<- ludu%>%
  filter(is.na(apn8))

unique(nchar(ludu$apn8))

apn<-ludu%>%
  filter(!is.na(apn8))%>%
  filter(lu== 4112 | lu== 4117 | lu== 4118 | lu== 1401 | lu==1403| lu== 2301 | lu== 4104| lu== 4120 | lu== 6101| lu== 6702| lu== 6703 | lu== 6701)
  
unique(apn$lu)

## Test 5: Check if lu values are valid and match the ones in the database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=data_cafe; trusted_connection=true')

ludu_codes <- sqlQuery(channel, "SELECT 
 [lu_code]
,[lu_description]
FROM [data_cafe].[ref].[sandag_lu_codes]")

length(unique(ludu$lu))
length(unique(ludu_codes$lu_code))
range(ludu$lu)
unique(nchar(ludu$lu))


not_lucodes<- ludu%>%
  filter(!lu %in% ludu_codes$lu_code)  # 1090 LU code doesnt exist in the LUDU codes table in the DB


### Need to do some additional checks on Test 5 LU in ArcGIS

## Test 6: Confirm if DU values are valid

range(ludu$du)

ludu_table<- ludu%>%
  group_by(lu)%>%
  summarise_at(vars(du), sum)

ludu_table<- merge(ludu_table, ludu_codes, by.x =  "lu", by.y = "lu_code", all= 'TRUE')

ludu_table2019<- ludu_2019%>%
  group_by(lu)%>%
  summarise_at(vars(du), sum)

setnames(ludu_table2019, old= "du", new= "du_2019")

ludu_table<- merge(ludu_table, ludu_table2019, by =  "lu", all= 'TRUE')

write.csv(ludu_table, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-41 LUDU Update\\Test#6 LUDU.csv", row.names = FALSE)


## Test 7: Confirm that genOwnIDs are valid
(unique(ludu$genOwnID))
length(unique(ludu$genOwnID))
genown<- as.data.table(table(ludu$genOwnID))

write.csv(genown, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-41 LUDU Update\\Test#7 genownID.csv", row.names = FALSE)



## Test 8: MGRA14

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8; database=RM; trusted_connection=true')

mgra14<- sqlQuery(channel, "SELECT [OBJECTID]
      ,[MGRA]
      ,[CT10]
      ,[CT10BG]
      ,[SRA]
      ,[MSA]
      ,[City]
      ,[ZIP]
      ,[Sphere]
      ,[CPA]
      ,[CPASG]
      ,[TAZ]
      ,[Council]
      ,[Super]
      ,[LUZ]
      ,[Elem]
      ,[Unif]
      ,[High]
      ,[Coll]
      ,[Transit]
      FROM [RM].[dbo].[MGRA14]")


length(unique(mgra14$MGRA))- length(unique(ludu$MGRA14))  # 24 mgras missing 

mis_mgras<- mgra14%>%
  filter(!MGRA %in% ludu$MGRA)


write.csv(mis_mgras, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-41 LUDU Update\\missing_mgra.csv", row.names = FALSE)


### Test 14: LC Keys

length(unique(ludu$LCKey))
unique(nchar(ludu$LCKey))
range(ludu$LCKey)


### Additional check: duplicate rows based on values in all columns

dup_rows<- ludu[duplicated(ludu[,1:ncol(ludu)]),]   # no duplicate rows






