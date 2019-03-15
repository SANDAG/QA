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

tail(hhinc_24)

hhinc_24 <- aggregate(hh~yr_id + geotype + geozone + name2 + income_id2, data=hhinc_24, sum)
hhtot_24 <- aggregate(hh~yr_id + geotype + geozone, data=hhinc_24, sum)
hhinc_24$hhtot_24 <- hhtot_24[match(paste(hhinc_24$yr_id,hhinc_24$geozone),paste(hhtot_24$yr_id,hhtot_24$geozone)),"hh"] 
hhinc_24$hhinc_prop_24 <- (hhinc_24$hh/hhinc_24$hhtot_24)* 100

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


#change integer to numeric type
hhinc_24$hh <- as.numeric(hhinc_24$hh)
hhinc_24$hhtot <- as.numeric(hhinc_24$hhtot_24)
hhinc$hh <- as.numeric(hhinc$hh)
hhinc$hhtot <- as.numeric(hhinc$hhtot)

#rename region for clarity in output
hhinc$geozone[hhinc$geotype=='region'] <- 'San Diego Region'
hhinc_24$geozone[hhinc_24$geotype=='region'] <- 'San Diego Region'

setnames(est_24, old=c(), new=c(""))

hhinc_24_26 <- merge(hhinc_24, hhinc, by.x = c("yr_id","geotype","geozone","income_id2","name2"), by.y = c("yr_id","geotype","geozone","income_id2","name2"), all=TRUE)

head(hhinc_24_26)
#confirm expected records are in dataframe
table(hhinc_24_26$yr_id)
table(hhinc_24_26$geozone)
table(hhinc_24_26$geotype)


#calculate number change
hhinc_24_26$hhinc_diff <- hhinc_24_26$hhinc_prop-hhinc_24_26$hhinc_prop_24

summary(hhinc_24_26$hhinc_diff)


head(subset(hhinc_24_26, hhinc_24_26$geotype=="jurisdiction"),15)

#calculate percent change
est_24_26$tot_pop_pctchg <- (est_24_26$tot_pop_numchg/est_24_26$pop_24)*100
est_24_26$tot_pop_pctchg <- round(est_24_26$tot_pop_pctchg,digits=2)


est_24_26 <- est_24_26[order(est_24_26$geozone, est_24_26$yr_id),]

#exclude 2017 and 2018 data since not in ID24 dataset
est_24_26 <- subset(est_24_26, est_24_26$yr_id<=2016)
est_24_26_2016 <- subset(est_24_26, est_24_26$yr_id==2016)
est_24_26_2016_reg <- subset(est_24_26_2016, est_24_26_2016$geotype.y=="region")
est_24_26_2016_jur <- subset(est_24_26_2016, est_24_26_2016$geotype.y=="jurisdiction")
est_24_26_2016_tract <- subset(est_24_26_2016, est_24_26_2016$geotype.y=="tract")

#melt region data before saving
#order jurisdiction



write.csv(hhinc_24_26[,c("yr_id","geozone","hhinc_24","hhinc","hhinc_24_prop","hhinc_prop","hhinc_prop_pctchg")],
                        "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc 2016 to 2018 differences.csv" )

write.csv(est_24_26_2016_jur[,c("yr_id","geozone","pop_24","pop","gqpop_24","gqpop","households_24","households","hu_24","hu",
                                  "hhp_24","hhp","hhs_24","hhs","vac_rate_24","vac_rate","tot_pop_numchg","tot_pop_pctchg","hhp_numchg","hhp_pctchg",
                                  "gqpop_numchg","gqpop_pctchg","hh_numchg","hh_pctchg","hu_numchg","hu_pctchg","sfa_numchg","sfd_numchg","mf_numchg","mf_pctchg",
                                  "mh_numchg","mh_pctchg","hhs_numchg","hhs_pctchg","vac_numchg","vac_pctchg")],
                                  "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc 2016 to 2018 differences_jur.csv" )


write.csv(est_24_26_2016_tract[,c("yr_id","geozone","pop_24","pop","gqpop_24","gqpop","households_24","households","hu_24","hu",
                       "hhp_24","hhp","hhs_24","hhs","vac_rate_24","vac_rate","tot_pop_numchg","tot_pop_pctchg","hhp_numchg","hhp_pctchg",
                       "gqpop_numchg","gqpop_pctchg","hh_numchg","hh_pctchg","hu_numchg","hu_pctchg","sfa_numchg","sfd_numchg","mf_numchg","mf_pctchg",
                       "mh_numchg","mh_pctchg","hhs_numchg","hhs_pctchg","vac_numchg","vac_pctchg")],
                        "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hhinc 2016 to 2018 differences_tract.csv" )



#calculate change in ID 26 data
hhinc <- est[order(est$geotype,est$geozone,est$yr_id),]
est$vacN_chg <- est$vac_rate - lag(est$vac_rate)
est$vacN_pct <- (est$vacN_chg / lag(est$vac_rate))*100
est$vacN_pct<-round(est$vacN_pct,digits=2)

head(est[est$geotype=="jurisdiction",],10)

#set 2010 number and pct change to NA - there is no previous year to calculate change
est$vacN_pct[est$yr_id==2010] <- NA
est$vacN_chg[est$yr_id==2010] <- NA 

#set Inf values to NA for later calculations
est$vacN_pct[is.infinite(est$vacN_pct)] <-NA 
#subset est file for jurisdiction and region
hhinc_jur <- subset(hhinc, hhinc$geotype=="jurisdiction")
hhinc_reg <- subset(hhinc, hhinc$geotype=="region")


#############################
#############################
#keep only tract geographies
#############################
#############################

est <- subset(est, est$geotype=="tract")
table(est$geotype)

est_2017 <- subset(est, est$yr_id<=2017)
table(est_2017$yr_id)

#calculate the mean and sd for hh variables
est_means <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_pct)~yr_id,data=est,mean,na.rm=TRUE)
est_sd <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_pct)~yr_id,data=est,sd,na.rm=TRUE)
est_min <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_pct)~geozone,data=est_2017,min,na.rm=TRUE)
est_max <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_pct)~geozone,data=est_2017,max,na.rm=TRUE)


head(est_means$hhpN_pct,9)
head(est_sd$hhpN_pct,9)
head(est_sd)
head(est_min,10)


#match in means to est file
est$hhp_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), 2]

#match in sd to est file
est$hhp_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), 2]
#match in min to est file
est$hhp_min<-est_min[match(paste(est$geozone), paste(est_min$geozone)), 2]
#match in max to est file
est$hhp_max<-est_max[match(paste(est$geozone), paste(est_max$geozone)), 2]
#concatenate min and max into one vector
est$hhp_range<-paste("(",est$hhp_min,"-",est$hhp_max,")")


head(hhinc_min)
head(hhinc_max)

#####
#####
head(hhinc)

#merge means and sd to calculate 3 standard deviations from mean
est_3sd <- merge(est_means, est_sd, by.x = "yr_id", by.y = "yr_id",all = TRUE)
#calculate 3 standard deviations above the mean
est_3sd$hhp_3sd <- est_3sd$hhpN_pct.x+(3*est_3sd$hhpN_pct.y)
#calculate 3 standard deviations below the mean
est_3sd$hhp_3sd_minus <- est_3sd$hhpN_pct.x-(3*est_3sd$hhpN_pct.y)

#match 3 standard deviations above the mean into est
est$hhp_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hhp_3sd"]

#match 3 standard deviations  below the mean into est
est$hhp_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hhp_3sd_minus"]


#create flag variables to identify outliers
est$hhp_flag[est$hhpN_pct>=est$hhp_3sd | est$hhpN_pct<=est$hhp_3sd_minus] <-1 
table(est$hhp_flag)

hhinc_outliers <- subset(hhinc, hhinc$hhinc_flag==1)

unique(hhinc_outliers$geozone)
hhinc_out <- subset(hhinc, hhinc$hhinc_flag==1)

hhinc$hhinc_maxflag[hhinc$geozone %in% hhinc_out$geozone] <- 1

hhinc_outliers <- subset(hhinc_outliers, hhinc_outliers$yr_id==2018)

#create a variable to indicate all years for tracts with outliers  

est_outlier_all_years <- subset(est, (est$geozone %in% est_outliers$geozone & est$outlier==1))

table(est_outliers$geozone)
row_number(est_outliers$geozone)
unique(est_outlier_all_years$geozone)

sum(est$gqpop, na.rm = TRUE)



#add script to delete unoccupiable, available, means, 3sd, min max
#rename flags specific record has issue, geozone has issue  

head(est,15)

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
