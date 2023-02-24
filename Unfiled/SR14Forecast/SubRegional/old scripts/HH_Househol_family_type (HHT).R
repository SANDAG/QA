
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
install.packages("reshape2")
library(sqldf)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read in files

HH_type<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\HH_Household_Type\\HH_HHTYPE.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")


#add y characterto year testes
HH_type$year<- "y"
HH_type$yr <- as.factor(paste( HH_type$year, HH_type$yr, sep = ""))
HH_type$year<- NULL

HH_type_reg<-aggregate(N~hht+yr, data=HH_type, sum)
HH_type_cpa<-aggregate(N~hht+yr+jcpa, data=HH_type, sum)
HH_type_jur<-aggregate(N~hht+yr+jurisdiction_id, data=HH_type, sum)
#if Andy's geography file doesn't include the jurisdiction you could exclude this statement or use it to exclude NULL
HH_type_cpa <- subset(HH_type_cpa, jcpa > 19)


HH_type_cpa_cast <- dcast(HH_type_cpa, jcpa+hht~yr, value.var="N")
HH_type_jur_cast <- dcast(HH_type_jur, jurisdiction_id+hht~yr, value.var="N")


head(HH_type_cpa_cast)

#################
#add percent change and absolute change and save as csv
#################

#unittype_cpa_cast$pct_chg <- (unittype_cpa_cast$y2050-unittype_cpa_cast$y2018)/unittype_cpa_cast$y2050
#unittype_jur_cast$pct_chg <- (unittype_jur_cast$y2050-unittype_jur_cast$y2018)/unittype_jur_cast$y2050

#unittype_cpa_cast$abs_chg <- unittype_cpa_cast$y2050-unittype_cpa_cast$y2018
#unittype_jur_cast$abs_chg <- unittype_jur_cast$y2050-unittype_jur_cast$y2018
#unittype_cpa_cast$pct_chg <- round(unittype_cpa_cast$pct_chg * 100, 2)
#unittype_jur_cast$pct_chg <- round(unittype_jur_cast$pct_chg * 100, 2)

write.csv(HH_type_cpa_cast,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\HH_type cpa freq.csv" )
write.csv(HH_type_jur_cast,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\HH_type jur freq.csv" )
write.csv(HH_type_reg,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\HH_type reg freq.csv" )

HH_type_cpa_omit<-na.omit(HH_type_cpa)

#add figure script and write out file
##################################################
#graphs
##################################################
#graphs save here
results<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\"


BRI I HAVE STOPPED HERE

##################################
#household Unit Type region
HH_type_reg<-ggplot(data=HH_type_reg, aes(x=yr, stat="count",colour=hht), lab=c("0","1")) +
  geom_bar (size =1)+
  labs(title="SD Regionwide Households by Unit Type", y="Households by Unit Type", x=" Year",
       caption="Source: isam.xpef03.household")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(unittype_region, file=paste(results, "Unit Type_reg.pdf"))


# #household Unit Type region
# unittype_region<-ggplot(data=unittype_reg, aes(x=yr, y=N, group=unittype, colour=unittype,)) +
#   geom_bar() +
#   labs(title="SD Regionwide Households by Unit Type", y="Households by Unit Type", x=" Year",
#        caption="Source: isam.xpef03.household")+
#   expand_limits(y = c(1, 3000000))+
#   scale_y_continuous(labels= comma, limits = c(1000,500000))+
#   theme_bw(base_size = 16)+
#   theme(legend.position = "bottom",
#         legend.title=element_blank())
# 
# ggsave(unittype_region, file=paste(results, "Unit Type_reg.pdf"))




#household Unit Type jurisdiction

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

#this is the loop with the subset, the ggplot and the ggsave commands
for(i in 1:length(jur_list)){
  plot<-ggplot(subset(unittype_jur, unittype_jur$jurisdiction_id==jur_list[i]),  
               aes(x=yr, y=N, group=as.factor(unittype), color=as.factor(unittype))) +
    geom_line(size=1.25) +
    labs(title=paste("Households by Jurisdiction by Unit Type\n", jur_list2[i]), y="Households by Unit Type category", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 300000))+
    scale_y_continuous(labels= comma, limits = c((.75 * min(subset(unittype_jur$N, unittype_jur$jurisdiction_id==jur_list[i]))),(1.5 * max(subset(unittype_jur$N, unittype_jur$jurisdiction_id==jur_list[i])))))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".pdf", sep=''), scale=2)
}

#household Unit Type cpa

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
cpa_list<- c(1401, 
             1402, 
             1403, 
             1404, 
             1405, 
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