###jurisdiction 4

hincome_jur4<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_2015==jur_list[4]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[4]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,1000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur4, file=paste(results2, "hincome_jur4.pdf"))



###jurisdiction 14

hincome_jur14<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_2015==jur_list[14]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title="Households by Jurisdiction 14 by Income", y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur14, file=paste(results2, "hincome_jur14.pdf"))





#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

#this is the loop with the subset, the ggplot and the ggsave commands
for(i in jur_list){
  plot<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_2015==jur_list[i]),  
               aes(x=yr, y=N, group=hinccat1, color=hinccat1)) +
    geom_line(size=1.25) +
    labs(title=paste("Households by Jurisdiction by Income\n                        ", jur_list2[i], y="Households by income category", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(1000,50000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
}    
  ggsave(plot, file= paste(results2, 'hincome_jur', jur_list2[i], ".pdf", sep=''), scale=2)


jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")






results2<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\trial\\"

#4 and 14
hincome_jur4<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_2015==jur_list[4]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("Households by Jurisdiction by Income \n", jur_list2[4], y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,1000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur4, file=paste(results2, "hincome_jur4new.pdf"))


hincome_jur14<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_2015==jur_list[14]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title="Households by Jurisdiction 14 by Income", y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur14, file=paste(results2, "hincome_jur14.pdf"))







#household income cpa

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


hincome_cpa_omit<-order(hincome_cpa_omit$yr)

#this is the loop with the subset, the ggplot and the ggsave commands
for(i in cpa_list){
  plot<-ggplot(subset(hincome_cpa_omit, hincome_cpa_omit$jcpa==cpa_list[i]),  
               aes(x=yr, y=N, group=hinccat1, color=hinccat1), na.rm=TRUE) +
    geom_line(size=1.25) +
    labs(title="Households by Income by CPA", y="Households by income category", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(100,50000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'hincome_cpa', cpa_list[i], ".pdf", sep=''), scale=1)
}







results<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\"

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

#this is the loop with the subset, the ggplot and the ggsave commands



for(i in jur_list){
  plot<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[i]),  
               aes(x=yr, y=N, group=bldgsz, color=bldgsz)) +
    geom_line(size=1.25) +
    labs(title=paste("Households by Jurisdiction by Household Size/n                        ", jur_list[i], y="Households by HH Size", x="Year",
               caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
           expand_limits(y = c(1, 3000000))+
           scale_y_continuous(labels= comma, limits = c(1000,50000))+
           theme_bw(base_size = 16)+
           theme(legend.position = "bottom",
                 legend.title=element_blank()))
}
  ggsave(plot, file= paste(results, 'hhsize_jur', jur_list[i], ".pdf", sep=''), scale=2)
  

 
  
  
  
  
  
  
hinc2<-subset(hincome_jur, yr=="y2016")
#2016
sum<-rep(c(44298,82743,15342,2124,35771,24815,47307,9657,25569,19098,21940,61845,
               17552,568522,31098,20440,6166,31080,197047),
             c(5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5))

hinc2$N/sum

#2018
sum<-rep(c(44947,84682,15346,2192,35889,25075,48352,9670,25594,19114,22314,62022,
               17605,575528,32017,20641,6175,31079,197942),
             c(5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5))
#2020
sum<-rep(c(45923,89913,15345,2192, 36081,25170, 49138, 9760, 25658, 19216, 23059, 62496,
           17678,583050, 32995, 20912, 6186, 31160,198518),
         c(5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5))
           
#2025
sum<-rep(c( 46975,101838,15372,2243,36389,25454,51516,10240,26222,19474,23446,64791,
           18266,612293,38530,22702,6263,32476,204061,
           c(5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5))
         


#2030
sum<-rep(c( 47752, 105376,16150,2245,37268,25889,52449,11341,28701,19697,24615,66464,
            18681,657894,39649,23032,6369,33714, 220356,
            c(5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5))
            
            
            
            




         c(5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5,5))
