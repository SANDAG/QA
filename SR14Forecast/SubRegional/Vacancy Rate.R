
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


# unique(hh[["geozone"]])
# note city of san diego and san diego region are both named san diego
# this causes problems with the aggregation
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'

vacancy$long_name<-' '

vacancy$long_name[vacancy$short_name=="mf"]<- "Multi Family"
vacancy$long_name[vacancy$short_name=="mh"]<- "Mobile Home"
vacancy$long_name[vacancy$short_name=="sf"]<- "Single Family"
vacancy$long_name[vacancy$short_name=="sfmu"]<- "Single Family Multi Unit"



vacancy$long_name<- factor(vacancy$long_name, levels = c("Multi Family",
                                       "Mobile Home","Single Family", "Single Family Multi Unit"))


vacancy$year<- "y"
vacancy$yr <- as.factor(paste(vacancy$year, vacancy$yr, sep = ""))


hh_jur = subset(vacancy,geotype=='jurisdiction')


hh_cpa = subset(vacancy,geotype=='cpa')


hh_region = subset(vacancy,geotype=='region')
# write.csv(hh_region,'SanDiego_region.csv')

head(vacancy)



maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Vacancy\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

jur_list = unique(hh_jur[["geozone"]])

results<-"plots\\Vacancy\\Jur"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

# colours = c('#ffffcc','#ffeda0','#fed976','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#bd0026','#800026')
colours = c('#ffffcc','#ffeda0','#fd8d3c','#bd0026','#800026')
colours = c('#ffeda0','#fd8d3c','#bd0026','#800026','#561B07')

for(i in jur_list) {
  plotdat = subset(hh_jur, hh_jur$geozone==i)
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
    #scale_colour_manual(values=colours) +
    ylim(0, .3) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1,size=14)) +
    theme(axis.text.y = element_text(size=14)) +
    theme(axis.title.y = element_text(face="bold", size=20)) +
    theme(legend.text=element_text(size=12)) +
    theme(strip.text.x = element_text(size = 14)) 
  
  #preoutput1<-data.frame(plotdat$yr_id,plotdat$income_id2,plotdat$hh)
 # setnames(preoutput1, old=c("plotdat.yr_id","plotdat.income_id2","plotdat.hh"),
           #new=c("Year","income","hh"))
  #preoutput2<-data.frame(plotdat$yr_id,plotdat$income_id2,plotdat$percent_income)
  #setnames(preoutput2, old=c("plotdat.yr_id","plotdat.income_id2","plotdat.percent_income"),
           #new=c("Year","income","pct"))
  #hh_by_income = reshape(preoutput1, idvar = "Year", timevar = "income", direction = "wide")
  #percents = reshape(preoutput2, idvar = "Year", timevar = "income", direction = "wide")
  # round
 # percents[] <- lapply(percents, function(x) if(is.numeric(x)) round(x, 0) else x)
  #total_pop_sub = subset(plotdat,income_id2==1)
  #setnames(total_pop_sub, old=c("yr_id",'tot_pop'),new=c("Year",paste(i,"_hh",sep='')))
  #totals <- merge(total_pop_sub[,c("Year",paste(i,"_hh",sep=''))],hh_by_income, by="Year")
  #output_table<- merge(totals,percents, by="Year")
  
  #hhtitle = paste("HH ",i,sep='')
  #tt <- ttheme_default(base_size=10,colhead=list(fg_params = list(parse=TRUE)))
  #tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
                     #  colhead = list(fg_params=list(cex = 1.0)),
                      # rowhead = list(fg_params=list(cex = 1.0)))
  #tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  #lay <- rbind(c(1,1,1,1,1),
               #c(2,2,2,2,2))
  #output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  #ggsave(tbl, file= paste(results, i,'_table', ".png", sep=''),
         #width=10, height=6, dpi=100)#, scale=2)
  ggsave(plot, file= paste(results,i, 'vacancy', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
}

# region output table
preoutput1<-data.frame(hh_region$yr_id,hh_region$income_id2,hh_region$hh)
setnames(preoutput1, old=c("hh_region.yr_id","hh_region.income_id2","hh_region.hh"),
         new=c("Year","income","hh"))
preoutput2<-data.frame(hh_region$yr_id,hh_region$income_id2,hh_region$percent_income)
setnames(preoutput2, old=c("hh_region.yr_id","hh_region.income_id2","hh_region.percent_income"),
         new=c("Year","income","pct"))
hh = reshape(preoutput1, idvar = "Year", timevar = "income", direction = "wide")
percents = reshape(preoutput2, idvar = "Year", timevar = "income", direction = "wide")
# round
percents[] <- lapply(percents, function(x) if(is.numeric(x)) round(x, 0) else x)
total_pop_sub = subset(hh_region,income_id2==1)
setnames(total_pop_sub, old=c("yr_id",'tot_pop'),new=c("Year",paste("Region","_hh",sep='')))
totals <- merge(total_pop_sub[,c("Year",paste("Region","_hh",sep=''))],hh, by="Year")
output_table<- merge(totals,percents, by="Year")
tbl <- tableGrob(output_table, rows=NULL, theme=tt)
ggsave(tbl, file= paste(results, "ARegion",'_table', ".png", sep=''),
       width=10, height=6, dpi=100)#, scale=2)


results<-"plots\\Vacancy\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(hh_cpa[["geozone"]])

for(i in cpa_list) {
  plotdat = subset(hh_cpa, hh_cpa$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name2,color=name2)) +
    geom_line(size=2) + geom_point(size=3, aes(colour=name2)) +
    facet_grid(. ~ geozone) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste("Percent of Total Households by Income Category\n ", i,' and Region',sep=''), 
         y=paste("Percent"), x="",
         caption="Sources: demographic_warehouse: fact.household_income,dim.mgra, dim.income_group\nhousehold_income.datasource_id = 14") +
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    scale_colour_manual(values=colours) +
    ylim(0, 64) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1,size=14)) +
    theme(axis.text.y = element_text(size=14)) +
    theme(axis.title.y = element_text(face="bold", size=20)) +
    theme(legend.text=element_text(size=12)) +
    theme(strip.text.x = element_text(size = 14)) 
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
  
  
  preoutput1<-data.frame(plotdat$yr_id,plotdat$income_id2,plotdat$hh)
  setnames(preoutput1, old=c("plotdat.yr_id","plotdat.income_id2","plotdat.hh"),
           new=c("Year","income","hh"))
  preoutput2<-data.frame(plotdat$yr_id,plotdat$income_id2,plotdat$percent_income)
  setnames(preoutput2, old=c("plotdat.yr_id","plotdat.income_id2","plotdat.percent_income"),
           new=c("Year","income","pct"))
  hh_by_income = reshape(preoutput1, idvar = "Year", timevar = "income", direction = "wide")
  percents = reshape(preoutput2, idvar = "Year", timevar = "income", direction = "wide")
  # round
  percents[] <- lapply(percents, function(x) if(is.numeric(x)) round(x, 0) else x)
  total_pop_sub = subset(plotdat,income_id2==1)
  setnames(total_pop_sub, old=c("yr_id",'tot_pop'),new=c("Year",paste(i,"_hh",sep='')))
  totals <- merge(total_pop_sub[,c("Year",paste(i,"_hh",sep=''))],hh_by_income, by="Year")
  output_table<- merge(totals,percents, by="Year")
  
  hhtitle = paste("HH ",i,sep='')
  tt <- ttheme_default(base_size=10,colhead=list(fg_params = list(parse=TRUE)))
  tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
                       colhead = list(fg_params=list(cex = 1.0)),
                       rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  ggsave(tbl, file= paste(results, i,'_table', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
  ggsave(plot, file= paste(results,i, '_hh_income', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)




