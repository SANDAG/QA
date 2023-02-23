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
hh_sql = getSQL("../Queries/Household Income (HHINC).sql")
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

write.csv(hh, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\household_income\\hhincome_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

# unique(hh[["geozone"]])
# note city of san diego and san diego region are both named san diego
# this causes problems with the aggregation
# rename San Diego region to 'San Diego Region' and then aggregate
levels(hh$geozone) <- c(levels(hh$geozone), "San Diego Region")
hh$geozone[hh$geotype=='region'] <- 'San Diego Region'
sd = subset(hh,geozone=='San Diego')
sd2 = subset(hh,geozone=='San Diego Region')
#write.csv(sd,'cityofsandiego.csv')
#write.csv(sd2,'regionofsandiego.csv')

Geo_totals<-aggregate(hh~yr_id+geozone, data=hh, sum)
hh$tot_pop<-Geo_totals[match(paste(hh$yr_id, hh$geozone),paste(Geo_totals$yr_id, Geo_totals$geozone)),3]
hh$tot_pop[hh$tot_pop==0] <- NA
hh$percent_income = hh$hh/hh$tot_pop * 100
#write.csv(Geo_totals,'geototals.csv')

# specify order of levels for plotting
hh$name <- factor(hh$name, levels = c("Less than $15,000", 
                    "$15,000 to $29,999", 
                    "$30,000 to $44,999",
                    "$45,000 to $59,999",
                    "$60,000 to $74,999",
                    "$75,000 to $99,999",
                    "$100,000 to $124,999",
                    "$125,000 to $149,999",
                    "$150,000 to $199,999",
                    "$200,000 or more"))

hh$income_id2 <-ifelse(hh$income_group_id>=11 &hh$income_group_id<=12, '1',
                ifelse(hh$income_group_id>=13 &hh$income_group_id<=14, '2',
                ifelse(hh$income_group_id>=15 &hh$income_group_id<=16, '3',
                ifelse(hh$income_group_id>=17 &hh$income_group_id<=18, '4',
                ifelse(hh$income_group_id>=19 &hh$income_group_id<=20, '5', NA)))))


hh$name2[hh$income_id2=="1"]<- "Less than $30,000"
hh$name2[hh$income_id2=="2"]<- "$30,000 to $59,999"
hh$name2[hh$income_id2=="3"]<- "$60,000 to $99,999"
hh$name2[hh$income_id2=="4"]<- "$100,000 to $149,999"
hh$name2[hh$income_id2=="5"]<- "$150,000 or more"

hh$name2<- as.factor(hh$name2)

hh$name2<- factor(hh$name2, levels = c("Less than $30,000",
"$30,000 to $59,999","$60,000 to $99,999", "$100,000 to $149,999", "$150,000 or more"))

                                   
Cat_agg<-aggregate(hh~yr_id+geozone+name2+geotype+income_id2, data=hh, sum)
Cat_agg$tot_pop<-Geo_totals[match(paste(Cat_agg$yr_id, Cat_agg$geozone),paste(Geo_totals$yr_id, Geo_totals$geozone)),3]
Cat_agg$tot_pop[Cat_agg$tot_pop==0] <- NA
Cat_agg$percent_income = Cat_agg$hh/Cat_agg$tot_pop * 100

Cat_agg$year<- "y"
Cat_agg$yr <- as.factor(paste(Cat_agg$year, Cat_agg$yr, sep = ""))


hh_jur = subset(Cat_agg,geotype=='jurisdiction')


hh_cpa = subset(Cat_agg,geotype=='cpa')


hh_region = subset(Cat_agg,geotype=='region')
# write.csv(hh_region,'SanDiego_region.csv')


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Household Income\\JUR"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

jur_list = unique(hh_jur[["geozone"]])
 
results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

# colours = c('#ffffcc','#ffeda0','#fed976','#feb24c','#fd8d3c','#fc4e2a','#e31a1c','#bd0026','#800026')
colours = c('#ffffcc','#ffeda0','#fd8d3c','#bd0026','#800026')
colours = c('#ffeda0','#fd8d3c','#bd0026','#800026','#561B07')

for(i in jur_list) {
  plotdat = subset(hh_jur, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name2,color=name2)) +
    geom_line(size=2) + geom_point(size=3, aes(colour=name2))  +
    facet_grid(. ~ geozone) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste("Percent of Total Households by Income Category\n ", i,' and Region',sep=''), 
         y=paste("Percent"), x="",
         caption="Sources: demographic_warehouse: fact.household_income,dim.mgra, dim.income_group\nhousehold_income.datasource_id = 19") +
    theme(legend.position = "bottom",
        legend.title=element_blank()) +
    scale_colour_manual(values=colours) +
    ylim(0, 41) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1,size=14)) +
    theme(axis.text.y = element_text(size=14)) +
    theme(axis.title.y = element_text(face="bold", size=20)) +
    theme(legend.text=element_text(size=12)) +
    theme(strip.text.x = element_text(size = 14)) 
  
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
    ggsave(tbl, file= paste(results, i,'_table', "19.png", sep=''),
           width=10, height=6, dpi=100)#, scale=2)
    ggsave(plot, file= paste(results,i, '_hh_income', "19.png", sep=''),
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
ggsave(tbl, file= paste(results, "ARegion",'_table', "19.png", sep=''),
       width=10, height=6, dpi=100)#, scale=2)


results<-"plots\\Household Income\\CPA\\"
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
         caption="Sources: demographic_warehouse: fact.household_income,dim.mgra, dim.income_group\nhousehold_income.datasource_id = 19") +
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
  ggsave(plot, file= paste(results, 'household_income', i, "19.png", sep=''),
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
ggsave(tbl, file= paste(results, i,'_table', "19.png", sep=''),
       width=10, height=6, dpi=100)#, scale=2)
ggsave(plot, file= paste(results,i, '_hh_income', ".png", sep=''),
       width=10, height=6, dpi=100)#, scale=2)
}
# test git commit


