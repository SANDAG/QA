#HH income estimate script
#started 3/14/2019
#ADD up each column by tract and see if totals match region


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")


getwd()
options(stringsAsFactors=FALSE)

ds_id=24

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", ds_id,hhinc_sql)
hhinc_24<-sqlQuery(channel,hhinc_sql)
odbcClose(channel)

ds_id=26

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", ds_id,hhinc_sql)
hhinc<-sqlQuery(channel,hhinc_sql)
odbcClose(channel)

head(hhinc)

head(hhinc_24)

table(hhinc$income_group_id)

#hhinc recode to fewer categories
#hhinc ID24 data
hhinc_24$income_id2 <-ifelse(hhinc_24$income_group_id>=11 & hhinc_24$income_group_id<=12, '1',
                       ifelse(hhinc_24$income_group_id>=13 & hhinc_24$income_group_id<=14, '2',
                              ifelse(hhinc_24$income_group_id>=15 & hhinc_24$income_group_id<=16, '3',
                                     ifelse(hhinc_24$income_group_id>=17 & hhinc_24$income_group_id<=18, '4',
                                            ifelse(hhinc_24$income_group_id>=19 & hhinc_24$income_group_id<=20, '5', NA)))))


hhinc_24$name2[hhinc_24$income_id2=="1"]<- "Less than $30,000"
hhinc_24$name2[hhinc_24$income_id2=="2"]<- "$30,000 to $59,999"
hhinc_24$name2[hhinc_24$income_id2=="3"]<- "$60,000 to $99,999"
hhinc_24$name2[hhinc_24$income_id2=="4"]<- "$100,000 to $149,999"
hhinc_24$name2[hhinc_24$income_id2=="5"]<- "$150,000 or more"

head(hhinc_24)

hhinc_24 <- aggregate(hh~yr_id + geotype + geozone + name2 + income_id2, data=hhinc_24, sum)
hhtot_24 <- aggregate(hh~yr_id + geotype + geozone, data=hhinc_24, sum)
hhinc_24$hhtot_24 <- hhtot_24[match(paste(hhinc_24$yr_id,hhinc_24$geozone),paste(hhtot_24$yr_id,hhtot_24$geozone)),"hh"] 
hhinc_24$hhinc_prop_24 <- (hhinc_24$hh/hhinc_24$hhtot_24)* 100
hhinc_24$hhinc_prop_24 <- round(hhinc_24$hhinc_prop_24,digits = 2 )
setnames(hhinc_24, old=c("hh"), new=c("hh_24"))

#hhinc ID26 data
#hhinc recode to fewer categories
hhinc$income_id2 <-ifelse(hhinc$income_group_id>=11 & hhinc$income_group_id<=12, '1',
                             ifelse(hhinc$income_group_id>=13 & hhinc$income_group_id<=14, '2',
                                    ifelse(hhinc$income_group_id>=15 & hhinc$income_group_id<=16, '3',
                                           ifelse(hhinc$income_group_id>=17 & hhinc$income_group_id<=18, '4',
                                                  ifelse(hhinc$income_group_id>=19 & hhinc$income_group_id<=20, '5', NA)))))


hhinc$name2[hhinc$income_id2=="1"]<- "Less than $30,000"
hhinc$name2[hhinc$income_id2=="2"]<- "$30,000 to $59,999"
hhinc$name2[hhinc$income_id2=="3"]<- "$60,000 to $99,999"
hhinc$name2[hhinc$income_id2=="4"]<- "$100,000 to $149,999"
hhinc$name2[hhinc$income_id2=="5"]<- "$150,000 or more"

tail(hhinc)

hhinc <- aggregate(hh~yr_id + geotype + geozone + name2 + income_id2, data=hhinc, sum)
hhtot <- aggregate(hh~yr_id + geotype + geozone, data=hhinc, sum)
hhinc$hhtot <- hhtot[match(paste(hhinc$yr_id,hhinc$geozone),paste(hhtot$yr_id,hhtot$geozone)),"hh"] 
hhinc$hhinc_prop <- (hhinc$hh/hhinc$hhtot)* 100
hhinc$hhinc_prop <- round(hhinc$hhinc_prop,digits = 2 )

head(hhinc)


#clean up geozone for merge
hhinc$geozone <- gsub("\\*","",hhinc$geozone)
hhinc$geozone <- gsub("\\-","_",hhinc$geozone)
hhinc$geozone <- gsub("\\:","_",hhinc$geozone)
hhinc$geozone <- gsub("^\\s+|\\s+$", "", hhinc$geozone)

hhinc_24$geozone <- gsub("\\*","",hhinc_24$geozone)
hhinc_24$geozone <- gsub("\\-","_",hhinc_24$geozone)
hhinc_24$geozone <- gsub("\\:","_",hhinc_24$geozone)
hhinc_24$geozone <- gsub("^\\s+|\\s+$", "", hhinc_24$geozone)


head(hhinc)
table(hhinc$income_id2)


head(hhinc_24)
table(hhinc_24$income_id2)

#change integer to numeric type
hhinc_24$hh_24 <- as.numeric(hhinc_24$hh_24)
hhinc_24$hhtot_24 <- as.numeric(hhinc_24$hhtot_24)
hhinc$hh <- as.numeric(hhinc$hh)
hhinc$hhtot <- as.numeric(hhinc$hhtot)

#rename region for clarity in output
hhinc$geozone[hhinc$geotype=='region'] <- 'San Diego Region'
hhinc_24$geozone[hhinc_24$geotype=='region'] <- 'San Diego Region'

hhinc_24_26 <- merge(hhinc_24, hhinc, by.x = c("yr_id","geotype","geozone","income_id2","name2"), by.y = c("yr_id","geotype","geozone","income_id2","name2"), all=TRUE)

head(hhinc_24_26,15)

#review records that aren't 2010 to make sure pop looks good
head(subset(hhinc_24_26, hhinc_24_26$geotype=="jurisdiction" & hhinc_24_26$yr_id!=2010),15)

#confirm expected records are in dataframe
table(hhinc_24_26$yr_id)
table(hhinc_24_26$geotype)

#calculate number change
hhinc_24_26$hhinc_diff <- hhinc_24_26$hhinc_prop-hhinc_24_26$hhinc_prop_24
#hhinc_24_26$hhinc_diff[hhinc_24_26$yr_id==2010] <- NA

hhinc_24_26 <- hhinc_24_26[order(hhinc_24_26$geozone,hhinc_24_26$yr_id, hhinc_24_26$income_id2),]
setnames(hhinc_24_26, old=c("name2","hh","hhtot","hhinc_prop"), new=c("income_cat","hh_26","hhtot_26","hhinc_prop_26"))


hhinc_24_26 <- subset(hhinc_24_26, hhinc_24_26$yr_id<=2016)
head(subset(hhinc_24_26, hhinc_24_26$geotype=="jurisdiction"),15)

hhinc_24_26$flag_5pct[hhinc_24_26$hhinc_diff>=5.00 | hhinc_24_26$hhinc_diff<=-5.00] <- 1
hhinc_24_26$flag_3pct[hhinc_24_26$hhinc_diff>=3.00 | hhinc_24_26$hhinc_diff<=-3.00] <- 1

hhinc_24_26_jur <- subset(hhinc_24_26, hhinc_24_26$geotype=="jurisdiction")
hhinc_24_26_reg <- subset(hhinc_24_26, hhinc_24_26$geotype=="region")
hhinc_24_26 <- subset(hhinc_24_26, hhinc_24_26$geotype=="tract")

table(hhinc_24_26_jur$flag_3pct)

head(hhinc_24_26_jur,20)

write.csv(hhinc_24_26_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_24_26_jur.csv",row.names = FALSE )
write.csv(hhinc_24_26_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_24_26_reg.csv",row.names = FALSE )
write.csv(hhinc_24_26, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_24_26_tract.csv",row.names = FALSE )

##################
##################
#within vintage hhinc comparison
##################
##################

head(hhinc,12)

#calculate year over year change
hhinc <- hhinc[order(hhinc$geozone, hhinc$income_id2 ,hhinc$yr_id),]
hhinc$hhinc_nchg <- hhinc$hhinc_prop - lag(hhinc$hhinc_prop)

#set 2010 number and pct change to NA - there is no previous year to calculate change
hhinc$hhinc_nchg[hhinc$yr_id==2010] <- NA
#hhinc$hhinc_npct[hhinc$yr_id==2010] <- NA 

hhinc <- hhinc[order(hhinc$geozone,hhinc$yr_id, hhinc$income_id2),]
setnames(hhinc, old="name2", new="income_cat")

#subset hhinc file for jurisdiction and region
hhinc_jur <- subset(hhinc, hhinc$geotype=="jurisdiction")
hhinc_reg <- subset(hhinc, hhinc$geotype=="region")
tail(hhinc[hhinc$geotype=="jurisdiction",],10)


rm(hhinc_24_26, hhinc_24_26_jur,hhinc_24_26_reg,hhinc_sql,hhtot,hhtot_24)

#############################
#############################
#keep only tract geographies
#############################
#############################

hhinc <- subset(hhinc, hhinc$geotype=="tract")
table(hhinc$geotype)

#create subset without 2018 to determine min and max of percent change
hhinc_2017 <- subset(hhinc, hhinc$yr_id<=2017)
table(hhinc_2017$yr_id)

#calculate the mean and sd for hhinc
hhinc_means <- aggregate(hhinc_nchg~income_id2,data=hhinc,mean,na.rm=TRUE)
hhinc_sd <- aggregate(hhinc_nchg~income_id2,data=hhinc,sd,na.rm=TRUE)
hhinc_means$hhinc_nchg <- round(hhinc_means$hhinc_nchg,digits = 2)
hhinc_sd$hhinc_nchg <- round(hhinc_sd$hhinc_nchg,digits = 2)

hhinc_min <- aggregate(hhinc_nchg~income_id2+geozone,data=hhinc_2017,min,na.rm=TRUE)
hhinc_max <- aggregate(hhinc_nchg~income_id2+geozone,data=hhinc_2017,max,na.rm=TRUE)
hhinc_min$hhinc_nchg <- round(hhinc_min$hhinc_nchg, digits = 2)
hhinc_max$hhinc_nchg <- round(hhinc_max$hhinc_nchg, digits = 2)


head(hhinc_means,20)
head(hhinc_sd,10)

#match in means to hhinc file
hhinc$hhinc_means<-hhinc_means[match(paste(hhinc$income_id2), paste(hhinc_means$income_id2)), "hhinc_nchg"]
#match in sd to hhinc file
hhinc$hhinc_sd<-hhinc_sd[match(paste(hhinc$income_id2), paste(hhinc_sd$income_id2)), "hhinc_nchg"]
#match in min to hhinc file
hhinc$hhinc_min<-hhinc_min[match(paste(hhinc$geozone,hhinc$income_id2), paste(hhinc_min$geozone,hhinc_min$income_id2)), "hhinc_nchg"]
#match in max to hhinc file
hhinc$hhinc_max<-hhinc_max[match(paste(hhinc$geozone,hhinc$income_id2), paste(hhinc_max$geozone,hhinc_max$income_id2)), "hhinc_nchg"]
#concatenate min and max into one vector
hhinc$range_nchg_2010_2017<-paste("(",hhinc$hhinc_min,"-",hhinc$hhinc_max,")")

head(hhinc_min)
head(hhinc_max)

#####
#####
head(hhinc,12)

#merge means and sd to calculate 3 standard deviations from mean
hhinc_3sd <- merge(hhinc_means, hhinc_sd, by.x = "income_id2", by.y = "income_id2", all = TRUE)
#calculate 3 standard deviations above the mean
hhinc_3sd$hhinc_3sd <- hhinc_3sd$hhinc_nchg.x+(3*hhinc_3sd$hhinc_nchg.y)
#calculate 3 standard deviations below the mean
hhinc_3sd$hhinc_3sd_minus <- hhinc_3sd$hhinc_nchg.x-(3*hhinc_3sd$hhinc_nchg.y)

head(hhinc_3sd)

#match 3 standard deviations above the mean into hhinc
hhinc$hhinc_3sd<-hhinc_3sd[match(paste(hhinc$income_id2), paste(hhinc_3sd$income_id2)), "hhinc_3sd"]

#match 3 standard deviations  below the mean into hhinc
hhinc$hhinc_3sd_minus<-hhinc_3sd[match(paste(hhinc$income_id2), paste(hhinc_3sd$income_id2)), "hhinc_3sd_minus"]


#create flag variables to identify outliers
hhinc$hhinc_flag[hhinc$hhinc_nchg>=hhinc$hhinc_3sd | hhinc$hhinc_nchg<=hhinc$hhinc_3sd_minus] <-1 
table(hhinc$hhinc_flag)
head(hhinc$hhinc_flag)



hhinc_outliers <- subset(hhinc, hhinc$hhinc_flag==1)

summary(hhinc$hhinc_nchg)

unique(hhinc_outliers$geozone)
table(hhinc_outliers$yr_id)

head(hhinc)

hhinc_outliers <- subset(hhinc_outliers, hhinc_outliers$yr_id==2018)

#create a variable to indicate all years for tracts with outliers  

sum(hhinc$gqpop, na.rm = TRUE)

#add script to delete unoccupiable, available, means, 3sd, min max
#rename flags specific record has issue, geozone has issue  

head(hhinc_outliers)

hhinc_wide_reg <- dcast(hhinc_reg, income_cat+income_id2+geozone~yr_id,value.var="hhinc_prop")

hhinc_wide_jur <- dcast(hhinc_jur, income_cat+income_id2+geozone~yr_id,value.var="hhinc_prop")
hhinc_wide_jur <- hhinc_wide_jur[order(hhinc_wide_jur$geozone, hhinc_wide_jur$income_id2),]


head(hhinc_wide_jur,10)

write.csv(hhinc_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_jur_ID26.csv",row.names = FALSE )
write.csv(hhinc_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_reg_ID26.csv",row.names = FALSE )
write.csv(hhinc_outliers[,c("yr_id","geozone","income_cat","hh","hhtot","hhinc_prop","hhinc_nchg","hhinc_sd","range_nchg_2010_2017","hhinc_flag")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_outliers_tract_ID26.csv",row.names = FALSE )
write.csv(hhinc_wide_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_jur_ID26_wide.csv",row.names = FALSE )
write.csv(hhinc_wide_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc\\hhinc_reg_ID26_wide.csv",row.names = FALSE )
