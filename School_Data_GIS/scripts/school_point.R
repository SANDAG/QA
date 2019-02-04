#school data checks


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
source("../queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8;trusted_connection=true')
schoolpt_sql = getSQL("../queries/school_point.sql")
schoolpt<-sqlQuery(channel,schoolpt_sql)
odbcClose(channel)

getwd()
warnings()


warnings()


,[schoolID]
,[cdsCode]
,[district]
,[name]
,[addr]
,[city]
,[zip]
,[openDate]
,[charter]
,[docType]
,[socType]
,[gsOffered]
,[shrtName]
,[priv]
,[ClosedDate]
,[Phantom]
,[Notes]
,[Shape]
,[Check_]
,[regionID]