#Traditional Vacancy Rate


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

#bring data in from SQL
channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
Vacancy_sql = getSQL("../Queries/Vacancy.sql")
vacancy<-sqlQuery(channel,Vacancy_sql)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\vacancy_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)

#This aggregates from type of units
vac <-aggregate(cbind(units, hh, unoccupiable) ~yr_id + geozone + geotype, data= vacancy, sum,na.rm = TRUE)


#calculate the vacancy rate - formula does not exclude unoccupiable units
vac$available <-(vac$units-vac$hh)
vac$rate <-(vac$available/vac$units)*100
vac$rate <-round(vac$rate,digits=2)


head(vac)
#vacancy$long_name<-' '

#vacancy$long_name[vacancy$short_name=="mf"]<- "Multi Family"
#vacancy$long_name[vacancy$short_name=="mh"]<- "Mobile Home"
#vacancy$long_name[vacancy$short_name=="sf"]<- "Single Family"
#vacancy$long_name[vacancy$short_name=="sfmu"]<- "Single Family Multi Unit"

#vacancy$long_name<- factor(vacancy$long_name, levels = c("Multi Family",
                                       #"Mobile Home","Single Family", "Single Family Multi Unit"))


vac$year<- "y"
vac$yr <- as.factor(paste(vac$year, vac$yr, sep = ""))

vac_jur = subset(vac,geotype=='jurisdiction')
vac_cpa = subset(vac,geotype=='cpa')
vac_region = subset(vac,geotype=='region')


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Vacancy\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

write.csv(vac,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\Traditional vacancy_17.csv")

tail(vac_region)

##Jurisdiction plots and tables



jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

citynames <- data.frame(jur_list, jur_list2)
vac_jur$jurisdiction_id<-citynames[match(vac_jur$geozone, citynames$jur_list2),1]
vac_jur$reg<-vac_region[match(vac_jur$yr_id, vac_region$yr_id),8]


for(i in jur_list) { 
plotdat = subset(vac_jur, vac_jur$jurisdiction_id==jur_list[i])
plot<- ggplot(plotdat, aes(x=yr_id, y=rate, colour=geozone))+
 geom_line(size=1)+
  geom_line(aes(x=yr_id, y=reg, colour="Region")) +
  scale_y_continuous(labels = comma, limits=c(0,10))+
  labs(title=paste("SR14 Vacancy Rate ", jur_list2[i],'\nand Region, 2016-2050',sep=""),
       caption="Source: demographic_warehouse: fact.housing,dim.mgra, dim.structure_type\nhousehold.datasource_id = 16\nNote:Unoccupiable units are included.Out of range data may not appear on the plot.\nRefer to the table below for those related data results.",
       y="Vacancy Rate", 
       x="Year")+
  theme_bw(base_size = 12)+
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 7))
ggsave(plot, file= paste(results, 'vacancy', jur_list2[i], "16.png", sep=''))#, scale=2)
#sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
output_table<-data.frame(plotdat$yr_id,plotdat$rate,plotdat$reg)
setnames(output_table, old=c("plotdat.yr_id","plotdat.rate","plotdat.reg"),new=c("Year","Jur Vac Rate","Reg Vac Rate"))
tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
#tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
 #                    colhead = list(fg_params=list(cex = 1.0)),
  #                   rowhead = list(fg_params=list(cex = 1.0)))
tbl <- tableGrob(output_table, rows=NULL, theme=tt)
lay <- rbind(c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(2,2,2,2,2),
             c(2,2,2,2,2))
output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
ggsave(output, file= paste(results,'vacancy',jur_list2[i], "16.png", sep=''))#, scale=2))
}

head(plotdat)

#####################
#CPA plots and tables


results<-"plots\\Vacancy\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(vac_cpa[["geozone"]])

#vac_jur$jurisdiction_id<-citynames[match(vac_jur$geozone, citynames$jur_list2),1]
vac_cpa$reg<-vac_region[match(vac_cpa$yr_id, vac_region$yr_id),8]


head(vac_cpa)

for(i in 1:length(cpa_list)) { 
  plotdat = subset(vac_cpa, vac_cpa$geozone==cpa_list[i])
  plot<- ggplot(plotdat, aes(x=yr_id, y=rate, colour=geozone))+
    geom_line(size=1)+
    geom_line(aes(x=yr_id, y=reg, colour="Region")) +
    scale_y_continuous(labels = comma, limits=c(0,10))+
    labs(title=paste("SR14 Vacancy Rate ", cpa_list[i],'\nand Region, 2016-2050',sep=""),
         caption="Source: demographic_warehouse: fact.housing,dim.mgra, dim.structure_type\nhousehold.datasource_id = 16\nNotes:Unoccupiable units are included. Out of range data may not appear on the plot.\nRefer to the table below for those related data results.",
         y="Vacancy Rate", 
         x="Year")+
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  ggsave(plot, file= paste(results, 'vacancy', cpa_list[i], "16.png", sep=''))#, scale=2)
  #sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
  output_table<-data.frame(plotdat$yr_id,plotdat$rate,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.rate","plotdat.reg"),new=c("Year","CPA Vacancy Rate","Region Vacancy Rate"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  #tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
  #                    colhead = list(fg_params=list(cex = 1.0)),
  #                   rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results,'vacancy',cpa_list[i], "16.png", sep=''))#, scale=2))
}




