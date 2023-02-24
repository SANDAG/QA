#DOF totals for projections/forecast are only available at the region level
#DOF projection totals are available by age, gender and ethnicity 
#waiting for feedback from EDAM before merging raw data to demographic warehouse. Expectation was that data would match but it doesn't.
#QA is waiting for reason so we can rework test if necessary.
#manual check to socioeconomic data shows a match between download and DOF uploaded.
# start on line 38

#function to load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

#identify packages to be loaded
packages <- c("data.table", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","tidyverse")
#confirm packages are read in
pkgTest(packages)

#set working directory and access code to read in SQL queries
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#turn off strings reading in as factors
options(stringsAsFactors=FALSE)

#read in QA DOF raw data download
dof <- read.csv("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\DOF\\Raw DOF\\P3_Complete.csv")

head(dof)

#subset data to include only SD fips and years of interest
dof <- subset(dof, dof$fips==6073 & (dof$year==2018 | dof$year==2020 | dof$year==2025 | dof$year==2030 | dof$year==2035 | dof$year==2040 | dof$year==2045 | dof$year==2050))


#confirm only San Diego region included and only years of interest
table(dof$fips)
table(dof$year)


#sum of region population by year
dof_sums <- dof %>%
  select(year, perwt) %>%
  group_by(year) %>%
  summarise(dof_pop_tot = sum(perwt,na.rm=TRUE))

head(dof_sums[dof_sums$year==2018 | dof_sums$year==2050,])

#sum of region population by year and gender
dof_gender <- dof %>%
  select(year, sex, perwt) %>%
  group_by(year, sex) %>%
  summarise(dof_gender_pop = sum(perwt,na.rm=TRUE))

head(dof_gender,10)

#sum of region population by year and ethnicity
dof_race <- dof %>%
  select(year, race7, perwt) %>%
  group_by(year, race7) %>%
  summarise(dof_ethn_pop = sum(perwt,na.rm=TRUE))

#Creates a dataframe with race code and value label and match to race dataframe
#DOF Race_code categories for coding - DOF does not report an "other" category: 
#1) White (Non-Hispanic)
#2) Black (Non-Hispanic)
#3) American Indian Alaska Native (Non-Hispanic)
#4) Asian (Non-Hispanic)
#5) Non-Hispanic Pacific Islander (Non-Hispanic)
#6) Multi-Race (Non-Hispanic)
#7) Hispanic (any race)
race_code <- c(1,2,3,4,5,6,7)
#value labels set to match demographic warehouse. 
race_name <- c('White','Black','American Indian','Asian','Pacific Islander',
               'Two or More','Hispanic')
race_label <- data.frame(race_code,race_name, stringsAsFactors = FALSE)
dof_race$race_name <- race_label[match(dof_race$race7,race_label$race_code),"race_name"]

head(dof_race,20)

#age by 20 DOF defined groups
dof_age <- dof %>%
  select(year, agerc, perwt) %>%
  group_by(year, agerc) %>%
  summarise(age_pop = sum(perwt,na.rm=TRUE))

head(dof_age[dof_age$year==2018 | dof_age$year==2050,],20)

#recode dof age groups
dof_age$agerc_qa <- ifelse(dof_age$agerc<18,1,
                           ifelse(dof_age$agerc<45,2,
                                  ifelse(dof_age$agerc<65,3,
                                        ifelse(dof_age$agerc>64,4,NA))))
                                                  

#review recode
table(dof_age$agerc[dof_age$agerc_qa==1])
table(dof_age$agerc[dof_age$agerc_qa==2])
table(dof_age$agerc[dof_age$agerc_qa==3])
table(dof_age$agerc[dof_age$agerc_qa==4])

#create variable of labels for new age categories
dof_age$age_group_name_rc<- ifelse(dof_age$agerc_qa==1,"<18",
                               ifelse(dof_age$agerc_qa==2,"18-44",
                                      ifelse(dof_age$agerc_qa==3,"45-64",
                                             ifelse(dof_age$agerc_qa==4,"65+",NA))))
table(dof_age$age_group_name_rc)

#calculate age totals by SANDAG 4 categories
dof_age_sum <- dof_age %>%
  select(year, agerc_qa, age_pop) %>%
  group_by(year, agerc_qa) %>%
  summarise(dof_age_pop = sum(age_pop,na.rm=TRUE))

head(dof_age_sum,10)

#read in demographic warehouse data.

#confirm working directory
getwd()

#set datasource id
ds_id=28

#set SQL channel
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# datasource name
ds_sql = getSQL("../Queries/datasource_name.sql")
ds_sql <- gsub("ds_id", ds_id,ds_sql)
datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)

dem_sql = getSQL("../Queries/age_ethn_gender.sql")
dem_sql <- gsub("ds_id", ds_id,dem_sql)
dem<-sqlQuery(channel,dem_sql)
odbcClose(channel)

#subset dw to include only region totals.
dem <- subset(dem, dem$geotype=="region")

head(dem,12)

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

#check recodes are working
table(dem$age_group_id[dem$age_group_rc==1])
table(dem$age_group_id[dem$age_group_rc==2])
table(dem$age_group_id[dem$age_group_rc==3])
table(dem$age_group_id[dem$age_group_rc==4])

#create variable of labels for new age categories
dem$age_group_name_rc<- ifelse(dem$age_group_rc==1,"<18",
                               ifelse(dem$age_group_rc==2,"18-44",
                                      ifelse(dem$age_group_rc==3,"45-64",
                                             ifelse(dem$age_group_rc==4,"65+",NA))))

head(dem)
#calculate age totals by category
dw_pop <- dem %>%
  select(yr_id, pop) %>%
  group_by(yr_id) %>%
  summarise(dw_pop = sum(pop,na.rm=TRUE))
head(dw_pop[dw_pop$yr_id==2018 | dw_pop$yr_id==2050,],20)

#calculate age totals by category
dw_age <- dem %>%
  select(yr_id, age_group_rc,age_group_name_rc,pop) %>%
  group_by(yr_id, age_group_name_rc,age_group_rc) %>%
  summarise(dw_age_pop = sum(pop,na.rm=TRUE))
head(dw_age[dw_age$yr_id==2018 | dw_age$yr_id==2050,],20)

#calculate gender totals by category
dw_gender <- dem %>%
  select(yr_id, sex_id, sex, pop) %>%
  group_by(yr_id, sex_id, sex) %>%
  summarise(dw_gender_pop = sum(pop,na.rm=TRUE))
head(dw_gender[dw_gender$yr_id==2018 | dw_gender$yr_id==2050,],20)

#calculate ethnicity totals by category
dw_ethn <- dem %>%
  select(yr_id, short_name,ethnicity_id, pop) %>%
  group_by(yr_id, ethnicity_id,short_name) %>%
  summarise(dw_ethn_pop = sum(pop,na.rm=TRUE))
head(dw_ethn[dw_ethn$yr_id==2018 | dw_ethn$yr_id==2050,],20)
head(dof_race[dof_race$year==2018 | dof_race$year==2050,],20)



#review totals
head(dw_age[dw_age$yr_id==2018 | dw_age$yr_id==2050,],20)
head(dof_age_sum[dof_age_sum$year==2018 | dof_age_sum$year==2050,],20)

#merge DOF and SANDAG demographic warehouse totals and calculate differences
dof2dw_totpop <- merge(dof_sums,dw_pop, by.x = "year",by.y = "yr_id", all = TRUE)
dof2dw_totpop$diff <- dof2dw_totpop$dof_pop_tot-dof2dw_totpop$dw_pop
dof2dw_totpop$diff_pct <- (dof2dw_totpop$diff/dof2dw_totpop$dw_pop)*100
dof2dw_totpop$diff_pct <- round(dof2dw_totpop$diff_pct, digits = 2)
head(dof2dw_totpop)

#merge DOF and SANDAG demographic warehouse totals by age and calculate differences
dof2dw_age <- merge(dof_age_sum,dw_age, by.x = c("year","agerc_qa"),by.y = c("yr_id","age_group_rc"), all = TRUE)
dof2dw_age$diff <- dof2dw_age$dof_age_pop-dof2dw_age$dw_age_pop
dof2dw_age$diff_pct <- (dof2dw_age$diff/dof2dw_age$dw_age_pop)*100
dof2dw_age$diff_pct <- round(dof2dw_age$diff_pct, digits = 2)
dof2dw_age <- select(dof2dw_age, year, age_group_name_rc,dof_age_pop,dw_age_pop,diff,diff_pct)
head(dof2dw_age)

#merge DOF and SANDAG demographic warehouse totals by gender and calculate differences
setnames(dw_gender, old="sex", new = "sex_name")
dof2dw_gender <- merge(dof_gender,dw_gender, by.x = c("year","sex"),by.y = c("yr_id","sex_id"), all = TRUE)
dof2dw_gender$diff <- dof2dw_gender$gender_pop-dof2dw_gender$dw_gender_pop
dof2dw_gender$diff_pct <- (dof2dw_gender$diff/dof2dw_gender$dw_gender_pop)*100
dof2dw_gender$diff_pct <- round(dof2dw_gender$diff_pct, digits = 2)
dof2dw_gender <- select(dof2dw_gender, year, sex, sex_name, dof_gender_pop, dw_gender_pop, diff, diff_pct)
head(dof2dw_gender)

#merge DOF and SANDAG demographic warehouse totals by ethnicity and calculate differences
dof2dw_ethn <- merge(dof_race,dw_ethn, by.x = c("year","race_name"),by.y = c("yr_id","short_name"), all = TRUE)
dof2dw_ethn$race7 <- NULL
dof2dw_ethn$ethnicity_id <- NULL
dof2dw_ethn$dof_ethn_pop[dof2dw_ethn$race_name=="Other"] <- 0
dof2dw_ethn$diff <- dof2dw_ethn$dof_ethn_pop-dof2dw_ethn$dw_ethn_pop
dof2dw_ethn$diff_pct <- (dof2dw_ethn$diff/dof2dw_ethn$dw_ethn_pop)*100
dof2dw_ethn$diff_pct <- round(dof2dw_ethn$diff_pct,digits = 2)
head(dof2dw_ethn)

by(dof2dw_ethn$diff_pct,dof2dw_ethn$year, summary)

write.csv(dof2dw_totpop,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\DOF\\pop_tot_diff.csv", row.names = FALSE)
write.csv(dof2dw_age,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\DOF\\age_diff.csv", row.names = FALSE)
write.csv(dof2dw_gender,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\DOF\\gender_diff.csv", row.names = FALSE)
write.csv(dof2dw_ethn,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\DOF\\ethn_diff.csv", row.names = FALSE)
