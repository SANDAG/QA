
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


vac <-aggregate(cbind(units, hh, unoccupiable) ~yr_id + geozone + geotype, data= vacancy, sum,na.rm = TRUE)

vac$occupiable_unit<-vac$units-vac$unoccupiable
vac$available <-(vac$occupiable_unit-vac$hh)
vac$rate <-vac$available/vac$occupiable_unit

#vac$rate2<-1-(vac$hh/(vac$units-57000))

head(vac)

tail(vac)


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


##Jurisdiction plots and tables

jur_list = unique(vac_jur[["geozone"]])


for(i in jur_list) { 
plotdat = subset(vac_jur, vac_jur$geozone==i)
pltwregion <- rbind(plotdat, vac_region)
plot<- ggplot(data=pltwregion, aes(x=yr, y=rate, group=geozone, colour=geozone))+
 geom_line(size=1.5)+
  labs(title=paste("Vacancy Rate\n ", i,' and Region',sep=''),
       caption="Source: demographic_warehouse: fact.housing,dim.mgra, dim.income_group\nhousehold_income.datasource_id = 14",
       y="Vacancy Rate", 
       x="Year")+
       #colour="Vacancy")+
  expand_limits(y = c(1, 300000))+
  scale_y_continuous(labels = comma, limits=c(.00,.15))+ 
  theme_bw(base_size = 14)+
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 7))
sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
output_table<-sortdat[,c("yr_id","geozone","units","rate")]
vactitle = paste("Vacancy Rate ",i,sep='')
tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
#tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
 #                    colhead = list(fg_params=list(cex = 1.0)),
  #                   rowhead = list(fg_params=list(cex = 1.0)))
tbl <- tableGrob(output_table, rows=NULL, theme=tt)
lay <- rbind(c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(2,2,2,2,2),
             c(2,2,2,2,2))
output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
results<-"plots\\Vacancy\\Jur\\"
ggsave(output, file= paste(results,i,'vacancy', ".png", sep=''),
       width=6, height=8, dpi=100)#, scale=2)
}

 

#CPA plots and tables


results<-"plots\\Vacancy\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(vac_cpa[["geozone"]])


for(i in cpa_list) { 
  plotdat = subset(vac_cpa, vac_cpa$geozone==i)
  pltwregion <- rbind(plotdat, vac_region)
  plot<- ggplot(data=pltwregion, aes(x=yr, y=rate, group=geozone, colour=geozone))+
    geom_line(size=1.5)+
    labs(title=paste("Vacancy Rate\n ", i,' and Region',sep=''),
         caption="Source: demographic_warehouse: fact.housing,dim.mgra, dim.income_group\nhousehold_income.datasource_id = 14",
         y="Vacancy Rate", 
         x="Year")+
    #colour="Vacancy")+
    expand_limits(y = c(1, 300000))+
    scale_y_continuous(labels = comma, limits=c(.00,.15))+ 
    theme_bw(base_size = 14)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
  output_table<-sortdat[,c("yr_id","geozone","units","rate")]
  vactitle = paste("Vacancy Rate ",i,sep='')
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  #tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
  #                    colhead = list(fg_params=list(cex = 1.0)),
  #                   rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
    results<-"plots\\Vacancy\\CPA\\"
  ggsave(output, file= paste(results,i,'vacancy', ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}

