


#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')


## retrieve data from database
hh<-readDB("../xpef_queries/xpef_households.sql",0)
pop<-readDB("../xpef_queries/xpef_population.sql",0)
