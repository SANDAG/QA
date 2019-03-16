#HH estimate script
#started 2/12/2019
#DOF doesn't report number of households
#fix ma by gender not working sql query -stored procedure requires geozone not just geotype- do we want to have someone create a script?
#why is there a column sfmu in est id 26 file?
#there is an issue with ma by tract - table doesn't have geotyp so it needs to be added - tracts with no pop aren't listed-are excluded
# why do I have two gqpop variables in the id 24 file
#ADD up each column by tract and see if totals match region


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
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
vac_sql = getSQL("../Queries/vacancy.sql")
vac_sql <- gsub("ds_id", ds_id,vac_sql)
vac_24<-sqlQuery(channel,vac_sql)
hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", ds_id,hhinc_sql)
hhinc_24<-sqlQuery(channel,hhinc_sql)
demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo_24<-sqlQuery(channel,demo_sql)
ma_jur_sql = getSQL("../Queries/median_age_jur.sql")
ma_jur_24<-sqlQuery(channel,ma_jur_sql)
ma_reg_sql = getSQL("../Queries/median_age_reg.sql")
ma_reg_24<-sqlQuery(channel,ma_reg_sql)
ma_cpa_sql = getSQL("../Queries/median_age_cpa.sql")
ma_cpa_24<-sqlQuery(channel,ma_cpa_sql)
ma_tract_sql = getSQL("../Queries/median_age_tract.sql")
ma_tract_24<-sqlQuery(channel,ma_tract_sql)
#ma_f_jur_sql = getSQL("../Queries/median_age_female_jur.sql")
#ma_f_jur_24<-sqlQuery(channel,ma_f_jur_sql)
#ma_m_jur_sql = getSQL("../Queries/median_age_male_jur.sql")
#ma_m_jur_24<-sqlQuery(channel,ma_m_jur_sql)
#ma_f_reg_sql = getSQL("../Queries/median_age_female_reg.sql")
#ma_f_reg_24<-sqlQuery(channel,ma_f_reg_sql)
#ma_m_reg_sql = getSQL("../Queries/median_age_male_reg.sql")
#ma_m_reg_24<-sqlQuery(channel,ma_m_reg_sql)
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
vac_sql = getSQL("../Queries/vacancy.sql")
vac_sql <- gsub("ds_id", ds_id,vac_sql)
vac<-sqlQuery(channel,vac_sql)
hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", ds_id,hhinc_sql)
hhinc<-sqlQuery(channel,hhinc_sql)
demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo<-sqlQuery(channel,demo_sql)
ma_jur_sql = getSQL("../Queries/median_age_jur_26.sql")
ma_jur<-sqlQuery(channel,ma_jur_sql)
ma_reg_sql = getSQL("../Queries/median_age_reg_26.sql")
ma_reg<-sqlQuery(channel,ma_reg_sql)
ma_jur_sql = getSQL("../Queries/median_age_jur_26.sql")
ma_jur<-sqlQuery(channel,ma_jur_sql)
ma_reg_sql = getSQL("../Queries/median_age_cpa_26.sql")
ma_reg<-sqlQuery(channel,ma_reg_sql)
ma_cpa_sql = getSQL("../Queries/median_age_cpa_26.sql")
ma_cpa<-sqlQuery(channel,ma_cpa_sql)
ma_tract_sql = getSQL("../Queries/median_age_tract_26.sql")
ma_tract<-sqlQuery(channel,ma_tract_sql)
#ma_f_jur_sql = getSQL("../Queries/median_age_female_jur_26.sql")
#ma_f_jur<-sqlQuery(channel,ma_f_jur_sql)
#ma_m_jur_sql = getSQL("../Queries/median_age_male_jur_26.sql")
#ma_m_jur<-sqlQuery(channel,ma_m_jur_sql)
#ma_f_reg_sql = getSQL("../Queries/median_age_female_reg_26.sql")
#ma_f_reg<-sqlQuery(channel,ma_f_reg_sql)
#ma_m_reg_sql = getSQL("../Queries/median_age_male_reg_26.sql")
#ma_m_reg<-sqlQuery(channel,ma_m_reg_sql)
odbcClose(channel)


#aggregate gq pop only - exclude hh pop
gq <-aggregate(pop~yr_id + geozone + geotype, subset(gq, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq, old="pop", new="gqpop")

gq_24 <-aggregate(pop~yr_id + geozone + geotype, subset(gq_24, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq_24, old="pop", new="gqpop_24")

#Delete rows with old structure type id - all unit numbers are zero because of a recode by EDAM
#vac <- vac [!(vac$structure_type_id==5 | vac$structure_type_id==6),]

#hu <- dcast(vac, yr_id + geotype + geozone ~ short_name, value.var="units")
#hutot <- aggregate(units~yr_id + geotype + geozone, data=vac, sum)
#setnames(hutot, old = "units", new = "hu")

hu_24 <- dcast(vac_24, yr_id + geotype + geozone ~ short_name, value.var="units")
hutot_24 <- aggregate(units~yr_id + geotype + geozone, data=vac_24, sum)

#merge sandag data and calculate the vacancy rate
#I think I can remove vac file since I have hu and hh
#clean up geozone for merge
vac$geozone <- gsub("\\*","",vac$geozone)
vac$geozone <- gsub("\\-","_",vac$geozone)
vac$geozone <- gsub("\\:","_",vac$geozone)
totpop$geozone <- gsub("\\*","",totpop$geozone)
totpop$geozone <- gsub("\\-","_",totpop$geozone)
totpop$geozone <- gsub("\\:","_",totpop$geozone)
gq$geozone <- gsub("\\*","",gq$geozone)
gq$geozone <- gsub("\\-","_",gq$geozone)
gq$geozone <- gsub("\\:","_",gq$geozone)
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)
#hutot$geozone <- gsub("\\*","",hutot$geozone)
#hutot$geozone <- gsub("\\-","_",hutot$geozone)
#hutot$geozone <- gsub("\\:","_",hutot$geozone)
#hu$geozone <- gsub("\\*","",hu$geozone)
#hu$geozone <- gsub("\\-","_",hu$geozone)
#hu$geozone <- gsub("\\:","_",hu$geozone)

vac_24$geozone <- gsub("\\*","",vac_24$geozone)
vac_24$geozone <- gsub("\\-","_",vac_24$geozone)
vac_24$geozone <- gsub("\\:","_",vac_24$geozone)
totpop_24$geozone <- gsub("\\*","",totpop_24$geozone)
totpop_24$geozone <- gsub("\\-","_",totpop_24$geozone)
totpop_24$geozone <- gsub("\\:","_",totpop_24$geozone)
gq_24$geozone <- gsub("\\*","",gq_24$geozone)
gq_24$geozone <- gsub("\\-","_",gq_24$geozone)
gq_24$geozone <- gsub("\\:","_",gq_24$geozone)
hh_24$geozone <- gsub("\\*","",hh_24$geozone)
hh_24$geozone <- gsub("\\-","_",hh_24$geozone)
hh_24$geozone <- gsub("\\:","_",hh_24$geozone)
hutot_24$geozone <- gsub("\\*","",hutot_24$geozone)
hutot_24$geozone <- gsub("\\-","_",hutot_24$geozone)
hutot_24$geozone <- gsub("\\:","_",hutot_24$geozone)
hu_24$geozone <- gsub("\\*","",hu_24$geozone)
hu_24$geozone <- gsub("\\-","_",hu_24$geozone)
hu_24$geozone <- gsub("\\:","_",hu_24$geozone)



head(totpop)

est <- merge(totpop, gq, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hh, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
#est <- merge(est, hutot, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
#est <- merge(est, hu, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)

setnames(est, old="units",new="hu")
head(est)

est_24 <- merge(totpop_24, gq_24, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est_24 <- merge(est_24, hh_24, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est_24 <- merge(est_24, hutot_24, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est_24 <- merge(est_24, hu_24, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)

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
est_24$gqpop <- as.numeric(est_24$gqpop)
est_24$households <- as.numeric(est_24$households)
est_24$hhp <- as.numeric(est_24$hhp)
est_24$units <- as.numeric(est_24$units.y)
est_24$mf <- as.numeric(est_24$mf)
est_24$mh <- as.numeric(est_24$mh)
est_24$sfmu <- as.numeric(est_24$sfmu)
est_24$sf <- as.numeric(est_24$sf)

head(est_24)

#levels(est$geozone) <- c(levels(est$geozone), "San Diego Region")
est$geozone[est$geotype=='region'] <- 'San Diego Region'
est_24$geozone[est_24$geotype=='region'] <- 'San Diego Region'

         
setnames(est_24, old=c("pop","gqpop_24","households","hhp","hhs","mf","mh","sfmu","sf","units"), new=c("pop_24","gqpop_24","households_24",
                                                                                                 "hhp_24","hhs_24","mf_24","mh_24",
                                                                                                 "sfa_24","sfd_24","hu_24"))

est$geozone <- gsub("^\\s+|\\s+$", "", est$geozone)
est_24$geozone <- gsub("^\\s+|\\s+$", "", est_24$geozone)

est_24_26 <- merge(est_24,est, by.x = c("yr_id","geozone"), by.y = c("yr_id", "geozone"), all=TRUE)

#confirm expected records are in dataframe
table(est_24_26$yr_id)
table(est_24_26$geozone)
table(est_24_26$geotype.x)
table(est_24_26$geotype.y)

##est_24_26$tot_pop_diff <- rowSums(est_24_26 [,c(est_24_26$pop_est, est_24_26$pop_est_24)], na.rm=TRUE)
##est_24_26$tot_pop_diff <- rowSums(est_24_26[,c(pop_est, pop_est_24)], na.rm=TRUE)

colnames(est_24_26)

#calculate number change
est_24_26$tot_pop_numchg <- est_24_26$pop-est_24_26$pop_24
est_24_26$hhp_numchg <- est_24_26$hhp-est_24_26$hhp_24
est_24_26$gqpop_numchg <- est_24_26$gqpop.y-est_24_26$gqpop_24
est_24_26$hh_numchg <- est_24_26$households-est_24_26$households_24
est_24_26$hu_numchg <- est_24_26$hu-est_24_26$hu_24
est_24_26$sfa_numchg <- est_24_26$sfa-est_24_26$sfa_24
est_24_26$sfd_numchg <- est_24_26$sfd-est_24_26$sfd_24
est_24_26$mf_numchg <- est_24_26$mf-est_24_26$mf_24
est_24_26$mh_numchg <- est_24_26$mh-est_24_26$mh_24
est_24_26$hhs_numchg <- est_24_26$hhs-est_24_26$hhs_24

head(subset(est_24_26, est_24_26$geotype.x=="jurisdiction"), 8)

#calculate percent change
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

#wait until EDAM fixes the units by type names
#add sfd and sfa

##############
###############
est_24_26$mf_pctchg <- (est_24_26$mf_numchg/est_24_26$mf_24)*100
est_24_26$mf_pctchg <- round(est_24_26$mf_pctchg,digits=2)
est_24_26$mh_pctchg <- (est_24_26$mh_numchg/est_24_26$mh_24)*100
est_24_26$mh_pctchg <- round(est_24_26$mh_pctchg,digits=2)
est_24_26$hhs_pctchg <- (est_24_26$hhs_numchg/est_24_26$hhs_24)*100
est_24_26$hhs_pctchg <- round(est_24_26$hhs_pctchg,digits=2)


est_24_26 <- est_24_26[order(est_24_26$geozone, est_24_26$yr_id),]

write.csv(est_24_26,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Est 2016 to 2018 differences.csv" )


head(est)
#two units variables so delete one
#est$units <- NULL

#calculate change in ID 26 data
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
#set Inf values to NA for later calculations
est$hhpN_pct[is.infinite(est$hhpN_pct)] <-NA 
est$hhsN_pct[is.infinite(est$hhsN_pct)] <-NA 
est$hhN_pct[is.infinite(est$hhN_pct)] <-NA 
est$huN_pct[is.infinite(est$huN_pct)] <-NA 

#subset est file for jurisdiction and region
est_jur <- subset(est, est$geotype=="jurisdiction")
est_reg <- subset(est, est$geotype=="region")


#############################
#############################
#keep only tract geographies
#############################
#############################

est <- subset(est, est$geotype=="tract")
table(est$geotype)

#calculate the mean and sd for hh variables
est_means <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct)~yr_id,data=est,mean,na.rm=TRUE)
est_sd <- aggregate(cbind(hhpN_pct,hhsN_pct,huN_pct,hhN_pct)~yr_id,data=est,sd,na.rm=TRUE)

head(est_means$hhpN_pct,9)
head(est_sd$hhpN_pct,9)


#match in stats to est file
est$hhp_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), 2]
est$hhs_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), 3]
est$hu_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), 4]
est$hh_means<-est_means[match(paste(est$yr_id), paste(est_means$yr_id)), 5]

est$hhp_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), 2]
est$hhs_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), 3]
est$hu_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), 4]
est$hh_sd<-est_sd[match(paste(est$yr_id), paste(est_sd$yr_id)), 5]

est_3sd <- merge(est_means, est_sd, by.x = "yr_id", by.y = "yr_id",all = TRUE)
est_3sd$hhp_3sd <- est_3sd$hhpN_pct.x+(3*est_3sd$hhpN_pct.y)
est_3sd$hhs_3sd <- est_3sd$hhsN_pct.x+(3*est_3sd$hhsN_pct.y)
est_3sd$hu_3sd <- est_3sd$huN_pct.x+(3*est_3sd$huN_pct.y)
est_3sd$hh_3sd <- est_3sd$hhN_pct.x+(3*est_3sd$hhN_pct.y)

est_3sd$hhp_3sd_minus <- est_3sd$hhpN_pct.x-(3*est_3sd$hhpN_pct.y)
est_3sd$hhs_3sd_minus <- est_3sd$hhsN_pct.x-(3*est_3sd$hhsN_pct.y)
est_3sd$hu_3sd_minus <- est_3sd$huN_pct.x-(3*est_3sd$huN_pct.y)
est_3sd$hh_3sd_minus <- est_3sd$hhN_pct.x-(3*est_3sd$hhN_pct.y)

est$hhp_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 10]
est$hhs_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 11]
est$hu_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 12]
est$hh_3sd<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 13]

est$hhp_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 14]
est$hhs_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 15]
est$hu_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 16]
est$hh_3sd_minus<-est_3sd[match(paste(est$yr_id), paste(est_3sd$yr_id)), 17]

head(est,12)
colnames(est_3sd)

est$hhp_flag<-NULL 
est$hhs_flag<-NULL
est$hu_flag <-NULL
est$hh_flag <-NULL

class(est$hh_flag)

est$hhp_flag[est$hhpN_pct>=est$hhp_3sd | est$hhpN_pct<=est$hhp_3sd_minus] <-1 
est$hhs_flag[est$hhsN_pct>=est$hhs_3sd | est$hhsN_pct<=est$hhs_3sd_minus] <-1 
est$hu_flag[est$huN_pct>=est$hu_3sd | est$huN_pct<=est$hu_3sd_minus] <-1 
est$hh_flag[est$hhN_pct>=est$hh_3sd | est$hhN_pct<=est$hh_3sd_minus] <-1 
table(est$hhp_flag)
table(est$hhs_fl)
table(est$hu_flag)
table(est$hh_flag)



head(est_3sd,9)
vacancy_cpa<- merge(select(vacancy_cpa, yr_id, year, geotype, geozone, rate14, reg14), (select (vacancy13_cpa, yr_id, year, geotype, geozone, rate13, reg13)), by.a=c("yr_id","geotype", "geozone"), by.b=c("yr_id","geotype","geozone"),all = TRUE)


head(est)

est_outliers <- subset(est, est$hhp_flag==1 | est$hhs_flag==1 | est$hu_flag==1 | est$hh_flag==1)

unique(est_outliers$geozone)


write.csv(est_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_jur_ID26.csv",row.names = FALSE )
write.csv(est_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_reg_ID26.csv",row.names = FALSE )
write.csv(est_outliers, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID26.csv",row.names = FALSE )
write.csv(est, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variable_tract_ID26.csv",row.names = FALSE )
