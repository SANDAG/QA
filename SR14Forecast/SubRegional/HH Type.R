jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")



results3<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\HHT\\"



HH_type_jur$hht <- factor(HH_type_jur$hht, levels=c(1, 2, 3, 4, 5, 6, 7), labels=c())



hhtype_jur1<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[1]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[1]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(100,25000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur1, file= paste(results3, "hhtype_jur1.pdf"))



hhtype_jur2<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[2]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[2]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(100,30000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur2, file= paste(results3, "hhtype_jur2.pdf"))



hhtype_jur3<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[3]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[3]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur3, file= paste(results3, "hhtype_jur3.pdf"))



hhtype_jur4<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[4]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[4]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur4, file= paste(results3, "hhtype_jur4.pdf"))



hhtype_jur5<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[5]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[5]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur5, file= paste(results3, "hhtype_jur5.pdf"))



hhtype_jur6<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[6]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[6]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur6, file= paste(results3, "hhtype_jur6.pdf"))



hhtype_jur7<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[7]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[7]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(100,30000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur7, file= paste(results3, "hhtype_jur7.pdf"))



hhtype_jur8<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[8]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[8]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,6000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur8, file= paste(results3, "hhtype_jur8.pdf"))



hhtype_jur9<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[9]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[9]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur9, file= paste(results3, "hhtype_jur9.pdf"))



hhtype_jur10<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[10]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[10]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur10, file= paste(results3, "hhtype_jur10.pdf"))



hhtype_jur11<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[11]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[11]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,10000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur11, file= paste(results3, "hhtype_jur11.pdf"))



hhtype_jur12<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[12]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[12]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(100,50000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur12, file= paste(results3, "hhtype_jur12.pdf"))



hhtype_jur13<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[13]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[13]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur13, file= paste(results3, "hhtype_jur13.pdf"))



hhtype_jur14<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[14]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[14]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(10000,300000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur14, file= paste(results3, "hhtype_jur14.pdf"))



hhtype_jur15<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[15]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[15]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur15, file= paste(results3, "hhtype_jur15.pdf"))



hhtype_jur16<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[16]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[16]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,15000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur16, file= paste(results3, "hhtype_jur16.pdf"))



hhtype_jur17<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[17]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[17]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,5000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur17, file= paste(results3, "hhtype_jur17.pdf"))



hhtype_jur18<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[18]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[18]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(100,20000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur18, file= paste(results3, "hhtype_jur18.pdf"))



hhtype_jur19<-ggplot(subset(HH_type_jur, HH_type_jur$jurisdiction_id==jur_list[19]),  
                    aes(x=yr, y=N, group=as.factor(hht), color=as.factor(hht))) +
  geom_line(size=1.25) +
  labs(title=paste("Number of Households by Jurisdiction by HH Type\n                           ", jur_list2[19]), y="Number of Households by HH Type", x="Year",
       caption="Source: isam.xpef03.household+data_cafe.regional_forecast.sr13_final.mgra13")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels= comma, limits = c(0,60000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(hhtype_jur19, file= paste(results3, "hhtype_jur19.pdf"))
