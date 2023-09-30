# vacancy rate

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}
# "summarytools"
packages <- c("RODBC","tidyverse")
pkgTest(packages)

# get data from database
source("../Queries/readSQL.R")

datasource_ids = c(28)

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

vacancy <- data.frame()
sourcename <- data.frame()
plotsource <- ''

for(ds_id in datasource_ids) {
  # datasource name
  ds_sql = getSQL("../Queries/datasource_name.sql")
  ds_sql <- gsub("ds_id", ds_id,ds_sql)
  datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  sourcename <- rbind(sourcename,datasource_name)
  
  # get vacancy
  Vacancy_sql = getSQL("../Queries/vacancy_ds_id.sql")
  Vacancy_sql <- gsub("ds_id", ds_id,Vacancy_sql)
  vac<-sqlQuery(channel,Vacancy_sql,stringsAsFactors = FALSE)
  vac$datasource_id = ds_id
  vacancy <- rbind(vacancy,vac)
  
  plotsource <- paste(plotsource,ds_id,sep=' ')
  
}

# get cpa id
geo_id_sql = getSQL("../Queries/get_cpa_and_jurisdiction_id.sql")
geo_id<-sqlQuery(channel,geo_id_sql,stringsAsFactors = FALSE)

odbcClose(channel)

# merge vacancy with datasource name
vacancy <- merge(x = vacancy, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)

# cleanup
rm(vac,datasource_name,sourcename)

###############################
# fix name of region: add "Region" to "San Diego"
# since city of San Diego and San Diego region are both named San Diego
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "~San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- '~San Diego Region'

# merge vacancy with jurisdiction and cpa id
# note: must be after change San Diego to San Diego Region 
#       otherwise region will be considered city of San Diego
geo_id <- subset(geo_id,id != 1493) # database error, see note
vacancy <- merge(x = vacancy, y =geo_id,by = "geozone", all.x = TRUE)
# add dummy id for region
vacancy$id[vacancy$geozone=="~San Diego Region"] <- 9999

#############################################################
# NOTE 
# had to remove CPA id for via de la valle 1493
# SELECT * 
#   FROM [demographic_warehouse].[dim].[mgra_denormalize]
# WHERE cpa = 'Via De La Valle' and series = 14 and cpa_id = 1493
# SELECT * 
#   FROM [demographic_warehouse].[dim].[mgra_denormalize]
# WHERE mgra_id = 1401333804
# SELECT * 
#   FROM [demographic_warehouse].[dim].[mgra_denormalize]
# WHERE cpa_id = 1493
# find any double counted rows
# t <- vacancy %>% group_by(geozone) %>% tally()
# subset(t,n>8)
# subset(vacancy,geozone=='Via De La Valle')
##############################################################

# remove characters  '*', '-', ':' from names
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)

#calculate the effective vacancy rate subtracting out unoccupiable units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 

vacancy$pc_vacancy_rate <- vacancy$vacancy_rate * 100

# region_vacancy for merge
region_vacancy <- subset(vacancy,geozone=='~San Diego Region')
reg <- region_vacancy[,c('yr_id','pc_vacancy_rate','geozone','id')]

# QC TEST
###############################################################
# check if crosses region line

crosses_region_test <- function(df,region,l) {
  qcfail<-c()
  for(i in 1:length(l)) {
    dat = subset(df, df$geozone==l[i])
    geo <-  dat[,c('yr_id','pc_vacancy_rate','geozone','id')]
    vac <- merge(x=geo, y=region, by = "yr_id", all.x = TRUE, suffixes=c('.geo','.reg'))
    vac$difference <- vac$pc_vacancy_rate.reg - vac$pc_vacancy_rate.geo
    if (sum(vac$difference<0) > 0 & sum(vac$difference<0) < 8) {
      qcfail<-c(qcfail,vac$geozone.geo[1])
    }
  }
  return(qcfail)
}

# jurisdictions
jur_list = unique(subset(vacancy, geotype=="jurisdiction")[["geozone"]])
qcfail_jur <- crosses_region_test(vacancy,reg,jur_list)

# cpas
cpa_list = unique(subset(vacancy, geotype=="cpa")[["geozone"]])
qcfail_cpa <- crosses_region_test(vacancy,reg,cpa_list)

# failures for cpa and jurisdiction
failures <- c(qcfail_jur,qcfail_cpa)
crosses_region <- subset(vacancy,geozone %in% failures)

# clean up dataframe
crosses_region$vacancy_rate_effective <- NULL
crosses_region$name <- NULL
crosses_region$vacancy_rate <- NULL

#rename region percent vacancy rate
reg <- reg %>% rename(region_vac = pc_vacancy_rate) 

# merge with region
crosses_region <- merge(x=crosses_region, y=reg[ , c("yr_id","region_vac")], by = "yr_id", all.x = TRUE)

# calculate difference from region
crosses_region$vac_region_diff <- crosses_region$region_vac - crosses_region$pc_vacancy_rate

# sort dataframe
crosses_region <-crosses_region[order(crosses_region$id,crosses_region$yr_id),]
write.csv(crosses_region,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\vacancy_crosses_region.csv",row.names = FALSE)

#qc_fail_geos <- data.frame(failures)
qc_fail_geos <- subset(crosses_region,yr_id==2018)[,c('geozone','geotype')]

names(qc_fail_geos) <- c('vacany_rate_crosses_region','geotype')
write.csv(qc_fail_geos,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\list_of_geographies_where_vacancy_crosses_region.csv",row.names = FALSE)


qc_fail_geos <- subset(crosses_region,yr_id==2018)[,c('geozone')]

# names(qc_fail_geos) <- c('vacany_rate_crosses_region','geotype')
write.csv(qc_fail_geos,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\list_of_geographies_where_vacancy_crosses_region2.csv",row.names = FALSE)


