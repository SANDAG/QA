#DOF totals for projections/forecast are only available at the region level
#DOF projection totals are available by age, gender and ethnicity but can't be compared because of group quarter changes based on local college and military data
#manual check to socioeconomic data shows a match between download and DOF uploaded.
#forecast total pop is calculated from DOF (y1+y2)/2

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

getwd()

#turn off strings reading in as factors
options(stringsAsFactors=FALSE)

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=socioec_data; trusted_connection=true')

dof <- sqlQuery(channel, "SELECT [fiscal_yr]
      ,sum(population) as pop
                     FROM [socioec_data].[ca_dof].[population_proj_2018_1_20]
                     where county_fips_code=6073 and fiscal_yr>2015
                     Group by fiscal_yr
                     order by fiscal_yr"
)

#read in QA DOF raw data download
#dof <- read.csv("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\DOF\\Raw DOF\\P3_Complete.csv")
gq_revisions <- read.csv("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\DOF\\Raw DOF\\GQ revisions.csv")
head(dof)
head(gq_revisions)
table(dof$fiscal_yr)



#order file before the calculating cumulative sum
gq_revisions <- gq_revisions[order(gq_revisions$year),]
#set NA values to zero
gq_revisions$col[is.na(gq_revisions$col)] <- 0
gq_revisions$mil[is.na(gq_revisions$mil)] <- 0
#sum gq added totals
gq_revisions$gq_add <- gq_revisions$col+gq_revisions$mil
#add one to the year to get proper calculation for dof data
gq_revisions$year <- gq_revisions$year+1
#add one to the year to get proper calculation for dof data
#gq_revisions$year <- gq_revisions$year-1

#set new total for 2017 gq to base year total 
gq_revisions$gq_add[gq_revisions$year==2017] <- gq_revisions$base_year_2017_gq
#calculate gq tot for forecast years
gq_revisions$gq_tot_rc <- cumsum(gq_revisions$gq_add)
#check match ofR cumulative sum to EDAM should match for all but 2016.
as.numeric(gq_revisions$tot_gq==gq_revisions$gq_tot_rc)


head(gq_revisions)

head(dof)
dof$pop2 <- dof$pop
dof$dof_hh_pop_rc <- (dof$pop+lag(dof$pop2))/2
dof$dof_hh_pop_rc <- dof$dof_hh_pop_rc-106299
dof <- merge(dof,gq_revisions, by.x = "fiscal_yr", by.y = "year")
dof$dof_pop <- dof$dof_hh_pop_rc+dof$tot_gq


#dof$yr_id <- dof$fiscal_yr-1

dof <- select(dof,fiscal_yr,dof_pop,dof_hh_pop_rc,gq_tot_rc)
head(dof)

##########################
##########################
#dof <-  subset(dof,dof$fips==6073 & dof$year>=2016)

#confirm only San Diego region included and only years of interest
#table(dof$fips)
#table(dof$year)

#sum of region population by year
# #dof_sums <- dof %>%
#   select(year, perwt) %>%
#   group_by(year) %>%
#   summarise(dof_pop_tot = sum(perwt,na.rm=TRUE))

#head(dof_sums[dof_sums$year==2018 | dof_sums$year==2050,])

#subset data to include only SD fips and years of interest
#dof <- subset(dof, dof$fips==6073 & (dof$year==2018 | dof$year==2020 | dof$year==2025 | dof$year==2030 | dof$year==2035 | dof$year==2040 | dof$year==2045 | dof$year==2050))


# dof_sums$dof_pop_tot2 <- dof_sums$dof_pop_tot
# dof_sums$temp <- (dof_sums$dof_pop_tot+lag(dof_sums$dof_pop_tot2))/2
###########################
###########################


#read in demographic warehouse data.

#confirm working directory
getwd()

#set datasource id
ds_id=28

#set SQL channel
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#get dw pop totals
dem_sql = getSQL("../Queries/age_ethn_gender.sql")
dem_sql <- gsub("ds_id", ds_id,dem_sql)
dem<-sqlQuery(channel,dem_sql)
odbcClose(channel)

#subset dw to include only region totals.
dem <- subset(dem, dem$geotype=="region")

head(dem)
#calculate age totals by category
dw_pop <- dem %>%
  select(yr_id, pop) %>%
  group_by(yr_id) %>%
  summarise(dw_pop = sum(pop,na.rm=TRUE))
head(dw_pop[dw_pop$yr_id==2018 | dw_pop$yr_id==2050,])

head(dof)
head(dw_pop)

#create yr_id in dof to match demographic warehouse
dof$yr_id <- dof$fiscal_yr-1
dof <- subset(dof, dof$yr_id==2018 | dof$yr_id==2020 | dof$yr_id==2025 | dof$yr_id==2030 | dof$yr_id==2035 | dof$yr_id==2040 | dof$yr_id==2045 | dof$yr_id==2050)


#merge DOF and SANDAG demographic warehouse totals and calculate differences
dof2dw_totpop <- merge(dof,dw_pop, by.x = "yr_id",by.y = "yr_id", all = TRUE)
dof2dw_totpop$diff <- dof2dw_totpop$dof_pop-dof2dw_totpop$dw_pop
dof2dw_totpop$diff_pct <- (dof2dw_totpop$diff/dof2dw_totpop$dw_pop)*100
dof2dw_totpop$diff_pct <- round(dof2dw_totpop$diff_pct, digits = 2)
head(dof2dw_totpop)


write.csv(dof2dw_totpop,"M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data Files\\DOF\\dof_isam_dw_forecast_pop_diff.csv", row.names = FALSE)
