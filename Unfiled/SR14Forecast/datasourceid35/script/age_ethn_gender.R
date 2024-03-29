
#load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)

#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#necessary code for running SQL scripts in R
source("../Queries/readSQL.R")

#channel set to SQL database access the query and pull the specific data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
dem_sql = getSQL("../Queries/age_ethn_gender.sql")
dem<-sqlQuery(channel,dem_sql)
odbcClose(channel)


write.csv(dem, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\dem_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

#order the data in the file
dem<- dem[order(dem$geotype,dem$geozone,dem$yr_id),]

#recode geozone for region of San Diego to say "San Diego Region" to differientate. 
dem$geozone[dem$geozone=="San Diego" & dem$geotype=="region"]<- "San Diego Region"

#deletes extra characters in geozone for matching later
dem$geozone <- gsub("\\*","",dem$geozone)
dem$geozone <- gsub("\\-","_",dem$geozone)
dem$geozone <- gsub("\\:","_",dem$geozone)


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
                                                  
#create variable of labels for new age categories
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
#recode geozone for region of San Diego to say "San Diego Region" to differientate. 
geozone_pop$geozone[geozone_pop$geozone=="San Diego" & geozone_pop$geotype=="region"]<- "San Diego Region"

tail(geozone_pop)

#calculate percent of the total population, total change, percent change by year for age, gender and ethnicity using a lag
head(dem_age,10)
dem_age <- dem_age[order(dem_age$age_group_name_rc,dem_age$geotype,dem_age$geozone,dem_age$yr_id),]
dem_age$N_chg <- dem_age$pop - lag(dem_age$pop)
dem_age$N_pct <- (dem_age$N_chg / lag(dem_age$pop))*100
#rounds percent
dem_age$N_pct<-round(dem_age$N_pct,digits=2)
#match in population for each geozone
dem_age$geozone_pop<-geozone_pop[match(paste(dem_age$yr_id, dem_age$geozone),
                                       paste(geozone_pop$yr_id, geozone_pop$geozone)),4]
#calculate the proportion of pop in each age group and round
dem_age$pct_of_total<-(dem_age$pop / dem_age$geozone_pop)*100
dem_age$pct_of_total<-round(dem_age$pct_of_total,digits=2)
#rename variables
setnames(dem_age, old=c("age_group_name_rc", "yr_id", "pop"),new=c("Age_Group", "Year", "Population"))


head(dem_gender)
dem_gender <- dem_gender[order(dem_gender$sex,dem_gender$geotype,dem_gender$geozone,dem_gender$yr_id),]
dem_gender$N_chg <- dem_gender$pop - lag(dem_gender$pop)
dem_gender$N_pct <- (dem_gender$N_chg / lag(dem_gender$pop))*100
dem_gender$N_pct<-round(dem_gender$N_pct,digits=2)
dem_gender$geozone_pop<-geozone_pop[match(paste(dem_gender$yr_id, dem_gender$geozone), 
                                          paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
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
dem_ethn$geozone_pop<-geozone_pop[match(paste(dem_ethn$yr_id, dem_ethn$geozone), 
                                        paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
dem_ethn$pct_of_total<-(dem_ethn$pop / dem_ethn$geozone_pop)*100
dem_ethn$pct_of_total<-round(dem_ethn$pct_of_total,digits=2)
setnames(dem_ethn, old=c("short_name", "yr_id", "pop"),new=c("Ethnicity", "Year", "Population"))


#recode wrong values for 2016 because of lag calculation from 2050-2016 records
dem_age$N_chg[dem_age$Year == "2016"] <- 0
dem_age$N_pct[dem_age$Year == "2016"] <- 0

dem_ag_test<-subset(dem_age, Year=="2016")

head(dem_ag_test)
rm(dem_ag_test)

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
dem_ethn$N_pct[dem_ethn$Year == "2016"] <- 0
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

#subset cpa files to only include top 10 cpas with highest change
#Per QA team discussionon 3/10/2020, if CPA qualifies as top 10, maintain all records
#related to that CPA (all years, all categories) to provide context during review. 
dem_age_cpa$N_pct_ab <- abs(dem_age_cpa$N_pct)
dem_gender_cpa$N_pct_ab <- abs(dem_gender_cpa$N_pct)
dem_ethn_cpa$N_pct_ab <- abs(dem_ethn_cpa$N_pct)

#determine CPAs with qualifying top 10 percent change.
#age
#determine max percent change by cpa
age_cpa10<- aggregate(N_pct_ab~ geozone, data=dem_age_cpa, max)
age_cpa10$N_pct_ab[age_cpa10$N_pct_ab == "Inf"] <- 0
#sort descending on max percent change
age_cpa10<- age_cpa10[order(-age_cpa10$N_pct_ab),]
#select only top 10 cpas
age_cpa10<- age_cpa10 %>% 
  top_n(10)
dem_age_cpa_10<- subset(dem_age_cpa, geozone %in% age_cpa10$geozone)

#gender
#determine max percent change by cpa
gender_cpa10<- aggregate(N_pct_ab~ geozone, data=dem_gender_cpa, max)
gender_cpa10$N_pct_ab[gender_cpa10$N_pct_ab == "Inf"] <- 0
#sort descending on max percent change
gender_cpa10<- gender_cpa10[order(-gender_cpa10$N_pct_ab),]
#select only top 10 cpas
gender_cpa10<- gender_cpa10 %>% 
  top_n(10)
dem_gender_cpa_10<- subset(dem_gender_cpa, geozone %in% gender_cpa10$geozone)

#ethnicity
#determine max percent change by cpa
ethnicity_cpa10<- aggregate(N_pct_ab~ geozone, data=dem_ethn_cpa, max)
ethnicity_cpa10$N_pct_ab[ethnicity_cpa10$N_pct_ab == "Inf"] <- 0
#sort descending on max percent change
ethnicity_cpa10<- ethnicity_cpa10[order(-ethnicity_cpa10$N_pct_ab),]
#select only top 10 cpas
ethnicity_cpa10<- ethnicity_cpa10 %>% 
  top_n(10)
dem_ethn_cpa_10<- subset(dem_ethn_cpa, geozone %in% ethnicity_cpa10$geozone)


#write files out for 
write.csv(dem_age, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_age.csv" )
write.csv(dem_gender, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_gender.csv" )
write.csv(dem_ethn, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_ethn.csv" )

write.csv(dem_age_region, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_age_region.csv" )
write.csv(dem_gender_region, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_gender_region.csv" )
write.csv(dem_ethn_region, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_ethn_region.csv" )

write.csv(dem_age_jurisdiction, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_age_jurisdiction.csv" )
write.csv(dem_gender_jurisdiction, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_gender_jurisdiction.csv" )
write.csv(dem_ethn_jurisdiction, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_ethn_jurisdiction.csv" )

write.csv(dem_age_cpa_10, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_age_cpa.csv" )
write.csv(dem_gender_cpa_10, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_gender_cpa.csv" )
write.csv(dem_ethn_cpa_10, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_ethn_cpa.csv" )

#write out files for PowerBI that includes all CPAs 
write.csv(dem_age_cpa, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_age_cpa_all.csv" )
write.csv(dem_gender_cpa, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_gender_cpa_all.csv" )
write.csv(dem_ethn_cpa, "C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Results\\ID 35\\Test 31, 32 demographics\\dem_ethn_cpa_all.csv" )

#################################################
#################################################
#internal integrity checks#
write.csv(dem_age, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_age19.csv" )
write.csv(dem_gender, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_gender19.csv" )
write.csv(dem_ethn, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_ethn19.csv" )

write.csv(dem_age_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_age_region19.csv" )
write.csv(dem_gender_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_gender_region19.csv" )
write.csv(dem_ethn_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_ethn_region19.csv" )

write.csv(dem_age_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_age_jurisdiction19.csv" )
write.csv(dem_gender_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_gender_jurisdiction19.csv" )
write.csv(dem_ethn_jurisdiction, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_ethn_jurisdiction19.csv" )

write.csv(dem_age_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_age_cpa19.csv" )
write.csv(dem_gender_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_gender_cpa19.csv" )
write.csv(dem_ethn_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\datasource_id 34\\Dem\\dem_ethn_cpa19.csv" )







#Internal Integrity Checks


ic_1<-summary(dem)

#this set of integrity checks really check the geography files which was not the intention. However people like these tests so you may need to run.

# #check age sums across 3 geotype files
# dem_age_cpa_ic<-aggregate(Population~Age_Group+Year+geotype, data=dem_age_cpa, sum)
# dem_age_jur_ic<-aggregate(Population~Age_Group+Year+geotype, data=dem_age_jurisdiction, sum)
# dem_age_reg_ic<-aggregate(Population~Age_Group+Year+geotype, data=dem_age_region, sum)
# 
# age_ic<-rbind(dem_age_cpa_ic,dem_age_jur_ic, dem_age_reg_ic)
# age_ic_wide<-dcast(age_ic, Age_Group+Year~geotype, value.var="Population")
# 
# age_ic_wide$CPA2Region<-age_ic_wide$cpa-age_ic_wide$region
# age_ic_wide$Jur2Region<-age_ic_wide$jurisdiction-age_ic_wide$region
# 
# head(age_ic_wide)
# 
# write.csv(age_ic_wide, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\datasource_id 34\\internal integrity\\age_group_ic.csv" )
# 
# #check gender sums across 3 geotype files
# dem_gender_cpa_ic<-aggregate(Population~Gender+Year+geotype, data=dem_gender_cpa, sum)
# dem_gender_jur_ic<-aggregate(Population~Gender+Year+geotype, data=dem_gender_jurisdiction, sum)
# dem_gender_reg_ic<-aggregate(Population~Gender+Year+geotype, data=dem_gender_region, sum)
# 
# gender_ic<-rbind(dem_gender_cpa_ic,dem_gender_jur_ic, dem_gender_reg_ic)
# gender_ic_wide<-dcast(gender_ic, Gender+Year~geotype, value.var="Population")
# 
# gender_ic_wide$CPA2Region<-gender_ic_wide$cpa-gender_ic_wide$region
# gender_ic_wide$Jur2Region<-gender_ic_wide$jurisdiction-gender_ic_wide$region
# 
# head(gender_ic_wide)
# 
# write.csv(gender_ic_wide, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\datasource_id 34\\internal integrity\\gender_ic.csv" )
# 
# #check ethnicity sums across 3 geotype files
# 
# 
# dem_ethn_cpa_ic<-aggregate(Population~Ethnicity+Year+geotype, data=dem_ethn_cpa, sum)
# dem_ethn_jur_ic<-aggregate(Population~Ethnicity+Year+geotype, data=dem_ethn_jurisdiction, sum)
# dem_ethn_reg_ic<-aggregate(Population~Ethnicity+Year+geotype, data=dem_ethn_region, sum)
# 
# ethn_ic<-rbind(dem_ethn_cpa_ic,dem_ethn_jur_ic, dem_ethn_reg_ic)
# ethn_ic_wide<-dcast(ethn_ic, Ethnicity+Year~geotype, value.var="Population")
# 
# ethn_ic_wide$CPA2Region<-ethn_ic_wide$cpa-ethn_ic_wide$region
# ethn_ic_wide$Jur2Region<-ethn_ic_wide$jurisdiction-ethn_ic_wide$region
# 
# head(ethn_ic_wide)
# 
# write.csv(ethn_ic_wide, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\datasource_id 34\\internal integrity\\ethn_ic.csv" )
# 

#check pop sums to total of original downloaded file
dem_age_tot_ic<-aggregate(Population~Year, data=dem_age_region, sum)
dem_gender_tot_ic<-aggregate(Population~Year, data=dem_gender_region, sum)
dem_ethn_tot_ic<-aggregate(Population~Year, data=dem_ethn_region, sum)

dem_age_tot_ic$source<-"Age"
dem_gender_tot_ic$source<-"Gender"
dem_ethn_tot_ic$source<-"Ethnicity"

dem_reg_ic<-subset(dem, geotype=="region")
dem_reg_ic<-aggregate(pop~yr_id, data=dem_reg_ic, sum)
dem_reg_ic$source<-"Region_SQLscript"
setnames(dem_reg_ic, old = c("yr_id","pop"), new =c("Year","Population"))
head(dem_reg_ic)  


dem_tot_ic<-rbind(dem_age_tot_ic,dem_gender_tot_ic,dem_ethn_tot_ic,dem_reg_ic)
dem_tot_ic_wide<-dcast(dem_tot_ic, Year~source, value.var="Population")

tail(dem_tot_ic_wide)
dem_tot_ic_wide$Age2Region<-dem_tot_ic_wide$Age-dem_tot_ic_wide$Region_SQLscript
dem_tot_ic_wide$Ethnicity2Region<-dem_tot_ic_wide$Age-dem_tot_ic_wide$Region_SQLscript
dem_tot_ic_wide$Gender2Region<-dem_tot_ic_wide$Gender-dem_tot_ic_wide$Region_SQLscript


write.csv(dem_tot_ic_wide, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\datasource_id 34\\internal integrity\\dem_region_totals_ic.csv" )



#file review only - not for file preparation - compare cpas included here to median age cpa records
dem_age_0<- subset(dem_age, geozone_pop == 0)
dem_age_1<- subset(dem_age, geozone == "Ncfua Reserve")
unique(dem_age_0$geozone)
tail(dem_age_1)
dem_age_2<- subset(dem_age, geozone == "Scripps Reserve")
unique(dem_age_2$geozone)
head(dem_age_2)




