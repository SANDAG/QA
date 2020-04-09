#job by industry
##revise save out location as needed


datasource_id=35

#load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2")
pkgTest(packages)

#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#necessary code for running SQL scripts in R
source("../Queries/readSQL.R")


#channel set to SQL database access the query and pull the specific data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

jobs_cpa_sql = getSQL("../Queries/jobs_cpa_PowerBI.sql")
jobs_cpa_sql <- gsub("ds_id", datasource_id, jobs_cpa_sql)
jobs_cpa<-sqlQuery(channel,jobs_cpa_sql)

jobs_jur_sql = getSQL("../Queries/jobs_jur_PowerBI.sql")
jobs_jur_sql <- gsub("ds_id", datasource_id, jobs_jur_sql)
jobs_jur<-sqlQuery(channel,jobs_jur_sql)

jobs_reg_sql = getSQL("../Queries/jobs_region_PowerBI.sql")
jobs_reg_sql <- gsub("ds_id", datasource_id, jobs_reg_sql)
jobs_reg<-sqlQuery(channel,jobs_reg_sql)

odbcClose(channel)

#save out files

https://sandag.sharepoint.com/:f:/r/qaqc/Shared%20Documents/Forecast/Results/ID%2035?csf=1&web=1&e=Irmd0Z

write.csv(jobs_cpa, paste("C:\\Users\\lho\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID ",datasource_id,"\\Results\\jobs_cpa.csv",sep=""))

write.csv(jobs_jur, paste("C:\\Users\\lho\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID ",datasource_id,"\\Results\\jobs_jur.csv",sep=""))

write.csv(jobs_reg, paste("C:\\Users\\lho\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID ",datasource_id,"\\Results\\jobs_region.csv",sep=""))

"C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Estimates\\ds_id=33\\Results\\file_name.csv"
