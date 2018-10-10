

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

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
median_income_jur_sql = getSQL("../Queries/median_income_jur.sql")
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
median_income_cpa_sql = getSQL("../Queries/median_income_cpa.sql")
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
median_income_region_sql = getSQL("../Queries/median_income_region.sql")
mi_region<-sqlQuery(channel,median_income_region_sql,stringsAsFactors = FALSE)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(mi_jur, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\mijur_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(mi_cpa, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\micpa_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(mi_region, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\miregion_sql_17",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

head(mi_region)
#remove unneeded characters from geozone values.
mi_cpa$geozone <- gsub("\\*","",mi_cpa$geozone)
mi_cpa$geozone <- gsub("\\-","_",mi_cpa$geozone)
mi_cpa$geozone <- gsub("\\:","_",mi_cpa$geozone)

mi_jur$reg<-mi_region[match(mi_jur$yr_id, mi_region$yr_id),"median_inc"]
mi_cpa$reg<-mi_region[match(mi_cpa$yr_id, mi_region$yr_id),"median_inc"]

#calculate number and percent changes
mi_jur <- mi_jur[order(mi_jur$geozone,mi_jur$yr_id),]
mi_cpa <- mi_cpa[order(mi_cpa$geozone,mi_cpa$yr_id),]
mi_jur$mi_numchg<- ave(mi_jur$median_inc, factor(mi_jur$geozone), FUN=function(x) c(NA,diff(x)))
mi_cpa$mi_numchg<- ave(mi_cpa$median_inc, factor(mi_cpa$geozone), FUN=function(x) c(NA,diff(x)))
mi_jur$mi_pctchg<- ave(mi_jur$median_inc, factor(mi_jur$geozone), FUN=function(x) c(NA,diff(x)/x*100))
mi_cpa$mi_pctchg<- ave(mi_cpa$median_inc, factor(mi_cpa$geozone), FUN=function(x) c(NA,diff(x)/x*100))
#round pct changes
mi_jur$mi_pctchg<-round(mi_jur$mi_pctchg,digits=2)
mi_cpa$mi_pctchg<-round(mi_cpa$mi_pctchg,digits=2)


#plots


#jurisdiction plots
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\median_income\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

citynames <- data.frame(jur_list, jur_list2)
mi_jur$jurisdiction_id<-citynames[match(mi_jur$geozone, citynames$jur_list2),1]

head(mi_jur)

#this is the loop with the subset, the ggplot and the ggsave commands

for(i in 1:length(jur_list)){
  plotdat = subset(mi_jur, mi_jur$jurisdiction_id==jur_list[i])
  plot<-ggplot(plotdat,aes(x=yr_id, y=median_inc, colour=geozone)) +
    geom_line(size=1)+ 
    geom_line(aes(x=yr_id, y = reg, colour = "Region")) +
    scale_y_continuous(label=comma,limits=c(41000,95000))+ 
    labs(title=paste("Median Income ", jur_list2[i],' and\n Region, 2016-2050',sep=''), 
         y=" median income", x="Year",
         caption="Sources: demographic warehouse: dbo.compute_median_income_all_zones 17
         \nNote:Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
    scale_colour_manual(values = c("blue", "red")) +
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  ggsave(plot, file= paste(results, 'median_inc', jur_list2[i],'17', ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$median_inc,plotdat$mi_numchg,plotdat$mi_pctchg,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.median_inc","plotdat.mi_numchg","plotdat.mi_pctchg","plotdat.reg"),new=c("Year","Median Inc","Num Chg","Pct Chg","Region Median Inc"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'median_inc', jur_list2[i],'17', ".png", sep=''))#, scale=2)
}


#############
summary(mi_cpa)

cpa_list<-unique(mi_cpa$geozone)

results<-"plots\\median_income\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in 1:length(cpa_list)){
  plotdat = subset(mi_cpa, mi_cpa$geozone==cpa_list[i])
  plot<-ggplot(plotdat,aes(x=yr_id, y=median_inc, colour=geozone)) +
    geom_line(size=1)+ 
    geom_line(aes(x=yr_id, y = reg, colour = "Region")) +
    scale_y_continuous(label=comma,limits=c(41000,95000))+ 
    labs(title=paste("Median Income ", cpa_list[i],' and\n Region, 2016-2050',sep=''), 
         y=" median income", x="Year",
         caption="Sources: demographic warehouse: dbo.compute_median_income_all_zones 17\nNote:Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
    scale_colour_manual(values = c("blue", "red")) +
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  ggsave(plot, file= paste(results, 'median_income', cpa_list[i], '17', ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$median_inc,plotdat$mi_numchg,plotdat$mi_pctchg,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.median_inc","plotdat.mi_numchg","plotdat.mi_pctchg","plotdat.reg"),new=c("Year","Median Inc","Num Chg","Pct Chg","Region Median Inc"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'median_income', cpa_list[i],'17', ".png", sep=''))#, scale=2)
}




