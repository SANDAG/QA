
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read in files

unittype<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\HH_unittype.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

#add y character to year
unittype$year<- "y"
unittype$yr <- as.factor(paste( unittype$year, unittype$yr, sep = ""))
unittype$year<- NULL

unittype_reg<-aggregate(N~unittype+yr, data=unittype, sum)
unittype_cpa<-aggregate(N~unittype+yr+jcpa, data=unittype, sum)
unittype_jur<-aggregate(N~unittype+yr+jurisdiction_id, data=unittype, sum)
#if Andy's geography file doesn't include the jurisdiction you could exclude this statement or use it to exclude NULL
unittype_cpa <- subset(unittype_cpa, jcpa > 19)

# plot only Household unit type "0"
unittype_jur <-subset(unittype_jur,unittype==0)
unittype_reg <-subset(unittype_reg,unittype==0)

unittype_jur$N_chg <- ave(unittype_jur$N, factor(unittype_jur$jurisdiction_id), FUN=function(x) c(NA,diff(x)))
unittype_reg$N_chg <- ave(unittype_reg$N, FUN=function(x) c(NA,diff(x)))

unittype_jur <- unittype_jur[order(unittype_jur$yr,unittype_jur$jurisdiction_id),]
unittype_jur$N_pct <- (unittype_jur$N_chg / lag(unittype_jur$N))*100

unittype_reg <- unittype_reg[order(unittype_reg$yr),]
unittype_reg$N_pct <- (unittype_reg$N_chg / lag(unittype_reg$N))*100

unittype_cpa_cast <- dcast(unittype_cpa, jcpa+unittype~yr, value.var="N")
unittype_jur_cast <- dcast(unittype_jur, jurisdiction_id+unittype~yr, value.var="N")

unittype_reg$N_pct <- sprintf("%.2f",unittype_reg$N_pct)
unittype_jur$N_pct <- sprintf("%.2f",unittype_jur$N_pct)

#################
#add percent change and absolute change and save as csv
#################

unittype_cpa_cast$pct_chg <- (unittype_cpa_cast$y2050-unittype_cpa_cast$y2018)/unittype_cpa_cast$y2050
unittype_jur_cast$pct_chg <- (unittype_jur_cast$y2050-unittype_jur_cast$y2018)/unittype_jur_cast$y2050

unittype_cpa_cast$abs_chg <- unittype_cpa_cast$y2050-unittype_cpa_cast$y2018
unittype_jur_cast$abs_chg <- unittype_jur_cast$y2050-unittype_jur_cast$y2018
unittype_cpa_cast$pct_chg <- round(unittype_cpa_cast$pct_chg * 100, 2)
unittype_jur_cast$pct_chg <- round(unittype_jur_cast$pct_chg * 100, 2)


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
dataout<-"data\\unittype\\"
ifelse(!dir.exists(file.path(maindir,dataout)), dir.create(file.path(maindir,dataout), showWarnings = TRUE, recursive=TRUE),0)

write.csv(unittype_cpa_cast,paste(dataout,"unittype_cpa_freq.csv"))
write.csv(unittype_jur_cast,paste(dataout,"unittype_jur_freq.csv"))
write.csv(unittype_reg,paste(dataout,"reg_freq.csv"))




##################################################
#graphs
##################################################
#save plots locally

results<-"plots\\unittype\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

#household Unit Type region
region_plot <- ggplot(data=unittype_reg, aes(x=yr, y=N_chg, group=1)) +
  geom_line(size=1.25) +
  geom_point() +
  xlab("Year") + ylab("Households") +
  ggtitle("Absolute Change: No. of Households for Region, 2016-2050") +
  labs(caption = "Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13") +
  theme_bw(base_size = 14) +  
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.position = "bottom",
        plot.margin = margin(15, 15, 15, 15),
        plot.caption = element_text(size = 10, hjust = 0))
region_plot
ggsave(region_plot, file= paste(results, 'unittype_region', ".png", sep=''))

# 
# unittype_region<-ggplot(data=unittype_reg, aes(x=yr, stat="count",colour=unittype), lab=c("0","1")) +
#   geom_bar (size =1)+
#   labs(title="SD Regionwide Households by Unit Type", y="Households by Unit Type", x=" Year",
#        caption="Source: isam.xpef03.household")+
#   expand_limits(y = c(1, 3000000))+
#   scale_y_continuous(labels= comma, limits = c(1000,500000))+
#   theme_bw(base_size = 16)+
#   theme(legend.position = "bottom",
#         legend.title=element_blank())
# 
# ggsave(unittype_region, file=paste(results, "Unit Type_reg.pdf"))


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

citynames <- data.frame(jur_list, jur_list2)
unittype_jur$cityname<-citynames[match(unittype_jur$jurisdiction_id, citynames$jur_list),2]
unittype_jur$reg<-unittype_reg[match(unittype_jur$yr, unittype_reg$yr),4]

#this is the loop with the subset, the ggplot and the ggsave commands


for(i in 1:length(jur_list)){
  plotdat = subset(unittype_jur, unittype_jur$jurisdiction_id==jur_list[i])
  plotdat$ratio = plotdat$reg/plotdat$N_chg
  plotdat$ratio[is.na(plotdat$ratio)] <- 0
  # ravg = median(plotdat[["ratio"]])
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region")) +
    scale_y_continuous(label=comma,sec.axis = 
                                  sec_axis(~.*ravg, name = "Region HH [abs chg]",label=comma)) +
    labs(title=paste("Absolute Change: No. of Households\n ", jur_list2[i],' and Region, 2016-2050',sep=''), 
         y=paste(jur_list2[i]," HH [abs chg]",sep=''), x="Year",
        caption="Sources: isam.xpef03.household\ndata_cafe.regional_forecast.sr13_final.mgra13") +
    scale_colour_manual(values = c("blue", "red")) +
    #expand_limits(y = c(1, 300000))+
    #scale_y_continuous(labels= comma, limits = c((.75 * min(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i]))),(1.5 * max(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i])))))+
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr,plotdat$N,plotdat$N_chg,plotdat$N_pct,unittype_reg$N, plotdat$reg)
  setnames(output_table, old=c("plotdat.yr","plotdat.N","plotdat.N_chg","plotdat.N_pct","unittype_reg.N","plotdat.reg"),new=c("Year","SR Total","SR Abs Chg","SR Pct Chg","Reg Total", "Reg Abs Chg"))
  tt <- ttheme_default(base_size=7,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,2,2),
               c(1,1,1,2,2),
               c(1,1,1,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'unittype_jur', jur_list[i], ".png", sep=''))#, scale=2)
}


#household Unit Type cpa

# double axis test
 
# jur1 = subset(unittype_jur, unittype_jur$jurisdiction_id==1)
# jur14 = subset(unittype_jur, unittype_jur$jurisdiction_id==14)
# unittype_reg$jur1 = jur1$N_chg
# unittype_reg$jur14 = jur14$N_chg
# unittype_reg$ratio = unittype_reg$N_chg/unittype_reg$jur14
# sapply(jur14, class)
# p <- ggplot(unittype_reg, aes(x = yr,y = jur14))
# p <- p +  geom_bar(stat="identity")
# # note divide 1.5
# p <- p + geom_line(aes(y = N_chg/1.5, group=1,colour = "Region"))
# # now adding the secondary axis, 
# # and, very important, reverting the above transformation (1.5)
# p <- p + scale_y_continuous(label=comma,sec.axis = 
#                               sec_axis(~.*1.5, name = "Region",label=comma))
# p <- p + scale_colour_manual(values = c("blue", "red"))
# p <- p + labs(y = "San Diego",
#               x = "yr"
#               #,colour = "Parameter"
#               )
# p <- p + theme(legend.position = c(0.8, 0.9))
# ggsave(p, file= paste(results, '2yaxis_unittype_jur', jur_list[14], ".png", sep='')) # , scale=2)
# p

#############

#cpa with missing data for one or more years - 1401, 1439, 1491, 1911,1483
#this creates the list for "i" which is what the loop relies on - like x in a do repeat
cpa_list<- c(# 1401, 
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
             # 1439, 
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
             #1483, 
             1485, 
             1486, 
             1488, 
             #1491, 
             1901, 
             1902, 
             1903, 
             1904, 
             1906, 
             1907, 
             1908, 
             1909, 
             #1911, 
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


unittype_cpa <-subset(unittype_cpa,unittype==0)
unittype_cpa$N_chg <- ave(unittype_cpa$N, factor(unittype_cpa$jcpa), FUN=function(x) c(NA,diff(x)))
unittype_cpa$reg<-unittype_reg[match(unittype_cpa$yr, unittype_reg$yr),4]
unittype_cpa <- unittype_cpa[order(unittype_cpa$yr,unittype_cpa$jcpa),]
unittype_cpa$N_pct <- (unittype_cpa$N_chg / lag(unittype_cpa$N))*100
unittype_cpa$N_pct <- sprintf("%.2f",unittype_cpa$N_pct)

for(i in 1:length(cpa_list)){
  plotdat = subset(unittype_cpa, unittype_cpa$jcpa==cpa_list[i])
  plotdat$ratio = plotdat$reg/plotdat$N_chg
  plotdat$ratio[is.na(plotdat$ratio)] <- 0
  # ravg = median(plotdat[["ratio"]])
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill='cpa')) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region")) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Region HH [abs chg]",label=comma)) +
    labs(title=paste("Absolute Change: No. of Households\n ", cpa_list[i],' and Region, 2016-2050',sep=''), 
         y=paste(cpa_list[i]," HH [abs chg]",sep=''), x="Year",
         caption="Sources: isam.xpef03.household\ndata_cafe.regional_forecast.sr13_final.mgra13") +
    scale_colour_manual(values = c("blue", "red")) +
    #expand_limits(y = c(1, 300000))+
    #scale_y_continuous(labels= comma, limits = c((.75 * min(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i]))),(1.5 * max(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i])))))+
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
    ggsave(plot, file= paste(results, 'unittype_cpa', cpa_list[i], ".png", sep=''))#, scale=2)
   output_table<-data.frame(plotdat$yr,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$reg)
   setnames(output_table, old=c("plotdat.yr","plotdat.N","plotdat.N_chg","plotdat.N_pct","plotdat.reg"),new=c("Year","SR Total","SR Abs Chg","SR Pct Chg","Reg Abs Chg"))
   tt <- ttheme_default(base_size=7,colhead=list(fg_params = list(parse=TRUE)))
   tbl <- tableGrob(output_table, rows=NULL, theme=tt)
   lay <- rbind(c(1,1,1,2,2),
                c(1,1,1,2,2),
                c(1,1,1,2,2))
   output<-grid.arrange(plot,tbl,ncol=2,as.table=TRUE,layout_matrix=lay)
   ggsave(output, file= paste(results, 'unittype_cpa', cpa_list[i], ".png", sep=''))#, scale=2)
}
  
  

#unittype_cpa_omit<-order(unittype_cpa_omit$yr)

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