pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr")

#Jennifer can clean up graph - change plot color for region
#jurisdiction_2015 column name will need to change when Andy's geography file is updated
#bri and Lisbeth tested omit to fix the cpa plots - maybe delete that out

# Install the car package
#install.packages("car")
#install.packages("anchors")
# Load the car package
library(car)
library(anchors)
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

#Collape Family HH and remove GQ
HH_Building_size<- replace.value(HH_Building_size,"bldgsz", 2,3)
HH_Building_size<- subset(HH_Building_size, bldgsz !=9)

#add y characterto year
HH_Building_size$year<- "y"
HH_Building_size$yr <- as.factor(paste( HH_Building_size$year, HH_Building_size$yr, sep = ""))
HH_Building_size$year<- NULL

HH_Building_size_reg<-aggregate(N~bldgsz+yr, data=HH_Building_size, sum)
HH_Building_size_cpa<-aggregate(N~bldgsz+yr+jcpa, data=HH_Building_size, sum)
HH_Building_size_jur<-aggregate(N~bldgsz+yr+jurisdiction_id, data=HH_Building_size, sum)
#if Andy's geography file doesn't include the jurisdiction you could exclude this statement or use it to exclude NULL
HH_Building_size_cpa <- subset(HH_Building_size_cpa, jcpa > 19)

HH_Building_size_jur<- HH_Building_size_jur[order(HH_Building_size_jur$jurisdiction_id, HH_Building_size_jur$bldgsz,HH_Building_size_jur$yr),]
HH_Building_size_reg<- HH_Building_size_reg[order(HH_Building_size_reg$bldgsz,HH_Building_size_reg$yr),]

HH_Building_size_jur$N_chg <- abs(ave(HH_Building_size_jur$N, factor(HH_Building_size_jur$bldgsz), factor(HH_Building_size_jur$jurisdiction_id), FUN=function(x) c(NA,diff(x))))
HH_Building_size_reg$N_chg <- abs(ave(HH_Building_size_reg$N, factor(HH_Building_size_jur$bldgsz), FUN=function(x) c(NA,diff(x))))

HH_Building_size_jur$N_pct <- (HH_Building_size_jur$N_chg / lag(HH_Building_size_jur$N))*100
HH_Building_size_reg$N_pct <- (HH_Building_size_reg$N_chg / lag(HH_Building_size_reg$N))*100

HH_Building_size_cpa_cast <- dcast(HH_Building_size_cpa, jcpa+bldgsz~yr, value.var="N")
HH_Building_size_cpa_cast <- dcast(HH_Building_size_jur, jurisdiction_id+bldgsz~yr, value.var="N")


head(HH_Building_size_cpa_cast)

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
dataout<-"data\\bldgsz\\"
ifelse(!dir.exists(file.path(maindir,dataout)), dir.create(file.path(maindir,dataout), showWarnings = TRUE, recursive=TRUE),0)


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

write.csv(HH_Building_size_jur,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\bldgsz jur freq.csv" )



#bldgsz_cpa_omit<-na.omit(bldgsz_cpa)

#add figure script and write out file
##################################################
#graphs
##################################################
#graphs save here
#results<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\"
#household Unit Type jurisdiction
results<-"plots\\bldgsz\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE))

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

citynames <- data.frame(jur_list, jur_list2)
HH_Building_size_jur$cityname<-citynames[match(HH_Building_size_jur$jurisdiction_id, citynames$jur_list),2]
HH_Building_size_jur$reg<-HH_Building_size_reg[match(HH_Building_size_jur$yr, HH_Building_size_reg$yr),4]

#household Building size Type jurisdiction

for(i in 1:length(jur_list)){
  plotdat = subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[i])
  plotdat$ratio = plotdat$reg/plotdat$N_chg
  plotdat$ratio[is.na(plotdat$ratio)] <- 0
  ravg = median(plotdat[["ratio"]])
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,group= bldgsz, fill=bldgsz)) +
    geom_bar(stat = "identity", position = "dodge") + #, #colour= "bldgsz") + 
    geom_line(aes(y = reg/ravg, group=bldgsz,colour = "Region")) + 
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Region HH [abs chg]",label=comma)) +
    #scale_x_discrete(breaks= "yr")+
    labs(title=paste("Absolute Change: No. of Structures\n ", jur_list2[i],' and Region, 2016-2050',sep=''), 
         y=paste(jur_list2[i]," HH [abs chg]",sep=''), x="Year",
         caption="Sources: isam.xpef03.household\ndata_cafe.regional_forecast.sr13_final.mgra13") +
    #scale_fill_brewer(palette="Set1")+
    #scale_colour_manual(values = c("blue", "red", "yellow")) +
    #scale_fill_manual(values = c("blue","red", "yellow")) +
    #expand_limits(y = c(1, 300000))+
    #scale_y_continuous(labels= comma, limits = c((.75 * min(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i]))),(1.5 * max(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i])))))+
    theme_bw(base_size = 16) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  # ggsave(plot, file= paste(results, 'bldgsz_jur', jur_list[i], ".pdf", sep=''), scale=2)
  ggsave(plot, file= paste(results, 'bldgsz_jur', jur_list[i], ".png", sep=''))#, scale=2)
}



#########################################################################################################
#Building Size Unit Type region
#bldgsz_region<-ggplot(data=HH_Building_size_reg, aes(x=yr, stat="count",colour=bldgsz), lab=c("0","1")) +
  geom_histogram ()+
  labs(title="SD Regionwide Households by Building Size", y="Households by HH size", x=" Year",
       caption="Source: isam.xpef03.household")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

#ggsave(bldgsz_region, file=paste(results, "Building Size_reg.pdf"))

results<-"plots\\building size type\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

#Building Size Region
bldgsz_region <- ggplot(data=HH_Building_size_reg, aes(x=yr, y=N_chg, group=1)) +
  geom_line(size=1.25) +
  geom_point() +
  xlab("Year") + ylab("Households") +
  ggtitle("Absolute Change: No. of Building Structure for Region, 2016-2050") +
  labs(caption = "Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13") +
  theme_bw(base_size = 14) +  
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.position = "bottom",
        plot.margin = margin(15, 15, 15, 15),
        plot.caption = element_text(size = 10, hjust = 0))
bldgsz_region
ggsave(buildingsize_region , file= paste(results, 'buildingsize_region', ".png", sep=''))







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



