
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

options(stringsAsFactors=FALSE)

#bring data in from SQL
channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
gq_sql = getSQL("../Queries/group_quarter.sql")
gq<-sqlQuery(channel,gq_sql)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(gq, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\gq_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

head(gq)


gq<-subset(gq, short_name!="hh")

#gq<-dcast(gq_long, yr_id+geotype+geozone~short_name, value.var = "pop")

head(gq)

gq$yr<- "y"
gq$yr <- as.factor(paste(gq$yr, gq$yr_id, sep = ""))
gq$geozone[gq$geotype=="region"]<- "San Diego Region"

class(gq$geozone)


gq_jur = subset(gq,geotype=='jurisdiction')
gq_cpa = subset(gq,geotype=='cpa')
gq_region = subset(gq,geotype=='region')


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\group quarter\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


tail(gq_region)

##Jurisdiction plots and tables

jur_list=unique(gq_jur[["geozone"]])

#create a copy of the data frame for the output table
gq_wide<-data.frame(gq_jur)
gq_wide$reg<-gq_region[match(paste(gq_jur$yr_id, gq_jur$housing_type_id), paste(gq_region$yr_id, gq_region$housing_type_id)),6]

write.csv(gq_jur, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\GQ\\gq_jur19.csv")
write.csv(gq_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\GQ\\gq_cpa19.csv")
write.csv(gq_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\GQ\\gq_region19.csv")

