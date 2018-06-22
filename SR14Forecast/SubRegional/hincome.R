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

hincome<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\HH_income2.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")


class(hincome)
summary(hincome)



#add y characterto year
hincome$year<- "y"
hincome$yr <- as.factor(paste( hincome$year, hincome$yr, sep = ""))
hincome$year<- NULL

hincome_reg<-aggregate(N~hinccat1+yr, data=hincome, sum)
hincome_cpa<-aggregate(N~hinccat1+yr+jcpa, data=hincome, sum)


hincome_jur<-aggregate(N~hinccat1+yr+jurisdiction_id, data=hincome, sum)
sum_HH<- aggregate(N~yr+jurisdiction_id, data=hincome, sum)

hincome_jur$Percent_Income<- round((hincome_jur$N/sum_HH$N)*100, 2)

#if Andy's geography file doesn't include the jurisdiction you could exclude this statement or use it to exclude NULL
hincome_cpa <- subset(hincome_cpa, jcpa > 19)


hincome_cpa_cast <- dcast(hincome_cpa, jcpa+hinccat1~yr, value.var="N")
hincome_jur_cast <- dcast(hincome_jur, jurisdiction_id+hinccat1~yr, value.var="N")


head(hincome_cpa_cast)

#################
#add percent change and absolute change and save as csv
#################

hincome_cpa_cast$pct_chg <- (hincome_cpa_cast$y2050-hincome_cpa_cast$y2018)/hincome_cpa_cast$y2050
hincome_jur_cast$pct_chg <- (hincome_jur_cast$y2050-hincome_jur_cast$y2018)/hincome_jur_cast$y2050
hincome_cpa_cast$abs_chg <- hincome_cpa_cast$y2050-hincome_cpa_cast$y2018
hincome_jur_cast$abs_chg <- hincome_jur_cast$y2050-hincome_jur_cast$y2018
hincome_cpa_cast$pct_chg <- round(hincome_cpa_cast$pct_chg * 100, 2)
hincome_jur_cast$pct_chg <- round(hincome_jur_cast$pct_chg * 100, 2)

write.csv(hincome_cpa_cast,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\hincome cpa freq.csv" )
write.csv(hincome_jur_cast,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\hincome jur freq.csv" )
write.csv(hincome_reg,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\hincome reg freq.csv" )

hincome_cpa_omit<-na.omit(hincome_cpa)

#add figure script and write out file
##################################################
#graphs
##################################################
#graphs save here
results<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\"

#household income region
hincome_region<-ggplot(data=hincome_reg, aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1) +
  labs(title="SD Regionwide Households by Income", y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(1000,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_region, file=paste(results, "hhincome_reg.pdf"))

jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

list<- c("<30k", "30k-60k", "60k-100k", "100k-150k", ">150k")


results4<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\Jurisdiction\\"

hincome_jur$hinccat1 <- factor(hincome_jur$hinccat1, levels=c(1, 2, 3, 4, 5), labels=c("<30k", "30k-60k", "60k-100k", "100k-150k", ">150k"))


###jurisdiction 1
hincome_jur1<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[1]),  
                     aes(x=yr, y=Percent_Income, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[1]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(0, 1))+
  scale_y_continuous(labels= scales::percent)+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur1, file= paste(results4, "hincome_jur1.pdf"))



###jurisdiction 2

hincome_jur2<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[2]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[2]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,30000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur2, file= paste(results4, "hincome_jur2.pdf"))




###jurisdiction 3

hincome_jur3<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[3]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[3]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(1000,8000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur3, file= paste(results4, "hincome_jur3.pdf"))




###jurisdiction 4

hincome_jur4<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[4]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[4]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,1000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur4, file= paste(results4, "hincome_jur4.pdf"))




###jurisdiction 5

hincome_jur5<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[5]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[5]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur5, file= paste(results4, "hincome_jur5.pdf"))




###jurisdiction 6

hincome_jur6<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[6]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[6]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(500,9000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur6, file= paste(results4, "hincome_jur6.pdf"))




###jurisdiction 7

hincome_jur7<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[7]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[7]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur7, file= paste(results4, "hincome_jur7.pdf"))




###jurisdiction 8

hincome_jur8<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[8]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[8]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur8, file= paste(results4, "hincome_jur8.pdf"))




###jurisdiction 9

hincome_jur9<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[9]),  
                     aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[9]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur9, file= paste(results4, "hincome_jur9.pdf"))




###jurisdiction 10

hincome_jur10<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[10]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[10]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur10, file= paste(results4, "hincome_jur10.pdf"))




###jurisdiction 11

hincome_jur11<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[11]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[11]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur11, file= paste(results4, "hincome_jur11.pdf"))




###jurisdiction 12

hincome_jur12<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[12]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[12]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur12, file= paste(results4, "hincome_jur12.pdf"))




###jurisdiction 13

hincome_jur13<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[13]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[13]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,7500))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur13, file= paste(results4, "hincome_jur13.pdf"))




###jurisdiction 14

hincome_jur14<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[14]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[14]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,250000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur14, file= paste(results4, "hincome_jur14.pdf"))




###jurisdiction 15

hincome_jur15<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[15]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[15]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur15, file= paste(results4, "hincome_jur15.pdf"))




###jurisdiction 16

hincome_jur16<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[16]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[16]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur16, file= paste(results4, "hincome_jur16.pdf"))




###jurisdiction 17

hincome_jur17<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[17]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[17]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,3000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur17, file= paste(results4, "hincome_jur17.pdf"))




###jurisdiction 18

hincome_jur18<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[18]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[18]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur18, file= paste(results4, "hincome_jur18.pdf"))




###jurisdiction 19

hincome_jur19<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[19]),  
                      aes(x=yr, y=N, group=as.factor(hinccat1), color=as.factor(hinccat1))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Income\n                           ", jur_list2[19]), y="Number of Households by income category", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(10000,70000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur19, file= paste(results4, "hincome_jur19.pdf"))



###jurisdiction 4
#this creates the list for "i" which is what the loop relies on - like x in a do repeat

jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")


hincome_jur4<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[4]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[4]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,1000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur4, file=paste(results, "hincome_jur4.pdf"))

###jurisdiction 4
#this creates the list for "i" which is what the loop relies on - like x in a do repeat

jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")


hincome_jur1<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[1]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[1]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur1, file=paste(results, "hincome_jur1.pdf"))


hincome_jur5<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[5]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[5]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur5, file=paste(results, "hincome_jur5.pdf"))


hincome_jur7<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[7]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[7]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur7, file=paste(results, "hincome_jur7.pdf"))


hincome_jur12<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[12]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[12]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur12, file=paste(results, "hincome_jur12.pdf"))

######

hincome_jur3<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[3]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[3]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur3, file=paste(results, "hincome_jur3.pdf"))



hincome_jur6<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[6]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[6]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur6, file=paste(results, "hincome_jur6.pdf"))


hincome_jur9<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[9]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[9]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur9, file=paste(results, "hincome_jur9.pdf"))


hincome_jur13<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[13]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[13]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur13, file=paste(results, "hincome_jur13.pdf"))



hincome_jur16<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[16]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[16]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur16, file=paste(results, "hincome_jur16.pdf"))


hincome_jur11<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[11]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[11]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur11, file=paste(results, "hincome_jur11.pdf"))



hincome_jur15<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[15]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[15]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur15, file=paste(results, "hincome_jur15.pdf"))

hincome_jur18<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[18]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[18]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur18, file=paste(results, "hincome_jur18.pdf"))

hincome_jur8<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[8]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[8]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur8, file=paste(results, "hincome_jur8.pdf"))


hincome_jur10<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[10]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[10]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur10, file=paste(results, "hincome_jur10.pdf"))


hincome_jur17<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[17]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[17]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur17, file=paste(results, "hincome_jur17.pdf"))



hincome_jur2<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[2]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[2]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,30000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur2, file=paste(results, "hincome_jur2.pdf"))



hincome_jur19<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[19]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[19]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,75000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur19, file=paste(results, "hincome_jur19.pdf"))


hincome_jur14<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[14]), aes(x=yr, y=N, group=hinccat1, colour=hinccat1)) +
  geom_line(size=1.25) +
  labs(title=paste("         Households by Jurisdiction by Income\n                              ", jur_list2[14]), y="Households by income category", x=" Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,250000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hincome_jur14, file=paste(results, "hincome_jur14.pdf"))

#household income jurisdiction

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)

#this is the loop with the subset, the ggplot and the ggsave commands
for(i in jur_list){
  plot<-ggplot(subset(hincome_jur, hincome_jur$jurisdiction_id==jur_list[i]),  
               aes(x=yr, y=N, group=hinccat1, color=hinccat1)) +
    geom_line(size=1.25) +
    labs(title="Households by Jurisdiction by Income", y="Households by income category", x="Year",
         caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(1000,50000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'hincome_jur', jur_list[i], ".pdf", sep=''), scale=2)
}

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



