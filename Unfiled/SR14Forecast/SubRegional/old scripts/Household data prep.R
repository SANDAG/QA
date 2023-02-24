
install.packages("installr")
install.packages("plot.new")

library(scales)
library(sqldf)
library(rstudioapi)
library(RODBC)
library(dplyr)
library(reshape2)
library(ggplot2)

library(data.table)
library(stringr)
#library(wesanderson)
#library(RColorBrewer)

#read in files

hh_2016<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2016_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2016$Year<- 2016


hh_2018<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2018_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2018$Year<- 2018


hh_2020<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2020_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2020$Year<- 2020


hh_2025<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2025_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2025$Year<- 2025

hh_2030<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2030_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2030$Year<- 2030

hh_2035<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2035_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2035$Year<- 2035


hh_2040<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2040_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2040$Year<- 2040

hh_2045<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2045_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2045$Year<- 2045

hh_2050<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\households_2050_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
hh_2050$Year<- 2050

#MERGES ALL HOUSEHOLD FILES FOR ALL YEARS TOGETHER

hh_all<-rbind(hh_2016,hh_2018,hh_2020,hh_2025,hh_2030,hh_2035,hh_2040,hh_2045,hh_2050)

geography<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\geography.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")
HouseHold_Geo<-merge(hh_all, geography, by.a="mgra", by.b="MGRA", all=TRUE)

HouseHold_PPH <- melt(HouseHold_Geo, id.vars = c("cpa_name","Year","hinccat1")) 

HouseHold_PPH<-data.frame(table(HouseHold_Geo$hinccat1))
HouseHold_PPH

INCOME_CPA_HH <- addmargins(xtabs( ~ hinccat1 + Year + cpa_name, data=HouseHold_Geo))
INCOME_CPA_HH<- addmargins(round(prop.table((xtabs( ~ hinccat1 + Year+cpa_name, data=INCOME_CPA_HH)),2),4))
summary(xtabs( ~ hinccat1 + Year+ cpa_name, data=HouseHold_Geo))

write.csv(INCOME_CPA_HH, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\INCOME_CPA_HH.csv")
#HH_PPH_CPA<- merge(HouseHold_hhp_SUM,HouseHold_hhp_CPA_MEAN, by.a=c("year", "cpa_name"), by.b=c("year", "cpa_name"), all=TRUE)

rm(hh_2016,hh_2018,hh_2020,hh_2025,hh_2030,hh_2035,hh_2040,hh_2045,hh_2050)


#Use for one line in graph - you need to reset scale_y_continuous to change the scale to accommodate your data

Person_Per_HH<-ggplot(PPERSONS_HH_MEAN_YEAR, aes(x=Year, y=value)) +
  geom_line(size=2) +
  labs(title="Average Number of Persons Per Household", y="Persons", x=" Year",
       caption="Source: 2016-2050 Household projection Files")+
  expand_limits(y = c(1, 9))+
  scale_y_continuous(labels= comma, limits=c(1.0,3.0))+
  theme_bw(base_size = 14)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(filename = "tot_pop.pdf", plot=tot_pop)

#############HouseHold_hhp_SUM<-aggregate(value~Year+cpa_name, data=HouseHold_hhp_CPA, sum)
##HouseHold_hhp_CPA_MEAN<-aggregate(value~Year+cpa_name, data=HouseHold_hhp_CPA, mean)
###setnames(HouseHold_hhp_CPA_MEAN, old=c("value"), new=c("Mean_PPH"))

