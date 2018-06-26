pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

head(hh)
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]
hh$N_chg <- ave(hh$households, factor(hh$geozone), FUN=function(x) c(NA,diff(x)))
hh$N_pct <- (hh$N_chg / lag(hh$households))*100

hh$N_chg[hh$yr_id == 2016] <- 0
hh$N_pct[hh$yr_id == 2016] <- 0

hh_jur = subset(hh,geotype=='jurisdiction')
colnames(hh_jur)[colnames(hh_jur)=="geozone"] <- "cityname"

hh_cpa = subset(hh,geotype=='cpa')
colnames(hh_cpa)[colnames(hh_cpa)=="geozone"] <- "cpaname"

hh_region = subset(hh,geotype=='region')
colnames(hh_region)[colnames(hh_region)=="geozone"] <- "SanDiegoRegion"

hh_jur$reg<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),7]
hh_cpa$reg<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),7]


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

hh_jur$yr <-  hh_jur$yr_id
hh_jur$N <-  hh_jur$households

jur_list = unique(hh_jur[["cityname"]])
jur_list2 = unique(hh_jur[["cityname"]])

for(i in jur_list) { #1:length(unique(hh_jur[["cityname"]]))){
  plotdat = subset(hh_jur, hh_jur$cityname==i)
  # plotdat$ratio = plotdat$reg/plotdat$N_chg
  # plotdat$ratio[is.na(plotdat$ratio)] <- 0
  # ravg = median(plotdat[["ratio"]])
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = reg/ravg, group=1,colour = "Region")) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Region HH [abs chg]",label=comma)) +
    labs(title=paste("Absolute Change: No. of Households\n ", i,' and Region, 2016-2050',sep=''), 
         y=paste(i," HH [abs chg]",sep=''), x="Year",
         caption="Sources: isam.xpef03.household\ndata_cafe.regional_forecast.sr13_final.mgra13") +
    scale_colour_manual(values = c("blue", "red")) +
    #expand_limits(y = c(1, 300000))+
    #scale_y_continuous(labels= comma, limits = c((.75 * min(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i]))),(1.5 * max(subset(unittype_jur$N, 
    #unittype_jur$jurisdiction_id==jur_list[i])))))+
    theme_bw(base_size = 16) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'households', i, ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr,plotdat$N,plotdat$N_chg,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr","plotdat.N","plotdat.N_chg","plotdat.reg"),new=c("Year","Total","Abs. Chg.","Reg abs. chg."))
  tt <- ttheme_default(colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,2,2),
               c(1,1,1,2,2),
               c(1,1,1,2,2))
  output<-grid.arrange(plot,tbl,ncol=2,as.table=TRUE,layout_matrix=lay)
  # ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".pdf", sep=''), scale=2)
  ggsave(output, file= paste(results, 'households', i, ".png", sep=''))#, scale=2)
}
