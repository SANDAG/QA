#hh size for id35

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

ds_id=35

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
hh$geozone[hh$geozone=="Southeastern_Encanto Neighborhoods"] <- "SE_Encanto Neighborhoods"
hh$geozone[hh$geozone=="Southeastern_Southeastern San Diego"] <- "SE_Southeastern Neighborhoods"

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
          plot.caption = element_text(size = 9)) +
    labs(title=paste("Household Size:", i,' and Region\n datasource_id ',ds_id,sep=''), 
         y="Household size", x="Year",
         caption=paste("Sources: demographic_warehouse",ds_id,"; Notes: Refer to table below for out of range hh size values",sep=''))
  results<-"plots\\hhsize\\jur\\"
  output_table<-plotdat[,c("yr_id","hhp","households","hhs","reg_hhp","reg_hh","reg_hhs")]
  colnames(output_table)[colnames(output_table)=="households"] <- "hh"
  tt <- ttheme_default(base_size=12,colhead=list(fg_params = list(parse=TRUE)))
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
          plot.caption = element_text(size = 10)) +
    labs(title=paste("Household Size ", i,' and Region\ndatasource_id: ',ds_id,sep=''), 
         y="Household size", x="Year",
         caption=paste("Sources: demographic_warehouse",ds_id,";\nNotes: Refer to table below for out of range hh size values",sep='')) 
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  results<-"plots\\hhsize\\cpa\\"
  output_table<-plotdat[,c("yr_id","hhp","households","hhs","reg_hhp","reg_hh","reg_hhs")]
  colnames(output_table)[colnames(output_table)=="households"] <- "hh"
  tt <- ttheme_default(base_size=12,colhead=list(fg_params = list(parse=TRUE)))
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


###############################################################################################
#Section NOT conducted for ds_id=35.
#The following section was added due to the request of customers to only display results for 
# the top 10 CPAs displaying the most amount of change between two time periods.
# 
# #calculate peercent change 
# hh_cpa10 <- hh_cpa[order(hh_cpa$geotype,hh_cpa$cpaname,hh_cpa$yr_id),]
# hh_cpa10$N_chg <- hh_cpa10$hhs - lag(hh_cpa10$hhs)
# hh_cpa10$N_pct <- (hh_cpa10$N_chg / lag(hh_cpa10$hhs))*100
# hh_cpa10$N_pct<-round(hh_cpa10$N_pct,digits=2)
# #recode 2016 and NaN/Inf percent change values to NA or 0.
# hh_cpa10$N_pct[hh_cpa10$yr_id == "2016"] <- NA
# hh_cpa10$N_pct[hh_cpa10$N_pct == "NaN"] <- 0
# #determine absolute value of percent change for top 10 selection
# hh_cpa10$N_pct_ab <- abs(hh_cpa10$N_pct)
# #determine max percent change by cpa
# hh_cpa_top10<- aggregate(N_pct_ab~ cpaname, data=hh_cpa10, max)
# hh_cpa_top10$N_pct_ab[hh_cpa_top10$N_pct_ab == "Inf"] <- 0
# #sort descending on max percent change
# hh_cpa_top10<- hh_cpa_top10[order(-hh_cpa_top10$N_pct_ab),]
# #select only top 10 cpas
# hh_cpa_top10<- hh_cpa_top10 %>% 
#   top_n(10)
# hh_cpa10<- subset(hh_cpa10, cpaname %in% hh_cpa_top10$cpaname)
# 
# #produce plots at designated folder pathway
# results<-"plots\\hhsize\\cpa_top10\\"
# ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)
# 
# cpa_list = unique(hh_cpa10[["cpaname"]])
# 
# for(i in cpa_list) { 
#   plotdat = subset(hh_cpa10, hh_cpa10$cpaname==i)
#   plot<-ggplot(plotdat, aes(yr)) + 
#     geom_line(aes(y = reg_hhs, colour = "1_Region",group=0),size=1.5) +
#     geom_point(size=3,aes(y=reg_hhs,color="1_Region")) +
#     theme(legend.position = "bottom",
#           legend.title=element_blank()) +
#     geom_line(aes(y = hhs, colour = cpaname,group=0),size=1.5) + 
#     geom_point(size=3,aes(y=hhs,colour=cpaname)) +
#     scale_y_continuous(limits = c(1.90, 4.32)) +
#     theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
#     theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
#     theme(legend.position = "bottom",
#           legend.title=element_blank(),
#           plot.caption = element_text(size = 10)) +
#     labs(title=paste("Household Size ", i,' and Region\ndatasource_id: ',ds_id,sep=''), 
#          y="Household size", x="Year",
#          caption=paste("Sources: demographic_warehouse",ds_id,";\nNotes: Refer to table below for out of range hh size values",sep='')) 
#   i = gsub("\\*","",i)
#   i = gsub("\\-","_",i)
#   i = gsub("\\:","_",i)
#   results<-"plots\\hhsize\\cpa_top10\\"
#   output_table<-plotdat[,c("yr_id","hhp","households","hhs","reg_hhp","reg_hh","reg_hhs")]
#   colnames(output_table)[colnames(output_table)=="households"] <- "hh"
#   tt <- ttheme_default(base_size=12,colhead=list(fg_params = list(parse=TRUE)))
#   tbl <- tableGrob(output_table, rows= NULL, theme=tt)
#   lay <- rbind(c(1,1,1,1,1),
#                c(1,1,1,1,1),
#                c(1,1,1,1,1),
#                c(2,2,2,2,2),
#                c(2,2,2,2,2))
#   output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
#   ggsave(output, file= paste(results, 'hhsize', i, ds_id,".png", sep=''),
#          width=6, height=8, dpi=100)#, scale=2)
# }
#  