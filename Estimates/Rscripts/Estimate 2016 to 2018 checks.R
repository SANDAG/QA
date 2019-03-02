#HH estimate script
#started 2/12/2019
#DOF doesn't report number of households
#fix ma by gender not working sql query -stored procedure requires geozone not just geotype- do we want to have someone create a script?
#why is there a column sfmu in est id 26 file?
#there is an issue with ma by tract - table doesn't have geotyp so it needs to be added - tracts with no pop aren't listed-are excluded
# why do I have two gqpop variables in the id 24 file


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
vac <- vac [!(vac$structure_type_id==5 | vac$structure_type_id==6),]

hu <- dcast(vac, yr_id + geotype + geozone ~ short_name, value.var="units")
hutot <- aggregate(units~yr_id + geotype + geozone, data=vac, sum)
setnames(hutot, old = "units", new = "hu")

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
hutot$geozone <- gsub("\\*","",hutot$geozone)
hutot$geozone <- gsub("\\-","_",hutot$geozone)
hutot$geozone <- gsub("\\:","_",hutot$geozone)
hu$geozone <- gsub("\\*","",hu$geozone)
hu$geozone <- gsub("\\-","_",hu$geozone)
hu$geozone <- gsub("\\:","_",hu$geozone)

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
est <- merge(est, hutot, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hu, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)

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
est$mf <- as.numeric(est$mf)
est$mh <- as.numeric(est$mh)
est$sfmu <- as.numeric(est$sf)
est$sf <- as.numeric(est$sf)

est_24$pop <- as.numeric(est_24$pop)
est_24$gqpop <- as.numeric(est_24$gqpop)
est_24$households <- as.numeric(est_24$households)
est_24$hhp <- as.numeric(est_24$hhp)
est_24$units <- as.numeric(est_24$units)
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


table(est_test$tot_pop_pctchg)
table(est_test$tot_pop_pctchg)

plot(est_test$yr_id, est_test$gqpop_numchg, "p" )


est_24_26 <- est_24_26[order(est_24_26$geozone, est_24_26$yr_id),]

write.csv(est_24_26,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\Data Files\\Est 2016 to 2018 differences.csv" )

#calculate standard deviation - is this useful?
by(est_24_26$pop,est_24_26$yr_id, sd, na.rm=TRUE)
by(est_24_26$pop_24,est_24_26$yr_id, sd, na.rm=TRUE)


rm(list = ls()[!ls() %in% c("demo_24", "demo", "hhinc_24", "hhinc")])

#merge demo

demo <- subset(demo, demo$geotype!="tract")
demo_24 <- subset(demo_24, demo_24$geotype!="tract")
demo_24_26 <- merge(demo_24,demo, by.x = c("yr_id","geozone"), by.y = c("yr_id", "geozone"), all=TRUE)

head(demo_24_26)

table(demo$geotype)












#######temporary
est_test <- est_24_26 [!(est_24_26$yr_id=='2018' | est_24_26$yr_id=='2017'),]

look_na <- (subset(est_test, (is.na(est_test$pop_est_24 | est_test$pop_est))))
unique(look_na$geozone)
unique(look_na$geotype.y)

est_test <- subset (est_test, (!is.na(est_test$pop_est)))
est_test <- subset (est_test, (!is.na(est_test$pop_est_24)))

est_test$tot_pop_diff <- est_test$pop_est-est_test$pop_est_24
est_test$hhp_diff <- est_test$hhp_est-est_test$hhp_est_24
est_test$gqpop_diff <- est_test$gqpop_est-est_test$gqpop_est_24
est_test$hu_diff <- est_test$hu_est-est_test$hu_est_24
est_test$sfa_diff <- est_test$sfa_est-est_test$sfa_est_24
est_test$sfd_diff <- est_test$sfd_est-est_test$sfd_est_24
est_test$mf_diff <- est_test$mf_est-est_test$mf_est_24
est_test$mh_diff <- est_test$mh_est-est_test$mh_est_24
est_test$hhs_diff <- est_test$hhs_est-est_test$hhs_est_24

est_test$tot_pop_pctchg <- (est_test$tot_pop_diff/est_test$pop_est_24)*100
est_test$tot_pop_pctchg <- round(est_test$tot_pop_pctchg,digits=2)
table(est_test$tot_pop_pctchg)

#############

