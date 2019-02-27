#HH estimate script
#started 2/12/2019
#DOF doesn't report number of households
#fix SQL code to bring in  est for id26 - what I have isn't working 

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
ma_f_jur_sql = getSQL("../Queries/median_age_female_jur.sql")
ma_f_jur_24<-sqlQuery(channel,ma_f_jur_sql)
ma_m_jur_sql = getSQL("../Queries/median_age_male_jur.sql")
ma_m_jur_24<-sqlQuery(channel,ma_m_jur_sql)
ma_f_reg_sql = getSQL("../Queries/median_age_female_reg.sql")
ma_f_reg_24<-sqlQuery(channel,ma_f_reg_sql)
ma_m_reg_sql = getSQL("../Queries/median_age_male_reg.sql")
ma_m_reg_24<-sqlQuery(channel,ma_m_reg_sql)
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
totpop<-sqlQuery(channel,totpop_sql)
vac_sql = getSQL("../Queries/vacancy.sql")
vac_sql <- gsub("ds_id", ds_id,vac_sql)
vac<-sqlQuery(channel,vac_sql)
hhinc_sql = getSQL("../Queries/hhinc.sql")
hhinc_sql <- gsub("ds_id", ds_id,hhinc_sql)
hhinc<-sqlQuery(channel,hhinc_sql)
demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo<-sqlQuery(channel,demo_sql)
ma_jur_sql = getSQL("../Queries/median_age_jur.sql")
ma_jur<-sqlQuery(channel,ma_jur_sql)
ma_reg_sql = getSQL("../Queries/median_age_reg.sql")
ma_reg<-sqlQuery(channel,ma_reg_sql)
ma_f_jur_sql = getSQL("../Queries/median_age_female_jur.sql")
ma_f_jur<-sqlQuery(channel,ma_f_jur_sql)
ma_m_jur_sql = getSQL("../Queries/median_age_male_jur.sql")
ma_m_jur<-sqlQuery(channel,ma_m_jur_sql)
ma_f_reg_sql = getSQL("../Queries/median_age_female_reg.sql")
ma_f_reg<-sqlQuery(channel,ma_f_reg_sql)
ma_m_reg_sql = getSQL("../Queries/median_age_male_reg.sql")
ma_m_reg<-sqlQuery(channel,ma_m_reg_sql)
odbcClose(channel)


#aggregate gq pop only - exclude hh pop
gq <-aggregate(pop~yr_id + geozone + geotype, subset(gq, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq, old="pop", new="gqpop")

gq_24 <-aggregate(pop~yr_id + geozone + geotype, subset(gq_24, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq, old="pop", new="gqpop_24")

hu <- dcast(vac, yr_id + geotype + geozone ~ short_name, value.var="units")
hutot <- aggregate(units~yr_id + geotype + geozone, data=vac, sum)

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



table(vac$yr_id)
#fix ma_jur ma_reg - no data for 2017 or 2018

est <- merge(totpop, gq, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hh, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hutot, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hu, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)

est <- subset(est, geotype!="cpa")

#change integer to numeric type
est$pop <- as.numeric(est$pop)
est$gqpop <- as.numeric(est$gqpop)
est$households <- as.numeric(est$households)
est$hhp <- as.numeric(est$hhp)
est$units <- as.numeric(est$units)
est$mf <- as.numeric(est$mf)
est$mh <- as.numeric(est$mh)
est$sfa <- as.numeric(est$sfa)
est$sfd <- as.numeric(est$sfd)

#levels(est$geozone) <- c(levels(est$geozone), "San Diego Region")
est$geozone[est$geotype=='region'] <- 'San Diego Region'

#################
#dof to estimate checkS
#################

dof<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Estimates\\Data Files\\DOF\\E-5_DOF_formatted.csv')

#rename first column to get rid of strange character
setnames(dof, 1, "Geography") 

dof$Geography <- gsub("\\:","_",dof$Geography)

#change column type from character to numeric - loop doesn't work
#type2num <-c("Total","Household","Group.Quarters","Housing.units","Single.Detached","Single.Attached","Two.to.Four","Five.Plus","Mobile.Homes","Occupied","Vacancy.Rate")
#for(i in type2num) { 
#dof$type2num[i] <- as.numeric(gsub(",", "", dof$type2num[i]))
#}

#strip commas and change type to numeric
dof$Total <- as.numeric(gsub(",", "", dof$Total))
dof$Household<-as.numeric(gsub(",", "", dof$Household))
dof$Group.Quarters<-as.numeric(gsub(",", "", dof$Group.Quarters))
dof$Total.1<-as.numeric(gsub(",", "", dof$Total.1))
dof$Single.Detached<-as.numeric(gsub(",", "", dof$Single.Detached))
dof$Single.Attached<-as.numeric(gsub(",", "", dof$Single.Attached))
dof$Two.to.Four<-as.numeric(gsub(",", "", dof$Two.to.Four))
dof$Five.Plus<-as.numeric(gsub(",", "", dof$Five.Plus))
dof$Mobile.Homes <- as.numeric(gsub(",", "", dof$Mobile.Homes))
dof$Occupied <- as.numeric(gsub(",", "", dof$Occupied))
dof$Vacancy.Rate <- as.numeric(substr(dof$Vacancy.Rate,0,nchar(dof$Vacancy.Rate)-1))

any(is.na(dof$Total))

#confirm that housing unit type add to Housing.units
dof$hu_rc<-dof$Single.Attached+dof$Single.Detached+dof$Two.to.Four+dof$Five.Plus+dof$Mobile.Homes
dof$hu_diff_rc <- dof$Total.1-dof$hu_rc
dof$hu_diff_rc

#create multifamily units by adding 2-4 and 5+ columns
dof$mf_dof <- dof$Two.to.Four+dof$Five.Plus
head(dof)

#rename dof columns before merge
setnames(dof, old=c("Total","Household","Group.Quarters","Total.1","Single.Detached","Single.Attached","Mobile.Homes","Occupied","Vacancy.Rate",
                    "Persons.per.Household", "year"), new=c("pop_dof","hhp_dof","gqpop_dof","hu_dof","sfd_dof","sfa_dof","mh_dof","occupied_dof",
                    "vac_dof","hhs_dof","yr_id"))
         
setnames(est, old=c("pop","gqpop","households","hhp","hhs","mf","mh","sfa","sfd","units"), new=c("pop_est","gqpop_est","households_est",
                                                                                         "hhp_est","hhs_est","mf_est","mh_est","sfa_est","sfd_est","hu_est"))


est$geozone <- gsub("^\\s+|\\s+$", "", est$geozone)
dof$Geography <- gsub("^\\s+|\\s+$", "", dof$Geography)
dof$Geography <- gsub('"', "", dof$Geography)

#rename column values
dof$Geography[dof$Geography=="Balance Of County"]<- "Unincorporated"
dof$Geography[dof$Geography=="County Total"]<- "San Diego Region"
dof<-dof[!dof$Geography=="Incorporated",]

#merge dof and estimates for comparison
dof2est <- merge(dof,est, by.x = c("yr_id","Geography"), by.y = c("yr_id", "geozone"), all=TRUE)

#get file for DM training
#change id to 24 and est$sfa to est$sfmu and est$sfd to est$sf 
#dmfile <- dof2est[dof2est$yr_id=="2010" | dof2est$yr_id=="2015" | dof2est$yr_id=="2016",]
#dmfile <- select(dmfile,yr_id,Geography,pop_dof,hhp_dof,gqpop_dof,hu_dof,mh_dof,occupied_dof,hhs_dof,
#                  pop_est,hhp_est,gqpop_est,mh_est,hhs_est)
#setnames(dmfile, old = c("pop_dof","hhp_dof","gqpop_dof","hu_dof","mh_dof","occupied_dof","hhs_dof",
#                        "pop_est","hhp_est","gqpop_est","mh_est","hhs_est"), new = c("pop_1","hhp_1","gqpop_1","hu_1",
#                        "mh_1","occupied_1","hhs_1","pop_2","hhp_2","gqpop_2","mh_2","hhs_2"))
#write.csv(dmfile, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\Data Files\\dmfile.csv")

table(dof2est$yr_id)
dof2est$tot_pop_diff <- dof2est$pop_dof-dof2est$pop_est
dof2est$hhp_diff <- dof2est$hhp_dof-dof2est$hhp_est
dof2est$gqpop_diff <- dof2est$gqpop_dof-dof2est$gqpop_est
dof2est$hu_diff <- dof2est$hu_dof-dof2est$hu_est
dof2est$sfa_diff <- dof2est$sfa_dof-dof2est$sfa_est
dof2est$sfd_diff <- dof2est$sfd_dof-dof2est$sfd_est
dof2est$mf_diff <- dof2est$mf_dof-dof2est$mf_est
dof2est$mh_diff <- dof2est$mh_dof-dof2est$mh_est
dof2est$hhs_diff <- dof2est$hhs_dof-dof2est$hhs_est

head(dof2est,8)
#dof2est_2018 <- dof2est[dof2est$yr_id==2018,]
#head(dof2est_2018,8)

dof2est <- dof2est[order(dof2est$Geography, dof2est$yr_id),]

write.csv(dof2est,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\Data Files\\DOF differences.csv" )

#calculate standard deviation - is this useful?
by(dof2est$pop_dof,dof$Geography, sd )


by(dof2est_2018$pop_dof,dof2est_2018$Geography, sum)

by(dof2est_2018$pop_est,dof2est_2018$Geography, sum)




head(est,10)
