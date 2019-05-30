#forecast
#sum variables at various geographies


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "reshape2", 
              "stringr","tidyverse")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

getwd()

ds_id=28

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# datasource name
ds_sql = getSQL("../Queries/datasource_name.sql")
ds_sql <- gsub("ds_id", ds_id,ds_sql)
datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)

demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo<-sqlQuery(channel,demo_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop<-sqlQuery(channel,totpop_sql)
odbcClose(channel)

setnames(totpop, old = "pop", new = "totpop")

totpop_region <- subset(totpop, geotype=="region")

table(totpop$geotype)

demo_sums <- demo %>%
  select(yr_id, geotype,age_group_name,short_name,sex,pop) %>%
  group_by(geotype,yr_id) %>%
    summarise(age_tot=sum(pop,na.rm = TRUE),ethn_tot=sum(pop,na.rm = TRUE),gender_tot=sum(pop,na.rm = TRUE))
  
demo_sums <- melt(demo_sums,id.vars=c("yr_id","geotype"),variable.name = "var_name",value.name = "sum_totals") 

demo_sums <- dcast(demo_sums,yr_id+var_name~geotype,value.var = "sum_totals")

head(demo_sums)
head(totpop_region)

demo_sums$totpop_fact_pop <- totpop_region[match(demo_sums$yr_id,totpop_region$yr_id),"totpop"]



#create a column to confirm that all sums by geography match
demo_sums$pass <- all(sapply(select(demo_sums,region,jurisdiction,cpa,tract,totpop_fact_pop), identical, select(demo_sums,region,jurisdiction,cpa,tract,totpop_fact_pop)[,1]))

#confirm all totals are equivalent, that is all values are TRUE
table(demo_sums$pass)


write.csv(demo_sums, "M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\internal integrity\\age_ethn_gender_sums.csv",row.names = FALSE)


