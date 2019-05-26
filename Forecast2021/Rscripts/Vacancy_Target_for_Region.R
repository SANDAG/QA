# vacancy rate for the region
# 
# compare effective vacancy (subtract out unoccupiable units)
# to region target of 4%

# "agenda item 18-06-1B from the Board dated June 22, 2018.
# In the summary of the discussion and actions from May 25, 2018 
# it says the Board agreed to 4% vacancy rate for forecast" 


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
  
}

odbcClose(channel)

# merge vacancy with datasource name
vacancy <- merge(x = vacancy, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)

# cleanup
rm(vac,datasource_name,sourcename)

# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region'
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'

# just the region
vacancy <- subset(vacancy,geozone=='San Diego Region')

#calculate the effective vacancy rate subtracting out unoccupiable units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 
vacancy$region_target_vacancy <- .04 # target for the region based on board report

vacancy$difference <- vacancy$vacancy_rate_effective - vacancy$region_target_vacancy
vacancy$pass <-  TRUE
vacancy$pass[vacancy$difference < 0] <-FALSE
vacancy$difference <- NULL

# reorder columns
vacancy <-  vacancy[,c(1,9,2,3,4,5,6,7,8,10,11,12)]

write.csv(vacancy,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\region_vacancy.csv",row.names = FALSE)

