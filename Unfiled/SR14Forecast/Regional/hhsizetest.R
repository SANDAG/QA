
#Katie's script for household size comparison test

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

#Sort data within columns by ascending order 
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]

#Calculate change in number of households, householdpop, and householdsize
#hh$hh_numchg<- (hh$households)-lag(hh$households)
#hh$hhp_numchg<- (hh$hhp)-lag(hh$hhp)
#hh$hhs_numchg<- (hh$hhs)-lag(hh$hhs)
#hh$hh_numchg[hh$yr_id=="2016"]<-0
#hh$hhp_numchg[hh$yr_id=="2016"]<-0
#hh$hhs_numchg[hh$yr_id=="2016"]<-0

#Calculate percent change from of households, householdpop, and householdsize (I reordered columns so hhp is first)
hh$hhp_pctchg<- (hh$hhp-lag(hh$hhp))/lag(hh$hhp)*100
hh$hh_pctchg<- (hh$households-lag(hh$households))/lag(hh$households)*100
hh$hhs_pctchg<- (hh$hhs-lag(hh$hhs))/lag(hh$hhs)*100
#Rounding
hh$hh_pctchg<-round(hh$hh_pctchg,digits=2)
hh$hhp_pctchg<-round(hh$hhp_pctchg,digits=2)
hh$hhs_pctchg<-round(hh$hhs_pctchg,digits=2)
#Reorder columns so hhp is first
hh <- hh[c(1,2,3,5,4,6,7,8,9)]
hh


hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

#Create character vector based on condition hhpop is neg. or zero
toMatch <- unique(hh$geozone[which(hh$hhp_pctchg <= 0)])
toMatch

#Create new dataframe by filtering cpas/jurs that match "toMatch" vector
result <- filter(hh, grepl(paste(toMatch, collapse="|"), geozone))
result


#Write result into csv
write.csv(result,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\hhsize_test.csv"))






