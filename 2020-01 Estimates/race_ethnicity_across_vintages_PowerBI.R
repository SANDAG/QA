# estimates
# compare datasources for race ethnicity differences

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("RODBC","tidyverse")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

# getwd()

datasource_ids = c(24,27)
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

demo_sql = getSQL("../Queries/age_ethn_gender.sql")
demo_sql <- gsub("ds_id", ds_id,demo_sql)
demo<-sqlQuery(channel,demo_sql)
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


# add datasource name, i.e. "2018 estimates"
race_ethnicity <- merge(x = race_ethnicity, y =sourcename[ , c("name","datasource_id","description")],by = "datasource_id")
names(race_ethnicity)[names(race_ethnicity) == 'name'] <- 'datasource'
rm(sourcename)

# aggregate population by race ethnicity and year and geography and datasource
# this removes age categories and M/F
race_ethnicity<-aggregate(pop~short_name+ethnicity_id+geotype+geozone+yr_id+datasource_id+datasource+description, data=race_ethnicity, sum)

# for checking data
# subset(race_ethnicity,geotype == 'region' & short_name=='American Indian' & yr_id == 2016)

# add total pop, household pop, gqpop
race_ethnicity <- merge(x = race_ethnicity, y =householdpop,by = c("yr_id","geozone","geotype","datasource_id"))

#cleanup
rm(datasource_name)
rm(demo)
rm(hhpop)
rm(householdpop)

################ DATA CHECK  ##########################################
# total expected rows in dataframe
# datasource 24: 627 tracts + 86 cpa + 19 jurs + 1 region = 733
#   8 race/eth multiplied by 7 years multiplied by 733 geo = 41048 rows
# datasource 26: 627 tracts + 89 cpa + 19 jurs + 1 region = 736
#   8 race/eth multiplied by 9 years multiplied by 736 geo = 52992 rows
# total rows = 94040
#######################################################################

# remove "not in a cpa" rows (9 year * 8 race/eth = 72 rows removed. 
# 93968 rows remaining
race_ethnicity<-race_ethnicity[!(race_ethnicity$geozone=="*Not in a CPA*"),]

# remove cpas new to datasource 18:
#    1. Via De La Valle Reserve
#    2. Marine Corps Recruit Depot

race_ethnicity<-race_ethnicity[!(race_ethnicity$geozone=="Via De La Valle Reserve"),]
# 72 rows removed. 93896 rows remain  
race_ethnicity<-race_ethnicity[!(race_ethnicity$geozone=="Marine Corps Recruit Depot"),]
# 72 rows removed. 93824 rows remain  


# clean up CPA names by removing special characters
race_ethnicity$geozone <- gsub("\\*","",race_ethnicity$geozone)
race_ethnicity$geozone <- gsub("\\-","_",race_ethnicity$geozone)
race_ethnicity$geozone <- gsub("\\:","_",race_ethnicity$geozone)

# change cpa names in 2016 estimates to match names in 2018 
race_ethnicity$geozone[race_ethnicity$geozone == 'City Heights'] <- 'Mid_City_City Heights'
race_ethnicity$geozone[race_ethnicity$geozone == 'Eastern Area'] <- 'Mid_City_Eastern Area'
race_ethnicity$geozone[race_ethnicity$geozone == 'Encanto'] <- 'Southeastern_Encanto Neighborhoods'
race_ethnicity$geozone[race_ethnicity$geozone == 'Kensington_Talmadge'] <- 'Mid_City_Kensington_Talmadge'
race_ethnicity$geozone[race_ethnicity$geozone == 'Normal Heights'] <- 'Mid_City_Normal Heights'
race_ethnicity$geozone[race_ethnicity$geozone == 'Nestor'] <- 'Otay Mesa_Nestor'
race_ethnicity$geozone[race_ethnicity$geozone == 'Southeastern San Diego'] <- 'Southeastern_Southeastern San Diego'
race_ethnicity$geozone[race_ethnicity$geozone == 'Ncfua Reserve'] <- 'NCFUA Reserve'
race_ethnicity$geozone[race_ethnicity$geozone == 'Ncfua Subarea 2'] <- 'NCFUA Subarea 2'

######################################################################
#creates file with population totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id+datasource_id, data=race_ethnicity, sum)
names(geozone_pop)[names(geozone_pop) == 'pop'] <- 'totalpop'
################ DATA CHECK  ##################################

# add population totals by geozone (to race/ethnicity pop totals)
race_ethnicity <- merge(x = race_ethnicity, y =geozone_pop,by = c("yr_id","geozone","geotype","datasource_id"))


# subset(race_ethnicity,geotype == 'region' & short_name=='American Indian' & yr_id == 2016)


rm(geozone_pop)


# add gq pop
race_ethnicity$gqpop = race_ethnicity$totalpop - race_ethnicity$hhpop


#remove columns
race_ethnicity$ethnicity_id <- NULL
# race_ethnicity$datasource_id <- NULL

# calculate percent of total population for each race/ethn
race_ethnicity$pct_of_total<-ifelse(race_ethnicity$totalpop==0,NA,race_ethnicity$pop / race_ethnicity$totalpop)


# order dataframe
race_ethnicity <- race_ethnicity[order(race_ethnicity$datasource,race_ethnicity$short_name,race_ethnicity$geotype,race_ethnicity$geozone,race_ethnicity$yr_id),]

# check data
# subset(race_ethnicity,geozone=='Alpine'& short_name=='Black')


# region only
# rename geozone for region
race_ethnicity$geozone[race_ethnicity$geotype =="region"]<- "Region"
region = subset(race_ethnicity,geozone == 'Region')
region$geotype <- NULL

regionest2016 = subset(region,datasource=='2016 Estimates')
regionest2018 = subset(region,datasource=='2018 Estimates')
region_across_vintage <- merge(x = regionest2016, y =regionest2018,by = c("yr_id","geozone","short_name"),
                                                                  suffixes = c(".2016est",".2018est"))                                                     
region_across_vintage$pct_of_total_chg <- region_across_vintage$pct_of_total.2018est - region_across_vintage$pct_of_total.2016est
region_across_vintage$pop_chg <- region_across_vintage$pop.2018est - region_across_vintage$pop.2016est


# 2016 only
# race_ethnicity <- subset(race_ethnicity, yr_id ==2016)

################ DATA CHECK  ##########################################
#   9 years multiplied by 8 race/ethn = 72 rows 
#######################################################################

# tracts only
tract = subset(race_ethnicity,geotype == 'tract')

rm(race_ethnicity)

# add FIPS code from geozone by string pad and adding state code
tract['FIPS'] <- tract$geozone
tract$FIPS[tract$geotype!='tract'] <- NA
tract$FIPS <- as.numeric(tract$FIPS) * 100
tract$FIPS <- str_pad(tract$FIPS, 5, side = 'left', pad = '0')
tract$FIPS <- paste("060730",tract$FIPS,sep='')

# replace geozone with FIPS
tract$geozone[tract$geotype=='tract'] <- tract$FIPS[tract$geotype=='tract']
tract$FIPS <- NULL 


names(tract)[names(tract) == 'geozone'] <- 'tracts'

tractslong <-tract

tract2016est2016 = subset(tract,datasource=='2016 Estimates')
tract2016est2018 = subset(tract,datasource=='2018 Estimates')


tractswide <- merge(x = tract2016est2016, y =tract2016est2018,by = c("yr_id","tracts","geotype","short_name"),
                 suffixes = c(".2016est",".2018est"))


tractswide$pct_of_total_chg <- tractswide$pct_of_total.2018est - tractswide$pct_of_total.2016est
tractswide$abs_pct_of_total_chg <- abs(tractswide$pct_of_total.2018est - tractswide$pct_of_total.2016est)

tractswide$pop_chg <- tractswide$pop.2018est - tractswide$pop.2016est
tractswide$abs_pop_chg <- abs(tractswide$pop.2018est - tractswide$pop.2016est)

rm(tract2016est2016)
rm(tract2016est2018)
rm(tract)

df2016 <- subset(tractswide, yr_id ==2016)


tract_summary <- df2016 %>%
  select(yr_id,short_name,pct_of_total.2016est,pct_of_total.2018est,pct_of_total_chg) %>%
  group_by(short_name) %>%
  summarise(pct_of_total2016est  = mean(pct_of_total.2016est,na.rm=TRUE),
            pct_of_total2018est  = mean(pct_of_total.2018est,na.rm=TRUE),
            mean.yearly.chg = mean(pct_of_total_chg,na.rm=TRUE), 
            stdev.chg = sd(pct_of_total_chg,na.rm=TRUE))

tract_summary['mean.plus.3stdev'] = tract_summary['mean.yearly.chg'] + (3*tract_summary['stdev.chg'])
tract_summary['mean.minus.3stdev'] = tract_summary['mean.yearly.chg'] - (3*tract_summary['stdev.chg'])


# threshold dataframe
# add column w mean & std dev for each year to dataframe of census tracts
df <- merge(x = df2016, y = tract_summary, by = c("short_name"), all.x = TRUE)


# create unique columns for filtering and flagging outliers
df$short_name_geozone = paste(df$short_name,df$tracts,sep='_')
df$short_name_geozone_yr = paste(df$short_name,df$tracts,
                                                  df$yr_id,sep='_')

# outliers outside of thresholds
outliers = subset(df, (pct_of_total_chg >= mean.plus.3stdev | pct_of_total_chg  <= mean.minus.3stdev))

# flag ALL years for a given tract and race/eth category that is an outlier
df$flag <- 0
df$flag[df$short_name_geozone %in% outliers$short_name_geozone] <- 1


# flag for SINGLE year for a given tract and race/eth category that is an outlier
df$outliers <- 0
df$outliers[df$short_name_geozone_yr %in% outliers$short_name_geozone_yr] <- 1

rm(outliers)

# rename columns 
names(df)[names(df) == 'pop'] <- 'pop_by_category'
names(df)[names(df) == 'hhpop'] <- 'totalHHpop'
names(df)[names(df) == 'gqpop'] <- 'totalGQpop'

# calculate max percent of total change for each geozone/race
# used for sorting data in PowerBI

df <- 
  df %>% 
  group_by(tracts,short_name) %>% 
  mutate(max.pct_of_total_chg = ifelse( 
    all(is.na(pct_of_total_chg)),NA,max(abs(pct_of_total_chg), na.rm = T)))


# calculate max pop for filtering on pop size
df <-
  df  %>%
  group_by(tracts,short_name) %>%
  mutate(max.totalpop = max(abs(totalpop.2018est),na.rm=TRUE))

# flag census tract with pop less than 1000
# df <- add_column(df,pop.LT.1000 = 0)
# df$pop.LT.1000[df$max.totalpop < 1000] <- 1

# flag census tract with pop less than 1000
# df <- add_column(df,pop.GRE.1000 = 0)
# df$pop.GRE.1000[df$max.totalpop >= 1000] <- 1

# flag census tract with pop less than 1000
# df <- add_column(df,pop.lessthan.1000 = 'no')
# df$pop.lessthan.1000[df$max.totalpop < 1000] <- 'yes'

# remove column after filtering
df$max.totalpop <- NULL
df$geotype <- NULL


# outlier_df = subset(df,flag==1 & pop.lessthan.1000=='no')
outlier_df = subset(df,flag==1) # include small pop
outlier_df$abs_pct_of_total_chg <- abs(outlier_df$pct_of_total_chg)

# outlier_df$total_count = n_distinct(outlier_df$geozone)

# replace all NA and Inf with "null" otherwise get an error in PowerBI
df <- df %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

tractswide <- tractswide %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))


tractslong <- tractswide %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

region <- region %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))

outlier_df <- outlier_df %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))


names(outlier_df)[names(outlier_df) == 'pop_by_category'] <- 'pop'
names(outlier_df)[names(outlier_df) == 'pop_chg'] <- 'chg'
names(outlier_df)[names(outlier_df) == 'pct_of_total'] <- 'pct'
names(outlier_df)[names(outlier_df) == 'pct_of_total_chg'] <- 'pct_chg'
names(outlier_df)[names(outlier_df) == 'short_name'] <- 'name'
names(outlier_df)[names(outlier_df) == 'outliers'] <- 'o'


outfolder = paste("..\\Data\\ethnicity\\ds_",datasource_ids[1],"_",datasource_ids[2],"\\",sep='')
dir.create(file.path(outfolder), showWarnings = FALSE)
setwd(file.path(outfolder))


df$race_tract = paste(df$short_name,df$tracts,sep='_')
tractswide$race_tract = paste(tractswide$short_name,tractswide$tracts,sep='_')


df$mean.yearly.chg <- NULL
df$stdev.chg <- NULL
df$mean.plus.3stdev <- NULL
df$mean.minus.3stdev <- NULL
df$short_name_geozone <- NULL
df$short_name_geozone_yr <-NULL


write.csv(region, "region_across_vintage_long.csv",row.names=FALSE)
write.csv(region_across_vintage, "region_across_vintage_wide.csv",row.names=FALSE)

write.csv(df, "tract_across_vintage2016.csv",row.names=FALSE)
write.csv(tract_summary,"summary_tract_across_vintage.csv",row.names=FALSE)
# write.csv(outlier_df,"tract_outlier_across_vintage.csv",row.names=FALSE)

write.csv(tractswide,"tracts_across_vintage_wide.csv",row.names=FALSE)
write.csv(tractslong,"tracts_across_vintage_long.csv",row.names=FALSE)

