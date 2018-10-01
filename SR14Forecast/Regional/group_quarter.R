
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

options(stringsAsFactors=FALSE)

#bring data in from SQL
channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
gq_sql = getSQL("../Queries/group_quarter.sql")
gq<-sqlQuery(channel,gq_sql)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(gq, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\gq_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

head(gq)


gq<-subset(gq, short_name!="hh")

#gq<-dcast(gq_long, yr_id+geotype+geozone~short_name, value.var = "pop")

head(gq)

gq$yr<- "y"
gq$yr <- as.factor(paste(gq$yr, gq$yr_id, sep = ""))
gq$geozone[gq$geotype=="region"]<- "San Diego Region"

class(gq$geozone)


gq_jur = subset(gq,geotype=='jurisdiction')
gq_cpa = subset(gq,geotype=='cpa')
gq_region = subset(gq,geotype=='region')


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\group quarter\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


tail(gq_region)

##Jurisdiction plots and tables

jur_list=unique(gq_jur[["geozone"]])

#create a copy of the data frame for the output table
gq_wide<-data.frame(gq_jur)
gq_wide$reg<-gq_region[match(paste(gq_jur$yr_id, gq_jur$housing_type_id), paste(gq_region$yr_id, gq_region$housing_type_id)),6]

write.csv(gq_jur, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\GQ\\gq_jur17.csv")
write.csv(gq_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\GQ\\gq_cpa17.csv")
write.csv(gq_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\GQ\\gq_region17.csv")


################
#plots below don't work
################


for(i in jur_list) { 
  plotdat = subset(gq_jur, gq_jur$jurisdiction_id==i)
  pltwregion<- rbind(plotdat, gq_region)
  plot<- ggplot(pltwregion, aes(x=yr, y=pop, group=geozone, fill=housing_type_id))+
    geom_bar(stat = "identity", position="stack")+
    facet_grid(. ~ geozone)+
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste("Group Quarter Pop ", i,'\nand Region, 2016-2050',sep=""),
         caption="Source: demographic_warehouse: fact.population,dim.mgra, dim.housing_type\npopulation.datasource_id = 17",
         y=paste("GQ pop"), x="Year")+
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))+
    scale_colour_manual(values=colours) +
    #ylim(0, ) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1,size=14)) +
    theme(axis.text.y = element_text(size=14)) +
    theme(axis.title.y = element_text(face="bold", size=14)) +
    theme(legend.text=element_text(size=12)) +
    theme(strip.text.x = element_text(size = 14)) 
  ggsave(plot, filename= paste(results, 'gq pop ', i, ".png", sep=''))#, scale=2)
  #sortdat <- pltwregion[order(pltwregion$geozone,pltwregion$yr_id,pltwregion$housing_type_id),]
  #gq_wide<-dcast(pltwregion, yr_id+geotype+geozone~short_name, value.var = "pop")
  output_table<-data.frame(gq_wide$yr_id,gq_wide$short_name,gq_wide$pop, gq_wide$reg)
  #setnames(output_table, old=c("yr_id", "short_name", "pop", "reg"), new=c("Year", "Group Quarter Type", "Jur Pop", "Region Pop"))
  #rename(output_table, yr_id=Year, short_name=GQ.type)
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
                      colhead = list(fg_params=list(cex = 1.0)),
                     rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results,"gq pop ", i, ".png", sep=''))#, scale=2))
}


head(gq_wide)

for(i in jur_list) { 
  plotdat = subset(gq_jur, gq_jur$jurisdiction_id==i)
  plot<- ggplot(plotdat, aes(x=yr, y=pop, fill=housing_type_id))+
    geom_bar(stat = "identity", position="stack")+
    scale_y_continuous(labels = comma, limits=c(0,100000))+  
    labs(title=paste("Group Quarter Pop ", i,'\nand Region, 2016-2050',sep=""),
         caption="Source: demographic_warehouse: fact.population,dim.mgra, dim.housing_type\npopulation.datasource_id = 17",
         y="GQ pop", x="Year")+
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))+
    scale_colour_manual(values=colours) +
    ggsave(plot, file= paste(results, 'gq pop ', i, ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$short_name,plotdat$pop, plotdat$reg)
  #setnames(output_table, old=c("yr_id", "short_name", "pop", "reg"), new=c("Year", "Group Quarter Type", "Jur Pop", "Region Pop"))
  #rename(output_table, yr_id=Year, short_name=GQ.type)
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results,"gq pop ", i, ".png", sep=''))#, scale=2))
}


                                  