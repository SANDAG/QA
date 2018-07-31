library(scales)
library(sqldf)
library(sas7bdat)
library(rstudioapi)
library(RODBC)
library(dplyr)
library(reshape2)
library(ggplot2)
library(data.table)
library(lubridate)
library(stringr)
library(eeptools)

Raw_DOF_Gender<-read.csv('M:/Technical Services/QA Documents/Projects/Sub Regional Forecast/4_Data Files/Phase 2/RAW DOF Gender and AGE.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

Raw_DOF_Gender$Age.Group<- NULL


Raw_DOF_Gender_MELT <- melt(Raw_DOF_Gender, id=(c("County", "Sex")))

Raw_DOF_Gender_MELT$variable<- substr(Raw_DOF_Gender_MELT$variable, start=2, stop=5)

RAW_GENDER_agg<-aggregate(value~Sex+variable, data=Raw_DOF_Gender_MELT, sum)


Raw_DOF_Gender_Final <- dcast(RAW_GENDER_agg, RAW_GENDER_agg$variable~Sex)

setnames(Raw_DOF_Gender_Final, old = c("RAW_GENDER_agg$variable"), new= c("RAW_YEAR"))



channel <- odbcConnect("r_connection")


isam_HH <-sqlQuery(channel,"SELECT yr
                   ,COUNT(sex) as sex_count_hh
                   ,COUNT(CASE WHEN sex = 'F' THEN sex  END) as female_hh
                   ,COUNT(CASE WHEN sex = 'M' THEN sex  END) as male_HH
                   ,COUNT(sex) - (COUNT(CASE WHEN sex = 'F' THEN sex  END) + COUNT(CASE WHEN sex = 'M' THEN sex  END)) as diff
                   FROM isam.xpef02.household_population
                   GROUP BY yr 
                   ORDER BY yr DESC, sex_count_hh DESC")


isam_GQ <-sqlQuery(channel,"SELECT yr
                   ,COUNT(sex) as sex_count_gq
                   ,COUNT(CASE WHEN sex = 'F' THEN sex  END) as female_gq
                   ,COUNT(CASE WHEN sex = 'M' THEN sex  END) as male_gq
                   ,COUNT(sex) - (COUNT(CASE WHEN sex = 'F' THEN sex  END) + COUNT(CASE WHEN sex = 'M' THEN sex  END)) as diff_gq
                   FROM isam.xpef02.gq_population
                   GROUP BY yr 
                   ORDER BY yr DESC, sex_count_gq DESC")

isam_tot_gender <- merge(isam_HH, isam_GQ, by.a="yr", by.b="yr", all=TRUE)

isam_tot_gender$isam_tot_pop<-isam_tot_gender$sex_count_hh+isam_tot_gender$sex_count_gq

colnames(isam_tot_gender)
isam_tot_gender$female_tot<- isam_tot_gender$female_hh + isam_tot_gender$female_gq
isam_tot_gender$male_tot<- isam_tot_gender$male_HH + isam_tot_gender$male_gq

Raw_DOF_Gender_Final$RAW_YEAR <- as.numeric(Raw_DOF_Gender_Final$RAW_YEAR)
setnames(Raw_DOF_Gender_Final, old=c("RAW_YEAR"), new=c("yr"))

  
Gender_Comparison<- merge(Raw_DOF_Gender_Final, isam_tot_gender, by.a="yr", by.b="yr" )

Gender_Comparison$sex_count_hh <- NULL
Gender_Comparison$sex_count_gq <- NULL
Gender_Comparison$female_gq <- NULL
Gender_Comparison$male_gq <- NULL
Gender_Comparison$female_hh <- NULL
Gender_Comparison$male_HH <- NULL
Gender_Comparison$diff <- NULL
Gender_Comparison$diff_gq <- NULL


Gender_Comparison$raw_tot_pop <- Gender_Comparison$FEMALE + Gender_Comparison$MALE
Gender_Comparison$female_comp<- Gender_Comparison$female_tot - Gender_Comparison$FEMALE
Gender_Comparison$male_comp<- Gender_Comparison$male_tot - Gender_Comparison$MALE
Gender_Comparison$TOTAL_Comp<- Gender_Comparison$isam_tot_pop - Gender_Comparison$raw_tot_pop
  
  
write.csv(Gender_Comparison,"M:\\Technical Services\\QA Documents\\Projects\\Regionwide Forecast\\Results\\Gender_Comparison.csv")






  