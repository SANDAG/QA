#Traditional Vacancy Rate by type and aggregated
#no comparison to SR13 because difference in coding - in SR13 there were 3 categories and in SR14 there are 4 - sf is broken into two (sfa and sfd)

###############
#Fix query ds_id statement
#add diff and percent change column
###############
##############
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
#########################
####################



pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  }
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2","lubridate", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#bring data in from SQL
datasource_ids = c(17,19)

vacancy <- data.frame()

for(ds_id in datasource_ids) {
  channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
  Vacancy_sql = getSQL("../Queries/HU_densification/Vacancy_ds_id.sql")
  vac_query<-sqlQuery(channel,Vacancy_sql)
  vac_query$datasource_id = ds_id
  vacancy <- rbind(vacancy,vac_query)
  odbcClose(channel)
}

# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)

#calculate the vacancy rate - formula does not exclude unoccupiable units
vacancy$available <-(vacancy$units-vacancy$hh)
vacancy$rate <-(vacancy$available/vacancy$units)*100
vacancy$rate <-round(vacancy$rate,digits=2)

head(vacancy)

#delete the following columns
vacancy$structure_type_id<-NULL
vacancy$vac<-NULL
vacancy$available<-NULL

#reshape from long to wide
vacancy_by_type<-reshape(vacancy,
        idvar = c("yr_id", "geotype", "geozone","datasource_id"),
        timevar = "short_name",
        direction = "wide")

vacancy_by_type<-reshape(vacancy_by_type,
                      idvar = c("yr_id", "geotype", "geozone"),
                      timevar = "datasource_id",
                      direction = "wide")
                      

tail(vacancy_by_type, 5)

#This aggregates from type of units
vacancy_agg<- aggregate(cbind(hh, units)~ yr_id + geotype + geozone + datasource_id, data=vacancy, sum)

#calculate the vacancy rate - formula does not exclude unoccupiable units
vacancy_agg$available <-(vacancy_agg$units-vacancy_agg$hh)
vacancy_agg$rate <-(vacancy_agg$available/vacancy_agg$units)*100
vacancy_agg$rate <-round(vacancy_agg$rate,digits=2)

head(vacancy_agg, 15)

#delete the following columns
vacancy_agg$available<-NULL

vacancy_agg<-reshape(vacancy_agg,
        idvar = c("yr_id", "geotype", "geozone"),
        timevar = "datasource_id",
        direction = "wide")

head(vacancy_agg, 15)

vacancy_agg$rate_diff<-vacancy_agg$rate.19-vacancy_agg$rate.17
summary(vacancy_agg$rate_diff)
vacancy_agg$hh_diff<-vacancy_agg$hh.19-vacancy_agg$hh.17
summary(vacancy_agg$hh_diff)
