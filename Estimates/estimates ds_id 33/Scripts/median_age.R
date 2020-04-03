#Complete: convert this forecast script to apply to estimates
#Complete: delete plot related script
#Complete: the queries run on gender and median age so that will require additional changes
#Complete:create script to flag changes >5% between years
#TODO: add script to check zip codes

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

median_age_zip_sql = getSQL("../Queries/median_age_zip.sql")
median_age_zip<-data.table::as.data.table(sqlQuery(channel,median_age_zip_sql))
table(median_age_zip$yr_id)

median_age_jur_sql = getSQL("../Queries/median_age_jur.sql")
median_age_jur<-data.table::as.data.table(sqlQuery(channel,median_age_jur_sql))
table(median_age_jur$yr_id)

median_age_region_sql = getSQL("../Queries/median_age_reg.sql")
median_age_region<-sqlQuery(channel,median_age_region_sql)
table(median_age_region$yr_id)

odbcClose(channel)


#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

median_age_cpa$geotype<-"cpa"
median_age_zip$geotype<-"zip"
median_age_jur$geotype<-"jurisdiction"
median_age_region$geotype<-"region"
median_age_region$geozone<-"San Diego Region"

median_age_cpa<- median_age_cpa[order(median_age_cpa$geotype,median_age_cpa$geozone,median_age_cpa$yr_id),]
median_age_zip<- median_age_zip[order(median_age_zip$geotype,median_age_zip$geozone,median_age_zip$yr_id),]
median_age_jur<- median_age_jur[order(median_age_jur$geotype,median_age_jur$geozone,median_age_jur$yr_id),]
median_age_region<- median_age_region[order(median_age_region$geotype,median_age_region$geozone,median_age_region$yr_id),]


head(median_age_cpa)

#these revisions only apply to cpa names
median_age_cpa$geozone[median_age_cpa$geotype =="region"]<- "1Region"
median_age_cpa$geozone <- gsub("\\*","",median_age_cpa$geozone)
median_age_cpa$geozone <- gsub("\\-","_",median_age_cpa$geozone)
median_age_cpa$geozone <- gsub("\\:","_",median_age_cpa$geozone)

#calculate percent change between years. 
median_age_cpa <- median_age_cpa[order(median_age_cpa$geozone,median_age_cpa$yr_id),]
median_age_cpa$N_chg <- median_age_cpa$median_age - lag(median_age_cpa$median_age)
median_age_cpa$N_pct <- (median_age_cpa$N_chg / lag(median_age_cpa$median_age))*100
median_age_cpa$N_pct<-round(median_age_cpa$N_pct,digits=2)

median_age_zip <- median_age_zip[order(median_age_zip$geozone,median_age_zip$yr_id),]
median_age_zip$N_chg <- median_age_zip$median_age - lag(median_age_zip$median_age)
median_age_zip$N_pct <- (median_age_zip$N_chg / lag(median_age_zip$median_age))*100
median_age_zip$N_pct<-round(median_age_zip$N_pct,digits=2)

median_age_jur <- median_age_jur[order(median_age_jur$geozone,median_age_jur$yr_id),]
median_age_jur$N_chg <- median_age_jur$median_age - lag(median_age_jur$median_age)
median_age_jur$N_pct <- (median_age_jur$N_chg / lag(median_age_jur$median_age))*100
median_age_jur$N_pct<-round(median_age_jur$N_pct,digits=2)

median_age_region <- median_age_region[order(median_age_region$geozone,median_age_region$yr_id),]
median_age_region$N_chg <- median_age_region$median_age - lag(median_age_region$median_age)
median_age_region$N_pct <- (median_age_region$N_chg / lag(median_age_region$median_age))*100
median_age_region$N_pct<-round(median_age_region$N_pct,digits=2)

#cleaning: assign NA to all 2010 records
median_age_cpa$N_chg[median_age_cpa$yr_id == "2010"] <- NA
median_age_cpa$N_pct[median_age_cpa$yr_id == "2010"] <- NA

median_age_zip$N_chg[median_age_cpa$yr_id == "2010"] <- NA
median_age_cpa$N_pct[median_age_cpa$yr_id == "2010"] <- NA

median_age_jur$N_chg[median_age_jur$yr_id == "2010"] <- NA
median_age_jur$N_pct[median_age_jur$yr_id == "2010"] <- NA

median_age_region$N_chg[median_age_region$yr_id == "2010"] <- NA
median_age_region$N_pct[median_age_region$yr_id == "2010"] <- NA

#create flag for records with change greater than 5% in either direction (postive or negative)
median_age_cpa$flag[median_age_cpa$N_pct>5]<-1 
median_age_cpa$flag[median_age_cpa$N_pct<(-5)]<-1 

median_age_zip$flag[median_age_zip$N_pct>5]<-1 
median_age_zip$flag[median_age_zip$N_pct<(-5)]<-1

median_age_jur$flag[median_age_jur$N_pct>5]<-1 
median_age_jur$flag[median_age_jur$N_pct<(-5)]<-1 

median_age_cpa$flag[median_age_cpa$N_pct>5]<-1 
median_age_region$flag[median_age_region$N_pct<(-5)]<-1 

#write out results file to analyst OneDrive for review before manual upload to Sharepoint
write.csv(median_age_cpa, "C:\\Users\\kte\\OneDrive\\QA\\Estimates\\ds_id=33\\Output\\median_age\\median_age_cpa_QA.csv")
write.csv(median_age_zip, "C:\\Users\\kte\\OneDrive\\QA\\Estimates\\ds_id=33\\Output\\median_age\\median_age_zip_QA.csv")
write.csv(median_age_jur, "C:\\Users\\kte\\OneDrive\\QA\\Estimates\\ds_id=33\\Output\\median_age\\median_age_jur_QA.csv")
write.csv(median_age_region, "C:\\Users\\kte\\OneDrive\\QA\\Estimates\\ds_id=33\\Output\\median_age\\median_age_region_QA.csv")









