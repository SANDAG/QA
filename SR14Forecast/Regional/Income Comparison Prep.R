pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#bring data in from SQL
#channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=data_cafe; trusted_connection=true')
#geo_sql = getSQL("../Queries/geography.sql")
#geography<-sqlQuery(channel,geo_sql)
#odbcClose(channel)

options('scipen'=10)

inc_abm_13_2020<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2020\\mgra13_based_input2020.csv", stringsAsFactors = FALSE)
inc_abm_13_2025<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2025\\mgra13_based_input2025.csv", stringsAsFactors = FALSE)
inc_abm_13_2035<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2035\\mgra13_based_input2035.csv", stringsAsFactors = FALSE)
inc_abm_13_2050<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2050\\mgra13_based_input2050.csv", stringsAsFactors = FALSE)


inc_abm_13_2020$yr = 2020
inc_abm_13_2025$yr = 2025
inc_abm_13_2035$yr = 2035
inc_abm_13_2050$yr = 2050

inc_abm_13<-rbind(inc_abm_13_2020,inc_abm_13_2025,inc_abm_13_2035,inc_abm_13_2050)

inc_abm_13$cat1<- inc_abm_13$i1 + inc_abm_13$i2
inc_abm_13$cat2<- inc_abm_13$i3 + inc_abm_13$i4
inc_abm_13$cat3<- inc_abm_13$i5 + inc_abm_13$i6
inc_abm_13$cat4<- inc_abm_13$i7 + inc_abm_13$i8
inc_abm_13$cat5<- inc_abm_13$i9 + inc_abm_13$i10

inc_abm_13<-select(inc_abm_13, mgra, hh, yr, cat1, cat2, cat3, cat4, cat5)

#SQL query isn't working above so currently accesses file from project folder
geography <-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\median_income\\geography.csv", stringsAsFactors = FALSE)
colnames(geography)[1]<-"mgra_13"

geography$cocpa_13<-as.numeric(geography$cocpa_13)
geography$cicpa_13<-as.numeric(geography$cicpa_13)

geography$cpa_13<- ifelse(is.na(geography$cicpa_13) & !is.na(geography$cocpa_13), geography$cocpa_13, geography$cicpa_13)

summary(geography$cpa_13)
head(geography)

inc_abm_13 <- merge(inc_abm_13, geography, by.x="mgra", by.y="mgra_13")
#areas not in a CPA are coded as 9
inc_abm_13$cpa_[is.na(inc_abm_13$cpa_13)]<- 9

inc_abm_13_cpa <- aggregate (cbind(cat1, cat2, cat3, cat4, cat5)~cpa_13+yr, data=inc_abm_13, sum)
inc_abm_13_cpa <- melt(inc_abm_13_cpa, id.vars=c("cpa_13", "yr"))
setnames(inc_abm_13_cpa,old=c("variable","value"),new=c("income_group_id","hh"))

inc_abm_13_cpa$income_group_id <-as.character(inc_abm_13_cpa$income_group_id)

inc_abm_13_cpa$income_group_id[inc_abm_13_cpa$income_group_id=="cat1"]<- "1"
inc_abm_13_cpa$income_group_id[inc_abm_13_cpa$income_group_id=="cat2"]<- "2"
inc_abm_13_cpa$income_group_id[inc_abm_13_cpa$income_group_id=="cat3"]<- "3"
inc_abm_13_cpa$income_group_id[inc_abm_13_cpa$income_group_id=="cat4"]<- "4"
inc_abm_13_cpa$income_group_id[inc_abm_13_cpa$income_group_id=="cat5"]<- "5"


inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="1"]<- 0
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="1"]<- 29999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="2"]<- 30000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="2"]<- 59999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="3"]<- 60000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="3"]<- 99999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="4"]<- 100000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="4"]<- 149999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="5"]<- 150000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="5"]<- 349999


#I added one to interval calculation because it looks like there is a rounding thing happening in SQL script results - keep or delete?
inc_abm_13_cpa$interval_width<-inc_abm_13_cpa$upper_bound-inc_abm_13_cpa$lower_bound +1


inc_abm_13_cpa<- inc_abm_13_cpa[order(inc_abm_13_cpa$cpa_13,inc_abm_13_cpa$yr),]

inc_abm_13_cpa <- data.table(inc_abm_13_cpa)
inc_abm_13_cpa[, cum_sum := cumsum(hh), by=list(yr, cpa_13)]

inc_abm_13_cpa<-as.data.frame.matrix(inc_abm_13_cpa) 

num_hh_cpa<-aggregate(hh~cpa_13+yr, data = inc_abm_13_cpa, sum)

inc_dist<-inc_abm_13_cpa

num_hh_cpa$hh_half<-num_hh_cpa$hh/2.0

cum_dist<-inc_dist

cum_dist$hh_full<-num_hh_cpa[match(paste(cum_dist$cpa_13, cum_dist$yr), paste(num_hh_cpa$cpa_13, num_hh_cpa$yr)),"hh"]

cum_dist$hh_half<-num_hh_cpa[match(paste(cum_dist$cpa_13, cum_dist$yr), paste(num_hh_cpa$cpa_13, num_hh_cpa$yr)),"hh_half"]

head(inc_dist)
head(cum_dist,15)


##########
#add formula for median income and exclude records of income groups below the group where the median will be found
##lower bound per income group- (hh by year and geozone/2-(cum_sum ???-))

cum_dist$med_inc<-cum_dist$lower_bound+((cum_dist$hh_half-(cum_dist$cum_sum-cum_dist$hh))/cum_dist$hh)*cum_dist$interval_width

cum_dist$flag<-0
cum_dist$flag[cum_dist$cum_sum>cum_dist$hh_half]<-1

cum_dist<- subset(cum_dist, cum_dist$flag==1)

cum_dist<-cum_dist %>% group_by(cpa_13, yr) %>% summarise(count=n(), med_inc=first(med_inc))



median_inc<-aggregate(income_group_id~yr+cpa_13, data = cum_dist, min)

#check for negative median income
#neg<- subset(cum_dist_test2, cum_dist_test2$med_inc<1)






head(abm_med_inc$med_inc)
#HAVING SUM(b.hh) > (num_hh.hh / 2.0);

median_inc<-aggregate(income_group_id~yr+cpa_13, data = cum_dist, min)

head(median_inc,15)

inc13_jur <- aggregate(cbind(cat1, cat2, cat3, cat4, cat5)~jurisdiction_2015+yr, data = inc13geo,sum)
inc13_jur <- melt(inc13_jur, id.vars=c("jurisdiction_2015", "yr"))

inc13_reg <- aggregate (c(i1,i2,i3,i4,i5,i6,i7,i8,i9,i10)~+yr, data = inc13geo,sum)                       
summary(Inc13geo$jurisdiction_2015)
class(Inc13geo$jurisdiction_2015)
table(Inc13geo$jurisdiction_2015)
class(inc13geo$i1)

inc13_reg <- aggregate(i1~yr+jurisdiction_2015, data = inc13geo,sum) 





