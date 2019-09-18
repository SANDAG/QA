#calculate housing units added from 2016 to 2035 and 2036 to 2050
#results can be compared to Board approved capacity numbers from May 25, 2018.


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}


packages <- c("data.table","sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr")
       
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

maindir = dirname(rstudioapi::getSourceEditorContext()$path)

source("../Queries/readSQL.R")


datasource_id = 30

hh <- data.frame()
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id,hh_sql)
hhquery<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
hhquery$datasource_id = datasource_id
hh <- rbind(hh,hhquery)
odbcClose(channel)


hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

hh$datasource_id = factor( hh$datasource_id) 

# exclude cpa records and unneeded years
hh<-subset(hh, geotype!="cpa")
hh <- subset(hh, yr_id=="2016" | yr_id=="2035"| yr_id=="2050")
hh$yr_id <- paste("y",hh$yr_id,sep = "")

head(hh)

hh_wide <- dcast(hh, geozone~yr_id, value.var = "units"  )


head(hh_wide)

hh_wide$diff16_35 <- hh_wide$y2035-hh_wide$y2016
hh_wide$diff35_50 <- hh_wide$y2050-hh_wide$y2035
hh_wide$diff16_50 <- hh_wide$y2050-hh_wide$y2016



