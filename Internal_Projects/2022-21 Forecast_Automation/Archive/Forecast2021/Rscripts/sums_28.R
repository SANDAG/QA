#Forecast
#check internal integrity of variables

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC","reshape2", 
              "stringr","tidyverse")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")


getwd()
options(stringsAsFactors=FALSE)

ds_id=28

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh<-sqlQuery(channel,hh_sql)
gq_sql = getSQL("../Queries/group_quarter.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq<-sqlQuery(channel,gq_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop<-sqlQuery(channel,totpop_sql)
odbcClose(channel)

head(hh)

#aggregate gq pop only - exclude hh pop
gq <-aggregate(pop~yr_id + geozone + geotype, subset(gq, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq, old="pop", new="gqpop")

hh <- merge(gq, hh, by.x=c("yr_id","geotype","geozone"), by.y=c("yr_id","geotype","geozone"), all=TRUE)
hh <- merge(totpop, hh, by.x=c("yr_id","geotype","geozone"), by.y=c("yr_id","geotype","geozone"), all=TRUE)

hh_sums <- hh %>%
select(yr_id, geotype,pop,gqpop,households,units,hhp) %>%
group_by(geotype,yr_id) %>%
summarise(pop_tot = sum(pop,na.rm=TRUE),gq_tot = sum(gqpop,na.rm=TRUE),hhp_tot = sum(hhp,na.rm=TRUE),hh_tot = sum(households,na.rm=TRUE),hu_tot = sum(units,na.rm=TRUE))

hh_sums <- melt(hh_sums, id.vars = c("yr_id","geotype"),variable.name = "var_name",value.name = "sum_totals" )
hh_sums <- dcast(hh_sums,yr_id+var_name~geotype,value.var = "sum_totals")

#create a column to confirm that all sums by geography match
hh_sums$pass <- all(sapply(select(hh_sums,region,jurisdiction,cpa,tract), identical, select(hh_sums,region,jurisdiction,cpa,tract)[,1]))

#confirm all totals are equivalent, that is all values are TRUE
table(hh_sums$pass)

head(totpop[totpop$geotype=="region",],10)

table(totpop$geotype)

write.csv(hh_sums, "M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\internal integrity\\pop_hh_sums.csv",row.names = FALSE)
