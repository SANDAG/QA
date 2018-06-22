

jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")



results2<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\Building Size\\"


HH_Building_size_jur$bldgsz <- factor(HH_Building_size_jur$bldgsz, levels=c(1, 3, 8, 9), labels=c("Mobile Home","Single Family Household","Apartments","Group Quarters"))



hhsize_jur1<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[1]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[1]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(1000,30000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur1, file= paste(results2, "hhsize_jur1.pdf"))



hhsize_jur2<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[2]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[2]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,60000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur2, file= paste(results2, "hhsize_jur2.pdf"))



hhsize_jur3<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[3]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[3]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur3, file= paste(results2, "hhsize_jur3.pdf"))



hhsize_jur4<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[4]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[4]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,2000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur4, file= paste(results2, "hhsize_jur4.pdf"))



hhsize_jur5<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[5]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[5]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,25000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur5, file= paste(results2, "hhsize_jur5.pdf"))



hhsize_jur6<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[6]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[6]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur6, file= paste(results2, "hhsize_jur6.pdf"))



hhsize_jur7<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[7]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[7]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,30000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur7, file= paste(results2, "hhsize_jur7.pdf"))



hhsize_jur8<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[8]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                       ", jur_list2[8]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur8, file= paste(results2, "hhsize_jur8.pdf"))



hhsize_jur9<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[9]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[9]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,25000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur9, file= paste(results2, "hhsize_jur9.pdf"))



hhsize_jur10<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[10]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                       ", jur_list2[10]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur10, file= paste(results2, "hhsize_jur10.pdf"))



hhsize_jur11<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[11]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                       ", jur_list2[11]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur11, file= paste(results2, "hhsize_jur11.pdf"))



hhsize_jur12<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[12]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[12]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,40000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur12, file= paste(results2, "hhsize_jur12.pdf"))



hhsize_jur13<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[13]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[13]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur13, file= paste(results2, "hhsize_jur13.pdf"))



hhsize_jur14<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[14]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[14]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,500000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur14, file= paste(results2, "hhsize_jur14.pdf"))



hhsize_jur15<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[15]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[15]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,25000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur15, file= paste(results2, "hhsize_jur15.pdf"))



hhsize_jur16<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[16]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[16]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur16, file= paste(results2, "hhsize_jur16.pdf"))



hhsize_jur17<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[17]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                           ", jur_list2[17]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur17, file= paste(results2, "hhsize_jur17.pdf"))



hhsize_jur18<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[18]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                             ", jur_list2[18]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur18, file= paste(results2, "hhsize_jur18.pdf"))



hhsize_jur19<-ggplot(subset(HH_Building_size_jur, HH_Building_size_jur$jurisdiction_id==jur_list[19]),  
                    aes(x=yr, y=N, group=as.factor(bldgsz), color=as.factor(bldgsz))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by Building Size\n                       ", jur_list2[19]), y="Number of Households by Building Size", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,250000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhsize_jur19, file= paste(results2, "hhsize_jur19.pdf"))
