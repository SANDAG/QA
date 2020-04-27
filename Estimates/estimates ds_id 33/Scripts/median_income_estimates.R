#median income for estimates


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  

}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

#set working directory to access necessary scripts
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#change any factors to strings 
options(stringsAsFactors=FALSE)

#format numbers
options('scipen'=10)

#read in data for id33
datasource_id=33
ds_id=33
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#region median income for ID33
median_income_reg_sql = getSQL("../Queries/median_income_region_ds_id.sql")
median_income_reg_sql <- gsub("ds_id", datasource_id, median_income_reg_sql)
mi_reg<-sqlQuery(channel,median_income_reg_sql,stringsAsFactors = FALSE)
#jurisdiction median income for ID33
median_income_jur_sql = getSQL("../Queries/median_income_jur_ds_id.sql")
median_income_jur_sql <- gsub("ds_id", datasource_id, median_income_jur_sql)
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
#cpa median income for ID33
median_income_cpa_sql = getSQL("../Queries/median_income_cpa_ds_id.sql")
median_income_cpa_sql <- gsub("ds_id", datasource_id, median_income_cpa_sql)
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
#census tract median income for ID33
median_income_zip_sql = getSQL("../Queries/median_income_zip_ds_id.sql")
median_income_zip_sql <- gsub("ds_id", datasource_id, median_income_zip_sql)
mi_zip<-sqlQuery(channel,median_income_zip_sql,stringsAsFactors = FALSE)
#households for ID33 - include for context
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id,hh_sql)
hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)

hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", datasource_id,hhinc_sql)
hh_inc<-sqlQuery(channel,hhinc_sql,stringsAsFactors = FALSE)

#check to ensure all years came through
table(hh_inc$yr_id)
table(mi_reg$yr_id)
table(mi_reg$yr_id)
table(mi_jur$yr_id)
table(mi_cpa$yr_id)
table(mi_zip$yr_id)

############
##############
#why this?
#cpa ids
#cpa_sql = getSQL("../Queries/cpa_id_lookup.sql")
#cpa_id<-sqlQuery(channel,cpa_sql,stringsAsFactors = FALSE)
odbcClose(channel)


#add geotype variable to differentiate in future analyses
mi_reg$geotype <- "region"
mi_jur$geotype <- "jurisdiction"
mi_cpa$geotype <- "cpa"
mi_zip$geotype <- "zip"

#recode San Diego Region geotype for clarity
mi_reg$geozone <- "San Diego Region"
hh_inc$geozone[hh_inc$geotype=="region"]<-"San Diego Region"

#calculate percent change between years. 
#zip
mi_zip <- mi_zip[order(mi_zip$geozone,mi_zip$yr_id),]
mi_zip$N_chg <- mi_zip$median_inc - lag(mi_zip$median_inc)
mi_zip$N_pct <- (mi_zip$N_chg / lag(mi_zip$median_inc))*100
mi_zip$N_pct<-round(mi_zip$N_pct,digits=2)
#cpa
mi_cpa <- mi_cpa[order(mi_cpa$geozone,mi_cpa$yr_id),]
mi_cpa$N_chg <- mi_cpa$median_inc - lag(mi_cpa$median_inc)
mi_cpa$N_pct <- (mi_cpa$N_chg / lag(mi_cpa$median_inc))*100
mi_cpa$N_pct<-round(mi_cpa$N_pct,digits=2)
#jurisdiction
mi_jur <- mi_jur[order(mi_jur$geozone,mi_jur$yr_id),]
mi_jur$N_chg <- mi_jur$median_inc - lag(mi_jur$median_inc)
mi_jur$N_pct <- (mi_jur$N_chg / lag(mi_jur$median_inc))*100
mi_jur$N_pct<-round(mi_jur$N_pct,digits=2)
#region
mi_reg <- mi_reg[order(mi_reg$geozone,mi_reg$yr_id),]
mi_reg$N_chg <- mi_reg$median_inc - lag(mi_reg$median_inc)
mi_reg$N_pct <- (mi_reg$N_chg / lag(mi_reg$median_inc))*100
mi_reg$N_pct<-round(mi_reg$N_pct,digits=2)
#hh by categories, all
hh_inc <- hh_inc[order(hh_inc$geozone,hh_inc$income_group_id,hh_inc$yr_id),]
hh_inc$N_chg <- hh_inc$hh - lag(hh_inc$hh)
hh_inc$N_pct <- (hh_inc$N_chg / lag(hh_inc$hh))*100
hh_inc$N_pct<-round(hh_inc$N_pct,digits=2)


#recode 2010 percent changes to "0"
mi_zip$N_chg[mi_zip$yr_id == "2010"] <- NA
mi_zip$N_pct[mi_zip$yr_id == "2010"] <- NA

mi_cpa$N_chg[mi_cpa$yr_id == "2010"] <- NA
mi_cpa$N_pct[mi_cpa$yr_id == "2010"] <- NA

mi_jur$N_chg[mi_jur$yr_id == "2010"] <- NA
mi_jur$N_pct[mi_jur$yr_id == "2010"] <- NA

mi_reg$N_chg[mi_reg$yr_id == "2010"] <- NA
mi_reg$N_pct[mi_reg$yr_id == "2010"] <- NA

hh_inc$N_chg[hh_inc$yr_id == "2010"] <- NA
hh_inc$N_pct[hh_inc$yr_id == "2010"] <- NA

#add flag variables for change at 5 percent
mi_zip$flag[mi_zip$N_pct>=5.00 | mi_zip$N_pct<=-5.00] <- 1 
mi_cpa$flag[mi_cpa$N_pct>=5.00 | mi_cpa$N_pct<=-5.00] <- 1 
mi_jur$flag[mi_jur$N_pct>=5.00 | mi_jur$N_pct<=-5.00] <- 1 
mi_reg$flag[mi_reg$N_pct>=5.00 | mi_reg$N_pct<=-5.00] <- 1 
hh_inc$flag[hh_inc$N_pct>=5.00 | hh_inc$N_pct<=-5.00] <- 1 

#remove tract from hh_inc dataset
hh_inc<-subset(hh_inc, geotype!="tract")

#saveout files for csv
write.csv(mi_zip,"C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Estimates\\ds_id=33\\Results\\Median Income\\median_income_zip.csv", row.names = FALSE)
write.csv(mi_cpa,"C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Estimates\\ds_id=33\\Results\\Median Income\\median_income_cpa.csv", row.names = FALSE)
write.csv(mi_jur,"C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Estimates\\ds_id=33\\Results\\Median Income\\median_income_jur.csv", row.names = FALSE)
write.csv(mi_reg,"C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Estimates\\ds_id=33\\Results\\Median Income\\median_income_reg.csv", row.names = FALSE)
write.csv(hh_inc,"C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Estimates\\ds_id=33\\Results\\Median Income\\median_income_category_hh.csv", row.names = FALSE)


#summary for test plan
table(hh_inc$flag,hh_inc$geozone)
table(mi_zip$flag,mi_zip$geozone)
table(mi_cpa$flag,mi_cpa$geozone)
table(mi_jur$flag,mi_jur$geozone)
table(mi_reg$flag,mi_reg$geozone)


