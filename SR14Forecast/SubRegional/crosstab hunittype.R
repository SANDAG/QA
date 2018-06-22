#can you understand columns

install.packages("gmodels")


library(scales)
library(sqldf)
library(rstudioapi)
library(RODBC)
library(dplyr)
library(reshape2)
library(ggplot2)
library(data.table)
library(stringr)
library(gmodels)
#library(wesanderson)
#library(RColorBrewer)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read in files

#gq units
hunittype<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\HH_unittype.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

head(hunittype)

hunit_ct<-CrossTable(hunittype$unittype, hunittype$jcpa) 

write.csv(hunit_ct,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\hunit_ct.csv" )
