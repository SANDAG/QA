#Group Quarters QA

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

gq <- sqlQuery(channel, 
  "SELECT [OBJECTID]
      ,[facilityID]
      ,[facilityType]
      ,[name]
      ,[gqPop]
      ,[gqMil]
      ,[gqCiv]
      ,[gqCivCol]
      ,[gqOther]
      ,[comment]
      ,[effectYear]
      ,[regionID]
      ,[subFacility]
      ,[Check_]
      ,[FOIAexempt]
      ,[DOF]
      ,[DOF_Name]
  FROM [SPACECORE].[gis].[GROUPQUARTER]
  where effectYear=2019"
)

#read in facilityType code list and remove blank records
facility_type <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\Group Quarters Spacecore 2019\\Data files\\Census GQ facility type codes.xlsx", sheet=1)
facility_type <- facility_type[complete.cases(facility_type),] 


#check OBJECTID
##confirm OBJECTID values are unique - no dups
dups_obj <- gq %>%
  filter(duplicated(OBJECTID) | duplicated(OBJECTID, fromLast = TRUE)) 
##check min and max
min(gq$OBJECTID)
max(gq$OBJECTID)
##values are not sequential
gq_obj <- gq[order(gq$OBJECTID),]
head(gq$OBJECTID, 8)

#check facilityID
length(unique(gq$facilityID))

#check facilityType
length(unique(gq$facilityType))
unique(gq$facilityType)

#review facilityType values in gq file
table(gq$facilityType)

#review cases with unknown facilityType (facilityType=0)
no_ft <- gq[gq$facilityType==0,]
summary(no_ft$gqPop)
sum(no_ft$gqPop)
summary(no_ft$gqMil)
sum(no_ft$gqMil)
summary(no_ft$gqCiv)
sum(no_ft$gqCiv)

rm(no_ft)

#code facilityType into mil_rc as yes no
gq$mil_rc <- ifelse(gq$facilityType==600 |
                    gq$facilityType==601 |
                    gq$facilityType==602 |
                    gq$facilityType==404 |
                    gq$facilityType==106,1,0)
                              

#review number of records that are and are not military facility types
table(gq$mil_rc)
#check for military population count at military facility types
gq %>% group_by(mil_rc) %>% tally(gqMil)
#check for civilian population count at military facility types
test <- gq %>% group_by(mil_rc) %>% tally(gqCiv)
#check for military pop at non-military facility types
sum(gq$gqMil[gq$facilityType==904])
#compare gqMil pop to above
sum(gq$gqMil)
#check for all facility types with gqMil pop 
table(gq$facilityType[gq$gqMil!=0])

#review records where facility type is military and gqmil is zero 
gq$flag_mil <- 0
gq$flag_mil[gq$mil_rc==1 & gq$gqMil==0] <- 1
table(gq$flag_mil)
head(gq[gq$flag_mil==1,],6)

#check for cases where gqmil+gqCiv!=gqPop
gq$flag=0
gq$flag[gq$gqPop!=gq$gqMil+gq$gqCiv] <-1 
table(gq$flag)

#check for cases where gqCol+gqOther!=gqCiv
gq$flag2=0
gq$flag2[gq$gqCiv!=gq$gqCivCol+gq$gqOther] <-1 
table(gq$flag2)

#check stats for each pop count
summary(gq$gqPop)
sum(gq$gqPop)

summary(gq$gqMil)
sum(gq$gqMil)

summary(gq$gqCiv)
sum(gq$gqCiv)

##identify case with NA value from stats
check <- gq[is.na(gq$gqCivCol),]
check
##exclude case with NA value from stats
##GIS staff changed NULL value to zero for gq$OBJECTID=52574 
summary(gq$gqCivCol)
sum(gq$gqCivCol)
summary(gq$gqOther)
sum(gq$gqOther)

#check valid values for regionID - all should be 0
table(gq$regionID)

#check values for subfacility
length(unique(gq$subFacility))
summary(gq$subFacility)

##check number of records coded as zero/missing for subfacility
gq1 <- gq[order(gq$subFacility),]
head(table(gq1$subFacility))

#check valid values for FOIAexempt
table(gq$FOIAexempt)

#check valid values for DOF
table(gq$DOF)
