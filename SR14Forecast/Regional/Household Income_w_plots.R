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

                                   
Cat_agg<-aggregate(hh~yr_id+geozone+name2+geotype, data=hh, sum)
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
results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

jur_list = unique(hh_jur[["geozone"]])
 
results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)



for(i in jur_list) {
  plotdat = subset(hh_jur, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name2,color=name2)) +
    geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    theme(legend.position = "bottom",
        legend.title=element_blank()) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  # output_table<-data.frame(plotdat$yr_id,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$regN_chg,plotdat$regN_pct)
  # output_table$plotdat.N_chg[output_table$plotdat.yr_id == 'y2016'] <- ''
  # output_table$plotdat.regN_chg[output_table$plotdat.yr_id == 'y2016'] <- ''
  # hhtitle = paste("HH ",i,sep='')
  # setnames(output_table, old=c("plotdat.yr_id","plotdat.N","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.regN_chg",
  #                              "plotdat.regN_pct"),new=c("Year",hhtitle,"Chg", "Pct","HH Region","Chg","Pct"))
  # tt <- ttheme_default(base_size=7,colhead=list(fg_params = list(parse=TRUE)))
  # tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  # lay <- rbind(c(1,1,1,1,1),
  #              c(2,2,2,2,2))
  # output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  # ggsave(output, file= paste(results, 'households', i, ".png", sep=''),
  #        width=6, height=8, dpi=100)#, scale=2)
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=8, height=6, dpi=100)#, scale=2)
}


results<-"plots\\Household Income\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)



cpa_list = unique(hh_cpa[["geozone"]])


#for(i in cpa_list) {
  #plotdat = subset(hh_cpa, hh_cpa$geozone==i)
  ##pltwregion <- rbind(plotdat, hh_region)
  #plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name,color=name)) +
   # geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    #theme(legend.position = "bottom",
          #legend.title=element_blank()) +
   # theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  #i = gsub("\\*","",i)
 # i = gsub("\\-","_",i)
  #ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         #width=6, height=8, dpi=100)#, scale=2)
#}

for(i in cpa_list) {
  plotdat = subset(hh_cpa, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=income_id2,color=income_id2)) +
    geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)

}results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


