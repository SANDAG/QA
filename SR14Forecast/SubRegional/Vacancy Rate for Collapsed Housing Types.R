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

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
vacancy = getSQL("../Queries/vacancy.sql")
vacancy<-sqlQuery(channel,vacancy)
odbcClose(channel)


# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'

# Collapse housing types to make plots 

##What Daniel soes in SQ: to show Anne
#SUM(housing.occupied) as hh
#,SUM(housing.units) as units
#,ROUND(CASE WHEN SUM(housing.occupied) = 0 THEN 0 ELSE 1.0 - SUM(housing.occupied) / CAST(SUM(housing.units) as float) END, 2) as vac


Vacancy_ALL <-aggregate(cbind(units, hh) ~yr_id + geozone + geotype, data= vacancy, sum,na.rm = TRUE)
Vacancy_ALL$Diff<- Vacancy_ALL$units - Vacancy_ALL$hh
Vacancy_ALL$VAC_RATE <- Vacancy_ALL$Diff/Vacancy_ALL$units
Vacancy_ALL$VAC_RATE<-round(Vacancy_ALL$VAC_RAT,digits=2)

Vacancy_ALL$year<- "y"
Vacancy_ALL$yr <- as.factor(paste(Vacancy_ALL$year, Vacancy_ALL$yr, sep = ""))


hh_jur = subset(Vacancy_ALL,geotype=='jurisdiction')


hh_cpa = subset(Vacancy_ALL,geotype=='cpa')


hh_region = subset(Vacancy_ALL,geotype=='region')
# write.csv(hh_region,'SanDiego_region.csv')

head(Vacancy_ALL)


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Vacancy_all\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

jur_list = unique(hh_jur[["geozone"]])




for(i in jur_list) { 
  plotdat = subset(hh_jur, hh_jur$geozone==i)
  #ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$VAC_RATE,na.rm=TRUE)
  #ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=VAC_RATE,fill=geozone)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = VAC_RATE, group=1,colour = "geozone"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    labs(title=paste("Vacancy Rate\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=14")+
    scale_fill_manual(values = c("blue", "red")) +
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank())
  # ggsave(plot, file= paste(results, 'Total Household Pop',  i, ".png", sep=''))#, scale=2)
  #output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct)
  #output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2016'] <- ''
  #output_table$plotdat.reg[output_table$plotdat.yr == 'y2016'] <- ''
  #hhtitle = paste("Vacancy ",i,sep='')
  #setnames(output_table, old=c("plotdat.yr_id","plotdat.hhp","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.reg",
                              # "plotdat.regN_pct"),new=c("Year",hhtitle,"Chg", "Pct","HH Pop Region","Chg","Pct"))
  #tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  #tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  #lay <- rbind(c(1,1,1,1,1),
               #c(1,1,1,1,1),
              # c(1,1,1,1,1),
               #c(2,2,2,2,2),
               #c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=2,as.table=TRUE,layout_matrix=lay)
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(output, file= paste(results, 'Vacancy Rate', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}




 results<-"plots\\Vacancy_ALL\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(hh_cpa[["geozone"]])


for(i in cpa_list) {
  plotdat = subset(hh_cpa, hh_cpa$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=vac,group=long_name,color=long_name)) +
    geom_line(size=2) + geom_point(size=3, aes(colour=long_name))  +
    facet_grid(. ~ geozone) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste("Vacancy Rate by Unit Type\n ", i,' and Region',sep=''), 
         y=paste("Vacancy Rate"), x="",
         caption="Sources: demographic_warehouse: fact.housing,dim.mgra, dim.structure_type\n housing.datasource_id = 14") +
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    # ylimh = .12
    #ylim(0, .30) +
    #annotate("text", label="y-axis .3",x = 'y2018', y = .30, label = "Some text",color="red") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1,size=14)) +
    theme(axis.text.y = element_text(size=14)) +
    theme(axis.title.y = element_text(face="bold", size=20)) +
    theme(legend.text=element_text(size=12)) +
    theme(strip.text.x = element_text(size = 14)) 
  sortdat <- plotdat[order(plotdat$long_name,plotdat$yr_id),]
  
  output_table<-sortdat[,c("yr_id","geozone","long_name","units","vac")]
  hhtitle = paste("HH ",i,sep='')
  tt <- ttheme_default(base_size=12,colhead=list(fg_params = list(parse=TRUE)))
  tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
                       colhead = list(fg_params=list(cex = 1.0)),
                       rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  results<-"plots\\Vacancy\\CPA\\"
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(tbl, file= paste(results, i,'_table', ".png", sep=''),
         width=10, height=12, dpi=100)#, scale=2)
  ggsave(plot, file= paste(results,i, 'vacancy', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
}