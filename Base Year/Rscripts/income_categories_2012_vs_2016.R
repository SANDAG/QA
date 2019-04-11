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
inc2016_by_region <- hh_no_gq2016 %>% group_by(hinccat1,income_range,constant_dollars_year) %>% tally()
inc2016_by_region <- rename(inc2016_by_region, count_households_2016 = n)
inc2012_by_region <- hh_no_gq2012 %>% group_by(hinccat1,income_range,constant_dollars_year) %>% tally()
inc2012_by_region <- rename(inc2012_by_region, count_households_2012 = n)
hhinc_region <- merge(x = inc2012_by_region, y =inc2016_by_region ,
                      by = c("hinccat1","income_range","constant_dollars_year"))
hhinc_region$geography_id = 'region'
hhinc_region$geography_name = 'Region'
hhinc_region$geography = 'region'
rm(inc2016_by_region)
rm(inc2012_by_region)
##########################################################

# jurisdiction ############################################
inc2016_by_jur <-
  hh_no_gq2016 %>%
  count(jurisdiction,jurisdiction_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)
inc2016_by_jur <- rename(inc2016_by_jur, count_households_2016 = n)
inc2012_by_jur <-
  hh_no_gq2012 %>%
  count(jurisdiction,jurisdiction_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)
inc2012_by_jur <- rename(inc2012_by_jur, count_households_2012 = n)
hhinc_jurisdiction <- merge(x = inc2012_by_jur , y =inc2016_by_jur,
                            by = c("hinccat1","jurisdiction","income_range",
                                   "constant_dollars_year","jurisdiction_name"))
hhinc_jurisdiction <- rename(hhinc_jurisdiction, geography_name = jurisdiction_name)
hhinc_jurisdiction <- rename(hhinc_jurisdiction, geography_id = jurisdiction)
hhinc_jurisdiction$geography = 'jurisdiction'
rm(inc2016_by_jur)
rm(inc2012_by_jur)
#############################################################

# cpa ############################################
inc2016_by_jur_and_cpa <-
  hh_no_gq2016 %>%
  count(jurisdiction_and_cpa,jurisdiction_and_cpa_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)

inc2016_by_jur_and_cpa <- rename(inc2016_by_jur_and_cpa, count_households_2016 = n)

inc2012_by_jur_and_cpa <-
  hh_no_gq2012 %>%
  count(jurisdiction_and_cpa,jurisdiction_and_cpa_name,hinccat1,income_range,constant_dollars_year, sort = FALSE)

inc2012_by_jur_and_cpa <- rename(inc2012_by_jur_and_cpa, count_households_2012 = n)
hhinc_cpa <- merge(x = inc2012_by_jur_and_cpa, y =inc2016_by_jur_and_cpa,
                                    by = c("hinccat1","jurisdiction_and_cpa","income_range",
                                           "constant_dollars_year","jurisdiction_and_cpa_name"),
                   all=TRUE)
hhinc_cpa <- subset(hhinc_cpa,jurisdiction_and_cpa>19)
hhinc_cpa <- rename(hhinc_cpa, geography_name = jurisdiction_and_cpa_name)
hhinc_cpa <- rename(hhinc_cpa, geography_id = jurisdiction_and_cpa)
hhinc_cpa$geography = 'cpa'
rm(inc2016_by_jur_and_cpa)
rm(inc2012_by_jur_and_cpa)
###########################################################################

outfolder = "..\\output"
dir.create(file.path(outfolder), showWarnings = FALSE)
setwd(file.path(outfolder))


hhinc <- rbind(hhinc_region, hhinc_jurisdiction, hhinc_cpa)

hhinc <- rename(hhinc, income_categories = hinccat1)

write.csv(hhinc,"hhinc.csv",row.names=FALSE)

