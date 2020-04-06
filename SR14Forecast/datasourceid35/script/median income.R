pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

options('scipen'=10)

# add series 14 median income

datasource_id=34

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#region median income for SR14
median_income_reg_sql = getSQL("../Queries/median_income_region_ds_id.sql")
median_income_reg_sql <- gsub("ds_id", datasource_id, median_income_reg_sql)
mi_reg<-sqlQuery(channel,median_income_reg_sql,stringsAsFactors = FALSE)
setnames(mi_reg, "median_inc", "med_inc_reg")
head(mi_reg)

#jurisdiction median income for SR14
median_income_jur_sql = getSQL("../Queries/median_income_jur_ds_id.sql")
median_income_jur_sql <- gsub("ds_id", datasource_id, median_income_jur_sql)
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)

#cpa median income for SR14
median_income_cpa_sql = getSQL("../Queries/median_income_cpa_ds_id.sql")
median_income_cpa_sql <- gsub("ds_id", datasource_id, median_income_cpa_sql)
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)

#households
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", datasource_id,hh_sql)
hh<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
hh$datasource_id = datasource_id

#cpa ids
cpa_sql = getSQL("../Queries/get_cpa_and_jurisdiction_id.sql")
cpa_id<-sqlQuery(channel,cpa_sql,stringsAsFactors = FALSE)

odbcClose(channel)

# get region data
mi_jur$med_inc_reg1<-mi_reg[match(mi_jur$yr_id, mi_reg$yr_id), "med_inc_reg"]
mi_cpa$med_inc_reg1<-mi_reg[match(mi_cpa$yr_id, mi_reg$yr_id), "med_inc_reg"]
mi_cpa<- merge(mi_cpa,cpa_id,by.x=c("geozone"), by.y=c("geozone"), all.x=TRUE)

# get household data
mi_jur_hh<- merge(mi_jur,hh,by.x=c("geozone", "yr_id"), by.y=c("geozone", "yr_id"), all.x=TRUE)
mi_cpa_hh<- merge(mi_cpa,hh,by.x=c("geozone", "yr_id"), by.y=c("geozone", "yr_id"), all.x=TRUE)

# write files
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
tempdir<-"temp_files\\"
ifelse(!dir.exists(file.path(maindir,tempdir)), dir.create(file.path(maindir,tempdir), showWarnings = TRUE, recursive=TRUE),0)
write.csv(mi_jur, paste(tempdir,"mi_jur_demographic_warehouse",".csv",sep=""))
write.csv(mi_cpa, paste(tempdir,"mi_cpa_demographic_warehouse",".csv",sep=""))


# plots
# function for jur and cpa plots
medianincomeplot <- function(plotdat) {
  lowerlimit = 40000
  upperlimit = 106000
  scale_change=''
  data_long <- melt(plotdat,id.vars=c("yr_id","geozone"),
                    measure.vars=c("median_inc","med_inc_reg1"),
                    variable.name="source",value.name="median_income")
  if (NROW(na.omit(data_long[(data_long[,'median_income']<lowerlimit),]))) {
    lowerlimit = min(data_long$median_income)
    scale_change='\nNote: scale change'
  }
  if (NROW(na.omit(data_long[(data_long[,'median_income']>upperlimit),]))) {
    upperlimit = max(data_long$median_income)
    scale_change='\nNote: scale change'
  }
  plot<- ggplot(plotdat, aes(x=yr_id))+
    geom_line(aes(y=median_inc,  color=paste("id ",datasource_id,' ',plotdat$geozone[1],sep='')),size=1.2) +
    geom_point(aes(y=median_inc, color=paste("id ",datasource_id,' ',plotdat$geozone[1],sep='')), size=3, alpha=0.8) +
    geom_line(aes(y= med_inc_reg1, color=paste("Region")),linetype="dashed",size=1.2) +
    geom_point(aes(y= med_inc_reg1, color=paste("Region")), size=3, alpha=0.8) +
    scale_y_continuous(labels = comma, limits=c(lowerlimit,upperlimit)) +
    labs(title=paste(plotdat$geozone[1], " Household Median Income ",sep=""), 
         y="Median Income", x="Year",
         subtitle=paste('SR14 datasource id ',datasource_id,
                        scale_change,sep='')) +
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme(axis.text.x=element_text(size=14,angle=0)) +
    theme(axis.title.x=element_text(size=16,angle=0, hjust=0.5, vjust=1)) +
    theme(axis.text.y=element_text(size=14,angle=0)) +
    theme(axis.title.y=element_text(size=16,angle=90)) +
    theme(plot.title = element_text(hjust = 0.5,size=18,face="bold")) +
    theme(plot.subtitle=element_text(size=14, hjust=0.5, face="italic", color="black"))
  
  output_table<-data.frame(plotdat$yr_id,plotdat$median_inc,
                           plotdat$med_inc_reg1,plotdat$households)
  sr14_colname1 = paste("Median Income ","\n",plotdat$geozone[1],sep=" ")
  sr14_colname_region1 = paste("Median Income ","\nRegion",sep=" ")
  setnames(output_table, 
           old=c("plotdat.yr_id","plotdat.median_inc",
                 "plotdat.med_inc_reg1","plotdat.households"),
           new=c("Year",sr14_colname1,sr14_colname_region1,"num_hh"))
  tt <- ttheme_default(colhead = 
                         # first unit is the wdith, and second the height
                         list(padding=unit.c(unit(4, "mm"), unit(10, "mm"))))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  title <- textGrob(paste("HH Median Income, ds id ",datasource_id,sep=""),
                    gp=gpar(fontsize=16))
  padding <- unit(5,"mm")
  table <- gtable_add_rows(
    tbl, 
    heights = grobHeight(title) + padding,
    pos = 0)
  table <- gtable_add_grob(
    table, 
    title, 
    1, 1, 1, ncol(table))
  output<-grid.arrange(plot,table,as.table=TRUE,nrow = 2,#layout_matrix=lay,
                       bottom = textGrob(paste("Sources:", 
                                               "\nSR14: demographic warehouse: 
                                               dbo.compute_median_income_all_zones ",datasource_id,sep=''),
                                         x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 6.5)))
  ggsave(output, width=6, height=8, dpi=100, 
         file= paste(results,'median income ',
                     plotdat$geozone[1], ".png", sep=''))
}


# jur plots
folder_name = paste('jur_ds',datasource_id,sep='')
results<-paste("plots\\median_income\\",folder_name,"\\",sep='')
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)
jur_name <-unique(mi_jur$geozone)
for(i in 1:length(jur_name)) { 
# for(i in 1:2) { 
  jurdat = subset(mi_jur_hh, mi_jur_hh$geozone==jur_name[i])
  #jurdat = jurdat[,c("geozone","yr_id","median_inc",
   #                  "med_inc_reg1","Num_Households")]
  medianincomeplot(jurdat)
}

# cpa plots
cpa_list<-unique(mi_cpa$geozone)
folder_name = paste('cpa_ds',datasource_id,sep='')
results<-paste("plots\\median_income\\",folder_name,"\\",sep='')
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)
for(i in 1:length(cpa_list)) { 
#for(i in 1:5) {
  cpadat = subset(mi_cpa_hh, mi_cpa_hh$geozone==cpa_list[i])
  cpadat$geozone = gsub("\\*","",cpadat$geozone)
  cpadat$geozone = gsub("\\-","_",cpadat$geozone)
  cpadat$geozone = gsub("\\:","_",cpadat$geozone)
  #cpadat = cpadat[,c("geozone","yr_id","median_inc",
  #                   "med_inc_reg1","Num_Households")]
  medianincomeplot(cpadat)
}

