#Traditional Vacancy Rate


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
#channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#Vacancy_sql = getSQL("../Queries/Vacancy.sql")
#vacancy<-sqlQuery(channel,Vacancy_sql)
#Series 13
#channel2 <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
#Vacancy13_sql = getSQL("../Queries/Vacancy 13.sql")
#vacancy13<-sqlQuery(channel2,Vacancy13_sql)

#odbcClose(channel)
#SERIES 13
#odbcClose(channel2)

#save a time stamped verion of the raw file from SQL
#write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\vacancy_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

####STARTED HERE WITH READ IN FILE BECAUSE CANT GET CHANNEL TO WORK 9_12_18.dco

vacancy<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\Vacancy.csv",stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

vacancy13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\Vacancy13.csv",stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)

#calculate the vacancy rate - formula does not exclude unoccupiable units
vacancy$available <-(vacancy$units-vacancy$hh)
vacancy$rate <-(vacancy$available/vacancy$units)*100
vacancy$rate <-round(vacancy$rate,digits=2)


#This aggregates from type of units

vacancy<- aggregate(cbind(hh, units)~ yr_id + geotype + geozone + rate, data=vacancy, sum)



#head(vacancy)
#vacancy$long_name<-' '

#vacancy$long_name[vacancy$short_name=="mf"]<- "Multi Family"
#vacancy$long_name[vacancy$short_name=="mh"]<- "Mobile Home"
#vacancy$long_name[vacancy$short_name=="sfd"]<- "Single Family"
#vacancy$long_name[vacancy$short_name=="sfa"]<- "Single Family Multi Unit"

#vacancy$long_name<- factor(vacancy$long_name, levels = c("Multi Family",
                                                         #"Mobile Home","Single Family", "Single Family Multi Unit"))

#SERIES 13
#write.csv(vacancy13, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\vacancy13_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy13$geozone) <- c(levels(vacancy13$geozone), "San Diego Region")
vacancy13$geozone[vacancy$geotype=='region'] <- 'San Diego Region'
vacancy13$geozone <- gsub("\\*","",vacancy13$geozone)
vacancy13$geozone <- gsub("\\-","_",vacancy13$geozone)
vacancy13$geozone <- gsub("\\:","_",vacancy13$geozone)


#calculate the vacancy rate - formula does not exclude unoccupiable units
vacancy13$available <-(vacancy13$units-vacancy13$hh)
vacancy13$rate <-(vacancy13$available/vacancy13$units)*100
vacancy13$rate <-round(vacancy13$rate,digits=2)

vacancy13<- aggregate(cbind(hh, units)~ yr_id +geotype + geozone + rate, data=vacancy13, sum)

#head(vacancy13)
#vacancy13$long_name<-' '

#vacancy13$long_name[vacancy13$short_name=="mf"]<- "Multi Family"
#vacancy13$long_name[vacancy13$short_name=="mh"]<- "Mobile Home"
#vacancy13$long_name[vacancy13$short_name=="sfd"]<- "Single Family"
#vacancy13$long_name[vacancy13$short_name=="sfa"]<- "Single Family Multi Unit"

#vacancy13$long_name<- factor(vacancy13$long_name, levels = c("Multi Family",
                                                         #"Mobile Home","Single Family", "Single Family Multi Unit"))

vacancy$yr<- "y"
vacancy$year <- as.factor(paste(vacancy$year, vacancy$yr, sep = ""))
vacancy$series <- 14

vacancy13$yr<- "y"
vacancy13$year <- as.factor(paste(vacancy13$year, vacancy13$yr, sep = ""))
vacancy13$series <- 13

vacancy13_14<- rbind(vacancy13, vacancy)


vacancy13jur = subset(vacancy13,geotype=='jurisdiction')
vacancy13_cpa = subset(vacancy13,geotype=='cpa')
vacancy13_region = subset(vacancy13,geotype=='region')
vacancy_jur = subset(vacancy,geotype=='jurisdiction')
vacancy_cpa = subset(vacancy,geotype=='cpa')
vacancy_region = subset(vacancy,geotype=='region')




maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Vacancy\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


tail(vacancy_region)
tail(vacancy13_region)

##Jurisdiction plots and tables


jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

citynames <- data.frame(jur_list, jur_list2)
vacancy_jur$jurisdiction_id<-citynames[match(vacancy_jur$geozone, citynames$jur_list2),1]

vacancy_jur$reg<-vacancy_region[match(vacancy_jur$yr_id, vacancy_region$yr_id),"rate"]

vacancy13jur$reg13<-vacancy13_region[match(vacancy13jur$yr_id, vacancy13_region$yr_id),"rate"]
setnames(vacancy13jur, old=c("rate"),new=c("rate13"))
vacancy14_13_jur<- merge(vacancy13jur, vacancy_jur, by.a=c("yr_id","geozone"), by.b=c("yr_id","geozone"), all=TRUE)
vacancy_jur$vac13<-vacancy13jur[match(vacancy_jur$yr_id, vacancy13jur$yr_id),"rate"]

vac_jur$jurisdiction_id<-citynames[match(vac_jur$geozone, citynames$jur_list2),"jur_list"]
vac_jur$reg<-vac_region[match(vac_jur$yr_id, vac_region$yr_id),"rate"]



Vacancy_Jur_reshape <- reshape(select(vacancy_jur, yr_id, geotype, geozone, long_name, rate, reg), idvar = c("yr_id", "geozone", "geotype", "reg"), timevar = "long_name", direction = "wide")




for(i in jur_list) { 
plotdat = subset(vacancy_jur, vacancy_jur$jurisdiction_id==jur_list[i])
plot<- ggplot(plotdat, aes(x=yr_id, y=rate, colour="Jurisdiction"))+
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
sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
output_table<-data.frame(plotdat$yr_id, plotdat$long_name, plotdat$rate,plotdat$reg)
setnames(output_table, old=c("plotdat.yr_id","plotdat.long_name", "plotdat.rate","plotdat.reg"),new=c("Year","Unit Type", "Jur Vac Rate","Reg Vac Rate"))
tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
#tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
                   #colhead = list(fg_params=list(cex = 1.0)),
                    #rowhead = list(fg_params=list(cex = 1.0)))
tbl <- tableGrob(output_table, rows=NULL, theme=tt)
#lay <- rbind(c(1,1,1,1,1),
             #c(1,1,1,1,1),
             #c(2,2,2,2,2),
             #c(2,2,2,2,2))
output<-grid.arrange(plot,tbl,as.table=TRUE)#layout_matrix=lay)
ggsave(output, file= paste(results,'vacancy',jur_list2[i], "16.png", sep=''))#, scale=2))
}

head(plotdat)

#####################
#CPA plots and tables


results<-"plots\\Vacancy\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(vacancy_cpa[["geozone"]])

#vacancy_jur$jurisdiction_id<-citynames[match(vacancy_jur$geozone, citynames$jur_list2),1]
vacancy_cpa$reg<-vacancy_region[match(vacancy_cpa$yr_id, vacancy_region$yr_id),8]


head(vacancy_cpa)

for(i in 1:length(cpa_list)) { 
  plotdat = subset(vacancy_cpa, vacancy_cpa$geozone==cpa_list[i])
  plot<- ggplot(plotdat, aes(x=yr_id, y=rate, colour="CPA"))+
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




