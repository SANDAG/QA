# QA checks of estimates
# created 2/25/2019 


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
}
packages <- c("RODBC", "dplyr", "stringr")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
maindir = dirname(rstudioapi::getSourceEditorContext()$path)

source("../Queries/readSQL.R")

# specify datasource to use
datasource_ids = c(26)

# SQL Queries

# get eatimates and datasource name from database

hh_all <- data.frame()
for(ds_id in datasource_ids) {
  channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
  
  # datasource name
  ds_sql = getSQL("../Queries/datasource_name.sql")
  ds_sql <- gsub("ds_id", ds_id,ds_sql)
  datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  
  #estimates
  hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
  hh_sql <- gsub("ds_id", ds_id,hh_sql)
  hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
  hh$datasource_id = ds_id
  hh_all <- rbind(hh_all,hh)
  
  odbcClose(channel)
}



# add datasource name
hh_all <- merge(x = hh_all, y =datasource_name[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)

# remove columns not needed
hh_all$datasource_id <- NULL

# change variable names
names(hh_all)[names(hh_all) == 'yr_id'] <- 'year'
names(hh_all)[names(hh_all) == 'hhp'] <- 'hhpop'
names(hh_all)[names(hh_all) == 'hhs'] <- 'hhsize'
names(hh_all)[names(hh_all) == 'households'] <- 'hh'
names(hh_all)[names(hh_all) == 'name'] <- 'datasource'

####################################################################
###### function to calculate percent change ########################

# household population, households, and units

calculate.pctchg <- function(df) {
  
    # add column w households,household pop, units from previous year
    growthdf <- 
      df %>%
      group_by(geozone) %>%
      mutate(lag.hhpop =lag(hhpop, order_by = year, default = NA),
          lag.hh = lag(hh,order_by=year,default=NA),
          lag.units = lag(units,order_by=year,default=NA))
  
    # calculate year over year change for hhpop growth,unit and household growth
    growthdf$hhpop.growth = growthdf$hhpop - growthdf$lag.hhpop 
    growthdf$units.growth = growthdf$units - growthdf$lag.units
    growthdf$hh.growth = growthdf$hh - growthdf$lag.hh

    # set growth for year 2010 to 0                
    growthdf$hhpop.growth[growthdf$year == 2010] <- 0 
    growthdf$units.growth[growthdf$year == 2010] <- 0 
    growthdf$hh.growth[growthdf$year == 2010] <- 0
  
    # calculate percent change year over year
    growthdf$pctchg.hhpop = round(growthdf$hhpop.growth/growthdf$lag.hhpop,3)
    growthdf$pctchg.units = round(growthdf$units.growth/growthdf$lag.units,3)
    growthdf$pctchg.hh = round(growthdf$hh.growth/growthdf$lag.hh,3)
    
    # remove unecessary columns after pctchg calculation
    growthdf$lag.hhpop <- NULL
    growthdf$lag.units<- NULL
    growthdf$lag.hh <- NULL
    
    # change na to zero
    growthdf[is.na(growthdf)] <- 0 # otherwise power bi stores columns as strings not numeric
  
    return(growthdf)
}
###### end function to calculate percent change ########################

###### function to calculate vacancy rate ########################

# vacancy rate

calculate.vacancy <- function(df) {
  df$vac = (df$units - df$hh)/df$units
  df$vac[df$units == 0] <- 0
  df$vac = round(df$vac,3)
  return(df)
}
###### end function to calculate vacancy rate  ########################

###### region #################################################
region <- subset(hh_all,geotype=="region")  
region2 = calculate.pctchg(region)
region3 = calculate.vacancy(region2)
region3$geozone <- NULL
region3$geotype <- NULL
write.csv(region3, "..\\Data\\hhpop\\region.csv",row.names=FALSE)

############# end region ###################################################


########### census tract ###############################################
tract <- subset(hh_all,geotype=="tract")

# add FIPS code to census tract for looking up geography
tract$geozone <- as.numeric(tract$geozone)
tract$geox100 =  tract$geozone * 100
tract$geo5 = str_pad(tract$geox100, 5, side = 'left', pad = '0')
tract$FIPS = paste("060730",tract$geo5,sep='')
tract$tract = tract$geozone # rename for power bi filter

# get percent changes for tracts
tract2 = calculate.pctchg(tract)

# remove columns not needed
tract2$geox100 <- NULL
tract2$geo5 <- NULL
tract2$geozone <- NULL
tract2$geotype <- NULL


# calaculate vacancy rate
tract3 = calculate.vacancy(tract2)  
          
# merge tracts with region to get regional averages
tract3 <- merge(x = tract3, y =region3[ , c("hhsize", "vac","year")],
                      by = "year", all.x = TRUE,suffixes = c("",".region"))

# calculate units available by using regional vacancy rate
tract3$units.avail = round(tract3$units - (tract3$units * tract3$vac.region),0)

# calculate hhpop theoretical using regional average persons per household
tract3$hhpop.theoretical = round(tract3$units.avail * tract3$hhsize.region,0)
tract3$hpop.residual = round(tract3$hhpop.theoretical - tract3$hhpop,0)

# remove unecessary column
tract3$units.avail <-NULL

# rename variables
names(tract3)[names(tract3) == 'hhsize.region'] <- 'avg.hhsize.region'
names(tract3)[names(tract3) == 'vac.region'] <- 'avg.vacancy.region'

# calculate max and min percent change in hhpop for each census tract
# tract3 <-
#   tract3 %>%
#   group_by(tract) %>%
#   mutate(max.pctchg.hhpop = max(pctchg.hhpop,na.rm=TRUE),
#          min.pctchg.hhpop = min(pctchg.hhpop,na.rm=TRUE))


# for plotting get min and max over the entire data 
tract3['xlim.max.pctchg.hhpop'] = max(tract3[["pctchg.hhpop"]])
tract3['xlim.min.pctchg.hhpop'] = min(tract3[["pctchg.hhpop"]])

# add new column with FIPS and year for joining dataframe
tract3['FIPS_yr'] = paste(tract3$FIPS,tract3$year,sep='_')

write.csv(tract3, "..\\Data\\hhpop\\estimates.csv",row.names=FALSE)

###################### end census tract estimates  ####################


########## summary w mean and standard dev of pct change of census tracts

# to be used for filtering data by tract for +/- 3 standard deviations

summarydf <- tract3 %>%
  select(hhpop, pctchg.hhpop,year) %>%
  group_by(year) %>%
  summarise(mean.pctchg.hhpop = mean(pctchg.hhpop,na.rm=TRUE), 
            stdev.pctchg.hhpop = sd(pctchg.hhpop,na.rm=TRUE))

summarydf$mean.pctchg.hhpop[summarydf$year == 2010] <- 0 
summarydf$stdev.pctchg.hhpop[summarydf$year == 2010] <- 0

summarydf['sdplus3'] = summarydf['mean.pctchg.hhpop'] + (3*summarydf['stdev.pctchg.hhpop'])
summarydf['sdminus3'] = summarydf['mean.pctchg.hhpop'] - (3*summarydf['stdev.pctchg.hhpop'])

write.csv(summarydf, "..\\Data\\hhpop\\summary.csv",row.names=FALSE)

#### end summary w mean and standard dev



##### filter tracts  based on +/- 3 standard deviations

# add column w mean & std dev for each year to dataframe of census tracts
tract4 <- merge(x = tract3, y = summarydf, by = "year", all.x = TRUE)

years = unique(tract4$year) # unique years in dataframe

outliers <- data.frame()

# note: keep year 2010 - will include all 627 census tracts for reference
# i.e. all will be in outliers dataframe

for(yr in years) {
  
  # for each year get the tracts that are +/- 3 standard deviations from the mean
  geozones = unique(subset(tract4, (pctchg.hhpop >= sdplus3 | pctchg.hhpop <= sdminus3) & year == yr)$tract)
  
  # get data for all other years for each tract in given year that is outlier
  outliers_in_yr <-
    tract4 %>%
    filter(tract %in% geozones)
  # add column with the year that was an outlier
  outliers_in_yr['outlier_yr'] = yr
  
  # add outliers for each year to dataframe
  outliers <- rbind(outliers,outliers_in_yr)
}


outliers_single_yr <- data.frame()

# note: keep year 2010 - will include all 627 census tracts for reference
# i.e. all will be in outliers dataframe

for(yr in years) {
  
  # for each year get the tracts that are +/- 3 standard deviations from the mean
  outliers_in_1yr = unique(subset(tract4, (pctchg.hhpop >= sdplus3 | pctchg.hhpop <= sdminus3) & year == yr))
  
  outliers_in_1yr['outlier_yr'] = yr
  
  # add outliers for each year to dataframe
  outliers_single_yr  <- rbind(outliers_single_yr ,outliers_in_1yr)
}


count_outliers <-
  outliers %>%                    
  group_by(outlier_yr) %>%          
  summarise(outliers = n_distinct(tract))   

# calculate percent outliers for each year
# use year 2010 as total census tracts
count_outliers['Total_Census_Tracts'] = subset(count_outliers,outlier_yr==2010)$outliers
count_outliers['Percent_Outliers'] = count_outliers$outliers/count_outliers['Total_Census_Tracts']

outliers <- merge(x = outliers, y = count_outliers, by = "outlier_yr", all.x = TRUE)
outliers_single_yr <- merge(x = outliers_single_yr, y = count_outliers, by = "outlier_yr", all.x = TRUE)
outliers_single_yr<-outliers_single_yr[!(outliers_single_yr$year==2010),]

write.csv(outliers, "..\\Data\\hhpop\\outliers.csv",row.names=FALSE)
write.csv(outliers_single_yr, "..\\Data\\hhpop\\outliers_single_yr.csv",row.names=FALSE)
