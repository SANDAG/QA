#In Progress: convert this forecast script to apply to estimates
#Done: delete plot related script
#In Progress: the queries run on gender and median age so that will require additional changes
#TODO create script to flag changes >5% between years

datasource_id=33
ds_id=datasource_id

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)


#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#necessary code for running SQL scripts in R
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

median_age_cpa_sql = getSQL("../Queries/median_age_cpa.sql")
median_age_cpa<- data.table::as.data.table(
  sqlQuery(channel,median_age_cpa_sql))
table(median_age_cpa$yr_id)

median_age_jur_sql = getSQL("../Queries/median_age_jur.sql")
median_age_jur<-data.table::as.data.table(sqlQuery(channel,median_age_jur_sql))
tail(median_age_jur)

median_age_region_sql = getSQL("../Queries/median_age_region.sql")
median_age_region<-sqlQuery(channel,median_age_region_sql)

odbcClose(channel)

tail(median_age_region)

#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

median_age_cpa$geotype<-"cpa"
median_age_jur$geotype<-"jurisdiction"
median_age_region$geotype<-"region"
median_age_region$geozone<-"San Diego Region"

median_age_cpa<- median_age_cpa[order(median_age_cpa$geotype,median_age_cpa$geozone,median_age_cpa$yr_id),]
median_age_jur<- median_age_jur[order(median_age_jur$geotype,median_age_jur$geozone,median_age_jur$yr_id),]
median_age_region<- median_age_region[order(median_age_region$geotype,median_age_region$geozone,median_age_region$yr_id),]


head(median_age_cpa)

#these revisions only apply to cpa names
median_age_cpa$geozone[median_age_cpa$geotype =="region"]<- "1Region"
median_age_cpa$geozone <- gsub("\\*","",median_age_cpa$geozone)
median_age_cpa$geozone <- gsub("\\-","_",median_age_cpa$geozone)
median_age_cpa$geozone <- gsub("\\:","_",median_age_cpa$geozone)

# write.csv(median_age_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\Median Age\\median_age_cpa19.csv")
# write.csv(median_age_jur, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\Median Age\\median_age_jur19.csv")
# write.csv(median_age_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\Median Age\\median_age19.csv")









