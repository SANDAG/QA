
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
vacancy = getSQL("../Queries/vacancy.sql")
vacancy<-sqlQuery(channel,vacancy)
odbcClose(channel)


# unique(hh[["geozone"]])
# note city of san diego and san diego region are both named san diego
# this causes problems with the aggregation
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'
sd = subset(vacancy,geozone=='San Diego')
sd2 = subset(vacancy,geozone=='San Diego Region')
#write.csv(sd,'cityofsandiego.csv')
#write.csv(sd2,'regionofsandiego.csv')

head(vacancy)

Geo_totals<-aggregate(vac~yr_id+geozone, data=vacancy, mean)
vacancy$tot_pop<-Geo_totals[match(paste(vacancy$yr_id, vacancy$geozone),paste(Geo_totals$yr_id, Geo_totals$geozone)),3]
vacancy$tot_pop[vacancy$tot_pop==0] <- NA
vacancy$percent_income = vacancy$hh/vacancy$tot_pop * 100
#write.csv(Geo_totals,'geototals.csv')

