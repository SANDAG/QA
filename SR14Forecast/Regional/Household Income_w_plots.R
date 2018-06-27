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

Geo_totals<-aggregate(hh~yr_id+geozone, data=hh, sum)
hh$tot_pop<-Geo_totals[match(paste(hh$yr_id, hh$geozone),paste(Geo_totals$yr_id, Geo_totals$geozone)),3]
hh$tot_pop[hh$tot_pop==0] <- NA
hh$percent_income = hh$hh/hh$tot_pop * 100


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


hh$name2[hh$income_id2=="1"]<- "$Less than $30,000"
hh$name2[hh$income_id2=="2"]<- "$30,000 to $59,999"
hh$name2[hh$income_id2=="3"]<- "$60,000 to $99,999"
hh$name2[hh$income_id2=="4"]<- "$100,000 to $149,999"
hh$name2[hh$income_id2=="5"]<- "$150,000 or more"

hh$name2<- as.factor(hh$name2)

hh$name2<- factor(hh$name2, levels = c("$Less than $30,000",
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

hh_region$geozone = 'San Diego Region'


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
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



#for(i in jur_list) {
  #plotdat = subset(hh_jur, hh_jur$geozone==i)
  #pltwregion <- rbind(plotdat, hh_region)
  #plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name,color=name)) +
    #geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    #theme(legend.position = "bottom",
          #legend.title=element_blank()) +
    #theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  #ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         #width=6, height=8, dpi=100)#, scale=2)


results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

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


