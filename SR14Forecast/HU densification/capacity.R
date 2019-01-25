#capacity for HU densification

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

channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=urbansim; trusted_connection=true')
cap17_sql = getSQL("../Queries/HU_densification/capacity_id17.sql")
cap17<-sqlQuery(channel,cap17_sql)
cap19_sql = getSQL("../Queries/HU_densification/capacity_id19.sql")
cap19<-sqlQuery(channel,cap19_sql)
odbcClose(channel)


cap17$ID<-NULL
cap19$ID<-NULL
cap19$jcpa<-NULL

setnames(cap17, old=c("jur_provided_cap", "additional_cap", "total_cap"), new=c("jur_provided_cap_17", "additional_cap_17", "total_cap_17"))
setnames(cap19, old=c("jur_provided_cap", "additional_cap", "total_cap"), new=c("jur_provided_cap_19", "additional_cap_19", "total_cap_19"))

capacity<-merge(cap17, cap19, by.x="jcpa_name", by.y="jcpa_name",all=TRUE )

capacity$jur_cap_diff<-capacity$jur_provided_cap_19-capacity$jur_provided_cap_17
capacity$add_cap_diff<-capacity$additional_cap_19-capacity$additional_cap_17

#add_diff<-select(capacity,jcpa_name,additional_cap_17,additional_cap_19,add_cap_diff)
#add_diff[add_diff$add_cap_diff!=0,]

write.csv(capacity, "M:\\Technical Services\\QA Documents\\Projects\\LU Densification\\results\\capacity.csv")
