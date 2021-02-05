#HH estimate script


#############
#############
#updated to datasource_id 26 to reflect 24 to 26 for redos of some estimate check output per cheryl's comments. 
#this results in slightly different output from what EDAM may have received.

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC","reshape2", 
              "stringr","tidyverse")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")


getwd()
options(stringsAsFactors=FALSE)

ds_id=24

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh_24<-sqlQuery(channel,hh_sql)
gq_sql = getSQL("../Queries/group_quarter.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq_24<-sqlQuery(channel,gq_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop_24<-sqlQuery(channel,totpop_sql)
odbcClose(channel)

ds_id=26

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh<-sqlQuery(channel,hh_sql)
gq_sql = getSQL("../Queries/group_quarter.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq<-sqlQuery(channel,gq_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop <-sqlQuery(channel,totpop_sql)
odbcClose(channel)

head(gq_24)


#aggregate gq pop only - exclude hh pop
gq <-aggregate(pop~yr_id + geozone + geotype, subset(gq, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq, old="pop", new="gqpop")

gq_24 <-aggregate(pop~yr_id + geozone + geotype, subset(gq_24, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq_24, old="pop", new="gqpop_24")

#clean up geozone for merge
totpop$geozone <- gsub("\\*","",totpop$geozone)
totpop$geozone <- gsub("\\-","_",totpop$geozone)
totpop$geozone <- gsub("\\:","_",totpop$geozone)
gq$geozone <- gsub("\\*","",gq$geozone)
gq$geozone <- gsub("\\-","_",gq$geozone)
gq$geozone <- gsub("\\:","_",gq$geozone)
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)


totpop_24$geozone <- gsub("\\*","",totpop_24$geozone)
totpop_24$geozone <- gsub("\\-","_",totpop_24$geozone)
totpop_24$geozone <- gsub("\\:","_",totpop_24$geozone)
gq_24$geozone <- gsub("\\*","",gq_24$geozone)
gq_24$geozone <- gsub("\\-","_",gq_24$geozone)
gq_24$geozone <- gsub("\\:","_",gq_24$geozone)
hh_24$geozone <- gsub("\\*","",hh_24$geozone)
hh_24$geozone <- gsub("\\-","_",hh_24$geozone)
hh_24$geozone <- gsub("\\:","_",hh_24$geozone)

#merge data and calculate the vacancy rate
est <- merge(totpop, gq, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hh, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
setnames(est, old="units",new="hu")
#calculate vac rate
est$vac <- ((est$hu-est$households)/est$hu)*100
est$vac <- round(est$vac,digits = 2)

head(est)

est_24 <- merge(totpop_24, gq_24, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est_24 <- merge(est_24, hh_24, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
setnames(est_24, old="units",new="hu")
#calculate vac rate
est_24$vac <- ((est_24$hu-est_24$households)/est_24$hu)*100
est_24$vac <- round(est_24$vac,digits = 2)

head(est_24)


#change integer to numeric type
est$pop <- as.numeric(est$pop)
est$gqpop <- as.numeric(est$gqpop)
est$households <- as.numeric(est$households)
est$hhp <- as.numeric(est$hhp)
est$hu <- as.numeric(est$hu)
#est$mf <- as.numeric(est$mf)
#est$mh <- as.numeric(est$mh)
#est$sfmu <- as.numeric(est$sf)
#est$sf <- as.numeric(est$sf)

est_24$pop <- as.numeric(est_24$pop)
est_24$gqpop_24 <- as.numeric(est_24$gqpop_24)
est_24$households <- as.numeric(est_24$households)
est_24$hhp <- as.numeric(est_24$hhp)
est_24$hu <- as.numeric(est_24$hu)
# est_24$mf <- as.numeric(est_24$mf)
# est_24$mh <- as.numeric(est_24$mh)
# est_24$sfmu <- as.numeric(est_24$sfmu)
# est_24$sf <- as.numeric(est_24$sf)

head(est_24)

est$geozone[est$geotype=='region'] <- 'San Diego Region'
est_24$geozone[est_24$geotype=='region'] <- 'San Diego Region'

         
setnames(est_24, old=c("pop","gqpop_24","households","hhp","hhs", "hu","vac"), new=c("pop_24","gqpop_24","households_24",
                                                                                                 "hhp_24","hhs_24","hu_24","vac_24"))

est$geozone <- gsub("^\\s+|\\s+$", "", est$geozone)
est_24$geozone <- gsub("^\\s+|\\s+$", "", est_24$geozone)

est_24_26 <- merge(est_24,est, by.x = c("yr_id","geozone","geotype"), by.y = c("yr_id", "geozone","geotype"), all=TRUE)

#confirm expected records are in dataframe
table(est_24_26$yr_id)
#table(est_24_26$geozone)
table(est_24_26$geotype)

#calculate number change
est_24_26$tot_pop_numchg <- est_24_26$pop-est_24_26$pop_24
est_24_26$hhp_numchg <- est_24_26$hhp-est_24_26$hhp_24
est_24_26$gqpop_numchg <- est_24_26$gqpop-est_24_26$gqpop_24
est_24_26$hh_numchg <- est_24_26$households-est_24_26$households_24
est_24_26$hu_numchg <- est_24_26$hu-est_24_26$hu_24
#est_24_26$sfa_numchg <- est_24_26$sfa-est_24_26$sfa_24
#est_24_26$sfd_numchg <- est_24_26$sfd-est_24_26$sfd_24
#est_24_26$mf_numchg <- est_24_26$mf-est_24_26$mf_24
#est_24_26$mh_numchg <- est_24_26$mh-est_24_26$mh_24
est_24_26$hhs_numchg <- est_24_26$hhs-est_24_26$hhs_24
est_24_26$vac_numchg <- est_24_26$vac-est_24_26$vac_24

head(subset(est_24_26, est_24_26$geotype.x=="jurisdiction"), 8)

#calculate percent change
#percent change for vac is misleading because numbers are small so only number change is calculated
est_24_26$tot_pop_pctchg <- (est_24_26$tot_pop_numchg/est_24_26$pop_24)*100
est_24_26$tot_pop_pctchg <- round(est_24_26$tot_pop_pctchg,digits=2)
est_24_26$hhp_pctchg <- (est_24_26$hhp_numchg/est_24_26$hhp_24)*100
est_24_26$hhp_pctchg <- round(est_24_26$hhp_pctchg,digits=2)
est_24_26$gqpop_pctchg <- (est_24_26$gqpop_numchg/est_24_26$gqpop_24)*100
est_24_26$gqpop_pctchg <- round(est_24_26$gqpop_pctchg,digits=2)
est_24_26$hh_pctchg <- (est_24_26$hh_numchg/est_24_26$households_24)*100
est_24_26$hh_pctchg <- round(est_24_26$hh_pctchg,digits=2)
est_24_26$hu_pctchg <- (est_24_26$hu_numchg/est_24_26$hu_24)*100
est_24_26$hu_pctchg <- round(est_24_26$hu_pctchg,digits=2)

#wait until EDAM changes the values for the units by type names
#add sfd and sfa

##############
###############
# est_24_26$mf_pctchg <- (est_24_26$mf_numchg/est_24_26$mf_24)*100
# est_24_26$mf_pctchg <- round(est_24_26$mf_pctchg,digits=2)
# est_24_26$mh_pctchg <- (est_24_26$mh_numchg/est_24_26$mh_24)*100
# est_24_26$mh_pctchg <- round(est_24_26$mh_pctchg,digits=2)
est_24_26$hhs_pctchg <- (est_24_26$hhs_numchg/est_24_26$hhs_24)*100
est_24_26$hhs_pctchg <- round(est_24_26$hhs_pctchg,digits=2)


est_24_26 <- est_24_26[order(est_24_26$geozone, est_24_26$yr_id),]

#saved from datasource_id 26
write.csv(est_24_26,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Est 2016 to 2018 differences_id24_26.csv" )



#calculate change in ID 26 data
#percent change for vac is misleading because numbers are small so only number change is calculated
est <- est[order(est$geotype,est$geozone,est$yr_id),]
est$hhpN_chg <- est$hhp - lag(est$hhp)
est$hhpN_pct <- (est$hhpN_chg / lag(est$hhp))*100
est$hhpN_pct<-round(est$hhpN_pct,digits=2)
est$hhsN_chg <- est$hhs - lag(est$hhs)
est$hhsN_pct <- (est$hhsN_chg / lag(est$hhs))*100
est$hhsN_pct<-round(est$hhsN_pct,digits=2)
est$hhN_chg <- est$households - lag(est$households)
est$hhN_pct <- est$hhN_chg / lag(est$households)*100
est$hhN_pct<-round(est$hhN_pct,digits=2)
est$huN_chg <- est$hu - lag(est$hu)
est$huN_pct <- (est$huN_chg / lag(est$hu))*100
est$huN_pct<-round(est$huN_pct,digits=2)
est$vacN_chg <- est$vac - lag(est$vac)

head(est[est$geotype=="jurisdiction",],10)

#set 2010 number and pct change to NA - there is no previous year to calculate change
est$hhpN_pct[est$yr_id==2010] <- NA
est$hhpN_chg[est$yr_id==2010] <- NA
est$hhsN_pct[est$yr_id==2010] <- NA
est$hhsN_chg[est$yr_id==2010] <- NA
est$hhN_pct[est$yr_id==2010] <- NA
est$hhN_chg[est$yr_id==2010] <- NA 
est$huN_pct[est$yr_id==2010] <- NA
est$huN_chg[est$yr_id==2010] <- NA 
est$vacN_chg[est$yr_id==2010] <- NA 
#set Inf values to NA for later calculations
est$hhpN_pct[is.infinite(est$hhpN_pct)] <-NA 
est$hhsN_pct[is.infinite(est$hhsN_pct)] <-NA 
est$hhN_pct[is.infinite(est$hhN_pct)] <-NA 
est$huN_pct[is.infinite(est$huN_pct)] <-NA 
 
#subset est file for jurisdiction and region
est_jur <- subset(est, est$geotype=="jurisdiction")
est_reg <- subset(est, est$geotype=="region")

head(est)
#############################
#############################
#keep only tract geographies
#############################
#############################

#remove unneeded objects
rm(hh_24,gq_24,totpop_24)

#make copy of est in case need to rerun after this point
est_backup <- data.frame(est) 

#subset for only census tract
est <- subset(est, est$geotype=="tract")
table(est$geotype)
#subset for records in 2017 and earlier to calculate the descriptive stats for comparison
est_2017 <- subset(est, est$yr_id<=2017)
table(est_2017$yr_id)

#calculate the mean and sd for hh variables
est_means <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_chg)~yr_id,data=est,mean,na.rm=TRUE)
est_sd <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_chg)~yr_id,data=est,sd,na.rm=TRUE)
est_min <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_chg)~geozone,data=est_2017,min,na.rm=TRUE)
est_max <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct,vacN_chg)~geozone,data=est_2017,max,na.rm=TRUE)

head(est_means$hhpN_pct,9)
head(est_sd$hhpN_pct,9)
head(est_sd)
head(est_min,10)

#match in means to est file

est$hhp_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), "hhpN_pct"]
est$hhs_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), "hhsN_pct"]
est$hh_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), "hhN_pct"]
est$hu_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), "huN_pct"]
est$vac_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), "vacN_chg"]

#match in sd to est file
est$hhp_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), "hhpN_pct"]
est$hhs_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), "hhsN_pct"]
est$hh_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), "hhN_pct"]
est$hu_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), "huN_pct"]
est$vac_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), "vacN_chg"]

#match in min to est file
est$hhp_min<-est_min[match(paste(est$geozone), paste(est_min$geozone)), "hhpN_pct"]
est$hhs_min<-est_min[match(paste(est$geozone), paste(est_min$geozone)), "hhsN_pct"]
est$hh_min<-est_min[match(paste(est$geozone), paste(est_min$geozone)), "hhN_pct"]
est$hu_min<-est_min[match(paste(est$geozone), paste(est_min$geozone)), "huN_pct"]
est$vac_min<-est_min[match(paste(est$geozone), paste(est_min$geozone)), "vacN_chg"]

#match in max to est file
est$hhp_max<-est_max[match(paste(est$geozone), paste(est_max$geozone)), "hhpN_pct"]
est$hhs_max<-est_max[match(paste(est$geozone), paste(est_max$geozone)), "hhsN_pct"]
est$hh_max<-est_max[match(paste(est$geozone), paste(est_max$geozone)), "hhN_pct"]
est$hu_max<-est_max[match(paste(est$geozone), paste(est_max$geozone)), "huN_pct"]
est$vac_max<-est_max[match(paste(est$geozone), paste(est_max$geozone)), "vacN_chg"]

#concatenate min and max into one vector
est$hhp_range<-paste("(",est$hhp_min,"-",est$hhp_max,")")
est$hhs_range<-paste("(",est$hhs_min,"-",est$hhs_max,")")
est$hh_range<-paste("(",est$hh_min,"-",est$hh_max,")")
est$hu_range<-paste("(",est$hu_min,"-",est$hu_max,")")
est$vac_range<-paste("(",est$vac_min,"-",est$vac_max,")")
#####
#####
head(est)

#merge means and sd to calculate 3 standard deviations from mean
est_3sd <- merge(est_means, est_sd, by.x = "yr_id", by.y = "yr_id",all = TRUE)
#calculate 3 standard deviations above the mean
est_3sd$hhp_3sd <- est_3sd$hhpN_pct.x+(3*est_3sd$hhpN_pct.y)
est_3sd$hhs_3sd <- est_3sd$hhsN_pct.x+(3*est_3sd$hhsN_pct.y)
est_3sd$hh_3sd <- est_3sd$hhN_pct.x+(3*est_3sd$hhN_pct.y)
est_3sd$hu_3sd <- est_3sd$huN_pct.x+(3*est_3sd$huN_pct.y)
est_3sd$vac_3sd <- est_3sd$vacN_chg.x+(3*est_3sd$vacN_chg.y)


#calculate 3 standard deviations below the mean
est_3sd$hhp_3sd_minus <- est_3sd$hhpN_pct.x-(3*est_3sd$hhpN_pct.y)
est_3sd$hhs_3sd_minus <- est_3sd$hhsN_pct.x-(3*est_3sd$hhsN_pct.y)
est_3sd$hh_3sd_minus <- est_3sd$hhN_pct.x-(3*est_3sd$hhN_pct.y)
est_3sd$hu_3sd_minus <- est_3sd$huN_pct.x-(3*est_3sd$huN_pct.y)
est_3sd$vac_3sd_minus <- est_3sd$vacN_chg.x-(3*est_3sd$vacN_chg.y)

#match 3 standard deviations above the mean into est
est$hhp_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hhp_3sd"]
est$hhs_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hhs_3sd"]
est$hh_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hh_3sd"]
est$hu_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hu_3sd"]
est$vac_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "vac_3sd"]

#match 3 standard deviations  below the mean into est
est$hhp_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hhp_3sd_minus"]
est$hhs_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hhs_3sd_minus"]
est$hh_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hh_3sd_minus"]
est$hu_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "hu_3sd_minus"]
est$vac_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), "vac_3sd_minus"]

#round sd for output file
est$hhp_sd<-round(est$hhp_sd,digits=2)
est$hhs_sd<-round(est$hhs_sd,digits=2)
est$hh_sd<-round(est$hh_sd,digits=2)
est$hu_sd<-round(est$hu_sd,digits=2)
est$vac_sd<-round(est$vac_sd,digits=2)

#create flag variables to identify outliers
est$hhp_flag[est$hhpN_pct>=est$hhp_3sd | est$hhpN_pct<=est$hhp_3sd_minus] <-1 
est$hhs_flag[est$hhsN_pct>=est$hhs_3sd | est$hhsN_pct<=est$hhs_3sd_minus] <-1
est$hh_flag[est$hhN_pct>=est$hh_3sd | est$hhN_pct<=est$hh_3sd_minus] <-1
est$hu_flag[est$huN_pct>=est$hu_3sd | est$huN_pct<=est$hu_3sd_minus] <-1
est$vac_flag[est$vacN_chg>=est$vac_3sd | est$vacN_chg<=est$vac_3sd_minus] <-1

#check flag results
table(est$hhp_flag)
table(est$hhs_flag)
table(est$hh_flag)
table(est$hu_flag)
table(est$vac_flag)

head(est) 

tract_sums <- est %>%
 select(yr_id,pop,gqpop,households,hu,hhp) %>%
 group_by(yr_id) %>%
 summarise(popsum = sum(pop,na.rm=TRUE),gqsum = sum(gqpop,na.rm=TRUE),hhsum=sum(households,na.rm=TRUE),husum=sum(hu,na.rm=TRUE),hhpsum=sum(hhp,na.rm=TRUE))  
  
tract_sums <- merge(tract_sums,select(est_reg,yr_id,pop,gqpop,households,hu,hhp), by.x = ("yr_id"),by.y = ("yr_id"),all = TRUE)

#setnames(tract_sums, old = c("sum(households, na.rm = TRUE)","sum(hu, na.rm = TRUE)","sum(hhp, na.rm = TRUE)"), new = c("hhsum","husum","hhpsum"))

tract_sums$pop_diff <-tract_sums$pop-tract_sums$popsum
tract_sums$gq_diff <-tract_sums$gqpop-tract_sums$gqsum
tract_sums$hh_diff <-tract_sums$households-tract_sums$hhsum
tract_sums$hu_diff <-tract_sums$hu-tract_sums$husum
tract_sums$hhp_diff <-tract_sums$hhp-tract_sums$hhpsum

tract_sums <- select(tract_sums,yr_id,popsum,pop,pop_diff,gqsum,gqpop,gq_diff,hhsum,households,hh_diff,husum,hu,hu_diff,
                     hhpsum,hhp,hhp_diff)

#create generic outlier to indicate any type of outlier
est$outlier[est$hhp_flag==1 | est$hhs_flag==1 | est$hh_flag==1 | est$hu_flag==1 | est$vac_flag==1] <- 1

table(est$outlier)

head(est,10)

#create a outlier list of census tract numbers with one or more outliers
outlier_max <- aggregate(outlier~geozone,data=est,max,na.rm=TRUE)

#match outlier to estimate file to identify records for every year of census tracts whether there is an outlier or not
est$any_outlier<-outlier_max[match(paste(est$geozone), paste(outlier_max$geozone)), "outlier"]

#save object with outliers cases
hh_outliers <- subset(est, est$hhp_flag==1 | est$hhs_flag==1 | est$hh_flag==1 | est$hu_flag==1 | est$vac_flag==1)

outliers_2018 <-subset(est, est$outlier==1 & est$yr_id==2018) 
                                     
table(hh_outliers$geozone)
row_number(hh_outliers$geozone)


#there is a difference in outliers overall all because of a change in the vacancy rate definition of outlier.
#Original was defined by sd of percent change and the new definition here and for id27 was outliers based on sd of number change/difference of rate from year to year.
#outliers from first round of QA on id26- 100.15
# 101.03
# 126
# 134.12
# 148.04
# 166.12
# 166.15
# 170.09
# 185.15
# 189.04
# 198.05
# 200.18
# 200.23
# 200.29
# 202.11
# 205
# 213.02
# 215
# 219
# 220
# 51
# 52
# 53
# 58
# 60
# 99.01


outlier_list <- c(100.15, 101.03, 126, 134.12, 148.04, 166.12, 166.15, 170.09, 185.15, 189.04, 198.05, 200.18, 200.23, 200.29, 202.11,
                  205, 213.02, 215, 219, 220, 51, 52, 53, 58, 60, 99.01)

outlier_df <- as.data.frame(outlier_list) 
outlier_df$old_outlier <- 1
outliers_2018$old_outlier <- outlier_df[match(paste(outliers_2018$geozone),paste(outlier_df$outlier_list)), "old_outlier"]


head(outliers_2018$geozone[outliers_2018$old_outlier==1],19)

#add script to delete unoccupiable, available, means, 3sd, min max
#rename flags specific record has issue, geozone has issue  


colnames(outliers_2018)

write.csv(est_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_jur_ID26 v2.csv",row.names = FALSE )
write.csv(est_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_reg_ID26 v2.csv",row.names = FALSE )


write.csv(outliers_2018[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hh_sd","hu","huN_chg","huN_pct","hu_range","hu_sd",
                          "hhp","hhpN_chg","hhpN_pct","hhp_range","hhp_sd","hhs","hhsN_chg","hhsN_pct","hhs_range","hhs_sd","vac","vacN_chg",
                          "vac_range","vac_sd","hh_flag","hu_flag","hhp_flag","hhs_flag","vac_flag","old_outlier")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID26_sd_2018_outliers v2.csv",row.names = FALSE )


write.csv(est[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hh_sd","hu","huN_chg","huN_pct","hu_range","hu_sd",
                          "hhp","hhpN_chg","hhpN_pct","hhp_range","hhp_sd","hhs","hhsN_chg","hhsN_pct","hhs_range","hhs_sd","vac","vacN_chg",
                          "vac_range","vac_sd","hh_flag","hu_flag","hhp_flag","hhs_flag","vac_flag")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID26 v2.csv",row.names = FALSE )

write.csv(tract_sums,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_tract_sums_to_reg_id26.csv",row.names = FALSE)
