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

#read in data for id24
datasource_id=24
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#region median income for ID24
median_income_reg_sql = getSQL("../Queries/median_income_region_ds_id.sql")
median_income_reg_sql <- gsub("ds_id", datasource_id, median_income_reg_sql)
mi_reg<-sqlQuery(channel,median_income_reg_sql,stringsAsFactors = FALSE)
#jurisdiction median income for ID24
median_income_jur_sql = getSQL("../Queries/median_income_jur_ds_id.sql")
median_income_jur_sql <- gsub("ds_id", datasource_id, median_income_jur_sql)
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
#cpa median income for ID24
median_income_cpa_sql = getSQL("../Queries/median_income_cpa_ds_id.sql")
median_income_cpa_sql <- gsub("ds_id", datasource_id, median_income_cpa_sql)
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
#census tract median income for ID24
median_income_tract_sql = getSQL("../Queries/median_income_tract_ds_id.sql")
median_income_tract_sql <- gsub("ds_id", datasource_id, median_income_tract_sql)
mi_tract<-sqlQuery(channel,median_income_tract_sql,stringsAsFactors = FALSE)
#households for ID24 - include for context
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id,hh_sql)
hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
hh$datasource_id = datasource_id

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
mi_tract$geotype <- "tract"

#bind all records
mi_all_24<-rbind(mi_reg,mi_jur,mi_cpa,mi_tract)
mi_24 <- merge(mi_all_24,select(hh,yr_id,geotype,geozone,households),by.x=c("yr_id","geozone","geotype"), by.y=c("yr_id","geozone","geotype"))
#change column names
setnames(mi_24,old=c("median_inc","households"),new=c("median_inc_24","households_24"))
#remove unnecessary objects
rm(mi_reg,mi_jur,mi_cpa,mi_tract,mi_all_24)

#bring in data for id=26
datasource_id=26
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#region median income for ID26
median_income_reg_sql = getSQL("../Queries/median_income_region_ds_id.sql")
median_income_reg_sql <- gsub("ds_id", datasource_id, median_income_reg_sql)
mi_reg<-sqlQuery(channel,median_income_reg_sql,stringsAsFactors = FALSE)
#jurisdiction median income for ID26
median_income_jur_sql = getSQL("../Queries/median_income_jur_ds_id.sql")
median_income_jur_sql <- gsub("ds_id", datasource_id, median_income_jur_sql)
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
#cpa median income for ID26
median_income_cpa_sql = getSQL("../Queries/median_income_cpa_ds_id.sql")
median_income_cpa_sql <- gsub("ds_id", datasource_id, median_income_cpa_sql)
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
#census tract median income for ID26
median_income_tract_sql = getSQL("../Queries/median_income_tract_ds_id.sql")
median_income_tract_sql <- gsub("ds_id", datasource_id, median_income_tract_sql)
mi_tract<-sqlQuery(channel,median_income_tract_sql,stringsAsFactors = FALSE)
#households for ID26 - include for context
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id,hh_sql)
hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
hh$datasource_id = datasource_id

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
mi_tract$geotype <- "tract"

#bind all records
mi_all_26<-rbind(mi_reg,mi_jur,mi_cpa,mi_tract)
mi_26 <- merge(mi_all_26,select(hh,yr_id,geotype,geozone,households),by.x=c("yr_id","geozone","geotype"), by.y=c("yr_id","geozone","geotype"))
#change column names
setnames(mi_26,old=c("median_inc","households"),new=c("median_inc_26","households_26"))
#remove unnecessary objects
rm(mi_reg,mi_jur,mi_cpa,mi_tract,mi_all_26)

#merge two vintages together and review
mi_24_26 <- merge(mi_24,mi_26,by.x=c("yr_id","geozone","geotype"),by.y=c("yr_id","geozone","geotype"),all = TRUE)
head(mi_24_26)

#calculate number and percent difference in median income. 
mi_24_26$median_inc_diff <- mi_24_26$median_inc_26-mi_24_26$median_inc_24
mi_24_26$median_inc_pct_diff <- (mi_24_26$median_inc_diff/mi_24_26$median_inc_24)*100
mi_24_26$median_inc_pct_diff <- round(mi_24_26$median_inc_pct_diff,digits = 2)

#delete out 2017 and 2018 data
mi_24_26 <- subset(mi_24_26, mi_24_26$yr_id<=2016) 
#reorder columns

#add flag variables for change at 5, 10, and 20 percent
mi_24_26$flag5pct[mi_24_26$median_inc_pct_diff>=5.00 | mi_24_26$median_inc_pct_diff<=-5.00] <- 1 
mi_24_26$flag10pct[mi_24_26$median_inc_pct_diff>=10.00 | mi_24_26$median_inc_pct_diff<=-10.00] <- 1 
mi_24_26$flag20pct[mi_24_26$median_inc_pct_diff>=20.00 | mi_24_26$median_inc_pct_diff<=-20.00] <- 1 

head(mi_24_26[mi_24_26$median_inc_pct_diff>=5.00,],10)

mi_24_26 <- select(mi_24_26,yr_id,geotype,geozone,median_inc_24,median_inc_26,median_inc_diff,median_inc_pct_diff,
                   households_24,households_26,flag5pct,flag10pct,flag20pct)
mi_24_26 <- mi_24_26[order(mi_24_26$geozone,mi_24_26$geotype,mi_24_26$yr_id),]

head(mi_24_26)

mi_24_26_reg <- subset(mi_24_26, mi_24_26$geotype=="region")
mi_24_26_jur <- subset(mi_24_26, mi_24_26$geotype=="jurisdiction")
mi_24_26_tract <- subset(mi_24_26, mi_24_26$geotype=="tract")

head(mi_24_26_tract[mi_24_26_tract$median_inc_pct_diff>=5.00,],10)

table(mi_24_26_reg$flag5pct)
table(mi_24_26_jur$flag5pct)
table(mi_24_26_tract$flag5pct)

unique(mi_24_26_jur$geozone[mi_24_26_jur$flag10pct==1])
unique(mi_24_26_tract$geozone[mi_24_26_tract$flag10pct==1])

table(mi_24_26_jur$flag5pct)
table(mi_24_26_tract$flag5pc)

write.csv(mi_24_26_reg,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\median income\\median income ID24 to ID26 reg .csv", row.names = FALSE)
write.csv(mi_24_26_jur,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\median income\\median income ID24 to ID26 jur.csv", row.names = FALSE)
write.csv(mi_24_26_tract,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\median income\\median income ID24 to ID26 tract.csv", row.names = FALSE)

rm(mi_24_26,mi_24_26_reg,mi_24_26_jur,mi_24_26_tract,mi_24)
##################
##################
#within vintage median income comparison
##################
##################

head(mi_26,12)

#calculate year over year change
hhinc <- hhinc[order(hhinc$geozone, hhinc$income_id2 ,hhinc$yr_id),]
hhinc$hhinc_nchg <- hhinc$hhinc_prop - lag(hhinc$hhinc_prop)

#set 2010 number and pct change to NA - there is no previous year to calculate change
hhinc$hhinc_nchg[hhinc$yr_id==2010] <- NA
#hhinc$hhinc_npct[hhinc$yr_id==2010] <- NA 

hhinc <- hhinc[order(hhinc$geozone,hhinc$yr_id, hhinc$income_id2),]
setnames(hhinc, old="name2", new="income_cat")

#subset hhinc file for jurisdiction and region
hhinc_jur <- subset(hhinc, hhinc$geotype=="jurisdiction")
hhinc_reg <- subset(hhinc, hhinc$geotype=="region")
tail(hhinc[hhinc$geotype=="jurisdiction",],10)


rm(hhinc_24_26, hhinc_24_26_jur,hhinc_24_26_reg,hhinc_sql,hhtot,hhtot_24)

