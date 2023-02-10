#Traditional Vacancy Rate by type
#no comparison to SR13 because difference in coding - in SR13 there were 3 categories and in SR14 there are 4 - sf is broken into two (sfa and sfd)


##########################
#LH to fix

#need to fix the table for the graph to show by structure type
##########################



pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  }
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2","lubridate", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#bring data in from SQL
channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#Series 14
Vacancy_sql = getSQL("../Queries/Vacancy.sql")
vacancy<-sqlQuery(channel,Vacancy_sql)

head(vacancy, 15)

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

#vacancy<- aggregate(cbind(hh, units)~ yr_id + geotype + geozone, data=vacancy, sum)

#calculate the vacancy rate - formula does not exclude unoccupiable units
vacancy$available <-(vacancy$units-vacancy$hh)
vacancy$rate <-(vacancy$available/vacancy$units)*100
vacancy$rate <-round(vacancy$rate,digits=2)


vacancy$yr<- "y"
vacancy$year <- as.factor(paste(vacancy$yr, vacancy$yr_id, sep = ""))
vacancy$series <- 14

#create one file for cpa jur and reg
vacancy_jur = subset(vacancy,geotype=='jurisdiction')
vacancy_cpa = subset(vacancy,geotype=='cpa')
vacancy_region = subset(vacancy,geotype=='region')


#create list of city names and merge in for plot formatting
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

citynames <- data.frame(jur_list, jur_list2)
vacancy_jur$jurisdiction_id<-citynames[match(vacancy_jur$geozone, citynames$jur_list2),1]

#match region rate into jur data
vacancy_jur$reg14<-vacancy_region[match(paste(vacancy_jur$yr_id,vacancy_jur$structure_type_id),
                                        paste(vacancy_region$yr_id,vacancy_region$structure_type_id)),"rate"]


#rename jur rate to include year
setnames(vacancy_jur, old=c("rate"), new=c("rate14"))

#cpa 



#match region rate into cpa 14 data
vacancy_cpa$reg14<-vacancy_region[match(paste(vacancy_cpa$yr_id,vacancy_cpa$structure_type_id),
                                        paste(vacancy_region$yr_id,vacancy_region$structure_type_id)),"rate"]


#rename cpa rate to include year
setnames(vacancy_cpa, old=c("rate"), new=c("rate14"))


#creates a list for reference by the ggplot for loop
cpa_list = unique(vacancy_cpa[["geozone"]])



###############################
##Jurisdiction plots and tables
###############################


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Vacancy\\Jur by type (19)\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

head(vacancy_jur)
colours = c(#E69F00", "#56B4E9", "#009E73","#CC79A7")


for(i in jur_list[]) { 
  plotdat = subset(vacancy_jur, vacancy_jur$jurisdiction_id==jur_list[i])
  plot<- ggplot(plotdat, aes(x=yr_id, y=rate14, group=short_name, color=short_name))+
    scale_color_manual(values =colour)+
    scale_y_continuous(labels = comma, limits=c(0,10))+
    labs(title=paste(jur_list2[i],' SR14 Vacancy by Type\nand Region, 2016-2050',sep=""),
         y="Vacancy Rate", 
         x="Year")+
    theme_bw(base_size = 9)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.title = element_text(hjust = 0.5)) 
  ggsave(plot, file= paste(results, 'vacancy ', jur_list2[i], "14.png", sep=''))#, scale=2)
  #sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
  output_table<-data.frame(plotdat$yr_id,plotdat$rate14,plotdat$reg14)
  setnames(output_table, old=c("plotdat.yr_id", "plotdat.rate14","plotdat.reg14"),new=c("Year","Jur Vac 14","Reg Vac 14"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE))) 
  #tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
  #colhead = list(fg_params=list(cex = 1.0)),
  #rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay,
                       bottom = textGrob("Source: demographic_warehouse: fact.housing,dim.mgra, dim.structure_type \nhousehold.datasource_id = 19 & 13\nNote: Unoccupiable units are included. Out of range data may not appear on the\nplot. Refer to the table for out of range results.",
                                         x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 6.5))) 
  ggsave(output, file= paste(results,'vacancy ',jur_list2[i], " 13 to 14.png", sep=''))#, scale=2))
}

vacancy_jur

 #####################
#CPA plots and tables


results<-"plots\\Vacancy\\CPA_SERIES 13 vs 14\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(vacancy_cpa[["geozone"]])
cpa_list

head(vacancy_cpa)

#filter top 10 highest vacancy rates (SR14) and lowest 10 rates by CPA
cpa_list_top <- top_n(vacancy_cpa, 30, rate14)
cpa_list_top <- subset(cpa_list_top, !duplicated(geozone))
cpa_list_top <- select(cpa_list_top,geozone,rate14)
cpa_list_top <- distinct(cpa_list_top[c("geozone", "rate14")])
cpa_list_top

cpa_list_bottom <- top_n(vacancy_cpa, -45, rate14)
cpa_list_bottom <- subset(cpa_list_bottom, !duplicated(geozone))
cpa_list_bottom <- select(cpa_list_bottom,geozone,rate14)
cpa_list_bottom
#combine into data frame
topbottom <- data.frame(cpa_list_top, cpa_list_bottom)
#rename columns
names(topbottom) <- c("CPA", "Highest Vacancy Rates SR14", "CPA", "Lowest Vacancy Rates SR14")
topbottom
#write into csv 
write.csv(topbottom, file = "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 5\\Trends\\Vacancy\\vacancyrateshighlow.csv",row.names=FALSE, na="")



for(i in 1:length(cpa_list)) { 
  plotdat = subset(vacancy_cpa, vacancy_cpa$geozone==cpa_list[i])
  plot<- ggplot(plotdat, aes(x=yr_id, y=rate, colour="CPA"))+
    geom_line(aes(y=rate14, color="CPA14", linetype="CPA14"))+
    geom_line(aes(y=reg14, color="Reg14", linetype="Reg14")) +
    geom_line(aes(y=rate13, color="CPA13", linetype="CPA13")) +
    geom_line(aes(y=reg13, color="Reg13", linetype="Reg13")) +
    scale_color_manual("",values =c(CPA14="red", Reg14="blue", CPA13="red", Reg13="blue"))+
    scale_linetype_manual("",values=c(CPA14="solid",Reg14="solid",CPA13="longdash",Reg13="longdash"))+
    scale_y_continuous(labels = comma, limits=c(0, 12))+  #dynamic y scale 
    labs(title=paste(cpa_list[i],' SR14 to 13 Vacancy Rate\nand Region, 2016-2050',sep=""),
              y="Vacancy Rate", 
              x="Year")+
    theme_bw(base_size = 9)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.title = element_text(hjust = 0.5, size = 9))#Katie: title font size and alignment
  ggsave(plot, file= paste(results, 'vacancy', cpa_list[i], "19.png", sep=''))#, scale=2)
  #sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
  output_table<-data.frame(plotdat$yr_id,plotdat$rate14,plotdat$rate13,plotdat$reg14,plotdat$reg13)
  setnames(output_table, old=c("plotdat.yr_id", "plotdat.rate14","plotdat.rate13","plotdat.reg14","plotdat.reg13"),new=c("Year","CPA Vac 14","CPA Vac 13","Reg Vac 14", "Reg Vac 13"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  #tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
  #                    colhead = list(fg_params=list(cex = 1.0)),
  #                   rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay,
              bottom = textGrob("Source: demographic_warehouse: fact.housing,dim.mgra, dim.structure_type \nhousehold.datasource_id = 19 & 13\nNote: Unoccupiable units are included. Out of range data may not appear on\nthe plot. Refer to the table for out of range results.",
                                         x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 7)))
  ggsave(output, file= paste(results,'vacancy',cpa_list[i], "19.png", sep=''))#, scale=2))
}







