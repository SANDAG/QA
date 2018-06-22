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
