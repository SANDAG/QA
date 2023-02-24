

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
median_age_cpa_sql = getSQL("../Queries/median_age_cpa.sql")
median_age_cpa<-sqlQuery(channel,median_age_cpa_sql)

median_age_jur_sql = getSQL("../Queries/median_age_jur.sql")
median_age_jur<-sqlQuery(channel,median_age_jur_sql)

tail(median_age_jur)
median_age_region_sql = getSQL("../Queries/median_age_region.sql")
median_age_region<-sqlQuery(channel,median_age_region_sql)

odbcClose(channel)

tail(median_age_region)

write.csv(median_age_cpa, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\median_age_cpa_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(median_age_jur, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\median_age_jur_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(median_age_region, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\median_age_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

median_age_cpa$geotype<-"cpa"
median_age_jur$geotype<-"jurisdiction"
median_age_region$geotype<-"region"
median_age_region$geozone<-"Region"

median_age_cpa<- median_age_cpa[order(median_age_cpa$geotype,median_age_cpa$geozone,median_age_cpa$yr_id),]
median_age_jur<- median_age_jur[order(median_age_jur$geotype,median_age_jur$geozone,median_age_jur$yr_id),]
median_age_region<- median_age_region[order(median_age_region$geotype,median_age_region$geozone,median_age_region$yr_id),]

head(median_age_cpa)

#these revisions only apply to cpa names
#median_age_cpa$geozone<-revalue(median_age_cpa$geozone, c("Los Penasquitos Canyon Preserve" = "Los Penas. Can. Pres."))
median_age_cpa$geozone[median_age_cpa$geotype =="region"]<- "Region"
median_age_cpa$geozone <- gsub("\\*","",median_age_cpa$geozone)
median_age_cpa$geozone <- gsub("\\-","_",median_age_cpa$geozone)
median_age_cpa$geozone <- gsub("\\:","_",median_age_cpa$geozone)


head(median_age_region)

median_age_19<-data.frame()
median_age_19<-rbind(median_age_cpa, median_age_jur, median_age_region)

write.csv(median_age_19, "M:\\Technical Services\\QA Documents\\Projects\\LU Densification\\results\\median_age_19.csv")


