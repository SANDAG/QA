pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)



#save a time stamped verion of the raw file from SQL
write.csv(hh, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\hh_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

head(hh)


#hh_agg<-merge(aggregate(flag~geozone, data = hh, max), hh)

#hh_agg<-aggregate(flag~geozone, data = hh, max)


hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]
hh$hh_numchg<- (hh$households)-lag(hh$households)
hh$hhp_numchg<- (hh$hhp)-lag(hh$hhp)
hh$hhs_numchg<- (hh$hhs)-lag(hh$hhs)
hh$hh_numchg[hh$yr_id=="2016"]<-0
hh$hhp_numchg[hh$yr_id=="2016"]<-0
hh$hhs_numchg[hh$yr_id=="2016"]<-0

hh$hh_pctchg<- (hh$households-lag(hh$households))/lag(hh$households)*100
hh$hhp_pctchg<- (hh$hhp-lag(hh$hhp))/lag(hh$hhp)*100
hh$hhs_pctchg<- (hh$hhs-lag(hh$hhs))/lag(hh$hhs)*100
hh$hh_pctchg<-round(hh$hh_pctchg,digits=2)
hh$hhp_pctchg<-round(hh$hhp_pctchg,digits=2)
hh$hhs_pctchg<-round(hh$hhs_pctchg,digits=2)

hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)


head(hh)


write.csv(hh,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\hh_hhp_hhs with change.csv"))


vac<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\Traditional vacancy_17.csv")
median_age_cpa<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_cpa17.csv")
median_age_jur<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_jur17.csv")
median_age<-rbind(median_age_cpa, median_age_jur)

tail(vac)
vac<- vac[order(vac$geotype,vac$geozone,vac$yr_id),]

vac$vac_numchg<- (vac$rate)-lag(vac$rate)

#vac$vac_numchg[hh$yr_id=="2016"]<-0

vac$vac_pctchg<- (vac$rate-lag(vac$rate))/lag(vac$rate)*100
vac$vac_pctchg<-round(vac$vac_pctchg,digits=2)

vac$units_numchg<- (vac$units)-lag(vac$units)

#vac$vac_numchg[hh$yr_id=="2016"]<-0

vac$units_pctchg<- (vac$units-lag(vac$units)/lag(vac$units))*100
vac$units_pctchg<-round(vac$units_pctchg,digits=2)

setnames(vac, old=c("rate"),new=c("vac_rate"))


vac$geozone[vac$geotype =="region"]<- "Region"
vac$geozone <- gsub("\\*","",vac$geozone)
vac$geozone <- gsub("\\-","_",vac$geozone)
vac$geozone <- gsub("\\:","_",vac$geozone)


#hh$flag_num<-ifelse(hh$hh_numchg<=0|
#                 hh$hhp_numchg<=0|
#                hh$hhs_numchg<=0,1,0)
#hh$flag_pct<-ifelse(hh$hh_pctchg<=0|
#                   hh$hhp_pctchg<=0|
#                  hh$hhs_pctchg<=0,1,0)

hh_merge<-merge(hh, vac, by.x=c("yr_id", "geotype", "geozone"), by.y=c("yr_id", "geotype", "geozone"),all=TRUE)

hh_merge<-merge(hh_merge, median_age, by.x=c("yr_id", "geotype", "geozone"), by.y=c("yr_id", "geotype", "geozone"),all=TRUE)

head(hh_merge)
head(median_age)

colnames(hh_merge)
hh_merge[c("X.x", "hh", "available", "year", "yr", "X.y")]<-list(NULL)
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","unoccupiable","vac_rate","hh_numchg","hhp_numchg","hhs_numchg","hh_pctchg","hhp_pctchg","hhs_pctchg","units_numchg","units_pctchg","vac_numchg","vac_pctchg","median_age")]


hh_merge<- hh_merge[order(hh_merge$geotype,hh_merge$geozone,hh_merge$yr_id),]
write.csv(hh_merge,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 4\\hh_hhp_hhs_hu_vac_age_comparison.csv"))
