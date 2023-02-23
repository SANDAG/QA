#hhinc sum checks

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")


getwd()
options(stringsAsFactors=FALSE)

ds_id=28

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", ds_id,hhinc_sql)
hhinc<-sqlQuery(channel,hhinc_sql)
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

hh$households <- as.numeric(hh$households)

hh_region <- subset(select(hh,yr_id,geotype,households), geotype=="region")

hhinc$hh <- as.numeric(hhinc$hh)

hhinc_sums <- hhinc %>%
  select(yr_id, geotype,hh) %>%
  group_by(geotype,yr_id) %>%
  summarise(hhinc_tot=sum(hh,na.rm = TRUE))

head(hhinc_sums)

hhinc_sums <- melt(hhinc_sums,id.vars=c("yr_id","geotype"),variable.name = "var_name",value.name = "sum_totals") 

hhinc_sums <- dcast(hhinc_sums,yr_id+var_name~geotype,value.var = "sum_totals")

head(hhinc_sums)
head(hh_region)

hhinc_sums$households<- hh_region[match(hhinc_sums$yr_id,hh_region$yr_id),"households"]


#create a column to confirm that all sums by geography match
hhinc_sums$pass <- all(sapply(select(hhinc_sums,region,jurisdiction,cpa,tract,households), identical, select(hhinc_sums,region,jurisdiction,cpa,tract,households)[,1]))

#confirm all totals are equivalent, that is all values are TRUE
table(hhinc_sums$pass)

sapply(hhinc_sums, class)

head(hhinc_sums)



write.csv(hhinc_sums, "M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\internal integrity\\hhinc_sums.csv",row.names = FALSE)
