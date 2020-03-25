#HH estimate script
#calculates differences across datasource ids and within current vintage and outputs separate files
#KT PS - I don't know if we need to check unoccupied. PS there isn't this number in DOF estimates is there? 
#############
#############
#updated to datasource_id 27 on 4/8/19

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
odbcClose(channel)

ds_id=27

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

est_24_27 <- merge(est_24,est, by.x = c("yr_id","geozone","geotype"), by.y = c("yr_id", "geozone","geotype"), all=TRUE)

#confirm expected records are in dataframe
table(est_24_27$yr_id)
table(est_24_27$geozone)
table(est_24_27$geotype)

#calculate number change
est_24_27$tot_pop_numchg <- est_24_27$pop-est_24_27$pop_24
est_24_27$hhp_numchg <- est_24_27$hhp-est_24_27$hhp_24
est_24_27$gqpop_numchg <- est_24_27$gqpop-est_24_27$gqpop_24
est_24_27$hh_numchg <- est_24_27$households-est_24_27$households_24
est_24_27$hu_numchg <- est_24_27$hu-est_24_27$hu_24
#est_24_27$sfa_numchg <- est_24_27$sfa-est_24_27$sfa_24
#est_24_27$sfd_numchg <- est_24_27$sfd-est_24_27$sfd_24
#est_24_27$mf_numchg <- est_24_27$mf-est_24_27$mf_24
#est_24_27$mh_numchg <- est_24_27$mh-est_24_27$mh_24
est_24_27$hhs_numchg <- est_24_27$hhs-est_24_27$hhs_24
est_24_27$vac_numchg <- est_24_27$vac-est_24_27$vac_24

head(subset(est_24_27, est_24_27$geotype.x=="jurisdiction"), 8)

#calculate percent change
#calc for percent change for vac is based on rate so different
est_24_27$tot_pop_pctchg <- (est_24_27$tot_pop_numchg/est_24_27$pop_24)*100
est_24_27$tot_pop_pctchg <- round(est_24_27$tot_pop_pctchg,digits=2)
est_24_27$hhp_pctchg <- (est_24_27$hhp_numchg/est_24_27$hhp_24)*100
est_24_27$hhp_pctchg <- round(est_24_27$hhp_pctchg,digits=2)
est_24_27$gqpop_pctchg <- (est_24_27$gqpop_numchg/est_24_27$gqpop_24)*100
est_24_27$gqpop_pctchg <- round(est_24_27$gqpop_pctchg,digits=2)
est_24_27$hh_pctchg <- (est_24_27$hh_numchg/est_24_27$households_24)*100
est_24_27$hh_pctchg <- round(est_24_27$hh_pctchg,digits=2)
est_24_27$hu_pctchg <- (est_24_27$hu_numchg/est_24_27$hu_24)*100
est_24_27$hu_pctchg <- round(est_24_27$hu_pctchg,digits=2)

#wait until EDAM changes the values for the units by type names
#add sfd and sfa

##############
###############
# est_24_27$mf_pctchg <- (est_24_27$mf_numchg/est_24_27$mf_24)*100
# est_24_27$mf_pctchg <- round(est_24_27$mf_pctchg,digits=2)
# est_24_27$mh_pctchg <- (est_24_27$mh_numchg/est_24_27$mh_24)*100
# est_24_27$mh_pctchg <- round(est_24_27$mh_pctchg,digits=2)
est_24_27$hhs_pctchg <- (est_24_27$hhs_numchg/est_24_27$hhs_24)*100
est_24_27$hhs_pctchg <- round(est_24_27$hhs_pctchg,digits=2)


est_24_27 <- est_24_27[order(est_24_27$geozone, est_24_27$yr_id),]

#saved from datasource_id 26
#write.csv(est_24_26,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Est 2016 to 2018 differences.csv" )

write.csv(est_24_27,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Est 2016 to 2018 differences id24 to id27.csv" )


#calculate change in ID 27 data
#percent change for vac is difference of rates across vintages
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

#KT or PS - I deleted the chunk of text with sd and outliers from old version - rework these flag variables to identify >5%.

#create flag variables to identify outliers
est$hhp_flag[est$hhpN_pct>=est$hhp_3sd | est$hhpN_pct<=est$hhp_3sd_minus] <-1 
est$hhs_flag[est$hhsN_pct>=est$hhs_3sd | est$hhsN_pct<=est$hhs_3sd_minus] <-1
est$hh_flag[est$hhN_pct>=est$hh_3sd | est$hhN_pct<=est$hh_3sd_minus] <-1
est$hu_flag[est$huN_pct>=est$hu_3sd | est$huN_pct<=est$hu_3sd_minus] <-1
est$vac_flag[est$vacN_chg>=est$vac_3sd | est$vacN_chg<=est$vac_3sd_minus] <-1

#check flag results
table(est$hhp_flag)

#save object with flag = 1
hh_outliers <- subset(est, est$hhp_flag==1 | est$hhs_flag==1 | est$hh_flag==1 | est$hu_flag==1 | est$vac_flag==1)

#create a variable to indicate all years for tracts with outliers  
hh_outlier_all_years <- subset(est, (est$geozone %in% hh_outliers$geozone & hh$outlier==1))
##hh_outlier_all_years <- subset(est, (est$geozone %in% hh_outliers$geozone ##& hh$outlier==1))
                                     
                                     
table(hh_outliers$geozone)
row_number(hh_outliers$geozone)
unique(hh_outlier_all_years$geozone)

sum(est$gqpop, na.rm = TRUE)


#PS KT - the output files will need to be reworked somewhat. 
#See M:\Technical Services\QA Documents\Projects\Estimates\Results\01_Estimates 2018 Analysis - Within Vintage id27.xlsx worksheet Jurisdiction details
#M:\Technical Services\QA Documents\Projects\Estimates\Results\02_Estimates 2018 Analysis - Cross Vintage id24 to id27.xlsx 1st worksheet
#rename flags specific record has issue, geozone has issue  

head(est,15)

write.csv(est_jur, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_jur_ID27 2.csv",row.names = FALSE )
write.csv(est_reg, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variables_reg_ID27 2.csv",row.names = FALSE )
write.csv(est_outliers[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hh_sd","hu","huN_chg","huN_pct","hu_range","hu_sd",
                          "hhp","hhpN_chg","hhpN_pct","hhp_range","hhp_sd","hhs","hhsN_chg","hhsN_pct","hhs_range","hhs_sd","vac_rate","vacN_chg","vacN_pct",
                          "vac_range","vac_sd","hh_flag","hu_flag","hhp_flag","hhs_flag","vac_flag")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID27_sd 2.csv",row.names = FALSE )
write.csv(est[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hu","huN_chg","huN_pct","hu_range",
                 "hhp","hhpN_chg","hhpN_pct","hhp_range","hhs","hhsN_chg","hhsN_pct","hhs_range","vac_rate","vacN_chg","vacN_pct",
                 "vac_range","hh_flag","hh_flag_max","hu_flag","hu_flag_max","hhp_flag","hhp_flag_max","hhs_flag","hhs_flag_max","vac_flag","vac_flag_max")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_variable_tract_ID27 2.csv",row.names = FALSE )
write.csv(est[,c("yr_id","geozone","pop","gqpop","households","hhN_chg","hhN_pct","hh_range","hu","huN_chg","huN_pct","hu_range",
                          "hhp","hhpN_chg","hhpN_pct","hhp_range","hhs","hhsN_chg","hhsN_pct","hhs_range","vac_rate","vacN_chg","vacN_pct",
                          "vac_range","hh_flag","hu_flag","hhp_flag","hhs_flag","vac_flag")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\hh_outliers_tract_ID27 2.csv",row.names = FALSE )
