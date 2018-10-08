#median age and vacancy csv files must be updated before this script is run.
#run tradition vacancy aggregated and median age script in Git hub.

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","ggpubr")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(hh, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\hh_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

#sort file
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]

#calculate number and percent changes
hh$hh_numchg<- ave(hh$households, factor(hh$geozone), FUN=function(x) c(NA,diff(x)))
hh$hhp_numchg<- ave(hh$hhp, factor(hh$geozone), FUN=function(x) c(NA,diff(x)))
hh$hhs_numchg<- ave(hh$hhs, factor(hh$geozone), FUN=function(x) c(NA,diff(x)))
hh$hh_pctchg<- ave(hh$households, factor(hh$geozone), FUN=function(x) c(NA,diff(x)/x*100))
hh$hhp_pctchg<- ave(hh$hhp, factor(hh$geozone), FUN=function(x) c(NA,diff(x)/x*100))
hh$hhs_pctchg<- ave(hh$hhs, factor(hh$geozone), FUN=function(x) c(NA,diff(x)/x*100))
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
vac<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\Traditional vacancy_17.csv",stringsAsFactors = FALSE)
median_age_cpa<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_cpa17.csv",stringsAsFactors = FALSE)
median_age_jur<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_jur17.csv",stringsAsFactors = FALSE)
median_age<-rbind(median_age_cpa, median_age_jur)

tail(vac)
vac<- vac[order(vac$geotype,vac$geozone,vac$yr_id),]

#calculate number and percent changes
vac$vac_numchg<- ave(vac$rate, factor(vac$geozone), FUN=function(x) c(NA,diff(x)))
vac$vac_pctchg<- ave(vac$rate, factor(vac$geozone), FUN=function(x) c(NA,diff(x)/x*100))
vac$vac_pctchg<-round(vac$vac_pctchg,digits=2)

vac$units_numchg<- ave(vac$units, factor(vac$geozone), FUN=function(x) c(NA,diff(x)))
vac$units_pctchg<- ave(vac$units, factor(vac$geozone), FUN=function(x) c(NA,diff(x)/x*100))
vac$units_pctchg<-round(vac$units_pctchg,digits=2)

median_age$age_numchg<- ave(median_age$median_age, factor(median_age$geozone), FUN=function(x) c(NA,diff(x)))
median_age$age_pctchg<- ave(median_age$median_age, factor(median_age$geozone), FUN=function(x) c(NA,diff(x)/x*100))
median_age$age_pctchg<-round(median_age$age_pctchg,digits=2)

setnames(vac, old=c("rate"),new=c("vac_rate"))

#rename region value for match
vac$geozone[vac$geotype =="region"]<- "Region"

#strip misc. characters from cpa names for match
vac$geozone <- gsub("\\*","",vac$geozone)
vac$geozone <- gsub("\\-","_",vac$geozone)
vac$geozone <- gsub("\\:","_",vac$geozone)

#rename region value for match
median_age$geozone[median_age$geotype =="region"]<- "Region"

#strip misc. characters from cpa names for match
median_age$geozone <- gsub("\\*","",median_age$geozone)
median_age$geozone <- gsub("\\-","_",median_age$geozone)
median_age$geozone <- gsub("\\:","_",median_age$geozone)

#merge hh with vacancy
hh_merge<-merge(hh, vac, by.x=c("yr_id", "geotype", "geozone"), by.y=c("yr_id", "geotype", "geozone"),all=TRUE)

#merge hh_merge with median age
hh_merge<-merge(hh_merge, median_age, by.x=c("yr_id", "geotype", "geozone"), by.y=c("yr_id", "geotype", "geozone"),all=TRUE)

#delete unneeded columns
hh_merge[c("X.x", "hh", "available", "year", "yr", "X.y")]<-list(NULL)

#reorder columns
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","unoccupiable","vac_rate","median_age","hh_numchg","hhp_numchg","hhs_numchg","hh_pctchg","hhp_pctchg","hhs_pctchg","units_numchg","units_pctchg","vac_numchg","vac_pctchg","age_numchg","age_pctchg")]

#sort file
hh_merge<- hh_merge[order(hh_merge$geotype,hh_merge$geozone,hh_merge$yr_id),]

#save out csv
write.csv(hh_merge,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 4\\hh_hhp_hhs_hu_vac_age_comparison.csv"))

head(hh_merge)

#delete unneeded columns
hh_merge["unoccupiable"]<-list(NULL)
#reorder columns
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","vac_rate","median_age","hh_numchg","hhp_numchg","hhs_numchg","units_numchg","vac_numchg","age_numchg","hh_pctchg","hhp_pctchg","hhs_pctchg","units_pctchg","vac_pctchg","age_pctchg")]

#Convert all values to NaN (numerical missing value)
hh_merge[is.na(hh_merge)] <- NaN

# Rename columns to help reshape function work properly
names(hh_merge)[4:21] <- c("hh.values","hhp.values","hhs.values","units.values","vac.values","age.values",
                           "hh.numchg","hhp.numchg","hhs.numchg","units.numchg","vac.numchg","age.numchg",
                           "hh.pctchg","hhp.pctchg","hhs.pctchg","units.pctchg","vac.pctchg","age.pctchg")

#Reshape data from wide to long
hh_merge_long <- reshape(hh_merge,
                         direction="long",
                         idvar=c("yr_id","geozone","geotype"),
                         varying=list(c(4:9),c(10:15),c(16:21)),
                         timevar="measure", 
                         v.names=c("values","numchg","pctchg"),
                         times=c("households","hh_pop","hh_size","housing_units","vacancy","median_age"))

#Fill NaN pctchg (occurs when there is never a value change) with 0 when numchg = 0
hh_merge_long$pctchg <- ifelse(hh_merge_long$numchg==0,0,hh_merge_long$pctchg)

#Reconvert all values to NaN (numerical missing value, above line converted to NA)
hh_merge_long[is.na(hh_merge_long)] <- NaN

rownames(hh_merge_long) <- NULL

head(hh_merge_long)

hh_merge_jur<-subset(hh_merge_long, geotype=="jurisdiction")
hh_merge_cpa<-subset(hh_merge_long, geotype=="cpa")

head(hh_merge_jur)

jur_list = unique(hh_merge_jur[["geozone"]])
maindir = dirname(rstudioapi::getSourceEditorContext()$path)

results<-"plots\\hh_variable_comparison\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

# Convert all NaN to 0, allows plots to start at base year.
hh_merge_jur[is.na(hh_merge_jur)] <- 0
min_pct = round(min(hh_merge_jur$pctchg, na.rm=TRUE),digits=0)-5
max_pct = round(max(hh_merge_jur$pctchg, na.rm=TRUE),digits=0)+3

for(i in jur_list) {
  plotdat = subset(hh_merge_jur,hh_merge_jur$geozone==i)
  #min_pct = round(min(plotdat$pctchg, na.rm=TRUE),digits=0)-1
  #max_pct = round(max(plotdat$pctchg, na.rm=TRUE),digits=0)+1
  plot <- ggplot(plotdat, aes(x=yr_id, y=pctchg,group=measure)) + 
    geom_point(aes(color=measure)) +
    geom_text(aes(label=paste(values,"\n",round(numchg,2),sep="")),check_overlap=TRUE) +
    facet_grid(measure ~ .,scales="free_y") + 
    geom_line(aes(color=measure),size=1) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste(i,": Household variable comparison\n (datasource_id=17)",sep='')) +
    scale_y_continuous(limits=c(min(0,min_pct),max(5,max_pct))) +
    geom_hline(yintercept=0,linetype="dashed",color="red")
  #plot
  ggsave(plot, file= paste(results,i, '_hh_var_17', ".png", sep=''),
         width=10, height=6, dpi=100)
}



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
