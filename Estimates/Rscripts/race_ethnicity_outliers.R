#Estimates

# install R packages ####################################
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
}
packages <- c("RODBC","tidyverse")
pkgTest(packages)
##########################################################

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#### read from database  #######################################

source("../Queries/readSQL.R")

datasource_ids = c(27)
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

race_ethnicity <- data.frame()
sourcename <- data.frame()
householdpop <- data.frame()

for(ds_id in datasource_ids) {
# datasource name
ds_sql = getSQL("../Queries/datasource_name.sql")
ds_sql <- gsub("ds_id", ds_id,ds_sql)
datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
sourcename <- rbind(sourcename,datasource_name)

# get race ethnicity
demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo<-sqlQuery(channel,demo_sql,stringsAsFactors = FALSE)
demo$datasource_id = ds_id
race_ethnicity <- rbind(race_ethnicity,demo)

# get total pop, household pop, gq pop
pop_sql = getSQL("../Queries/hh_pop_only.sql")
pop_sql <- gsub("ds_id", ds_id,pop_sql)
hhpop<-sqlQuery(channel,pop_sql,stringsAsFactors = FALSE)
hhpop$datasource_id = ds_id
householdpop <- rbind(householdpop,hhpop)
}

odbcClose(channel)

rm(datasource_name)
rm(demo)
rm(hhpop)

####   end read from database #################################

# add datasource name, i.e. "2018 estimates"
race_ethnicity <- merge(x = race_ethnicity, y =sourcename[ , c("name","datasource_id","description")],by = "datasource_id")
names(race_ethnicity)[names(race_ethnicity) == 'name'] <- 'datasource'
rm(sourcename)

# aggregate population by race ethnicity and year and geography and datasource
# this removes age categories and M/F
race_ethnicity<-aggregate(pop~short_name+ethnicity_id+geotype+geozone+yr_id+datasource_id+datasource+description, data=race_ethnicity, sum)

# add total pop, household pop, gqpop
race_ethnicity <- merge(x = race_ethnicity, y =householdpop,by = c("yr_id","geozone","geotype","datasource_id"))

rm(householdpop)

################ DATA CHECK  ##########################################
# datasource 27: 627 tracts + 89 cpa + 19 jurs + 1 region = 736
#   8 race/eth multiplied by 9 years multiplied by 736 geo = 52992 rows
#######################################################################
  

# rename geozone for region (not "San Diego" to avoid confusion)
race_ethnicity$geozone[race_ethnicity$geotype =="region"]<- "Region"  #chg name from San Diego

# clean up CPA names by removing special characters
race_ethnicity$geozone <- gsub("\\*","",race_ethnicity$geozone)
race_ethnicity$geozone <- gsub("\\-","_",race_ethnicity$geozone)
race_ethnicity$geozone <- gsub("\\:","_",race_ethnicity$geozone)

#creates file with population totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id+datasource_id, data=race_ethnicity, sum)
names(geozone_pop)[names(geozone_pop) == 'pop'] <- 'totalpop'
################ DATA CHECK  ##########################################
#   9 years multiplied by 736 geo = 6624 rows 
# (note: includes: "not in a cpa",Via De La Valle Reserve, Marine Corps Recruit Depot)
#######################################################################

# add population totals by geozone (to race/ethnicity pop totals)
race_ethnicity <- merge(x = race_ethnicity, y =geozone_pop[ , c("yr_id", "geozone","totalpop","datasource_id")],by = c("yr_id","geozone","datasource_id"))

rm(geozone_pop)

# order dataframe
race_ethnicity <- race_ethnicity[order(race_ethnicity$short_name,race_ethnicity$geotype,race_ethnicity$geozone,race_ethnicity$yr_id),]

# add gq pop
race_ethnicity$gqpop = race_ethnicity$totalpop - race_ethnicity$hhpop

#remove columns
race_ethnicity$ethnicity_id <- NULL
# race_ethnicity$datasource_id <- NULL

# calculate percent of total population for each race/ethn
race_ethnicity$pct_of_total<-ifelse(race_ethnicity$totalpop==0,NA,race_ethnicity$pop / race_ethnicity$totalpop)

# check data
# subset(race_ethnicity,geozone=='Alpine'& short_name=='Black')


# calculate lag
# pct of total from previous year
race_ethnicity <- 
  race_ethnicity %>%
  group_by(geozone,short_name) %>%
  mutate(lag.pct_of_total =lag(pct_of_total, order_by = yr_id, default = NA),
         lag.pop = lag(pop,order_by = yr_id, default = NA))

# calculate percent of total population year over year difference
race_ethnicity$pct_of_total_chg <- race_ethnicity$pct_of_total - race_ethnicity$lag.pct_of_total
race_ethnicity$pop_chg <- race_ethnicity$pop - race_ethnicity$lag.pop

# region only
region = subset(race_ethnicity,geotype == 'region')
################ DATA CHECK  ##########################################
#   9 years multiplied by 8 race/ethn = 72 rows 
#######################################################################

# tracts only
tract = subset(race_ethnicity,geotype == 'tract')



################ DATA CHECK  ##########################################
#   9 years multiplied by 627 geo = 5016 rows 
#   5016 rows * 8 race/ethn categories = 45144 TOTAL ROWS
#######################################################################


# add FIPS code from geozone by string pad and adding state code
tract$FIPS <- tract$geozone
tract$FIPS[tract$geotype!='tract'] <- NA
tract$FIPS <- as.numeric(tract$FIPS) * 100
tract$FIPS <- str_pad(tract$FIPS, 5, side = 'left', pad = '0')
tract$FIPS <- paste("060730",tract$FIPS,sep='')

# replace geozone with FIPS
tract$geozone[tract$geotype=='tract'] <- tract$FIPS[tract$geotype=='tract']
tract$FIPS <- NULL 


#   DETERMINE THRESHOLDS  BASED on STANDARD DEVIATION ########################
########## summary w mean and standard dev of pct change of census tracts

# to be used for filtering data by tract for +/- 3 standard deviations

tract_summary <- tract %>%
  select(pop,yr_id,geozone,short_name,pct_of_total,pct_of_total_chg) %>%
  group_by(short_name) %>%
  summarise(pct_of_totalpop  = mean(pct_of_total,na.rm=TRUE),
            mean.yearly.chg = mean(pct_of_total_chg,na.rm=TRUE), 
            stdev.chg = sd(pct_of_total_chg,na.rm=TRUE))

tract_summary['mean.plus.3stdev'] = tract_summary['mean.yearly.chg'] + (3*tract_summary['stdev.chg'])
tract_summary['mean.minus.3stdev'] = tract_summary['mean.yearly.chg'] - (3*tract_summary['stdev.chg'])

# change name of geozone to tract
names(tract)[names(tract) == 'geozone'] <- 'tracts'



# threshold dataframe
# add column w mean & std dev for each year to dataframe of census tracts
threshold_race_ethn <- merge(x = tract, y = tract_summary, by = c("short_name"), all.x = TRUE)

rm(tract)

# create unique columns for filtering and flagging outliers
threshold_race_ethn$short_name_geozone = paste(threshold_race_ethn$short_name,threshold_race_ethn$tracts,sep='_')
threshold_race_ethn$short_name_geozone_yr = paste(threshold_race_ethn$short_name,threshold_race_ethn$tracts,
                                                  threshold_race_ethn$yr_id,sep='_')

# outliers outside of thresholds
outliers = subset(threshold_race_ethn, (pct_of_total_chg >= mean.plus.3stdev | pct_of_total_chg  <= mean.minus.3stdev))

# flag ALL years for a given tract and race/eth category that is an outlier
threshold_race_ethn$flag <- 0
threshold_race_ethn$flag[threshold_race_ethn$short_name_geozone %in% outliers$short_name_geozone] <- 1



# flag for SINGLE year for a given tract and race/eth category that is an outlier
threshold_race_ethn$outliers <- 0
threshold_race_ethn$outliers[threshold_race_ethn$short_name_geozone_yr %in% outliers$short_name_geozone_yr] <- 1

rm(outliers)

# remove column for merging dataframes 
#threshold_race_ethn$short_name_geozone <- NULL
# threshold_race_ethn$short_name_geozone_yr <- NULL



# rename columns 
names(threshold_race_ethn)[names(threshold_race_ethn) == 'pop'] <- 'pop_by_category'
names(threshold_race_ethn)[names(threshold_race_ethn) == 'hhpop'] <- 'totalHHpop'
names(threshold_race_ethn)[names(threshold_race_ethn) == 'gqpop'] <- 'totalGQpop'

# calculate max percent of total change for each geozone/race
# used for sorting data in PowerBI

threshold_race_ethn <- 
  threshold_race_ethn %>% 
  group_by(tracts,short_name) %>% 
  mutate(max.pct_of_total_chg = ifelse( 
    all(is.na(pct_of_total_chg)),NA,max(abs(pct_of_total_chg), na.rm = T)))

# calculate max pop for filtering on pop size
threshold_race_ethn <-
  threshold_race_ethn  %>%
  group_by(tracts,short_name) %>%
  mutate(max.totalpop = max(abs(totalpop),na.rm=TRUE))

# flag census tract with pop less than 1000
threshold_race_ethn <- add_column(threshold_race_ethn,pop.LT.1000 = 0)
threshold_race_ethn$pop.LT.1000[threshold_race_ethn$max.totalpop < 1000] <- 1

# flag census tract with pop less than 1000
threshold_race_ethn <- add_column(threshold_race_ethn,pop.GRE.1000 = 0)
threshold_race_ethn$pop.GRE.1000[threshold_race_ethn$max.totalpop >= 1000] <- 1

# flag census tract with pop less than 1000
threshold_race_ethn <- add_column(threshold_race_ethn,pop.lessthan.1000 = 'no')
threshold_race_ethn$pop.lessthan.1000[threshold_race_ethn$max.totalpop < 1000] <- 'yes'

# remove column after filtering
threshold_race_ethn$max.totalpop <- NULL
threshold_race_ethn$geotype <- NULL

threshold_race_ethn$abs_pct_of_total_chg <- abs(threshold_race_ethn$pct_of_total_chg)
threshold_race_ethn$abs_pop_chg <- abs(threshold_race_ethn$pop_chg)

# outlier_df = subset(threshold_race_ethn,flag==1 & pop.lessthan.1000=='no')
outlier_df = subset(threshold_race_ethn,flag==1) # include small pop
outlier_df$abs_pct_of_total_chg <- abs(outlier_df$pct_of_total_chg)

# outlier_df$total_count = n_distinct(outlier_df$geozone)


outliers_singleyr <- subset(outlier_df,outliers==1)
outliers_singleyr$ID <- seq.int(nrow(outliers_singleyr))
outliers_singleyr$abs_pct_of_total_chg <- abs(outliers_singleyr$pct_of_total_chg)



outliers_allyr <- data.frame()
for(ID in outliers_singleyr$ID) {
  # print(ID)
  
  short_name_geozone <- outliers_singleyr$short_name_geozone[outliers_singleyr$ID==ID]
  x <- threshold_race_ethn[threshold_race_ethn$short_name_geozone == short_name_geozone, ]
  x$ID <- ID
  outliers_allyr <-  bind_rows(outliers_allyr, x)
  
}

outliers_allyr$rowid <- seq.int(nrow(outliers_allyr))

# replace all NA and Inf with "null" otherwise get an error in PowerBI
threshold_race_ethn <- threshold_race_ethn %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

region <- region %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

outlier_df <- outlier_df %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

outliers_allyr <- outliers_allyr %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

unique_tracts <- data.frame(tracts = unique(threshold_race_ethn$tracts))


names(outlier_df)[names(outlier_df) == 'pop_by_category'] <- 'pop'
names(outlier_df)[names(outlier_df) == 'pop_chg'] <- 'chg'
names(outlier_df)[names(outlier_df) == 'pct_of_total'] <- 'pct'
names(outlier_df)[names(outlier_df) == 'pct_of_total_chg'] <- 'pct_chg'
names(outlier_df)[names(outlier_df) == 'short_name'] <- 'name'
names(outlier_df)[names(outlier_df) == 'outliers'] <- 'o'


race_yr_o_yr <- threshold_race_ethn


race_yr_o_yr$lag.pct_of_total <- NULL
race_yr_o_yr$lag.pop <- NULL
race_yr_o_yr$pct_of_totalpop <- NULL
race_yr_o_yr$mean.yearly.chg <- NULL
race_yr_o_yr$stdev.chg <- NULL
race_yr_o_yr$mean.plus.3stdev <- NULL
race_yr_o_yr$mean.minus.3stdev <- NULL
race_yr_o_yr$short_name_geozone <- NULL
race_yr_o_yr$short_name_geozone_yr <- NULL
race_yr_o_yr$pop.LT.1000 <- NULL
race_yr_o_yr$pop.GRE.1000 <- NULL
race_yr_o_yr$pop.lessthan.1000 <- NULL


write.csv(threshold_race_ethn, paste("..\\Data\\ethnicity\\ds",ds_id,"\\threshold_raceethn.csv",sep=''),row.names=FALSE)
write.csv(race_yr_o_yr, paste("..\\Data\\ethnicity\\ds",ds_id,"\\race_yr_o_yr.csv",sep=''),row.names=FALSE)

write.csv(region, paste("..\\Data\\ethnicity\\ds",ds_id,"\\region.csv",sep=''),row.names=FALSE)
write.csv(tract_summary,paste("..\\Data\\ethnicity\\ds",ds_id,"\\tract_summary.csv",sep=''),row.names=FALSE)
write.csv(outlier_df, paste("..\\Data\\ethnicity\\ds",ds_id,"\\outlier_df.csv",sep=''),row.names=FALSE)
write.csv(outliers_singleyr, paste("..\\Data\\ethnicity\\ds",ds_id,"\\outliers_singleyr.csv",sep=''),row.names=FALSE)
write.csv(unique_tracts, paste("..\\Data\\ethnicity\\ds",ds_id,"\\unique_tracts.csv",sep=''),row.names=FALSE)
write.csv(outliers_allyr, paste("..\\Data\\ethnicity\\ds",ds_id,"\\outliers_allyr.csv",sep=''),row.names=FALSE)

