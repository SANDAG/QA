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

CPA_pop<-aggregate(hh~yr_id+geozone, data=hh, sum)
hh$tot_pop<-CPA_pop[match(paste(hh$yr_id, hh$geozone),paste(CPA_pop$yr_id, CPA_pop$geozone)),3]
hh$tot_pop[hh$tot_pop==0] <- NA
hh$percent_income = hh$hh/hh$tot_pop * 100

hh$year<- "y"
hh$yr <- as.factor(paste(hh$year, hh$yr, sep = ""))

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
                                   

hh_jur = subset(hh,geotype=='jurisdiction')


hh_cpa = subset(hh,geotype=='cpa')


hh_region = subset(hh,geotype=='region')

hh_region$geozone = 'San Diego Region'


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

jur_list = unique(hh_jur[["geozone"]])
 

for(i in jur_list) {
  plotdat = subset(hh_jur, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name,color=name)) +
    geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    theme(legend.position = "bottom",
        legend.title=element_blank()) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}

results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in jur_list) {
  plotdat = subset(hh_jur, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=income_id2,color=income_id2)) +
    geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)

}

results<-"plots\\Household Income\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)



cpa_list = unique(hh_cpa[["cpaname"]])


for(i in cpa_list) {
  plotdat = subset(hh_cpa, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=name,color=name)) +
    geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}


for(i in cpa_list) {
  plotdat = subset(hh_cpa, hh_jur$geozone==i)
  pltwregion <- rbind(plotdat, hh_region)
  plot <- ggplot(data=pltwregion, aes(x=yr, y=percent_income,group=income_id2,color=income_id2)) +
    geom_line(size=1.25) +  facet_grid(. ~ geozone) + 
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) 
  ggsave(plot, file= paste(results, 'household_income', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)

}

