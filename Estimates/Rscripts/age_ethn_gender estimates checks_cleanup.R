#estimates
#file sizes are large so id26 data is transformed first and then id 24 data

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
demo_26$datasource_id = ds_id

# datasource name
ds_sql = getSQL("../Queries/datasource_name.sql")
ds_sql <- gsub("ds_id", ds_id,ds_sql)
datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)


odbcClose(channel)

#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

demo_26<- demo_26[order(demo_26$geotype,demo_26$geozone,demo_26$yr_id),]
demo_26 <- merge(x = demo_26, y =datasource_name[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)

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
demo_26_age<-aggregate(pop~age_group_name_rc+geotype+geozone+yr_id+name, data=demo_26, sum)



setnames(demo_26_age, old = "pop", new = "pop_age_26")



table(demo_26_age$geotype)

#creates file with pop totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=demo_26, sum)

tail(geozone_pop)

rm(demo_26)


#merge id24 to id26
age_24_26 <- demo_26_age




age_24_26$pop_age_26 <- as.numeric(age_24_26$pop_age_26)


#calculate percent of the total population, total change, percent change for age, gender and ethnicity from id24 to id26


age_24_26 <- age_24_26[order(age_24_26$age_group_name_rc,age_24_26$geotype,age_24_26$geozone,age_24_26$yr_id),]
age_24_26$N_chg <- age_24_26$pop_age_26 - lag(age_24_26$pop_age_26)
age_24_26$N_pct <- (age_24_26$N_chg / lag(age_24_26$pop_age_26))
age_24_26$N_pct<-round(age_24_26$N_pct,digits=2)


age_24_26$geozone_pop<-geozone_pop[match(paste(age_24_26$yr_id, age_24_26$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), 4]
age_24_26$pct_of_total<-(age_24_26$pop_age_26 / age_24_26$geozone_pop)
age_24_26$pct_of_total<-round(age_24_26$pct_of_total,digits=5)
#setnames(age_24_26, old=c("age_group_name_rc", "yr_id", "pop_age_26"),new=c("Age_Group", "Year", "Pop_ID26"))

# change NA pct change to zero
age_24_26[is.na(age_24_26)] <- 0
age_24_26$N_pct[age_24_26$N_pct=="Inf"] <- 0 

age_24_26$N_chg[age_24_26$yr_id=="2010"] <- 0 
age_24_26$N_pct[age_24_26$yr_id=="2010"] <- 0

# head(subset(gender_24_26, gender_24_26$geotype=="jurisdiction"), 8)

#age_24_26 <- age_24_26[order(age_24_26$age_group_name_rc,age_24_26$geotype,age_24_26$geozone,age_24_26$yr_id),]
age_24_26$prop_change <- age_24_26$pct_of_total - lag(age_24_26$pct_of_total)


age_24_26$prop_change[age_24_26$yr_id=="2010"] <- 0

# 
# age_outliers <- subset(age_24_26, age_24_26$prop_change>=3)
# summary(age_outliers$prop_change)
# unique((age_outliers$geozone))
# gender_outliers <- subset(gender_24_26, gender_24_26$prop_change>=2)
# summary(gender_outliers$prop_change)
# unique((gender_outliers$geozone))
# ethn_outliers <- subset(ethn_24_26, ethn_24_26$prop_change>=3)
# summary(ethn_outliers$prop_change)
# unique((ethn_outliers$geozone))



#colnames(age_24_26)


age_26 <- age_24_26 %>% select("yr_id","geozone","geotype","age_group_name_rc",       
                  "pop_age_26","N_chg","N_pct","geozone_pop",      
                  "pct_of_total","prop_change","name")

#save out files for PowerBI
write.csv(age_26, "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\dem_age_prop_only.csv",row.names=FALSE) 





