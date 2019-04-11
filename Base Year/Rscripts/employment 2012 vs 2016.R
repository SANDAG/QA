#install color package
install.packages("wesanderson")
install.packages("RColorBrewer")
install.packages("qdap")

#check size
install.packages("pryr")
install.packages("tidyr")
library(scales)
library(sqldf)
library(rstudioapi)
library(RODBC)
library(dplyr)
library(reshape2)
library(ggplot2)
library(data.table)
library(stringr)
library(pryr)
library(tidyr)
library(qdap)
#library(wesanderson)
#library(RColorBrewer)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

channel <- odbcConnect("r_connection")

mgra<-read.csv('T:\\ABM\\ABM_FY17\\Data_Preparation\\land use\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

mgra_old<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Data Files\\MGRA HH PERSONS DATA FILES\\MGRA INPUT FILES\\MGRA 2016 input UPDATE 2_5_18.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

geography<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Data Files\\Geography files\\MGRA_matched_keyed.csv' ,stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

geography$cpa.1[geography$cpa.1=="NULL"]<- "Cnty not in CPA"

#for SPSS mgra integrity checks
mgra_SPSS<-merge(mgra, geography, by.a="mgra", by.b="mgra", all=TRUE)
write.csv(mgra_SPSS, "M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Phase II\\Data Files\\MGRA_05_22_18.csv" )

merge_geo_mgra_16_12, diff!=0)


hhp<-subset(mgra, hhp>0)
hhp$hh_tot<-sum(hhp$hh)
summary(hhp$hhs)

hhp$hh_tot

head(mgra)
#delete unwanted columns
geography$sra<-NULL
geography$tract<-NULL
geography$msa<-NULL
geography$zip<-NULL
geography$cpa.2<-NULL
geography$cpa_id.2<-NULL
geography$cpa.3<-NULL
geography$cpa_id.3<-NULL
geography$jurisdiction_id.3<-NULL

mgra_2012<-read.csv('T:\\ABM\\release\\ABM\\version_13_3_2\\input\\2012\\mgra13_based_input2012.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

colnames(taz_hhp)

summary(mgra)


taz_hhp<-aggregate(hhp~taz, data=mgra, sum)
taz_hhp<-subset(taz_hhp, hhp!=0)

taz_unique<-unique(taz_hhp$taz)  

length(taz_unique)


#create civilian employment total for each file
mgra$civ_emp_tot<-mgra$emp_total-mgra$emp_fed_mil
mgra_old$civ_emp_tot<-mgra_old$emp_total-mgra_old$emp_fed_mil
mgra_2012$civ_emp_tot<-mgra_2012$emp_total-mgra_2012$emp_fed_mil



#melt each mgra file
melt_mgra<-melt(mgra, id.vars=c("mgra"))

melt_mgra_old<-melt(mgra_old, id.vars=c("mgra"))

melt_mgra_2012<-melt(mgra_2012, id.vars=c("mgra"))

setnames(melt_mgra_old, old=c("value"),new=c("value_old"))

setnames(melt_mgra, old=c("value"),new=c("value_new"))

setnames(melt_mgra_2012, old=c("value"),new=c("value_2012"))

#merge old and new 2016 files for comparison
merge_mgra<-merge(melt_mgra, melt_mgra_old, by=c("mgra", "variable"))

#merge 2016 and 2012 for comparison
merge_mgra_16_12<-merge(melt_mgra, melt_mgra_2012, by=c("mgra", "variable"))

#rm(mgra, mgra_old, mgra_2012, melt_mgra, melt_mgra_old, melt_mgra_2012)

#calculate difference from 2016 old and new for each variable
merge_mgra$diff<-merge_mgra$value_new-merge_mgra$value_old

#calculate difference from new 2016 to 2012 for each variable
merge_mgra_16_12$diff<-merge_mgra_16_12$value_new-merge_mgra_16_12$value_2012

#merge in geography files
merge_geo_mgra<-merge(merge_mgra, geography, by="mgra")

merge_geo_mgra_16_12<-merge(merge_mgra_16_12, geography, by="mgra")

#aggregate the totals by cpa
cpa_tot_2016_new<-aggregate(value_new~variable+cpa.1, data=merge_geo_mgra, sum)

cpa_tot_2016_old<-aggregate(value_old~variable+cpa.1, data=merge_geo_mgra, sum)

cpa_tot_2012<-aggregate(value_2012~variable+cpa.1, data=merge_geo_mgra_16_12, sum)

setnames(cpa_tot_2016_new, old=c("value_new"),new=c("cpa_tot_new"))

setnames(cpa_tot_2016_old, old=c("value_old"),new=c("cpa_tot_old"))

setnames(cpa_tot_2012, old=c("value_2012"),new=c("cpa_tot_2012"))


#merge cpa totals into 2016 old and new and 2012 to 2016 comparison files.
merge_geo_mgra<-merge(merge_geo_mgra, cpa_tot_2016_new, by.x=c("cpa.1", "variable"), by.y = c("cpa.1", "variable"), all=TRUE)

merge_geo_mgra<-merge(merge_geo_mgra, cpa_tot_2016_old, by.x=c("cpa.1", "variable"), by.y = c("cpa.1", "variable"), all=TRUE)

merge_geo_mgra_16_12<-merge(merge_geo_mgra_16_12, cpa_tot_2016_new, by.x=c("cpa.1", "variable"), by.y = c("cpa.1", "variable"), all=TRUE)

merge_geo_mgra_16_12<-merge(merge_geo_mgra_16_12, cpa_tot_2012, by.x=c("cpa.1", "variable"), by.y = c("cpa.1", "variable"), all=TRUE)

head()
head(cpa_tot_2012)
#delete rows with no difference from one file to another
merge_mgra_diff<-subset(merge_geo_mgra, diff!=0)

merge_mgra_diff_16_12<-subset(merge_geo_mgra_16_12, diff!=0)

head(merge_mgra_diff)

write.csv(merge_mgra_diff[,c("mgra","variable", "value_new", "value_old", "cpa_tot_new", "cpa_tot_old", "diff", "cpa.1", "jurisdiction.1")], "M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Phase II\\Scripts\\output\\MGRA_2016_diff.csv" )

write.csv(merge_mgra_diff_16_12[,c("mgra","variable", "value_new", "value_2012", "cpa_tot_new", "cpa_tot_2012", "diff", "cpa.1", "jurisdiction.1")], "M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Phase II\\Scripts\\output\\MGRA_2016_2012_diff.csv" )



value_2016<-aggregate(value_new~variable+cpa.1, data=merge_mgra_diff, sum)
old_value_2016<-aggregate(value_old~variable+cpa.1, data=merge_mgra_diff, sum)
value_2012<-aggregate(value_2012~variable+cpa.1, data=merge_mgra_diff_16_12, sum)
value_2016_12<-aggregate(value_new~variable+cpa.1, data=merge_mgra_diff_16_12, sum)

merge_cpa<-merge(value_2016, old_value_2016, by.x=c("cpa.1", "variable"), by.y=c("cpa.1", "variable"))
merge_cpa<-merge(merge_cpa, by.x=c("cpa.1", "variable"), by.y=c("cpa.1", "variable"))

merge_cpa_16_12<-merge(value_2016_12, value_2012, by.x=c("cpa.1", "variable"), by.y=c("cpa.1", "variable"))
merge_cpa<-merge(value_2016, old_value_2016, by.x=c("cpa.1", "variable"), by.y=c("cpa.1", "variable"))


write.csv(merge_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Phase II\\Scripts\\output\\cpa_2016_diff.csv" )

write.csv(merge_cpa_16_12, "M:\\Technical Services\\QA Documents\\Projects\\Synthetic Population\\Phase II\\Scripts\\output\\cpa_2016_12_diff.csv" )



