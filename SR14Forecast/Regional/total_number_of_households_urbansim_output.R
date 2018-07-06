pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; 
#                             database=demographic_warehouse; trusted_connection=true')
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; 
                             database=urbansim; trusted_connection=true')

hh_sql = getSQL("../Queries/urbansim_hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql)
hh_sql = getSQL("../Queries/urbansim_hh_hhp_hhs_total.sql")
hh_tot<-sqlQuery(channel,hh_sql)
hh_region_sql = getSQL("../Queries/urbansim_region_hh_hhp_hhs.sql")
hh_region<-sqlQuery(channel,hh_region_sql)
odbcClose(channel)

#head(hh)

hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]
hh$N_chg <- hh$unit_chg
hh$N_chg[hh$yr_id == 2016] <- 0

hh_tot<- hh_tot[order(hh_tot$geotype,hh_tot$geozone,hh_tot$yr_id),]
hh_tot$N_chg <- hh_tot$unit_chg
hh_tot$N_chg[hh_tot$yr_id == 2016] <- 0


hh_jur = subset(hh,geotype=='jurisdiction')
colnames(hh_jur)[colnames(hh_jur)=="geozone"] <- "cityname"

hh_jur_tot = subset(hh_tot,geotype=='jurisdiction')
colnames(hh_jur_tot)[colnames(hh_jur_tot)=="geozone"] <- "cityname"

hh_cpa = subset(hh,geotype=='CPA')
colnames(hh_cpa)[colnames(hh_cpa)=="geozone"] <- "cpaname"

hh_region$geotype='region'
hh_region$geozone="SanDiegoRegion"

hh_jur$regN_chg<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),3]
hh_cpa$regN_chg<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),3]


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-paste("plots\\hh\\jur\\urbansim\\run",toString(hh$run_id[1]),"\\",sep='')
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

hh_jur$year<- "y"
hh_jur$yr <- as.factor(paste(hh_jur$year, hh_jur$yr, sep = ""))


hh_jur$cap_type = hh_jur$capacity_type
hh_jur$cap_type <- factor(hh_jur$cap_type, levels = c(levels(hh_jur$cap_type), "sgoa"))
hh_jur$cap_type[hh_jur$capacity_type=='cc'] <- 'sgoa'
hh_jur$cap_type[hh_jur$capacity_type=='mc'] <- 'sgoa'
hh_jur$cap_type[hh_jur$capacity_type=='tc'] <- 'sgoa'
hh_jur$cap_type[hh_jur$capacity_type=='tco'] <- 'sgoa'
hh_jur$cap_type[hh_jur$capacity_type=='uc'] <- 'sgoa'




jur_list = unique(hh_jur[["cityname"]])

for(i in jur_list) { 
  plotdat = subset(hh_jur, hh_jur$cityname=='i')
  ravg = max(plotdat$regN_chg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot <- ggplot() + geom_bar(aes(y = N_chg, x = yr_id, fill = cap_type), 
                          data = plotdat,
                          stat="identity") +
  geom_line(aes(x = yr_id,y = regN_chg/ravg, group=1),data = plotdat,size=2) +
  scale_y_continuous(label=comma,sec.axis = 
                       sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
  labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
       y=paste("Chg in ",i,sep=''), x="Year") +
  theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5))  +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(legend.position = "bottom",
      legend.title=element_blank())
  ggsave(plot, file= paste(results, 'units', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}


hh_cpa$year<- "y"
hh_cpa$yr <- as.factor(paste(hh_cpa$year, hh_cpa$yr, sep = ""))
hh_cpa$N <-  hh_cpa$households


cpa_list = unique(hh_cpa[["cpaname"]])


results<-paste("plots\\hh\\cpa\\urbansim\\run",toString(hh$run_id[1]),"\\",sep='')
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

hh_cpa$cap_type = hh_cpa$capacity_type
hh_cpa$cap_type <- factor(hh_cpa$cap_type, levels = c(levels(hh_cpa$cap_type), "sgoa"))
hh_cpa$cap_type[hh_cpa$capacity_type=='cc'] <- 'sgoa'
hh_cpa$cap_type[hh_cpa$capacity_type=='mc'] <- 'sgoa'
hh_cpa$cap_type[hh_cpa$capacity_type=='tc'] <- 'sgoa'
hh_cpa$cap_type[hh_cpa$capacity_type=='tco'] <- 'sgoa'
hh_cpa$cap_type[hh_cpa$capacity_type=='uc'] <- 'sgoa'




for(i in cpa_list) { 
  plotdat = subset(hh_cpa, hh_cpa$cpaname==i)
  ravg = max(plotdat$regN_chg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot <- ggplot() + geom_bar(aes(y = N_chg, x = yr_id, fill = cap_type), 
                              data = plotdat,
                              stat="identity") +
    geom_line(aes(x = yr_id,y = regN_chg/ravg, group=1),data = plotdat,size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year") +
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5))  +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(plot, file= paste(results, toString(plotdat$jcpa[1]),'_',i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}




for(i in jur_list) { #1:length(unique(hh_jur[["cityname"]]))){
  plotdat = subset(hh_jur, hh_jur$cityname==i)
  citytotal = subset(hh_jur, hh_jur$cityname==i)
  ravg = max(citytotal$regN_chg,na.rm=TRUE)/max(citytotal$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr_id, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity",aes(fill=cap_type)) +
    geom_line(aes(y = regN_chg/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    scale_colour_manual(values = c("blue")) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=14")+
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  #ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".png", sep=''))
  ggsave(plot, file= paste(results, 'units', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



hh_cpa$year<- "y"
hh_cpa$yr <- as.factor(paste(hh_cpa$year, hh_cpa$yr, sep = ""))
hh_cpa$N <-  hh_cpa$households

cpa_list = unique(hh_cpa[["cpaname"]])

results<-"plots\\hh\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in cpa_list) { 
  plotdat = subset(hh_cpa, hh_cpa$cpaname==i)
  ravg = max(plotdat$regN,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 1
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cpaname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = regN/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
    caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=14")+
    scale_fill_manual(values = c("blue", "red"))+
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption=element_text(size=7))
  output_table<-data.frame(plotdat$yr_id,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$regN_chg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2016'] <- ''
  output_table$plotdat.regN_chg[output_table$plotdat.yr == 'y2016'] <- ''
  hhtitle = paste("HH", "\n","in ",i)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.N","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.regN_chg",
                               "plotdat.regN_pct"),new=c("Year",hhtitle,"Chg", "Pct","HH Region","Chg","Pct"))
  tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
 
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(output, file= paste(results, 'households', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}
