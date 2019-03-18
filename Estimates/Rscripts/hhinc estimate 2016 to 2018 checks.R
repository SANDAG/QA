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

#calculate percent diff
hhinc_24_26$hhinc_pctdiff <- (hhinc_24_26$hhinc_diff/hhinc_24_26$hhinc_prop_24)*100
hhinc_24_26$hhinc_pctdiff <- round(hhinc_24_26$hhinc_pctdiff,digits=2)
hhinc_24_26$hhinc_pctdiff[is.infinite(hhinc_24_26$hhinc_pctdiff)] <-NA 

hhinc_24_26 <- subset(hhinc_24_26, hhinc_24_26$yr_id<=2016)

head(subset(hhinc_24_26, hhinc_24_26$geotype=="jurisdiction"),15)

hhinc_24_26_jur <- subset(hhinc_24_26, hhinc_24_26$geotype=="jurisdiction")
hhinc_24_26_reg <- subset(hhinc_24_26, hhinc_24_26$geotype=="region")
hhinc_24_26 <- subset(hhinc_24_26, hhinc_24_26$geotype=="tract")

head(hhinc_24_26_jur,20)

write.csv(hhinc_24_26_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc_24_26_jur.csv",row.names = FALSE )
write.csv(hhinc_24_26_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc_24_26_reg.csv",row.names = FALSE )
write.csv(hhinc_24_26, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc_24_26_tract.csv",row.names = FALSE )


##################
##################
#within vintage hhinc comparison
##################
##################

head(hhinc,12)

#calculate year over year change
hhinc <- hhinc[order(hhinc$geozone, hhinc$income_id2 ,hhinc$yr_id),]
hhinc$hhinc_nchg <- hhinc$hhinc_prop - lag(hhinc$hhinc_prop)
#hhinc$hhinc_npct <- hhinc$hhinc_nchg/lag(hhinc$hhinc_prop)*100 
#hhinc$hhinc_npct <- round(hhinc$hhinc_npct, digits = 2)

#set 2010 number and pct change to NA - there is no previous year to calculate change
hhinc$hhinc_nchg[hhinc$yr_id==2010] <- NA
#hhinc$hhinc_npct[hhinc$yr_id==2010] <- NA 

#set Inf values to NA for later calculations
#hhinc$hhinc_npct[is.infinite(hhinc$hhinc_npct)] <-NA 

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
hhinc_means <- aggregate(hhinc_nchg~income_id2+yr_id,data=hhinc,mean,na.rm=TRUE)
hhinc_sd <- aggregate(hhinc_nchg~income_id2+yr_id,data=hhinc,sd,na.rm=TRUE)
hhinc_means$hhinc_nchg <- round(hhinc_means$hhinc_nchg,digits = 2)
hhinc_sd$hhinc_nchg <- round(hhinc_sd$hhinc_nchg,digits = 2)

hhinc_min <- aggregate(hhinc_nchg~income_id2+geozone,data=hhinc_2017,min,na.rm=TRUE)
hhinc_max <- aggregate(hhinc_nchg~income_id2+geozone,data=hhinc_2017,max,na.rm=TRUE)
hhinc_min <- round(hhinc_min$hhinc_nchg, digits = 2)
hhinc_max <- round(hhinc_min$hhinc_nchg, digits = 2)


head(hhinc_means,20)
head(hhinc_sd,10)

hhinc_test <- subset(hhinc,hhinc$geozone==1)
head(hhinc_test,10)
#match in means to hhinc file
hhinc$hhinc_means<-hhinc_means[match(paste(hhinc$yr_id), paste(hhinc_means$yr_id)), 2]
#match in sd to hhinc file
hhinc$hhinc_sd<-hhinc_sd[match(paste(hhinc$yr_id), paste(hhinc_sd$yr_id)), 2]
#match in min to hhinc file
hhinc$hhinc_min<-hhinc_min[match(paste(hhinc$geozone,hhinc$income_id2), paste(hhinc_min$geozone,hhinc$income_id2)), 3]
#match in max to hhinc file
hhinc$hhinc_max<-hhinc_max[match(paste(hhinc$geozone), paste(hhinc_max$geozone)), 3]
#concatenate min and max into one vector
hhinc$hhinc_range<-paste("(",hhinc$hhinc_min,"-",hhinc$hhinc_max,")")

head(hhinc_min)
head(hhinc_max)

#####
#####
head(hhinc)

head(hhinc_3sd)

#merge means and sd to calculate 3 standard deviations from mean
hhinc_3sd <- merge(hhinc_means, hhinc_sd, by.x = c("yr_id","income_id2"), by.y = c("yr_id","income_id2"), all = TRUE)
#calculate 3 standard deviations above the mean
hhinc_3sd$hhinc_3sd <- hhinc_3sd$hhinc_npct.x+(3*hhinc_3sd$hhinc_npct.y)
#calculate 3 standard deviations below the mean
hhinc_3sd$hhinc_3sd_minus <- hhinc_3sd$hhinc_npct.x-(3*hhinc_3sd$hhinc_npct.y)

#match 3 standard deviations above the mean into hhinc
hhinc$hhinc_3sd<-hhinc_3sd[match(paste(hhinc$yr_id), paste(hhinc_3sd$yr_id)), "hhinc_3sd"]

#match 3 standard deviations  below the mean into hhinc
hhinc$hhinc_3sd_minus<-hhinc_3sd[match(paste(hhinc$yr_id), paste(hhinc_3sd$yr_id)), "hhinc_3sd_minus"]


#create flag variables to identify outliers
hhinc$hhinc_flag[hhinc$hhinc_npct>=hhinc$hhinc_3sd | hhinc$hhinc_npct<=hhinc$hhinc_3sd_minus] <-1 
table(hhinc$hhinc_flag)

hhinc_outliers <- subset(hhinc, hhinc$hhinc_flag==1)

unique(hhinc_outliers$geozone)
table(hhinc_outliers$yr_id)

#test
hhinc_out <- subset(hhinc, hhinc$hhinc_flag==1)
hhinc$hhinc_maxflag[hhinc$geozone %in% hhinc_out$geozone] <- 1
#end test
hhinc_outliers <- subset(hhinc_outliers, hhinc_outliers$yr_id==2018)

#create a variable to indicate all years for tracts with outliers  

hhinc_outlier_all_years <- subset(hhinc, (hhinc$geozone %in% hhinc_outliers$geozone & hhinc$outlier==1))

table(hhinc_outliers$geozone)
row_number(hhinc_outliers$geozone)
unique(hhinc_outlier_all_years$geozone)

sum(hhinc$gqpop, na.rm = TRUE)



#add script to delete unoccupiable, available, means, 3sd, min max
#rename flags specific record has issue, geozone has issue  

head(hhinc,15)

write.csv(est_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_jur_ID26.csv",row.names = FALSE )
write.csv(est_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_reg_ID26.csv",row.names = FALSE )
write.csv(est_outliers[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hh_sd","hu","huN_chg","huN_pct","hu_range","hu_sd",
                          "hhp","hhpN_chg","hhpN_pct","hhp_range","hhp_sd","hhs","hhsN_chg","hhsN_pct","hhs_range","hhs_sd","vac_rate","vacN_chg","vacN_pct",
                          "vac_range","vac_sd","hh_flag","hu_flag","hhp_flag","hhs_flag","vac_flag")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID26_sd.csv",row.names = FALSE )
write.csv(est[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hu","huN_chg","huN_pct","hu_range",
                 "hhp","hhpN_chg","hhpN_pct","hhp_range","hhs","hhsN_chg","hhsN_pct","hhs_range","vac_rate","vacN_chg","vacN_pct",
                 "vac_range","hh_flag","hh_flag_max","hu_flag","hu_flag_max","hhp_flag","hhp_flag_max","hhs_flag","hhs_flag_max","vac_flag","vac_flag_max")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variable_tract_ID26.csv",row.names = FALSE )
write.csv(est[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hu","huN_chg","huN_pct","hu_range",
                          "hhp","hhpN_chg","hhpN_pct","hhp_range","hhs","hhsN_chg","hhsN_pct","hhs_range","vac_rate","vacN_chg","vacN_pct",
                          "vac_range","hh_flag","hu_flag","hhp_flag","hhs_flag","vac_flag")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID26.csv",row.names = FALSE )
