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


inc_2020<-read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.3\\input\\2020\\mgra13_based_input2020.csv")

colnames(inc_2020)

median(inc_2020$HINC)


channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
median_income_jur_sql = getSQL("../Queries/median_income_jur.sql")
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
median_income_cpa_sql = getSQL("../Queries/median_income_cpa.sql")
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
median_income_region_sql = getSQL("../Queries/median_income_region.sql")
mi_region<-sqlQuery(channel,median_income_region_sql,stringsAsFactors = FALSE)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(mi_jur, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\mijur_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(mi_cpa, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\micpa_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(mi_region, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\miregion_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

head(mi_region)
#remove unneeded characters from geozone values.
mi_cpa$geozone <- gsub("\\*","",mi_cpa$geozone)
mi_cpa$geozone <- gsub("\\-","_",mi_cpa$geozone)
mi_cpa$geozone <- gsub("\\:","_",mi_cpa$geozone)

mi_jur$reg<-mi_region[match(mi_jur$yr_id, mi_region$yr_id),"median_inc"]
mi_cpa$reg<-mi_region[match(mi_cpa$yr_id, mi_region$yr_id),"median_inc"]

head(mi_region,9)

head(inc_2020)



median(inc_2020$hh)
