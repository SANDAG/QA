

#Jennifer can clean up graph - change plot color for region
#jurisdiction_2015 column name will need to change when Andy's geography file is updated
#bri and Lisbeth tested omit to fix the cpa plots - maybe delete that out


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

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read in files

HH_Building_size<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\HH_Building Size\\HH_BuildingSize.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")


#add y characterto year
HH_Building_size$year<- "y"
HH_Building_size$yr <- as.factor(paste( HH_Building_size$year, HH_Building_size$yr, sep = ""))
HH_Building_size$year<- NULL

HH_Building_size_reg<-aggregate(N~bldgsz+yr, data=HH_Building_size, sum)
HH_Building_size_cpa<-aggregate(N~bldgsz+yr+jcpa, data=HH_Building_size, sum)
HH_Building_size_jur<-aggregate(N~bldgsz+yr+jurisdiction_id, data=HH_Building_size, sum)
#if Andy's geography file doesn't include the jurisdiction you could exclude this statement or use it to exclude NULL
HH_Building_size_cpa <- subset(HH_Building_size_cpa, jcpa > 19)


HH_Building_size_cpa_cast <- dcast(HH_Building_size_cpa, jcpa+bldgsz~yr, value.var="N")
HH_Building_size_cpa_cast <- dcast(HH_Building_size_jur, jurisdiction_id+bldgsz~yr, value.var="N")


head(HH_Building_size_cpa_cast)

#################
#add percent change and absolute change and save as csv
#################

#unittype_cpa_cast$pct_chg <- (unittype_cpa_cast$y2050-unittype_cpa_cast$y2018)/unittype_cpa_cast$y2050
#unittype_jur_cast$pct_chg <- (unittype_jur_cast$y2050-unittype_jur_cast$y2018)/unittype_jur_cast$y2050

#unittype_cpa_cast$abs_chg <- unittype_cpa_cast$y2050-unittype_cpa_cast$y2018
#unittype_jur_cast$abs_chg <- unittype_jur_cast$y2050-unittype_jur_cast$y2018
#unittype_cpa_cast$pct_chg <- round(unittype_cpa_cast$pct_chg * 100, 2)
#unittype_jur_cast$pct_chg <- round(unittype_jur_cast$pct_chg * 100, 2)

write.csv(HH_Building_size_cpa_cast,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\bldgsz cpa freq.csv" )
write.csv(HH_Building_size_cpa_cast,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\bldgsz jur freq.csv" )
write.csv(HH_Building_size_reg,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\bldgsz reg freq.csv" )

write.csv(HH_Building_size_Jur,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\bldgsz jur freq.csv" )



bldgsz_cpa_omit<-na.omit(bldgsz_cpa)

#add figure script and write out file
##################################################
#graphs
##################################################
#graphs save here
results<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\"

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

#this is the loop with the subset, the ggplot and the ggsave commands

for(i in jur_list){
  plot<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[i]),  
               aes(x=yr, y=N, group=bldgsz, color=bldgsz)) +
    geom_line(size=1.25) +
    labs(title("Households by Jurisdiction by Household Size/N                        ", jur_list[i], y="Households by HH Size", x="Year",
                     caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
           expand_limits(y = c(1, 300000))+
           scale_y_continuous(labels= comma, limits = c(1000,50000))+
           theme_bw(base_size = 16)+
           theme(legend.position = "bottom",
                 legend.title=element_blank()))
    ggsave(plot, file= paste(results, 'hhsize_jur', jur_list[i], ".pdf", sep=''), scale=2)
}



#this is the loop with the subset, the ggplot and the ggsave commands
for(i in jur_list){
  plot<-ggplot(subset(unittype_jur, unittype_jur$jurisdiction_id==jur_list[i]),  
               aes(x=yr, y=N, group=unittype, color=unittype)) +
    geom_line(size=1.25) +
    labs(title="Households by Jurisdiction by Unit Type", y="Households by Unit Type category", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(1000,50000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".pdf", sep=''), scale=2)
}



#########################################################################################################
#household Unit Type region
unittype_region<-ggplot(data=unittype_reg, aes(x=yr, stat="count",colour=unittype), lab=c("0","1")) +
  geom_histogram ()+
  labs(title="SD Regionwide Households by Unit Type", y="Households by Unit Type", x=" Year",
       caption="Source: isam.xpef03.household")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(unittype_region, file=paste(results, "Unit Type_reg.pdf"))


#household Unit Type region
unittype_region<-ggplot(data=unittype_reg, aes(x=yr, y=N, group=unittype, colour=unittype)) +
  geom_bar(size=1) +
  labs(title="SD Regionwide Households by Unit Type", y="Households by Unit Type", x=" Year",
       caption="Source: isam.xpef03.household")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(unittype_region, file=paste(results, "Unit Type_reg.pdf"))




#household Unit Type jurisdiction

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

#this is the loop with the subset, the ggplot and the ggsave commands
for(i in jur_list){
  plot<-ggplot(subset(unittype_jur, unittype_jur$jurisdiction_id==jur_list[i]),  
               aes(x=yr, y=N, group=unittype, color=unittype)) +
    geom_line(size=1.25) +
    labs(title="Households by Jurisdiction by Unit Type", y="Households by Unit Type category", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(1000,50000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".pdf", sep=''), scale=2)
}



#household Unit Type cpa

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
#cpa_list<- c(1401, 
             #1402, 
             #1403, 
             #1404, 
             #1405, 
             1406, 
             1407, 
             1408, 
             1409, 
             1410, 
             1412, 
             1414, 
             1415, 
             1417, 
             1418, 
             1419, 
             1420, 
             1421, 
             1423, 
             1424, 
             1425, 
             1426, 
             1427, 
             1428, 
             1429, 
             1430, 
             1431, 
             1432, 
             1433, 
             1434, 
             1435, 
             1438, 
             1439, 
             1440, 
             1441, 
             1442, 
             1444, 
             1447, 
             1448, 
             1449, 
             1450, 
             1455, 
             1456, 
             1457, 
             1458, 
             1459, 
             1461, 
             1462, 
             1463, 
             1464, 
             1465, 
             1466, 
             1467, 
             1468, 
             1469, 
             1481, 
             1482, 
             1483, 
             1485, 
             1486, 
             1488, 
             1491, 
             1901, 
             1902, 
             1903, 
             1904, 
             1906, 
             1907, 
             1908, 
             1909, 
             1911, 
             1912, 
             1914, 
             1915, 
             1918, 
             1919, 
             1920, 
             1921, 
             1922, 
             1951, 
             1952, 
             1953, 
             1954, 
             1955, 
             1998, 
             1999
             
)


unittype_cpa_omit<-order(unittype_cpa_omit$yr)

#this is the loop with the subset, the ggplot and the ggsave commands
for(i in cpa_list){
  plot<-ggplot(subset(unittype_cpa_omit, unittype_cpa_omit$jcpa==cpa_list[i]),  
               aes(x=yr, y=N, group=unittype, color=unittype), na.rm=TRUE) +
    geom_line(size=1.25) +
    labs(title="Households by Unit Type by CPA", y="Households by Unit Type", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(100,50000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'unittype_cpa', cpa_list[i], ".pdf", sep=''), scale=1)
}



