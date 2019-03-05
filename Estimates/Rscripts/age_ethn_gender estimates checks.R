#estimates
#file sizes are large so id26 data is transformed first and then id 24 data
#add variable with datasource ID

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

#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

demo_26<- demo_26[order(demo_26$geotype,demo_26$geozone,demo_26$yr_id),]

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



table(demo_26_ethn$short_name)

#aggregate total counts by year for age, gender and ethnicity
demo_26_age<-aggregate(pop~age_group_name_rc+geotype+geozone+yr_id, data=demo_26, sum)
demo_26_gender<-aggregate(pop~sex+geotype+geozone+yr_id, data=demo_26, sum)
demo_26_ethn<-aggregate(pop~short_name+geotype+geozone+yr_id, data=demo_26, sum)

head(demo_26_ethn)


#recode ethn into 3 categories per EDAM - White, Hispanic, Other
#copy ethnicity column for reference
demo_26_ethn$short_name_orig=demo_26_ethn$short_name
#collapse ethnic categories
demo_26_ethn$short_name_rc <- 3
demo_26_ethn$short_name_rc[demo_26_ethn$short_name=="Hispanic"] <- 1
demo_26_ethn$short_name_rc[demo_26_ethn$short_name=="White"] <- 2

#name recoded ethnic categories
demo_26_ethn$short_name<- ifelse(demo_26_ethn$short_name_rc==1,"Hispanic",
                                   ifelse(demo_26_ethn$short_name_rc==2,"White",
                                          ifelse(demo_26_ethn$short_name_rc==3,"Other",NA)))
                                                 
table(demo_26_ethn$short_name_rc)

setnames(demo_26_age, old = "pop", new = "pop_age_26")
setnames(demo_26_ethn, old = "pop", new = "pop_ethn_26")
setnames(demo_26_gender, old = "pop", new = "pop_gender_26")

#############################################
############################################
table(demo_26_age$pop_age_26[demo_26_age$geotype=="region"])
table(demo_26_age$geotype)


#creates file with pop totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=demo_26, sum)

tail(geozone_pop)


#calculate year to year changes within ID26.
demo_26_gender <- demo_26_gender[order(demo_26_gender$sex,demo_26_gender$geotype,demo_26_gender$geozone,demo_26_gender$yr_id),]
demo_26_gender$N_chg <- demo_26_gender$pop_gender_26 - lag(demo_26_gender$pop_gender_26)
demo_26_gender$N_pct <- (demo_26_gender$N_chg / lag(demo_26_gender$pop_gender_26))
demo_26_gender$N_pct<-round(demo_26_gender$N_pct,digits=5)
demo_26_gender$geozone_pop<-geozone_pop[match(paste(demo_26_gender$yr_id, demo_26_gender$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
demo_26_gender$pct_of_total<-(demo_26_gender$pop_gender_26 / demo_26_gender$geozone_pop)
demo_26_gender$pct_of_total<-round(demo_26_gender$pct_of_total,digits=5)
#setnames(demo_26_gender, old=c("sex", "yr_id", "pop_gender_26"),new=c("Gender", "Year", "Pop_ID26"))
#demo_26_gender$Gender[demo_26_gender$Gender=="F"]<- "Female"
#demo_26_gender$Gender[demo_26_gender$Gender=="M"]<- "Male"

demo_26_ethn <- demo_26_ethn[order(demo_26_ethn$short_name,demo_26_ethn$geotype,demo_26_ethn$geozone,demo_26_ethn$yr_id),]
demo_26_ethn$N_chg <- demo_26_ethn$pop_ethn_26 - lag(demo_26_ethn$pop_ethn_26)
demo_26_ethn$N_pct <- (demo_26_ethn$N_chg / lag(demo_26_ethn$pop_ethn_26))
demo_26_ethn$N_pct<-round(demo_26_ethn$N_pct,digits=5)
demo_26_ethn$geozone_pop<-geozone_pop[match(paste(demo_26_ethn$yr_id, demo_26_ethn$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
demo_26_ethn$pct_of_total<-(demo_26_ethn$pop_ethn_26 / demo_26_ethn$geozone_pop)
demo_26_ethn$pct_of_total<-round(demo_26_ethn$pct_of_total,digits=5)
#setnames(demo_26_ethn, old=c("short_name", "yr_id", "pop_ethn_26"),new=c("Ethnicity", "Year", "Pop_ID26"))

demo_26_age <- demo_26_age[order(demo_26_age$age_group_name_rc,demo_26_age$geotype,demo_26_age$geozone,demo_26_age$yr_id),]
demo_26_age$N_chg <- demo_26_age$pop_age_26 - lag(demo_26_age$pop_age_26)
demo_26_age$N_pct <- (demo_26_age$N_chg / lag(demo_26_age$pop_age_26))
demo_26_age$N_pct<-round(demo_26_age$N_pct,digits=5)
demo_26_age$geozone_pop<-geozone_pop[match(paste(demo_26_age$yr_id, demo_26_age$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
demo_26_age$pct_of_total<-(demo_26_age$pop_age_26 / demo_26_age$geozone_pop)
demo_26_age$pct_of_total<-round(demo_26_age$pct_of_total,digits=5)

head(demo_26_ethn)
class(demo_26_ethn$pct_of_total)

#setnames(demo_26_age, old=c("age_group_name_rc", "yr_id", "pop_age_26"),new=c("Age_Group", "Year", "Pop_ID26"))

demo_26_age$N_chg[demo_26_age$yr_id=="2010"] <- NA 
demo_26_age$N_pct[demo_26_age$yr_id=="2010"] <- NA
demo_26_gender$N_chg[demo_26_gender$yr_id=="2010"] <- NA 
demo_26_gender$N_pct[demo_26_gender$yr_id=="2010"] <- NA
demo_26_ethn$N_chg[demo_26_ethn$yr_id=="2010"] <- NA 
demo_26_ethn$N_pct[demo_26_ethn$yr_id=="2010"] <- NA

head(subset(demo_26_gender, demo_26_gender$geotype=="jurisdiction"), 8)
head(subset(demo_26_ethn, demo_26_ethn$geotype=="jurisdiction"), 8)
head(subset(demo_26_age, demo_26_age$geotype=="jurisdiction"), 8)

#demo_26_age <- demo_26_age[order(demo_26_age$age_group_name_rc,demo_26_age$geotype,demo_26_age$geozone,demo_26_age$yr_id),]
demo_26_age$prop_change <- demo_26_age$pct_of_total - lag(demo_26_age$pct_of_total)
demo_26_gender$prop_change <- demo_26_gender$pct_of_total - lag(demo_26_gender$pct_of_total)
demo_26_ethn$prop_change <- demo_26_ethn$pct_of_total - lag(demo_26_ethn$pct_of_total)

demo_26_age$prop_change[demo_26_age$yr_id=="2010"] <- 0
demo_26_gender$prop_change[demo_26_gender$yr_id=="2010"] <- 0
demo_26_ethn$prop_change[demo_26_ethn$yr_id=="2010"] <- 0

#####################################
######################################

#calculate sd and iqr

demo_26_age$N_pct_sd <- sapply(demo_26_age$N_pct, sd)

head(demo_26_age$N_pct_sd)

######################################
#######################################
age_outliers <- subset(demo_26_age, demo_26_age$prop_change>=3)
summary(age_outliers$prop_change)
unique((age_outliers$geozone))
gender_outliers <- subset(demo_26_gender, demo_26_gender$prop_change>=2)
summary(gender_outliers$prop_change)
unique((gender_outliers$geozone))
ethn_outliers <- subset(demo_26_ethn, demo_26_ethn$prop_change>=3)
summary(ethn_outliers$prop_change)
unique((ethn_outliers$geozone))

#save out files for PowerBI
write.csv(demo_26_age, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Phase 6\\dem_age.csv" )
write.csv(demo_26_gender, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Phase 6\\dem_gender.csv" )
write.csv(demo_26_ethn, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Phase 6\\dem_ethn.csv" )
write.csv(age_outliers, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Phase 6\\age_outliers.csv" )
write.csv(gender_outliers, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Phase 6\\gender_outliers.csv" )
write.csv(ethn_outliers, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\Phase 6\\ethn_outliers.csv" )

################################################
###################################################




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
age_24_26$age_numdiff <- age_24_26$pop_age_26-age_24_26$pop_age_24  
ethn_24_26$ethn_numdiff <- ethn_24_26$pop_ethn_26-ethn_24_26$pop_ethn_24  
gender_24_26$gender_numdiff <- gender_24_26$pop_gender_26-gender_24_26$pop_gender_24  
age_24_26$age_pctdiff <- (age_24_26$age_numdiff/age_24_26$pop_age_24)*100 
age_24_26$age_pctdiff <- round(age_24_26$age_pctdiff,digits=2)
ethn_24_26$ethn_pctdiff <- (ethn_24_26$ethn_numdiff/ethn_24_26$pop_ethn_24)*100 
ethn_24_26$ethn_pctdiff <- round(ethn_24_26$ethn_pctdiff,digits=2)
gender_24_26$gender_pctdiff <- (gender_24_26$gender_numdiff/gender_24_26$pop_gender_24)*100 
gender_24_26$gender_pctdiff <- round(gender_24_26$gender_pctdiff,digits=2)


#create categorical variable of 5%, 10%, 15%, 20% from ID24 to ID26
age_24_26$pct5up <- ifelse(age_24_26$age_pctdiff>=5,1,0)
age_24_26$pct10up <- ifelse(age_24_26$age_pctdiff>=10,1,0)
age_24_26$pct15up <- ifelse(age_24_26$age_pctdiff>=15,1,0)
age_24_26$pct20up <- ifelse(age_24_26$age_pctdiff>=20,1,0)
ethn_24_26$pct5up <- ifelse(ethn_24_26$ethn_pctdiff>=5,1,0)
ethn_24_26$pct10up <- ifelse(ethn_24_26$ethn_pctdiff>=10,1,0)
ethn_24_26$pct15up <- ifelse(ethn_24_26$ethn_pctdiff>=15,1,0)
ethn_24_26$pct20up <- ifelse(ethn_24_26$ethn_pctdiff>=20,1,0)
gender_24_26$pct5up <- ifelse(gender_24_26$gender_pctdiff>=5,1,0)
gender_24_26$pct10up <- ifelse(gender_24_26$gender_pctdiff>=10,1,0)
gender_24_26$pct15up <- ifelse(gender_24_26$gender_pctdiff>=15,1,0)
gender_24_26$pct20up <- ifelse(gender_24_26$gender_pctdiff>=20,1,0)

#review data
table(age_24_26$pct20up)
age_test <- subset(age_24_26, age_24_26$pct20up=="1" & age_24_26=="2016" & age_24_26$pop_age_24>100 & age_24_26$pop_age_26>100)
unique(age_test$geozone)


demo_26_age$geozone_pop_24<-geozone_pop_24[match(paste(demo_26_age$yr_id, demo_26_age$geozone), paste(geozone_pop_24$yr_id, geozone_pop_24$geozone)), 4]
demo_26_age$pct_of_total_24<-(demo_26_age$pop_age_24 / demo_26_age$geozone_pop_24)
demo_26_age$pct_of_total_24<-round(demo_26_age$pct_of_total_24,digits=5)



