# base year by hinc categories

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

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

mgra_to_jur_sql = getSQL("../Queries/geography.sql")
mgra_to_jur<-sqlQuery(channel,mgra_to_jur_sql)

income_sql = getSQL("../Queries/income_categories.sql")
income_cat<-sqlQuery(channel,income_sql)

odbcClose(channel)

nrow(mgra_to_jur)

mgra_to_jur <- rename(mgra_to_jur, JUR1 = jurisdiction)
mgra_to_jur <- rename(mgra_to_jur, JUR2 = jurisdiction_and_cpa)


#######################################
# base year 2016
hhinc2016 <- read.csv(paste("T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\households_2016_01.csv",sep=''), 
                  stringsAsFactors = FALSE)
hhinc2016 <- merge(x = hhinc2016, y =mgra_to_jur,by = "mgra")
hhinc2016 <- merge(x = hhinc2016, y =income_cat,by = "hinccat1")
median(hhinc2016$hinc)
# remove group quarters 
hh_no_gq2016 = subset(hhinc2016,hht!=0)
nrow(hh_no_gq2016)
median(hh_no_gq2016$hinc)
#########################################
# base year 2012
hhinc2012 <- read.csv(paste("T:\\ABM\\release\\ABM\\version_13_3_2\\input\\2012\\households.csv",sep=''), 
                      stringsAsFactors = FALSE)
hhinc2012 <- merge(x = hhinc2012, y =mgra_to_jur,by = "mgra")
hhinc2012 <- merge(x = hhinc2012, y =income_cat,by = "hinccat1")
median(hhinc2012$hinc)
# remove group quarters 
hh_no_gq2012 = subset(hhinc2012,hht!=0)
nrow(hh_no_gq2012)
median(hh_no_gq2012$hinc)
########################################

# region ###################################################
inc2016_by_region  <- hh_no_gq2016 %>% group_by(hinccat1,income_range,constant_dollars_year) %>% tally()
inc2016_by_region <- rename(inc2016_by_region, count_households_2016 = n)
inc2012_by_region <- hh_no_gq2012 %>% group_by(hinccat1,income_range,constant_dollars_year) %>% tally()
inc2012_by_region <- rename(inc2012_by_region, count_households_2012 = n)
hhinc_region <- merge(x = inc2012_by_region, y =inc2016_by_region ,
                      by = c("hinccat1","income_range","constant_dollars_year"))
hhinc_region$JUR1 = 0
hhinc_region$JUR2 = 0
hhinc_region$geography_name = 'Region'
hhinc_region$geography = 'region'
rm(inc2016_by_region)
rm(inc2012_by_region)
##########################################################

# jurisdiction ############################################
inc2016_by_jur <-
  hh_no_gq2016 %>%
  count(JUR1,jurisdiction_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)
inc2016_by_jur <- rename(inc2016_by_jur, count_households_2016 = n)
inc2012_by_jur <-
  hh_no_gq2012 %>%
  count(JUR1,jurisdiction_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)
inc2012_by_jur <- rename(inc2012_by_jur, count_households_2012 = n)
hhinc_jurisdiction <- merge(x = inc2012_by_jur , y =inc2016_by_jur,
                            by = c("hinccat1","JUR1","income_range",
                                   "constant_dollars_year","jurisdiction_name"))
hhinc_jurisdiction <- rename(hhinc_jurisdiction, geography_name = jurisdiction_name)
#hhinc_jurisdiction <- rename(hhinc_jurisdiction, jur2 = jurisdiction)
hhinc_jurisdiction$geography = 'jurisdiction'
hhinc_jurisdiction$JUR2 <- hhinc_jurisdiction$JUR1
rm(inc2016_by_jur)
rm(inc2012_by_jur)
#############################################################

# cpa ############################################

inc2016_by_jur_and_cpa <-
  hh_no_gq2016 %>%
  count(jurisdiction_and_cpa_name,JUR1,JUR2,hinccat1,income_range,constant_dollars_year, sort = FALSE)

inc2016_by_jur_and_cpa <- rename(inc2016_by_jur_and_cpa, count_households_2016 = n)

inc2012_by_jur_and_cpa <-
  hh_no_gq2012 %>%
  count(jurisdiction_and_cpa_name,JUR1,JUR2,hinccat1,income_range,constant_dollars_year, sort = FALSE)

inc2012_by_jur_and_cpa <- rename(inc2012_by_jur_and_cpa, count_households_2012 = n)
hhinc_cpa <- merge(x = inc2012_by_jur_and_cpa, y =inc2016_by_jur_and_cpa,
                                    by = c("hinccat1","jurisdiction_and_cpa_name","income_range",
                                           "constant_dollars_year","JUR1","JUR2"),all=TRUE)
hhinc_cpa <- subset(hhinc_cpa,JUR2>19)
hhinc_cpa <- rename(hhinc_cpa, geography_name = jurisdiction_and_cpa_name)
# hhinc_cpa <- rename(hhinc_cpa, jur2 = jurisdiction_and_cpa)
hhinc_cpa$geography = 'cpa'
rm(inc2016_by_jur_and_cpa)
rm(inc2012_by_jur_and_cpa)
###########################################################################

outfolder = "..\\output"
dir.create(file.path(outfolder), showWarnings = FALSE)
setwd(file.path(outfolder))


hhinc <- rbind(hhinc_region, hhinc_jurisdiction, hhinc_cpa)

hhinc <- rename(hhinc, income_categories = hinccat1)

hhinc['pct_chg'] <- (hhinc$count_households_2016-hhinc$count_households_2012)/hhinc$count_households_2012

hhinc['diff_2016_minus_2012'] <- hhinc$count_households_2016-hhinc$count_households_2012

#inc2016_by_jur_and_cpa <-
#  hh_no_gq2016 %>%
#  count(jurisdiction_and_cpa,jurisdiction_and_cpa_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)


summary <- hhinc %>%
  select(count_households_2012,count_households_2016,JUR2,geography_name,geography) %>%
  group_by(JUR2,geography_name,geography) %>%
  summarise(hh2012 = sum(count_households_2012,na.rm=TRUE),hh2016 = sum(count_households_2016,na.rm=TRUE))

subset(summary,geography_name=='Desert')

hhinc<- merge(x = hhinc, y = summary, by = c('JUR2','geography_name','geography'), all.x = TRUE)

hhinc$pct_of_tot2012 <- hhinc$count_households_2012/hhinc$hh2012
hhinc$pct_of_tot2016 <- hhinc$count_households_2016/hhinc$hh2016

hhinc$diff_pct_of_total <- hhinc$pct_of_tot2016 - hhinc$pct_of_tot2012

hhinc$abs_diff_pct_of_total <- abs(hhinc$diff_pct_of_total)

# replace all NA and Inf with "null" otherwise get an error in PowerBI
hhinc <- hhinc %>% 
  mutate_all(~replace(.,is.na(.)|is.infinite(.),'null'))


hhinc <- hhinc[,c(3,9,1,2,4,5,6,7,8,11,12,13,14,15,16,10,17)]
hhinc <- hhinc[,c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,16,10,15,17)]
write.csv(hhinc,"hhinc.csv",row.names=FALSE)

data_long <- gather(hhinc, base_year, households,count_households_2012,count_households_2016 , factor_key=TRUE)
data_long$base_year = as.character(data_long$base_year)
data_long$base_year[data_long$base_year=="count_households_2012"]<-2012
data_long$base_year[data_long$base_year=="count_households_2016"]<-2016
subset(data_long,JUR2 ==4)

write.csv(data_long,"hhinc_l.csv",row.names=FALSE)


data_long <- gather(hhinc, base_year, pct_of_total,pct_of_tot2012,pct_of_tot2016,factor_key=TRUE)
data_long$base_year = as.character(data_long$base_year)
data_long$base_year[data_long$base_year=="pct_of_tot2012"]<-2012
data_long$base_year[data_long$base_year=="pct_of_tot2016"]<-2016
subset(data_long,JUR2 ==4)

write.csv(data_long,"hhinc_pcttot.csv",row.names=FALSE)
