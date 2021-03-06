#CPA names change and the CPAs included change from SR13 to SR14 so there will be an issue with matching


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "gtable")

pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
dem_sql = getSQL("../Queries/age_ethn_gender_13.sql")

#############
#Need help from Anne or Nick to fix
#dem<-sqlQuery(channel,dem_sql)
#odbcClose(channel)


#write.csv(dem, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\dem_sql13",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
#############

dem<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\dem_sql_13.csv")

#rename first column
names(dem) [1]<-"yr_id"

#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

dem<- dem[order(dem$geotype,dem$geozone,dem$yr_id),]

#The code below makes fixes in SR 14 - the values are different in SR 13 so
#dem$geozone<-revalue(dem$geozone, c("Los Penasquitos Canyon Preserve" = "Los Penas. Can. Pres."))
dem$geozone[dem$geotype =="region"]<- "Region"
dem$geozone <- gsub("\\*","",dem$geozone)
dem$geozone <- gsub("\\-","_",dem$geozone)
dem$geozone <- gsub("\\:","_",dem$geozone)

colnames(dem)
#recode age groups
dem$age_group_rc <- ifelse(dem$age_group_id==1|
                           dem$age_group_id==2|
                           dem$age_group_id==3|
                           dem$age_group_id==4,1,
                           ifelse(dem$age_group_id==5|
                                    dem$age_group_id==6|
                                    dem$age_group_id==7|
                                    dem$age_group_id==8|
                                    dem$age_group_id==9|
                                    dem$age_group_id==10,2,
                                  ifelse(dem$age_group_id==11|
                                           dem$age_group_id==12|
                                           dem$age_group_id==13|
                                           dem$age_group_id==14|
                                           dem$age_group_id==15,3,
                                         ifelse(dem$age_group_id==16|
                                                  dem$age_group_id==17|
                                                  dem$age_group_id==18|
                                                  dem$age_group_id==19|
                                                  dem$age_group_id==20,4,NA))))
                                                  
                                        
dem$age_group_name_rc<- ifelse(dem$age_group_rc==1,"<18",
                               ifelse(dem$age_group_rc==2,"18-44",
                                      ifelse(dem$age_group_rc==3,"45-64",
                                             ifelse(dem$age_group_rc==4,"65+",NA))))

head(dem)

#aggregate total counts by year for age, gender and ethnicity
dem_age<-aggregate(pop~age_group_name_rc+geotype+geozone+yr_id, data=dem, sum)
dem_gender<-aggregate(pop~sex+geotype+geozone+yr_id, data=dem, sum)
dem_ethn<-aggregate(pop~short_name+geotype+geozone+yr_id, data=dem, sum)

#creates file with pop totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=dem, sum)

tail(geozone_pop)

#calculate percent of the total population, total change, percent change by year for age, gender and ethnicity

head(dem_age)
dem_age <- dem_age[order(dem_age$age_group_name_rc,dem_age$geotype,dem_age$geozone,dem_age$yr_id),]
dem_age$N_chg <- dem_age$pop - lag(dem_age$pop)
dem_age$N_pct <- (dem_age$N_chg / lag(dem_age$pop))*100
dem_age$N_pct<-round(dem_age$N_pct,digits=2)
dem_age$geozone_pop<-geozone_pop[match(paste(dem_age$yr_id, dem_age$geozone),paste(geozone_pop$yr_id, geozone_pop$geozone)),4]
dem_age$pct_of_total<-(dem_age$pop / dem_age$geozone_pop)*100
dem_age$pct_of_total<-round(dem_age$pct_of_total,digits=2)
setnames(dem_age, old=c("age_group_name_rc", "yr_id", "pop"),new=c("Age_Group", "Year", "Population"))


head(dem_gender)
dem_gender <- dem_gender[order(dem_gender$sex,dem_gender$geotype,dem_gender$geozone,dem_gender$yr_id),]
dem_gender$N_chg <- dem_gender$pop - lag(dem_gender$pop)
dem_gender$N_pct <- (dem_gender$N_chg / lag(dem_gender$pop))*100
dem_gender$N_pct<-round(dem_gender$N_pct,digits=2)
dem_gender$geozone_pop<-geozone_pop[match(paste(dem_gender$yr_id, dem_gender$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
dem_gender$pct_of_total<-(dem_gender$pop / dem_gender$geozone_pop)*100
dem_gender$pct_of_total<-round(dem_gender$pct_of_total,digits=2)
setnames(dem_gender, old=c("sex", "yr_id", "pop"),new=c("Gender", "Year", "Population"))
dem_gender$Gender[dem_gender$Gender=="F"]<- "Female"
dem_gender$Gender[dem_gender$Gender=="M"]<- "Male"


head(dem_ethn)
dem_ethn <- dem_ethn[order(dem_ethn$short_name,dem_ethn$geotype,dem_ethn$geozone,dem_ethn$yr_id),]
dem_ethn$N_chg <- dem_ethn$pop - lag(dem_ethn$pop)
dem_ethn$N_pct <- (dem_ethn$N_chg / lag(dem_ethn$pop))*100
dem_ethn$N_pct<-round(dem_ethn$N_pct,digits=2)
dem_ethn$geozone_pop<-geozone_pop[match(paste(dem_ethn$yr_id, dem_ethn$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
dem_ethn$pct_of_total<-(dem_ethn$pop / dem_ethn$geozone_pop)*100
dem_ethn$pct_of_total<-round(dem_ethn$pct_of_total,digits=2)
setnames(dem_ethn, old=c("short_name", "yr_id", "pop"),new=c("Ethnicity", "Year", "Population"))


#recode wrong values for 2012 because of lag calculation from 2050-2016 records
dem_age$N_chg[dem_age$Year == "2012"] <- 0
dem_age$N_pct[dem_age$Year == "2012"] <- 0


#recode NA values for 2012 change
dem_age$N_pct[dem_age$N_chg == "NA"] <- 0
dem_age$N_pct[dem_age$N_pct == "NA"] <- 0
dem_age$pct_of_total[dem_age$pct_of_total == "NaN"] <- 0

dem_gender$N_chg[dem_gender$Year == "2012"] <- 0
dem_gender$N_pct[dem_gender$Year == "2012"] <- 0
dem_gender$N_pct[dem_gender$N_chg == "NA"] <- 0
dem_gender$N_pct[dem_gender$N_pct == "NA"] <- 0
dem_gender$pct_of_total[dem_gender$pct_of_total == "NaN"] <- 0

dem_ethn$N_chg[dem_ethn$Year == "2012"] <- 0
dem_ethn$N_pct[dem_ethn$yr_id == "2012"] <- 0
dem_ethn$N_pct[dem_ethn$N_chg == "NA"] <- 0
dem_ethn$N_pct[dem_ethn$N_pct == "NA"] <- 0
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



write.csv(dem_age, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13.csv" )
write.csv(dem_gender, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_gender13.csv" )
write.csv(dem_ethn, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_ethn13.csv" )

write.csv(dem_age_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13_region.csv" )
write.csv(dem_gender_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_gender13_region.csv" )
write.csv(dem_ethn_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_ethn13_region.csv" )

write.csv(dem_age_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13_jurisdiction.csv" )
write.csv(dem_gender_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_gender13_jurisdiction.csv" )
write.csv(dem_ethn_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_ethn13_jurisdiction.csv" )

write.csv(dem_age_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13_cpa.csv" )
write.csv(dem_gender_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_gender13_cpa.csv" )
write.csv(dem_ethn_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_ethn13_cpa.csv" )




