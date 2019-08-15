#forecast id=29.
#hhpop change

#fix line 26


#forecast 2021 household pop plots


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

ds_id = 28

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id, hh_sql)
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)



#create dataframes
# hhp <- data.frame()
# sourcename <- data.frame()
# hh <- data.frame()

#work with AK to fix code
# for(i in 1:length(datasource_ids)) {
#   # get the name of the datasource
#   datasource_name <- readDB("../Queries/datasource_name.sql",datasource_ids[i])
#   sourcename <- rbind(sourcename,datasource_name)
# 
#   # get hhpop data
#   hh <- readDB("../Queries/hh_hhp_hhs_ds_id.sql",datasource_ids[i])
#   hh$datasource_id = datasource_ids[i]
#   hh$series = datasource_names[i]
#   hhp <- rbind(hhp,hh)
# }



# #config contents
# datasource_id_current <- 28
# datasource_ids <- c(13,28)
# datasource_names <- c("Series 13 (ds 13)","Series 14 (ds 28)")
# datasource_name_short <- c("Series 13","Series 14")
# datasource_outfolder <- "vacancyds28"

#get the name of the datasource
  datasource_name <- readDB("../Queries/datasource_name.sql")
#  sourcename <- rbind(sourcename,datasource_name)

  # get hhpop data
  hh <- readDB("../Queries/hh_hhp_hhs_ds_id.sql",datasource_ids[i])
  hh$datasource_id = datasource_ids[i]
  hh$series = datasource_names[i]
  hhp <- rbind(hhp,hh)


# get cpa id
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_ids[i])
odbcClose(channel)

# fix names of sr13 cpas to match sr14 cpas
hhp <- rename_sr13_cpas(hhp)

head(hhp)
hhp <- hhp[order(hhp$geotype,hhp$geozone,hhp$yr_id),]
hhp$N_chg <- ave(hhp$hhp, factor(hhp$geozone), FUN=function(x) c(NA,diff(x)))
hhp$N_pct <- (hhp$N_chg / lag(hh$hhp))*100
hhp$N_pct <- round(hhp$N_pct, digits = 2)

hhp$N_chg[hhp$yr_id == 2018] <- 0
hhp$N_pct[hhp$yr_id == 2018] <- 0

hhp_jur = subset(hhp,geotype=='jurisdiction')
colnames(hhp_jur)[colnames(hhp_jur)=="geozone"] <- "cityname"

hhp_cpa = subset(hhp,geotype=='cpa')
colnames(hhp_cpa)[colnames(hhp_cpa)=="geozone"] <- "cpaname"

hhp_region = subset(hhp,geotype=='region')
colnames(hhp_region)[colnames(hhp_region)=="geozone"] <- "SanDiegoRegion"

hhp_jur$reg<-hhp_region[match(hhp_jur$yr_id, hhp_region$yr_id),"N_chg"]
hhp_cpa$reg<-hhp_region[match(hhp_cpa$yr_id, hhp_region$yr_id),"N_chg"]

hhp_jur$regN<-hhp_region[match(hhp_jur$yr_id, hhp_region$yr_id),"hhp"]
hhp_cpa$regN<-hhp_region[match(hhp_cpa$yr_id, hhp_region$yr_id),"hhp"]

hhp_jur$regN_pct<-hhp_region[match(hhp_jur$yr_id, hhp_region$yr_id),"N_pct"]
hhp_cpa$regN_pct<-hhp_region[match(hhp_cpa$yr_id, hhp_region$yr_id),"N_pct"]


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hh_pop\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

hhp_jur$year<- "y"
hhp_jur$yr <- as.factor(paste(hhp_jur$year, hhp_jur$yr, sep = ""))
hhp_jur$N <-  hhp_jur$hhp

jur_list = unique(hhp_jur[["cityname"]])
jur_list2 = unique(hhp_jur[["cityname"]])



for(i in jur_list) { #1:length(unique(hhp_jur[["cityname"]]))){
  plotdat = subset(hhp_jur, hhp_jur$cityname==i)
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    labs(title=paste("Change in Total Household Pop\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption=paste("Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=",ds_id,sep=''))+
    scale_fill_manual(values = c("blue", "red")) +
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  # ggsave(plot, file= paste(results, 'Total Household Pop',  i, ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2018'] <- ''
  output_table$plotdat.reg[output_table$plotdat.yr == 'y2018'] <- ''
  hhptitle = paste("HH Pop ",i,sep='')
  setnames(output_table, old=c("plotdat.yr_id","plotdat.hhp","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.reg",
                               "plotdat.regN_pct"),new=c("Year",hhptitle,"Chg", "Pct","HH Pop Region","Chg","Pct"))
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
  ggsave(output, file= paste(results, 'total household pop', i, ds_id,".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}


####CPA

hhp_cpa$N_pct[is.nan(hhp_cpa$N_pct)] <- 1

hhp_cpa$year<- "y"
hhp_cpa$yr <- as.factor(paste(hhp_cpa$year, hhp_cpa$yr, sep = ""))
hhp_cpa$N <-  hhp_cpa$hhpp


cpa_list = unique(hhp_cpa[["cpaname"]])

results<-"plots\\hh_pop\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)



for(i in cpa_list) { #1:length(unique(hhp_jur[["cityname"]]))){
  plotdat = subset(hhp_cpa, hhp_cpa$cpaname==i)
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cpaname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    labs(title=paste("Change in Total Household Pop\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption=paste("Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=",ds_id, sep=''))+
    scale_fill_manual(values = c("blue", "red")) +
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  # ggsave(plot, file= paste(results, 'Total Household Pop',  i, ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2018'] <- ''
  output_table$plotdat.reg[output_table$plotdat.yr == 'y2018'] <- ''
  hhptitle = paste("HH Pop ",i,sep='')
  setnames(output_table, old=c("plotdat.yr_id","plotdat.hhp","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.reg",
                               "plotdat.regN_pct"),new=c("Year",hhptitle,"Chg", "Pct","HH Pop Region","Chg","Pct"))
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
  ggsave(output, file= paste(results, 'total household pop', i, ds_id,".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



###Per Anne's request
hhp_jur = subset(hhp,geotype=='jurisdiction')
hhp_region = subset(hhp,geotype=='region')
hhp_region$geozone = 'Region'
hhp_plot <- rbind(hhp_jur,hhp_region)
sp<-ggplot(hhp_plot,aes(x=yr_id,y=hhp)) + geom_point(shape=1) + geom_line()
sp + facet_wrap(~geozone,ncol=3,scales="free")





