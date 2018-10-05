#median age and vacancy csv files must be updated before this script is run.
#run tradition vacancy aggregated and median age script in Git hub.

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
hh_sql = getSQL("../Queries/hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

#x==17

#save a time stamped verion of the raw file from SQL
write.csv(hh, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\hh_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


#sort file
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]

#calculate number and percent changes
hh$hh_numchg<- (hh$households)-lag(hh$households)
hh$hhp_numchg<- (hh$hhp)-lag(hh$hhp)
hh$hhs_numchg<- (hh$hhs)-lag(hh$hhs)
hh$hh_pctchg<- (hh$households-lag(hh$households))/lag(hh$households)*100
hh$hhp_pctchg<- (hh$hhp-lag(hh$hhp))/lag(hh$hhp)*100
hh$hhs_pctchg<- (hh$hhs-lag(hh$hhs))/lag(hh$hhs)*100
#round pct changes
hh$hh_pctchg<-round(hh$hh_pctchg,digits=2)
hh$hhp_pctchg<-round(hh$hhp_pctchg,digits=2)
hh$hhs_pctchg<-round(hh$hhs_pctchg,digits=2)

#rename region value for match
hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

write.csv(hh,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\hh_hhp_hhs with change.csv"))

#read in vacancy and median age file
vac<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\Traditional vacancy_17.csv")
median_age_cpa<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_cpa17.csv")
median_age_jur<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_jur17.csv")
median_age<-rbind(median_age_cpa, median_age_jur)

tail(vac)
vac<- vac[order(vac$geotype,vac$geozone,vac$yr_id),]

vac$vac_numchg<- (vac$rate)-lag(vac$rate)

vac$vac_pctchg<- (vac$rate-lag(vac$rate))/lag(vac$rate)*100
vac$vac_pctchg<-round(vac$vac_pctchg,digits=2)

vac$units_numchg<- (vac$units)-lag(vac$units)

vac$units_pctchg<- (vac$units-lag(vac$units)/lag(vac$units))*100
vac$units_pctchg<-round(vac$units_pctchg,digits=2)

setnames(vac, old=c("rate"),new=c("vac_rate"))

#rename region value for match
vac$geozone[vac$geotype =="region"]<- "Region"
#strip misc. characters from cpa names for match
vac$geozone <- gsub("\\*","",vac$geozone)
vac$geozone <- gsub("\\-","_",vac$geozone)
vac$geozone <- gsub("\\:","_",vac$geozone)


#hh$flag_num<-ifelse(hh$hh_numchg<=0|
 #                hh$hhp_numchg<=0)
#hh$flag_pct<-ifelse(hh$hh_pctchg<=0|
 #                  hh$hhp_pctchg<=0)

#merge hh with vacancy
hh_merge<-merge(hh, vac, by.x=c("yr_id", "geotype", "geozone"), by.y=c("yr_id", "geotype", "geozone"),all=TRUE)
#merge hh_merge with median age
hh_merge<-merge(hh_merge, median_age, by.x=c("yr_id", "geotype", "geozone"), by.y=c("yr_id", "geotype", "geozone"),all=TRUE)

#delete unneeded columns
hh_merge[c("X.x", "hh", "available", "year", "yr", "X.y")]<-list(NULL)
#reorder columns
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","unoccupiable","vac_rate","hh_numchg","hhp_numchg","hhs_numchg","hh_pctchg","hhp_pctchg","hhs_pctchg","units_numchg","units_pctchg","vac_numchg","vac_pctchg","median_age")]

#sort file
hh_merge<- hh_merge[order(hh_merge$geotype,hh_merge$geozone,hh_merge$yr_id),]
#set 2016 numbers incorrectly calculated by lag to NA
hh_merge$hh_numchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$hhp_numchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$hhs_numchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$vac_numchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$units_numchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$hh_pctchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$hhp_pctchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$hhs_pctchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$vac_pctchg[hh_merge$yr_id=="2016"]<-NA
hh_merge$units_pctchg[hh_merge$yr_id=="2016"]<-NA

#save out csv
write.csv(hh_merge,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 4\\hh_hhp_hhs_hu_vac_age_comparison.csv"))

rm(median_age, median_age_jur, median_age_cpa, vac)

head(hh_merge)

#delete unneeded columns
hh_merge["unoccupiable"]<-list(NULL)
#reorder columns
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","vac_rate","median_age","hh_numchg","hhp_numchg","hhs_numchg","units_numchg","vac_numchg","hh_pctchg","hhp_pctchg","hhs_pctchg","units_numchg","units_pctchg","vac_pctchg")]

hh_merge<- hh_merge %>% gather(hh_var, value, households:median_age)
hh_merge<- hh_merge %>% gather(hh_pctchg, pct_chg, hh_pctchg:vac_pctchg)
hh_merge<- hh_merge %>% gather(hh_numchg, num_chg, hh_numchg:vac_numchg)

hh_merge$pct_chg=as.numeric(hh_merge$pct_chg)

hh_merge_jur<-subset(hh_merge, geotype=="jurisdiction")
hh_merge_cpa<-subset(hh_merge, geotype=="cpa")

head(hh_merge_jur)

class(hh_merge_jur$pctchg)

jur_list = unique(hh_merge_jur[["geozone"]])
maindir = dirname(rstudioapi::getSourceEditorContext()$path)

results<-"plots\\hh_variable_comparison\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in jur_list) {
  plotdat = subset(hh_merge_jur,hh_merge_jur$geozone==i)
  #plotd <- plotdat %>% gather(hh_var, value, households:median_age)
  plot <- ggplot(plotdat, aes(x=yr_id, y=pct_chg,group=hh_var, label=rownames(plotdat$value)) + geom_point(aes(color=hh_var))) +
    facet_grid(hh_var ~ .,scales="free_y") + geom_line(aes(color=hh_var),size=1) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste(i,": Household variable comparison\n (datasource_id=17)",sep=''))
  #plot
  ggsave(plot, file= paste(results,i, '_hh_var_17', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
}



gg + geom_text(aes(label=large_county), size=2, data=midwest_sub) + labs(subtitle="With ggplot2::geom_text") + theme(legend.position = "None")   # text

gg + geom_label(aes(label=large_county), size=2, data=midwest_sub, alpha=0.25) + labs(subtitle="With ggplot2::geom_label") + theme(legend.position = "None")  # label


for(i in jur_list) {
  plotdat = subset(Income_Jur,Income_Jur$jurisdiction==i)
  plotd <- plotdat %>% gather(datasource, POP, POP_17:POP_14)
  plot <- ggplot(plotd, aes(x=yr, y=POP,group=datasource)) + geom_point(aes(color=datasource)) +
    facet_grid(hinccat1 ~ unittype,scales="free_y") + geom_line(aes(color=datasource),size=1) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste(i,": Pop by 5 Income Categories\n (unit type 0 and 1)",sep=''))
  #plot
  ggsave(plot, file= paste(results,i, '_datasource_14_17_income', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
}
