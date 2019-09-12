#hh size for id30

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

ds_id=30

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

head(hh)
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]

hh$year<- "y"
hh$yr <- as.factor(paste(hh$year, hh$yr, sep = ""))

hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

hh_jur = subset(hh,geotype=='jurisdiction')
colnames(hh_jur)[colnames(hh_jur)=="geozone"] <- "cityname"

hh_cpa = subset(hh,geotype=='cpa')
colnames(hh_cpa)[colnames(hh_cpa)=="geozone"] <- "cpaname"

hh_region = subset(hh,geotype=='region')
colnames(hh_region)[colnames(hh_region)=="geozone"] <- "SanDiegoRegion"

hh_jur$reg_hhs<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),'hhs']
hh_jur$reg_hh<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),'households']
hh_jur$reg_hhp<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),'hhp']

hh_cpa$reg_hhs<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),'hhs']
hh_cpa$reg_hh<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),'households']
hh_cpa$reg_hhp<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),'hhp']

hh_region

head(hh_jur)
head(hh_cpa)

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hhsize\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

jur_list = unique(hh_jur[["cityname"]])

for(i in jur_list) {
  plotdat = subset(hh_jur, hh_jur$cityname==i)
  plot<-ggplot(plotdat, aes(yr)) + 
    geom_line(aes(y = reg_hhs, colour = "1_Region",group=0),size=1.5) +
    geom_point(size=3,aes(y=reg_hhs,color="1_Region")) +
    geom_line(aes(y = hhs, colour = cityname,group=0),size=1.5) + 
    geom_point(size=3,aes(y=hhs,colour=cityname)) +
    scale_y_continuous(limits = c(2, 3.5)) +
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 7)) +
    labs(title=paste("Household Size:", i,' and Region\n datasource_id ',ds_id,sep=''), 
         y="Household size", x="Year",
         caption=paste("Sources: demographic_warehouse",ds_id,"; Notes: Refer to table below for out of range hh size values",sep=''))
    results<-"plots\\hhsize\\jur\\"
    output_table<-plotdat[,c("yr_id","hhp","households","hhs","reg_hhp","reg_hh","reg_hhs")]
    colnames(output_table)[colnames(output_table)=="households"] <- "hh"
    tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
    tbl <- tableGrob(output_table, rows=NULL, theme=tt)
    lay <- rbind(c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(2,2,2,2,2),
                 c(2,2,2,2,2))
    output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
    ggsave(output, file= paste(results, 'hhsize', i, ds_id,".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}





cpa_list = unique(hh_cpa[["cpaname"]])

results<-"plots\\hhsize\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in cpa_list) { 
  plotdat = subset(hh_cpa, hh_cpa$cpaname==i)
  plot<-ggplot(plotdat, aes(yr)) + 
    geom_line(aes(y = reg_hhs, colour = "1_Region",group=0),size=1.5) +
    geom_point(size=3,aes(y=reg_hhs,color="1_Region")) +
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    geom_line(aes(y = hhs, colour = cpaname,group=0),size=1.5) + 
    geom_point(size=3,aes(y=hhs,colour=cpaname)) +
    scale_y_continuous(limits = c(1.90, 4.32)) +
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7)) +
    labs(title=paste("Household Size ", i,' and Region\ndatasource_id: ',ds_id,sep=''), 
         y="Household size", x="Year",
         caption=paste("Sources: demographic_warehouse",ds_id,"; Notes: Refer to table below for out of range hh size values",sep='')) 
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  results<-"plots\\hhsize\\cpa\\"
  output_table<-plotdat[,c("yr_id","hhp","households","hhs","reg_hhp","reg_hh","reg_hhs")]
  colnames(output_table)[colnames(output_table)=="households"] <- "hh"
  tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'hhsize', i, ds_id,".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}

 
 