#hh number plots
#for id 28 2018 is earliest year in dataset though base year is still 2016.


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

options(stringsAsFactors=FALSE)

ds_id=28

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
# datasource name
ds_sql = getSQL("../Queries/datasource_name.sql")
ds_sql <- gsub("ds_id", ds_id,ds_sql)
datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)

hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh<-gsub("ds_id", ds_id,hh_sql)
hh <- sqlQuery(channel,hh)
odbcClose(channel)

head(hh)
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]
hh$N_chg <- ave(hh$households, factor(hh$geozone), FUN=function(x) c(NA,diff(x)))
hh$N_pct <- (hh$N_chg / lag(hh$households))*100
hh$N_pct<-round(hh$N_pct, digits = 2)


##############################
##############################
# rename series 13 CPA to the same name as Series 14 CPA names when appropriate

# hh$geozone[hh$geozone == "City Heights"] <- "Mid-City:City Heights"
# 
# hh$geozone[hh$geozone == "Normal Heights"] <- "Mid-City:Normal Heights"
# 
# hh$geozone[hh$geozone == "Kensington-Talmadge"] <- "Mid-City:Kensington-Talmadge"
# 
# hh$geozone[hh$geozone == "Ncfua Reserve"] <- "NCFUA Reserve"
# 
# hh$geozone[hh$geozone == "Ncfua Subarea 2"] <- "NCFUA Subarea 2"
# 
# hh$geozone[hh$geozone == "Nestor"] <- "Otay Mesa-Nestor"
# 
# hh$geozone[hh$geozone == "Encanto"] <- "Southeastern:Encanto Neighborhoods"
# 
# hh$geozone[hh$geozone == "Eastern Area"] <- "Mid-City:Eastern Area"
# 
# hh$geozone[hh$geozone == "Southeastern San Diego"] <- "Southeastern:Southeastern San Diego"

##############################
##############################


hh$N_chg[hh$yr_id == 2018] <- 0
hh$N_pct[hh$yr_id == 2018] <- 0

hh_jur = subset(hh,geotype=='jurisdiction')
colnames(hh_jur)[colnames(hh_jur)=="geozone"] <- "cityname"

hh_cpa = subset(hh,geotype=='cpa')
colnames(hh_cpa)[colnames(hh_cpa)=="geozone"] <- "cpaname"

hh_region = subset(hh,geotype=='region')
colnames(hh_region)[colnames(hh_region)=="geozone"] <- "SanDiegoRegion"

head(hh_region)

hh_jur$regN_chg<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),"N_chg"]
hh_cpa$regN_chg<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),"N_chg"]

hh_jur$regN<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),"households"]
hh_cpa$regN<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),"households"]

hh_jur$regN_pct<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),"N_pct"]
hh_cpa$regN_pct<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),"N_pct"]

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hh\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

hh_jur$year<- "y"
hh_jur$yr <- as.factor(paste(hh_jur$year, hh_jur$yr, sep = ""))
hh_jur$N <-  hh_jur$households

jur_list = unique(hh_jur[["cityname"]])

for(i in jur_list) { #1:length(unique(hh_jur[["cityname"]]))){
  plotdat = subset(hh_jur, hh_jur$cityname==i)
  ravg = max(plotdat$regN_chg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = regN_chg/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    scale_colour_manual(values = c("blue")) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption=paste("Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=",ds_id,sep=''))+
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  #ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".png", sep=''))
  output_table<-data.frame(plotdat$yr_id,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$regN_chg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr_id == 'y2018'] <- ''
  output_table$plotdat.regN_chg[output_table$plotdat.yr_id == 'y2018'] <- ''
  hhtitle = paste("HH ",i,sep='')
  setnames(output_table, old=c("plotdat.yr_id","plotdat.N","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.regN_chg",
                               "plotdat.regN_pct"),new=c("Year",hhtitle,"Chg", "Pct","HH Region","Chg","Pct"))
  tt <- ttheme_default(base_size=12,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
    lay <- rbind(c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(2,2,2,2,2),
                 c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'households', i, ds_id,".png", sep=''),
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
  ravg = max(plotdat$regN_chg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cpaname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = regN_chg/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    scale_colour_manual(values = c("blue")) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption=paste("Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=",ds_id, sep=''))+
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  output_table<-data.frame(plotdat$yr_id,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$regN_chg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2018'] <- ''
  output_table$plotdat.regN_chg[output_table$plotdat.yr == 'y2018'] <- ''
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
  ggsave(output, file= paste(results, 'households', i, ds_id,".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



