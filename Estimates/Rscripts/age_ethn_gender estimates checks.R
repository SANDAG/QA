#estimates

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

getwd()

#rm(demo_26)

ds_id=26

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo_26<-sqlQuery(channel,demo_sql)
odbcClose(channel)


#ds_id=24

#channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#demo_sql = getSQL("../Queries/age_ethn_gender.sql")
#demo_sql <- gsub("ds_id", ds_id,demo_sql)
#demo_26<-sqlQuery(channel,demo_sql)
#odbcClose(channel)


#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

demo_26<- demo_26[order(demo_26$geotype,demo_26$geozone,demo_26$yr_id),]

#demo_26$geozone<-revalue(demo_26$geozone, c("Los Penasquitos Canyon Preserve" = "Los Penas. Can. Pres."))
demo_26$geozone[demo_26$geotype =="region"]<- "Region"
demo_26$geozone <- gsub("\\*","",demo_26$geozone)
demo_26$geozone <- gsub("\\-","_",demo_26$geozone)
demo_26$geozone <- gsub("\\:","_",demo_26$geozone)


#recode age groups
demo_26$age_group_rc <- ifelse(demo_26$age_group_id==1|
                           demo_26$age_group_id==2|
                           demo_26$age_group_id==3|
                           demo_26$age_group_id==4,1,
                           ifelse(demo_26$age_group_id==5|
                                    demo_26$age_group_id==6|
                                    demo_26$age_group_id==7|
                                    demo_26$age_group_id==8|
                                    demo_26$age_group_id==9|
                                    demo_26$age_group_id==10,2,
                                  ifelse(demo_26$age_group_id==11|
                                           demo_26$age_group_id==12|
                                           demo_26$age_group_id==13|
                                           demo_26$age_group_id==14|
                                           demo_26$age_group_id==15,3,
                                         ifelse(demo_26$age_group_id==16|
                                                  demo_26$age_group_id==17|
                                                  demo_26$age_group_id==18|
                                                  demo_26$age_group_id==19|
                                                  demo_26$age_group_id==20,4,NA))))
                                                  
                                        
demo_26$age_group_name_rc<- ifelse(demo_26$age_group_rc==1,"<18",
                               ifelse(demo_26$age_group_rc==2,"18-44",
                                      ifelse(demo_26$age_group_rc==3,"45-64",
                                             ifelse(demo_26$age_group_rc==4,"65+",NA))))

head(demo_26)

#aggregate total counts by year for age, gender and ethnicity
demo_26_age<-aggregate(pop~age_group_name_rc+geotype+geozone+yr_id, data=demo_26, sum)
demo_26_gender<-aggregate(pop~sex+geotype+geozone+yr_id, data=demo_26, sum)
demo_26_ethn<-aggregate(pop~short_name+geotype+geozone+yr_id, data=demo_26, sum)

setnames(demo_26_age, old = "pop", new = "pop_age_26")
setnames(demo_26_ethn, old = "pop", new = "pop_ethn_26")
setnames(demo_26_gender, old = "pop", new = "pop_gender_26")


table(demo_26_age$geotype)

#creates file with pop totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=demo_26, sum)

tail(geozone_pop)

rm(demo_26)



ds_id=24
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo_24<-sqlQuery(channel,demo_sql)
odbcClose(channel)

demo_24<- demo_24[order(demo_24$geotype,demo_24$geozone,demo_24$yr_id),]
demo_24$geozone[demo_24$geotype =="region"]<- "Region"
demo_24$geozone <- gsub("\\*","",demo_24$geozone)
demo_24$geozone <- gsub("\\-","_",demo_24$geozone)
demo_24$geozone <- gsub("\\:","_",demo_24$geozone)


#recode age groups
demo_24$age_group_rc <- ifelse(demo_24$age_group_id==1|
                                 demo_24$age_group_id==2|
                                 demo_24$age_group_id==3|
                                 demo_24$age_group_id==4,1,
                               ifelse(demo_24$age_group_id==5|
                                        demo_24$age_group_id==6|
                                        demo_24$age_group_id==7|
                                        demo_24$age_group_id==8|
                                        demo_24$age_group_id==9|
                                        demo_24$age_group_id==10,2,
                                      ifelse(demo_24$age_group_id==11|
                                               demo_24$age_group_id==12|
                                               demo_24$age_group_id==13|
                                               demo_24$age_group_id==14|
                                               demo_24$age_group_id==15,3,
                                             ifelse(demo_24$age_group_id==16|
                                                      demo_24$age_group_id==17|
                                                      demo_24$age_group_id==18|
                                                      demo_24$age_group_id==19|
                                                      demo_24$age_group_id==20,4,NA))))


demo_24$age_group_name_rc<- ifelse(demo_24$age_group_rc==1,"<18",
                                   ifelse(demo_24$age_group_rc==2,"18-44",
                                          ifelse(demo_24$age_group_rc==3,"45-64",
                                                 ifelse(demo_24$age_group_rc==4,"65+",NA))))

head(demo_24)

xtabs()

#aggregate total counts by year for age, gender and ethnicity
demo_24_age<-aggregate(pop~age_group_name_rc+geotype+geozone+yr_id, data=demo_24, sum)
demo_24_gender<-aggregate(pop~sex+geotype+geozone+yr_id, data=demo_24, sum)
demo_24_ethn<-aggregate(pop~short_name+geotype+geozone+yr_id, data=demo_24, sum)

setnames(demo_24_age, old = "pop", new = "pop_age_24")
setnames(demo_24_ethn, old = "pop", new = "pop_ethn_24")
setnames(demo_24_gender, old = "pop", new = "pop_gender_24")


table(demo_24_age$geotype)

#creates file with pop totals by geozone and year
geozone_pop_24<-aggregate(pop~geotype+geozone+yr_id, data=demo_24, sum)

#remove unneeded dataframes after aggregation
rm(demo_24)

#merge id24 to id26
age_24_26 <- merge(demo_24_age, demo_26_age, by.x = c("yr_id","geozone","geotype","age_group_name_rc"), by.y = c("yr_id","geozone","geotype","age_group_name_rc"), all = TRUE)
ethn_24_26 <- merge(demo_24_ethn, demo_26_ethn, by.x = c("yr_id","geozone","geotype","short_name"), by.y = c("yr_id","geozone","geotype","short_name"), all = TRUE)
gender_24_26 <- merge(demo_24_gender, demo_26_gender, by.x = c("yr_id","geozone","geotype","sex"), by.y = c("yr_id","geozone","geotype","sex"), all = TRUE)

#remove unneeded dataframes after merge
rm(demo_24_age, demo_26_age,demo_24_ethn, demo_26_ethn,demo_24_gender, demo_26_gender)


age_24_26$pop_age_24 <- as.numeric(age_24_26$pop_age_24)
ethn_24_26$pop_ethn_24 <- as.numeric(ethn_24_26$pop_ethn_24)
gender_24_26$pop_gender_24 <- as.numeric(gender_24_26$pop_gender_24)
age_24_26$pop_age_26 <- as.numeric(age_24_26$pop_age_26)
ethn_24_26$pop_ethn_26 <- as.numeric(ethn_24_26$pop_ethn_26)
gender_24_26$pop_gender_26 <- as.numeric(gender_24_26$pop_gender_26)

#calculate percent of the total population, total change, percent change for age, gender and ethnicity from id24 to id26
age_24_26$age_numchg <- age_24_26$pop_age_26-age_24_26$pop_age_24  
ethn_24_26$ethn_numchg <- ethn_24_26$pop_ethn_26-ethn_24_26$pop_ethn_24  
gender_24_26$gender_numchg <- gender_24_26$pop_gender_26-gender_24_26$pop_gender_24  

age_24_26$age_pctchg <- (age_24_26$age_numchg/age_24_26$pop_age_24)*100 
age_24_26$age_pctchg <- round(age_24_26$age_pctchg,digits=2)
ethn_24_26$ethn_pctchg <- (ethn_24_26$ethn_numchg/ethn_24_26$pop_ethn_24)*100 
ethn_24_26$ethn_pctchg <- round(ethn_24_26$ethn_pctchg,digits=2)
gender_24_26$gender_pctchg <- (gender_24_26$gender_numchg/gender_24_26$pop_gender_24)*100 
gender_24_26$gender_pctchg <- round(gender_24_26$gender_pctchg,digits=2)

head(gender_24_26)

age_24_26$pct5up <- ifelse(age_24_26$age_pctchg>=5,1,0)
age_24_26$pct10up <- ifelse(age_24_26$age_pctchg>=10,1,0)
age_24_26$pct15up <- ifelse(age_24_26$age_pctchg>=15,1,0)
age_24_26$pct20up <- ifelse(age_24_26$age_pctchg>=20,1,0)
ethn_24_26$pct5up <- ifelse(ethn_24_26$ethn_pctchg>=5,1,0)
ethn_24_26$pct10up <- ifelse(ethn_24_26$ethn_pctchg>=10,1,0)
ethn_24_26$pct15up <- ifelse(ethn_24_26$ethn_pctchg>=15,1,0)
ethn_24_26$pct20up <- ifelse(ethn_24_26$ethn_pctchg>=20,1,0)
gender_24_26$pct5up <- ifelse(gender_24_26$gender_pctchg>=5,1,0)
gender_24_26$pct10up <- ifelse(gender_24_26$gender_pctchg>=10,1,0)
gender_24_26$pct15up <- ifelse(gender_24_26$gender_pctchg>=15,1,0)
gender_24_26$pct20up <- ifelse(gender_24_26$gender_pctchg>=20,1,0)


table(unique(ethn_24_26$geozone(ethn_24_26$pct5up)))
table(ethn_24_26$pct10up)
table(ethn_24_26$pct15up)
table(ethn_24_26$pct20up)

tapply(age_24_26$pct5up, age_24_26$geozone, FUN = function(x) length(unique(x)))

geozone_pop_24<-aggregate(pop~geotype+geozone+yr_id, data=demo_24, sum)

age_24_26$yes20 <- aggregate(pct20up~geotype+geozone, data=age_24_26, max)


table(gender_24_26$pct5up)
table(gender_24_26$pct5up)
table(gender_24_26$pct5up)
table(gender_24_26$pct5up)

#review data
table(age_24_26$pct20up)
table(age_test$pct10up)
head(age_test)
age_test <- subset(age_24_26, age_24_26$pct20up=="1" & age_24_26=="2016" & age_24_26$pop_age_24>100 & age_24_26$pop_age_26>100)
unique(age_test$geozone)
###########

####################
####################
####################

START here

#####################
#####################

demo_26_gender <- demo_26_gender[order(demo_26_gender$sex,demo_26_gender$geotype,demo_26_gender$geozone,demo_26_gender$yr_id),]
demo_26_gender$N_chg <- demo_26_gender$pop - lag(demo_26_gender$pop)
demo_26_gender$N_pct <- (demo_26_gender$N_chg / lag(dem_gender$pop))*100
dem_gender$N_pct<-round(dem_gender$N_pct,digits=2)
dem_gender$geozone_pop<-geozone_pop[match(paste(dem_gender$yr_id, dem_gender$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
dem_gender$pct_of_total<-(dem_gender$pop / dem_gender$geozone_pop)*100
dem_gender$pct_of_total<-round(dem_gender$pct_of_total,digits=2)
setnames(dem_gender, old=c("sex", "yr_id", "pop"),new=c("Gender", "Year", "Population"))
dem_gender$Gender[dem_gender$Gender=="F"]<- "Female"
dem_gender$Gender[dem_gender$Gender=="M"]<- "Male"

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



head(dem_ethn)
dem_ethn <- dem_ethn[order(dem_ethn$short_name,dem_ethn$geotype,dem_ethn$geozone,dem_ethn$yr_id),]
dem_ethn$N_chg <- dem_ethn$pop - lag(dem_ethn$pop)
dem_ethn$N_pct <- (dem_ethn$N_chg / lag(dem_ethn$pop))*100
dem_ethn$N_pct<-round(dem_ethn$N_pct,digits=2)
dem_ethn$geozone_pop<-geozone_pop[match(paste(dem_ethn$yr_id, dem_ethn$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
dem_ethn$pct_of_total<-(dem_ethn$pop / dem_ethn$geozone_pop)*100
dem_ethn$pct_of_total<-round(dem_ethn$pct_of_total,digits=2)
setnames(dem_ethn, old=c("short_name", "yr_id", "pop"),new=c("Ethnicity", "Year", "Population"))



dem_ag_test<-subset(dem_age, Year=="2016")

head(dem_ag_test)

#recode NA values for 2016 change
dem_age$N_pct[dem_age$N_chg == "NA"] <- 0
dem_age$N_pct[dem_age$N_pct == "NA"] <- 0
dem_age$pct_of_total[dem_age$pct_of_total == "NaN"] <- 0

dem_gender$N_chg[dem_gender$Year == "2016"] <- 0
dem_gender$N_pct[dem_gender$Year == "2016"] <- 0
dem_gender$N_pct[dem_gender$N_chg == "NA"] <- 0
dem_gender$N_pct[dem_gender$N_pct == "NA"] <- 0
dem_gender$pct_of_total[dem_gender$pct_of_total == "NaN"] <- 0

dem_ethn$N_chg[dem_ethn$Year == "2016"] <- 0
dem_ethn$N_pct[dem_ethn$yr_id == "2016"] <- 0
dem_ethn$N_pct[dem_ethn$N_chg == "NA"] <- 0
dem_ethn$N_pct[dem_ethn$N_pct == "NA"] <- 0
dem_ethn$N_pct[dem_ethn$N_pct == "Inf"] <- 0
dem_ethn$pct_of_total[dem_ethn$pct_of_total == "NaN"] <- 0



#create files for the region
dem_age_region = subset(dem_age,geotype=='region')
dem_gender_region = subset(dem_gender,geotype=='region')
dem_ethn_region = subset(dem_ethn,geotype=='region')

#create files for jurisdictions
dem_age_jurisdiction = subset(dem_age,geotype=='jurisdiction')
dem_gender_jurisdiction = subset(dem_gender,geotype=='jurisdiction')
dem_ethn_jurisdiction = subset(dem_ethn,geotype=='jurisdiction')

#create files for cpas
dem_age_cpa = subset(dem_age,geotype=='cpa')
dem_gender_cpa = subset(dem_gender,geotype=='cpa')
dem_ethn_cpa = subset(dem_ethn,geotype=='cpa')




write.csv(dem_age, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_age.csv" )
write.csv(dem_gender, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_gender.csv" )
write.csv(dem_ethn, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_ethn.csv" )

write.csv(dem_age_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_age_region.csv" )
write.csv(dem_gender_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_gender_region.csv" )
write.csv(dem_ethn_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_ethn_region.csv" )

write.csv(dem_age_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_age_jurisdiction.csv" )
write.csv(dem_gender_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_gender_jurisdiction.csv" )
write.csv(dem_ethn_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_ethn_jurisdiction.csv" )

write.csv(dem_age_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_age_cpa.csv" )
write.csv(dem_gender_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_gender_cpa.csv" )
write.csv(dem_ethn_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\dem_ethn_cpa.csv" )





