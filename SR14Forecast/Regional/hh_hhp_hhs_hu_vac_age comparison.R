#median age and vacancy csv files must be updated before this script is run.
#run tradition vacancy aggregated and median age script in Git hub.

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","cowplot")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
odbcClose(channel)

#save a time stamped verion of the raw file from SQL
write.csv(hh, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\hh_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

#rename region value for match
hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

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



write.csv(hh,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 5\\hh_hhp_hhs with change.csv"))

#read in vacancy and median age file
vac<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 5\\Traditional vacancy_18.csv",stringsAsFactors = FALSE)
median_age_cpa<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 5\\Median Age\\median_age_cpa18.csv",stringsAsFactors = FALSE)
median_age_jur<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 5\\Median Age\\median_age_jur18.csv",stringsAsFactors = FALSE)
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

# add theoretical household pop based on household size of 2.5
hh_merge$hhp2.5.values = hh_merge$households * 2.5
hh_merge$hhp2.5.numchg = NA
hh_merge$hhp2.5.pctchg = NA
#reorder columns
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","unoccupiable","vac_rate","median_age","hhp2.5.values",
                       "hh_numchg","hhp_numchg","hhs_numchg","hh_pctchg","hhp_pctchg","hhs_pctchg","hhp2.5.numchg",
                       "units_numchg","units_pctchg","vac_numchg","vac_pctchg","age_numchg","age_pctchg","hhp2.5.pctchg")]

#sort file
hh_merge<- hh_merge[order(hh_merge$geotype,hh_merge$geozone,hh_merge$yr_id),]

#save out csv
write.csv(hh_merge,("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 5\\hh_hhp_hhs_hu_vac_age_comparison.csv"))

head(hh_merge)

#delete unneeded columns
hh_merge["unoccupiable"]<-list(NULL)
#reorder columns
hh_merge<-hh_merge[, c("yr_id","geotype","geozone","households","hhp","hhs","units","vac_rate","median_age","hhp2.5.values",
                       "hh_numchg","hhp_numchg","hhs_numchg","units_numchg","vac_numchg","age_numchg","hhp2.5.numchg", 
                       "hh_pctchg","hhp_pctchg","hhs_pctchg","units_pctchg","vac_pctchg","age_pctchg","hhp2.5.pctchg")]

#Convert all missing values to NaN (numerical missing value)
hh_merge[is.na(hh_merge)] <- NaN

# Rename columns to help reshape function work properly
names(hh_merge)[4:24] <- c("hh.values","hhp.values","hhs.values","units.values","vac.values","age.values","hhp2.5.values",
                           "hh.numchg","hhp.numchg","hhs.numchg","units.numchg","vac.numchg","age.numchg","hhp2.5.numchg",
                           "hh.pctchg","hhp.pctchg","hhs.pctchg","units.pctchg","vac.pctchg","age.pctchg","hhp2.5.pctchg")


#Reshape data from wide to long
hh_merge_long <- reshape(hh_merge,
                         direction="long",
                         idvar=c("yr_id","geozone","geotype"),
                         varying=list(c(4:10),c(11:17),c(18:24)),
                         timevar="measure", 
                         v.names=c("values","numchg","pctchg"),
                         times=c("households","hh_pop","hh_size","housing_units","vacancy","median_age","hhp2.5"))

#Fill NaN pctchg (occurs when there is never a value change) with 0 when numchg = 0
hh_merge_long$pctchg <- ifelse(hh_merge_long$numchg==0,0,hh_merge_long$pctchg)

#Reconvert all values to NaN (numerical missing value, above line converted to NA)
hh_merge_long[is.na(hh_merge_long)] <- NaN

# Reorder index starting at 1
rownames(hh_merge_long) <- NULL

head(hh_merge_long)

hh_merge_jur<-subset(hh_merge_long, geotype=="jurisdiction")
hh_merge_cpa<-subset(hh_merge_long, geotype=="cpa")
hh_merge_region<-subset(hh_merge_long, geotype=="region")

#############################################################################################
### JURISDICTIONS ### JURISDICTIONS ### JURISDICTIONS ### JURISDICTIONS ### JURISDICTIONS ###
#############################################################################################

head(hh_merge_jur)

jur_list = unique(hh_merge_jur[["geozone"]])
maindir = dirname(rstudioapi::getSourceEditorContext()$path)

results<-"plots\\hh_variable_comparison\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

# Convert all NaN to 0, allows plots to start at base year.
#hh_merge_jur[is.na(hh_merge_jur)] <- 0
#min_pct = round(min(hh_merge_jur$pctchg, na.rm=TRUE),digits=0)
#max_pct = round(max(hh_merge_jur$pctchg, na.rm=TRUE),digits=0)

theme_set(theme_grey())

for(i in jur_list) {
  plotdat = subset(hh_merge_jur,hh_merge_jur$geozone==i)
  min_pct = round(min(plotdat[!(plotdat$measure %in% c("vacancy")),]$pctchg, na.rm=TRUE),digits=2)
  max_pct = round(max(plotdat[!(plotdat$measure %in% c("vacancy")),]$pctchg, na.rm=TRUE),digits=2)
  plot <- ggplot(plotdat, aes(x=yr_id, y=pctchg,group=measure)) + 
    geom_point(aes(color=measure)) +
    geom_text(aes(label=paste(round(numchg,2),"\n",values,sep="")),
              check_overlap=TRUE, size=3) +
    facet_grid(measure ~ .) + 
    geom_line(aes(color=measure),size=1) + 
    theme(plot.title=element_text(hjust = 0.5,size=16), panel.spacing=unit(1,"lines")) + 
    labs(title=paste(i,": Household variable comparison\n (datasource_id=18)",sep='')) +
    scale_y_continuous(limits=c(min_pct,max_pct),expand = expand_scale(mult = c(0, .1))) +
    geom_hline(yintercept=0,linetype="dashed",color="red")
  #plot
  gt = ggplot_gtable(ggplot_build(plot))
  gt$layout$clip = "off"
  ggsave(gt, file= paste(results,i, '_hh_var_18', ".png", sep=''),
         width=10, height=6, dpi=100)
}


results<-"plots\\hh_variable_comparison\\Jur_vacs\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in jur_list) {
  plotdat <- subset(hh_merge_jur,hh_merge_jur$geozone==i)
  plot1 <- ggplot(plotdat[(plotdat$measure %in% c("households","housing_units")),], 
                  aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    geom_text(aes(label=ifelse(measure=="housing_units",
                               ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),""),
                               ifelse(!is.na(numchg),paste("\n",round(numchg,0),sep=""),""))),
              size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plotdat <- rbind(plotdat,hh_merge_region)
  plot2 <- ggplot(plotdat[(plotdat$measure %in% c("vacancy")),], aes(x=yr_id, y=values, group=geozone)) +
    geom_point(aes(color=geozone)) +
    geom_line(aes(color=geozone),size=1) +
    geom_text(aes(label=ifelse(!is.na(values) & geotype!="region",paste(round(values,2),"\n",sep=""),"")),size=3) +
    theme(legend.justification = "left") +
    ggtitle("Vacancy Rate") +
    scale_color_manual(values=c("green4","gold"))
  gt1 <- ggplot_gtable(ggplot_build(plot1))
  gt1$layout$clip = "off"
  gt2 <- ggplot_gtable(ggplot_build(plot2))
  gt2$layout$clip = "off"
  plotout <- plot_grid(gt1,gt2,align="hv",ncol=1,rel_heights=c(2,1))
  ggsave(plotout, file=paste(results,i,"_hh_units_18.png",sep=""),
         width=12,height=8,dpi=100)
}

results<-"plots\\hh_variable_comparison\\Jur_hhs\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in jur_list) {
  plotdat <- subset(hh_merge_jur,hh_merge_jur$geozone==i)
  #plotdat[(plotdat$measure %in% c("households","hh_pop","vacancy")),]
  plot1 <- ggplot(plotdat[(plotdat$measure %in% c("households","hh_pop")),], 
                  aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    geom_text(aes(label=ifelse(measure=="hh_pop",
                               ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),""),
                               ifelse(!is.na(numchg),paste("\n",round(numchg,0),sep=""),""))),
              size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          #panel.spacing=unit(1,"lines"),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    #(limits=c(.9*min(values),1.1*max(values))) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plotdat <- rbind(plotdat,hh_merge_region)
  plot2 <- ggplot(plotdat[(plotdat$measure %in% c("hh_size")),], aes(x=yr_id, y=values, group=geozone)) +
    geom_point(aes(color=geozone)) +
    geom_line(aes(color=geozone),size=1) +
    geom_text(aes(label=ifelse(!is.na(values) & geotype!="region",paste(round(values,2),"\n",sep=""),"")),size=3) +
    theme(legend.justification = "left") +
    ggtitle("Household Size") +
    scale_color_manual(values=c("green4","gold"))
  gt1 <- ggplot_gtable(ggplot_build(plot1))
  gt1$layout$clip = "off"
  gt2 <- ggplot_gtable(ggplot_build(plot2))
  gt2$layout$clip = "off"
  plotout <- plot_grid(gt1,gt2,align="hv",ncol=1,rel_heights=c(2,1))
  ggsave(plotout, file=paste(results,i,"_hh_units_18.png",sep=""),
         width=12,height=8,dpi=100)
}


# with theoretical pop with household size of 2.5
results<-"plots\\hh_variable_comparison\\Jur_hhs_2.5\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)
for(i in jur_list) {
  plotdat <- subset(hh_merge_jur,hh_merge_jur$geozone==i)
  #plotdat[(plotdat$measure %in% c("households","hh_pop","vacancy")),]
  plot1 <- ggplot(plotdat[(plotdat$measure %in% c("households","hh_pop","hhp2.5")),], 
                  aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    #geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),values)),size=3) +
    geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),'')),size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          #panel.spacing=unit(1,"lines"),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    #(limits=c(.9*min(values),1.1*max(values))) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plot1b <- ggplot(plotdat[(plotdat$measure %in% c("households")),], 
                   aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    #geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),values)),size=3) +
    geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),'')),size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          #panel.spacing=unit(1,"lines"),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    #(limits=c(.9*min(values),1.1*max(values))) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plot2 <- ggplot(plotdat[(plotdat$measure %in% c("hh_size")),], aes(x=yr_id, y=values)) +
    geom_point(aes(color="hh_size")) +
    geom_line(aes(color="hh_size"),size=1) +
    geom_text(aes(label=ifelse(!is.na(values),paste(round(values,2),"\n",sep=""),"")),size=3) +
    scale_color_manual(name="",values=c("hh_size"="green4")) +
    theme(plot.title=element_blank(),
          legend.justification = "left") #+
  #scale_y_continuous(limits=c(.9*min(values),1.1*max(values)))
  gt1 <- ggplot_gtable(ggplot_build(plot1))
  gt1$layout$clip = "off"
  gt1b <- ggplot_gtable(ggplot_build(plot1b))
  gt1b$layout$clip = "off"
  gt2 <- ggplot_gtable(ggplot_build(plot2))
  gt2$layout$clip = "off"
  #plotout <- plot_grid(gt1b,gt1,gt2,align="hv",ncol=1,rel_heights=c(1,1,1))
  plotout <- plot_grid(gt1,gt2,align="hv",ncol=1,rel_heights=c(2,1))
  ggsave(plotout, file=paste(results,i,"_hh_units_18.png",sep=""),
         width=12,height=8,dpi=100)
}

#############################################################################################
### CPAS ### CPAS ### CPAS ### CPAS ### CPAS ### CPAS ### CPAS ### CPAS ### CPAS ### CPAS ###
#############################################################################################

head(hh_merge_cpa)

cpa_list = unique(hh_merge_cpa[["geozone"]])
maindir = dirname(rstudioapi::getSourceEditorContext()$path)

results<-"plots\\hh_variable_comparison\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

theme_set(theme_grey())

for(i in cpa_list) {
  plotdat = subset(hh_merge_cpa,hh_merge_cpa$geozone==i)
  min_pct = round(min(plotdat[!(plotdat$measure %in% c("vacancy")),]$pctchg, na.rm=TRUE),digits=2)
  #this currently fails when it hits east elliot because max_pct = Inf
  max_pct = round(max(plotdat[!(plotdat$measure %in% c("vacancy")),]$pctchg, na.rm=TRUE),digits=2)
  plot <- ggplot(plotdat, aes(x=yr_id, y=pctchg,group=measure)) + 
    geom_point(aes(color=measure)) +
    geom_text(aes(label=paste(round(numchg,2),"\n",values,sep="")),
              check_overlap=TRUE, size=3) +
    facet_grid(measure ~ .) + 
    geom_line(aes(color=measure),size=1) + 
    theme(plot.title=element_text(hjust = 0.5,size=16), panel.spacing=unit(1,"lines")) + 
    labs(title=paste(i,": Household variable comparison\n (datasource_id=18)",sep='')) +
    scale_y_continuous(limits=c(min_pct,max_pct),expand=expand_scale(mult = c(0, .1))) +
    geom_hline(yintercept=0,linetype="dashed",color="red")
  #plot
  gt = ggplot_gtable(ggplot_build(plot))
  gt$layout$clip = "off"
  ggsave(gt, file= paste(results,i, '_hh_var_18', ".png", sep=''),
         width=10, height=6, dpi=100)
}


results<-"plots\\hh_variable_comparison\\cpa_vacs\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in cpa_list) {
  plotdat <- subset(hh_merge_cpa,hh_merge_cpa$geozone==i)
  plot1 <- ggplot(plotdat[(plotdat$measure %in% c("households","housing_units")),], 
                  aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    geom_text(aes(label=ifelse(measure=="housing_units",
                               ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),""),
                               ifelse(!is.na(numchg),paste("\n",round(numchg,0),sep=""),""))),
              size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plotdat <- rbind(plotdat,hh_merge_region)
  plot2 <- ggplot(plotdat[(plotdat$measure %in% c("vacancy")),], aes(x=yr_id, y=values, group=geozone)) +
    geom_point(aes(color=geozone)) +
    geom_line(aes(color=geozone),size=1) +
    geom_text(aes(label=ifelse(!is.na(values) & geotype!="region",paste(round(values,2),"\n",sep=""),"")),size=3) +
    theme(legend.justification = "left") +
    ggtitle("Vacancy Rate") +
    scale_color_manual(values=c("green4","gold"))
  gt1 <- ggplot_gtable(ggplot_build(plot1))
  gt1$layout$clip = "off"
  gt2 <- ggplot_gtable(ggplot_build(plot2))
  gt2$layout$clip = "off"
  plotout <- plot_grid(gt1,gt2,align="hv",ncol=1,rel_heights=c(2,1))
  ggsave(plotout, file=paste(results,i,"_hh_units_18.png",sep=""),
         width=12,height=8,dpi=100)
}

results<-"plots\\hh_variable_comparison\\cpa_hhs\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in cpa_list) {
  plotdat <- subset(hh_merge_cpa,hh_merge_cpa$geozone==i)
  #plotdat[(plotdat$measure %in% c("households","hh_pop","vacancy")),]
  plot1 <- ggplot(plotdat[(plotdat$measure %in% c("households","hh_pop")),], 
                  aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    geom_text(aes(label=ifelse(measure=="hh_pop",
                               ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),""),
                               ifelse(!is.na(numchg),paste("\n",round(numchg,0),sep=""),""))),
              size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          #panel.spacing=unit(1,"lines"),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    #(limits=c(.9*min(values),1.1*max(values))) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plotdat <- rbind(plotdat,hh_merge_region)
  plot2 <- ggplot(plotdat[(plotdat$measure %in% c("hh_size")),], aes(x=yr_id, y=values, group=geozone)) +
    geom_point(aes(color=geozone)) +
    geom_line(aes(color=geozone),size=1) +
    geom_text(aes(label=ifelse(!is.na(values) & geotype!="region",paste(round(values,2),"\n",sep=""),"")),size=3) +
    theme(legend.justification = "left") +
    ggtitle("Household Size") +
    scale_color_manual(values=c("green4","gold"))
  gt1 <- ggplot_gtable(ggplot_build(plot1))
  gt1$layout$clip = "off"
  gt2 <- ggplot_gtable(ggplot_build(plot2))
  gt2$layout$clip = "off"
  plotout <- plot_grid(gt1,gt2,align="hv",ncol=1,rel_heights=c(2,1))
  ggsave(plotout, file=paste(results,i,"_hh_units_18.png",sep=""),
         width=12,height=8,dpi=100)
}


# with theoretical pop with household size of 2.5
results<-"plots\\hh_variable_comparison\\cpa_hhs_2.5\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)
for(i in cpa_list) {
  plotdat <- subset(hh_merge_cpa,hh_merge_cpa$geozone==i)
  #plotdat[(plotdat$measure %in% c("households","hh_pop","vacancy")),]
  plot1 <- ggplot(plotdat[(plotdat$measure %in% c("households","hh_pop","hhp2.5")),], 
                  aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    #geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),values)),size=3) +
    geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),'')),size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          #panel.spacing=unit(1,"lines"),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    #(limits=c(.9*min(values),1.1*max(values))) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plot1b <- ggplot(plotdat[(plotdat$measure %in% c("households")),], 
                   aes(x=yr_id, y=values, group=measure)) +
    geom_point(aes(color=measure)) +
    geom_line(aes(color=measure),size=1) +
    #geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),values)),size=3) +
    geom_text(aes(label=ifelse(!is.na(numchg),paste(round(numchg,0),"\n",sep=""),'')),size=3) +
    theme(plot.title=element_text(hjust = 0.5,size=16),
          #panel.spacing=unit(1,"lines"),
          legend.justification = "left",
          axis.title.x=element_blank(),
          axis.text.x=element_blank(),
          axis.ticks.x=element_blank()) + 
    #(limits=c(.9*min(values),1.1*max(values))) +
    labs(title=paste(i,": Household and Housing Units Comparison\n (datasource_id=18)",sep=''))
  plot2 <- ggplot(plotdat[(plotdat$measure %in% c("hh_size")),], aes(x=yr_id, y=values)) +
    geom_point(aes(color="hh_size")) +
    geom_line(aes(color="hh_size"),size=1) +
    geom_text(aes(label=ifelse(!is.na(values),paste(round(values,2),"\n",sep=""),"")),size=3) +
    scale_color_manual(name="",values=c("hh_size"="green4")) +
    theme(plot.title=element_blank(),
          legend.justification = "left") #+
  #scale_y_continuous(limits=c(.9*min(values),1.1*max(values)))
  gt1 <- ggplot_gtable(ggplot_build(plot1))
  gt1$layout$clip = "off"
  gt1b <- ggplot_gtable(ggplot_build(plot1b))
  gt1b$layout$clip = "off"
  gt2 <- ggplot_gtable(ggplot_build(plot2))
  gt2$layout$clip = "off"
  #plotout <- plot_grid(gt1b,gt1,gt2,align="hv",ncol=1,rel_heights=c(1,1,1))
  plotout <- plot_grid(gt1,gt2,align="hv",ncol=1,rel_heights=c(2,1))
  ggsave(plotout, file=paste(results,i,"_hh_units_18.png",sep=""),
         width=12,height=8,dpi=100)
}

