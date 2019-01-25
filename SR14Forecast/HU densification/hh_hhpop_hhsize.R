#HU densification forecast checks
#created 1/18/2018 


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
       
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

maindir = dirname(rstudioapi::getSourceEditorContext()$path)

source("../Queries/readSQL.R")
datasource_ids = c(17,19)

hh_all <- data.frame()

for(ds_id in datasource_ids) {
  channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
  hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
  hh_sql <- gsub("ds_id", ds_id,hh_sql)
  hhquery<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
  hhquery$datasource_id = ds_id
  hh_all <- rbind(hh_all,hhquery)
  odbcClose(channel)
}

hh_all$geozone[hh_all$geotype =="region"]<- "Region"
hh_all$geozone <- gsub("\\*","",hh_all$geozone)
hh_all$geozone <- gsub("\\-","_",hh_all$geozone)
hh_all$geozone <- gsub("\\:","_",hh_all$geozone)

colnames(hh_all)[colnames(hh_all)=="yr_id"] <- "year"


############
#hh data
############

hh <- dcast(hh_all, year + geotype + geozone ~ datasource_id, value.var="households")

setnames(hh, old=c("17", "19"),new=c("hh_17", "hh_19"))

#where hh_diff!=0 and denominator=0 pct_chg="-Inf"; Where hh_diff=0 and denominator=0 pct_chg="NaN" 
hh$hh_diff<-hh$hh_19-hh$hh_17
hh$hh_pct_chg<-(hh$hh_diff/hh$hh_19)*100
hh$hh_pct_chg[hh$hh_pct_chg=="NaN"]<-NA
hh$hh_pct_chg[hh$hh_pct_chg=="-Inf"]<-NA
hh$hh_pct_chg<-round(hh$hh_pct_chg,digits=2)

hh$hh_chg_gt5[hh$hh_pct_chg>5]<-1

hh <- hh[order(hh$geozone, hh$geotype, hh$year),]

hh_change<-subset(hh, hh_diff!=0)
hh_gth_5<-subset(hh, hh_chg_gt5==1)

hh_gth_5<-unique(hh_gth_5[, c(3,8)])

nrow(hh_gth_5)


############
#hhp data
############

hhp <- dcast(hh_all, year + geotype + geozone ~ datasource_id, value.var="hhp")

setnames(hhp, old=c("17", "19"),new=c("hhp_17", "hhp_19"))

hhp$hhp_diff<-hhp$hhp_19-hhp$hhp_17
hhp$hhp_pct_chg<-(hhp$hhp_diff/hhp$hhp_19)*100
hhp$hhp_pct_chg[hhp$hhp_pct_chg=="NaN"]<-NA
hhp$hhp_pct_chg[hhp$hhp_pct_chg=="-Inf"]<-NA
hhp$hhp_pct_chg<-round(hhp$hhp_pct_chg,digits=2)

hhp$hhp_chg_gt5[hhp$hhp_pct_chg>5]<-1

hhp <- hhp[order(hhp$geozone, hhp$geotype, hhp$year),]

hhp_change<-subset(hhp, hhp_diff!=0)
hhp_gth_5<-subset(hhp, hhp_chg_gt5==1)

hhp_gth_5<-unique(hhp_gth_5[, c(3,8)])

nrow(hhp_gth_5)

############
#hhs data
############

hhs <- dcast(hh_all, year + geotype + geozone ~ datasource_id, value.var="hhs")

setnames(hhs, old=c("17", "19"),new=c("hhs_17", "hhs_19"))

hhs$hhs_diff<-hhs$hhs_19-hhs$hhs_17
hhs$hhs_pct_chg<-(hhs$hhs_diff/hhs$hhs_19)*100
hhs$hhs_pct_chg[hhs$hhs_pct_chg=="NaN"]<-NA
hhs$hhs_pct_chg[hhs$hhs_pct_chg=="-Inf"]<-NA
hhs$hhs_pct_chg<-round(hhs$hhs_pct_chg,digits=2)

hhs$hhs_chg_gt5[hhs$hhs_pct_chg>5]<-1

hhs <- hhs[order(hhs$geozone, hhs$geotype, hhs$year),]

hhs_change<-subset(hhs, hhs_diff!=0)
hhs_gth_5<-subset(hhs, hhs_chg_gt5==1)

hhs_gth_5<-unique(hhs_gth_5[, c(3,8)])

nrow(hhs_gth_5)


hh_total<-cbind(hh, hhp, hhs)

hhtot <- merge(hh, hhp, by.x=c("year", "geotype", "geozone"), by.y=c("year", "geotype", "geozone"), all=TRUE)
hhtot <- merge(hhtot, hhs, by.x=c("year", "geotype", "geozone"), by.y=c("year", "geotype", "geozone"), all=TRUE)

write.csv(hhtot, "M:\\Technical Services\\QA Documents\\Projects\\LU Densification\\results\\hhtot.csv")
