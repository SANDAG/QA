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

Income13_2020<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2020\\mgra13_based_input2020.csv", stringsAsFactors = FALSE)
Income13_2025<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2025\\mgra13_based_input2025.csv", stringsAsFactors = FALSE)
Income13_2035<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2035\\mgra13_based_input2035.csv", stringsAsFactors = FALSE)
Income13_2050<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2050\\mgra13_based_input2050.csv", stringsAsFactors = FALSE)


Income13_2020$yr = 2020
Income13_2025$yr = 2025
Income13_2035$yr = 2035
Income13_2050$yr = 2050

Income13<-rbind(Income13_2020,Income13_2025,Income13_2035,Income13_2050)

Income13$cat1<- Income13$i1 + Income13$i2
Income13$cat2<- Income13$i3 + Income13$i4
Income13$cat3<- Income13$i5 + Income13$i6
Income13$cat4<- Income13$i7 + Income13$i8
Income13$cat5<- Income13$i9 + Income13$i10


##Still need to save on M Drive
Geo_Mgra13 <-read.csv("C:\\Users\\dco\\Desktop\\QA Version Control\\SR14Forecast\\Regional\\Geography_MGRA_13.csv", stringsAsFactors = FALSE)

Geo_Mgra13$cocpa_13<-as.numeric(Geo_Mgra13$cocpa_13)
Geo_Mgra13$cicpa_13<-as.numeric(Geo_Mgra13$cicpa_13)

Geo_Mgra13$cpa_13<- ifelse(is.na(Geo_Mgra13$cicpa_13) & !is.na(Geo_Mgra13$cocpa_13), Geo_Mgra13$cocpa_13, Geo_Mgra13$cicpa_13)

summary(Geo_Mgra13$cpa_13)

inc13geo <- merge(Income13, Geo_Mgra13, by.x="mgra", by.y="ï..mgra_13")
inc13geo$cpa_13[is.na(inc13geo$cpa_13)]<- 9
summary(inc13geo$cpa_13)

inc13_cpa <- aggregate (cbind(cat1, cat2, cat3, cat4, cat5)~cpa_13+yr, data= inc13geo, sum)
inc13_cpa_melt <- melt(inc13_cpa, id.vars=c("cpa_13", "yr"))
setnames(inc13_cpa_melt, old="variable", new="income_group_id")

as.character(inc13_cpa_melt$income_group_id)

inc13_cpa_melt$income_group_id[inc13_cpa_melt$income_group_id=="cat1"]<- "1"



inc13_jur <- aggregate(cbind(cat1, cat2, cat3, cat4, cat5)~jurisdiction_2015+yr, data = inc13geo,sum)
inc13_jur_melt <- melt(inc13_jur, id.vars=c("jurisdiction_2015", "yr"))




inc13_reg <- aggregate (c(i1,i2,i3,i4,i5,i6,i7,i8,i9,i10)~+yr, data = inc13geo,sum)                       
summary(Inc13geo$jurisdiction_2015)
class(Inc13geo$jurisdiction_2015)
table(Inc13geo$jurisdiction_2015)
class(inc13geo$i1)

inc13_reg <- aggregate(i1~yr+jurisdiction_2015, data = inc13geo,sum) 


channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
median_income_jur_sql = getSQL("../Queries/median_income_jur.sql")
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
median_income_cpa_sql = getSQL("../Queries/median_income_cpa.sql")
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
median_income_region_sql = getSQL("../Queries/median_income_region.sql")
mi_region<-sqlQuery(channel,median_income_region_sql,stringsAsFactors = FALSE)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(mi_jur, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\mijur_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(mi_cpa, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\micpa_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(mi_region, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\miregion_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

head(mi_region)
#remove unneeded characters from geozone values.
mi_cpa$geozone <- gsub("\\*","",mi_cpa$geozone)
mi_cpa$geozone <- gsub("\\-","_",mi_cpa$geozone)
mi_cpa$geozone <- gsub("\\:","_",mi_cpa$geozone)

mi_jur$reg<-mi_region[match(mi_jur$yr_id, mi_region$yr_id),"median_inc"]
mi_cpa$reg<-mi_region[match(mi_cpa$yr_id, mi_region$yr_id),"median_inc"]









Income14_2020<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2020\\households.csv", stringsAsFactors = FALSE)
Income14_2025<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2025\\households.csv", stringsAsFactors = FALSE)
Income14_2035<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2035\\households.csv", stringsAsFactors = FALSE)
Income14_2050<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2050\\households.csv", stringsAsFactors = FALSE)


Income14_2020$yr = 2020
Income14_2025$yr = 2025
Income14_2035$yr = 2035
Income14_2050$yr = 2050
