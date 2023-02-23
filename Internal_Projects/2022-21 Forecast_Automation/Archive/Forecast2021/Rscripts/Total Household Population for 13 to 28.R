#hhpop plots and tables across 2 datasource ids


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

datasource_id = 17

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id, hh_sql)
hh_old<-sqlQuery(channel,hh_sql)
odbcClose(channel)

datasource_id = 28
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id, hh_sql)
hh_new<-sqlQuery(channel,hh_sql)
odbcClose(channel)

hh_old$ds_id<-17
hh_new$ds_id<-28

hh_old<- hh_old[order(hh_old$geotype,hh_old$geozone,hh_old$yr_id,hh_old$ds_id),]
hh_old$N_chg <- ave(hh_old$hhp, factor(hh_old$geozone), FUN=function(x) c(NA,diff(x)))
hh_old$N_pct <- (hh_old$N_chg / lag(hh_old$hhp))*100
hh_old$N_pct<-sprintf("%.2f",hh_old$N_pct)

hh_new<- hh_new[order(hh_new$geotype,hh_new$geozone,hh_new$yr_id,hh_new$ds_id),]
hh_new$N_chg <- ave(hh_new$hhp, factor(hh_new$geozone), FUN=function(x) c(NA,diff(x)))
hh_new$N_pct <- (hh_new$N_chg / lag(hh_new$hhp))*100
hh_new$N_pct<-sprintf("%.2f",hh_new$N_pct)

hh_region = subset(hh_new,geotype=='region')
hh_old = subset(hh_old,geotype=='jurisdiction')
hh_new = subset(hh_new,geotype=='jurisdiction')

hh_region<- hh_region[order(hh_region$geotype,hh_region$geozone,hh_region$yr_id,hh_region$ds_id),]
hh_region$N_chg <- ave(hh_region$hhp, factor(hh_region$geozone), FUN=function(x) c(NA,diff(x)))
hh_region$N_pct <- (hh_region$N_chg / lag(hh_region$hhp))*100
hh_region$N_pct<-sprintf("%.2f",hh_region$N_pct)
head(hh_region)

#hh_old$ds_id<-NULL
hh_old$households<-NULL
hh_old$hhs<-NULL

#hh_new$ds_id<-NULL
hh_new$households<-NULL
hh_new$hhs<-NULL

#hh_region$ds_id<-NULL
hh_region$households<-NULL
hh_region$hhs<-NULL

hh_jur<-rbind(hh_old, hh_new)

#setnames(hh_old, old =c("hhp","N_chg","N_pct"), new =c("hhp14","N_chg14","N_pct14"))
#setnames(hh_new, old =c("hhp","N_chg","N_pct"), new =c("hhp15","N_chg15","N_pct15"))

#hh$geozone<-as.character(hh$geozone)

#hh<-merge(select(hh_old,yr_id,geotype,geozone,hhp14),(select(hh_new,yr_id,geotype,geozone,hhp15)),by.x=c("yr_id","geotype","geozone"),by.y=c("yr_id","geotype","geozone"),all=TRUE)

#hh<-merge(hh_old,hh_new,by.x=c("yr_id","geotype","geozone"),by.y=c("yr_id","geotype","geozone"),all=TRUE)


head(hh_jur)
tail(hh_jur)
#hh_region$N_chg[hh_region$yr_id == 2016] <- 0
#hh_region$N_pct[hh_region$yr_id == 2016] <- 0

#hh_jur = hh

#hh_jur = subset(hh,geotype=='jurisdiction')
colnames(hh_jur)[colnames(hh_jur)=="geozone"] <- "cityname"

#hh_cpa = subset(hh,geotype=='cpa')
#colnames(hh_cpa)[colnames(hh_cpa)=="geozone"] <- "cpaname"

#hh_region = subset(hh_new,geotype=='region')
#colnames(hh_region)[colnames(hh_region)=="geozone"] <- "SanDiegoRegion"



hh_jur$reg<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),"hhp"]
#hh_cpa$reg<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),"hhp"]

hh_jur$regN<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),"N_chg"]
#hh_cpa$regN<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),"N_chg"]

hh_jur$regN_pct<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),"N_pct"]
#hh_cpa$regN_pct<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),"N_pct"]

head(hh_jur,10)

table(hh_jur$geotype)
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hh_pop\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

hh_jur$year<- "y"
hh_jur$yr <- as.factor(paste(hh_jur$year, hh_jur$yr, sep = ""))
hh_jur$N <-  hh_jur$hhp

jur_list = unique(hh_jur[["cityname"]])
jur_list2 = unique(hh_jur[["cityname"]])

head(hh_jur)

for(i in jur_list) { #1:length(unique(hh_jur[["cityname"]]))){
  plotdat = subset(hh_jur, hh_jur$cityname==i)
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cityname)) +
    facet_grid(.~ds_id)+
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region"),size=2) +
    levels(tips2$sex)[levels(tips2$sex)=="Female"] <- ""+
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    labs(title=paste("Change in Total Household Pop\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=18")+
    scale_fill_manual(values = c("blue", "red")) +
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  # ggsave(plot, file= paste(results, 'Total Household Pop',  i, ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2016'] <- ''
  output_table$plotdat.reg[output_table$plotdat.yr == 'y2016'] <- ''
  hhtitle = paste("HH Pop ",i,sep='')
  setnames(output_table, old=c("plotdat.yr_id","plotdat.hhp","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.reg",
                               "plotdat.regN_pct"),new=c("Year",hhtitle,"Chg", "Pct","Chg","HH Pop Region","Pct"))
  tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
    output<-grid.arrange(plot,tbl,ncol=2,as.table=TRUE,layout_matrix=lay)
    i = gsub("\\*","",i)
    i = gsub("\\-","_",i)
    i = gsub("\\:","_",i)
  ggsave(output, file= paste(results, 'total household pop', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}


####CPA



hh_cpa$N_pct[is.nan(hh_cpa$N_pct)] <- 1

hh_cpa$year<- "y"
hh_cpa$yr <- as.factor(paste(hh_cpa$year, hh_cpa$yr, sep = ""))
hh_cpa$N <-  hh_cpa$hhp


cpa_list = unique(hh_cpa[["cpaname"]])

results<-"plots\\hh_pop\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)



for(i in cpa_list) { #1:length(unique(hh_jur[["cityname"]]))){
  plotdat = subset(hh_cpa, hh_cpa$cpaname==i)
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cpaname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    labs(title=paste("Change in Total Household Pop\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=18")+
    scale_fill_manual(values = c("blue", "red")) +
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  # ggsave(plot, file= paste(results, 'Total Household Pop',  i, ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2016'] <- ''
  output_table$plotdat.reg[output_table$plotdat.yr == 'y2016'] <- ''
  hhtitle = paste("HH Pop ",i,sep='')
  setnames(output_table, old=c("plotdat.yr_id","plotdat.hhp","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.reg",
                               "plotdat.regN_pct"),new=c("Year",hhtitle,"Chg", "Pct","HH Pop Region","Chg","Pct"))
  tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=2,as.table=TRUE,layout_matrix=lay)
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(output, file= paste(results, 'total household pop', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



###Per Anne's request
hh_jur = subset(hh,geotype=='jurisdiction')
hh_region = subset(hh,geotype=='region')
hh_region$geozone = 'Region'
hh_plot <- rbind(hh_jur,hh_region)
sp<-ggplot(hh_plot,aes(x=yr_id,y=hhp)) + geom_point(shape=1) + geom_line()
sp + facet_wrap(~geozone,ncol=3,scales="free")





