
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash")
pkgTest(packages)

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get hhpop data
hhvars <- readDB("../Queries/hh_hhp_hhs_ds_id.sql",datasource_id_current)
odbcClose(channel)

#hhsize <- hhvars %>% select("datasource_id","geotype","geozone","yr_id","hhs")
 
iqrdf <- subset(hhvars,units>5000) %>% 
    group_by(yr_id) %>% # group by increment
    mutate(lowerq = quantile(hhvars$hhs)[2],
           upperq = quantile(hhvars$hhs)[4])
  
iqrdf$iqr <- iqrdf$upperq - iqrdf$lowerq
iqrdf$iqrx1.5 <- iqrdf$iqr * 1.5
iqrdf$threshold.lower = iqrdf$lowerq - iqrdf$iqrx1.5

# iqrdf$threshold.lower[iqrdf$threshold.lower<0] <- 0
iqrdf$threshold.upper <- iqrdf$iqrx1.5 + iqrdf$upperq
list_of_outliers <- unique(subset(iqrdf,(iqrdf$hhs>iqrdf$threshold.upper | 
                                             iqrdf$hhs<iqrdf$threshold.lower))$geozone)
list_of_outliers

outliers  <- subset(hhvars,geozone %in% (list_of_outliers))

write.csv(outliers,'hhsize_outliers.csv')

ggplot(subset(hhvars,units>10000), aes(x=as.factor(yr_id),y=hhs)) + 
  geom_boxplot() + 
  labs(title="Household Size at Forecast Increments: all geographies", 
       subtitle="Outliers by IQR", 
       caption=paste("Source: Demographic Warehouse Datasource:",sep=''),
       y="Household Size", x="Increment",
       color=NULL)  # title and caption

subset(hhvars,geozone=="Downtown")
