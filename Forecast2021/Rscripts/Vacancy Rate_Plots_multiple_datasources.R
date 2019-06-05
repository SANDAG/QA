# vacancy rate plots compared to regional vacancy

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}
# "summarytools"
packages <- c("RODBC","tidyverse","gridExtra")
pkgTest(packages)

# get data from database
source("../Queries/readSQL.R")


datasource_ids = c(17,28)

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

vacancy <- data.frame()
sourcename <- data.frame()
plotsource <- ''

for(ds_id in datasource_ids) {
  # datasource name
  ds_sql = getSQL("../Queries/datasource_name.sql")
  ds_sql <- gsub("ds_id", ds_id,ds_sql)
  datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  sourcename <- rbind(sourcename,datasource_name)
  
  # get vacancy
  Vacancy_sql = getSQL("../Queries/vacancy_ds_id.sql")
  Vacancy_sql <- gsub("ds_id", ds_id,Vacancy_sql)
  vac<-sqlQuery(channel,Vacancy_sql,stringsAsFactors = FALSE)
  vac$datasource_id = ds_id
  vacancy <- rbind(vacancy,vac)
  
  plotsource <- paste(plotsource,ds_id,sep=' ')
  
}

# get cpa id
geo_id_sql = getSQL("../Queries/get_cpa_and_jurisdiction_id.sql")
geo_id<-sqlQuery(channel,geo_id_sql,stringsAsFactors = FALSE)

odbcClose(channel)

datasource_outfolder = paste("ds",plotsource,sep='')

# merge vacancy with datasource name
vacancy <- merge(x = vacancy, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)


# cleanup
rm(vac,datasource_name,sourcename)

# write output of vacancy query 


# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "~San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- '~San Diego Region'

# merge vacancy with jurisdiction and cpa id
# note: must be after change San Diego to San Diego Region 
#       otherwise region will be considered city of San Diego
# geo_id <- subset(geo_id,id != 1493) # database error
vacancy <- merge(x = vacancy, y =geo_id,by = "geozone", all.x = TRUE)
# add dummy id for region
vacancy$id[vacancy$geozone=="~San Diego Region"] <- 9999

# find any double counted rows
# t <- vacancy %>% group_by(geozone) %>% tally()
# subset(t,n>8)
# subset(vacancy,geozone=='Via De La Valle')

#check mid city name gets fixed
vacancy$geozone[vacancy$id==1459]

# clean up names
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)

#check mid city name is fixed
vacancy$geozone[vacancy$id==1459]

#calculate the effective vacancy rate subtracting out unoccupiable units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 


vacancy$pc_vacancy_rate_wo_unoccupiable <- vacancy$vacancy_rate_effective * 100
vacancy$pc_vacancy_rate <- vacancy$vacancy_rate * 100


#save a time stamped verion of the raw file from SQL
### write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\vacancy",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
#vacancy_outfile = vacancy[ , c("datasource_id","name","geotype","id","geozone","yr_id","units","unoccupiable",
#                          "hh","pc_vacancy_rate_wo_unoccupiable","pc_vacancy_rate")]
#write.csv(vacancy_outfile, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\",
#                                 datasource_outfolder,"vacancy.csv",sep=''),row.names=FALSE)


# function to determine outliers by IQR
thresholds_by_IQR <- function(geo_vac) {
  lowerq = quantile(geo_vac$pc_vacancy_rate)[2]
  upperq = quantile(geo_vac$pc_vacancy_rate)[4]
  iqr = upperq - lowerq #Or use IQR(data)
  mild.threshold.upper = (iqr * 1.5) + upperq
  mild.threshold.lower = lowerq - (iqr * 1.5)
  limitsforplot <- c(mild.threshold.lower,mild.threshold.upper)
  return(limitsforplot)
}

thresholds <- thresholds_by_IQR(vacancy)
lowerthresh <- thresholds[1]
upperthresh <- thresholds[2]

outliersonly <- subset(vacancy,(pc_vacancy_rate>upperthresh | 
                                  pc_vacancy_rate<lowerthresh))

geo_list = unique(vacancy$geozone)
outliers <- unique(outliersonly$geozone)
not_outliers <- geo_list[!geo_list %in% outliers]


# function to determine plot limits
xy_limits <- function(geo_vac_in_limits) {
  # use actual min and max for plots not 1.5*IQR
  # could be less than 1.5*IQR.  
  yminplot <- min(geo_vac_in_limits$pc_vacancy_rate)
  ymaxplot <- max(geo_vac_in_limits$pc_vacancy_rate)
  limitsforplot <- c(yminplot,ymaxplot)
  return(limitsforplot)
}

vacancy_not_outliers <- subset(vacancy, geozone %in% not_outliers)
ymin_ymax <- xy_limits(vacancy_not_outliers)
ymin <- ymin_ymax[1]
ymax <- ymin_ymax[2]

################################################################
# region_vacancy
region_vacancy <- subset(vacancy,geozone=='~San Diego Region')
##################################################################

theme_set(theme_bw())
# function to plot data
vacancy_plot <- function(geo,reg,subtitle,ylim_min,ylim_max,status,geo_name,dsid) {
  #geoforplot <-  geo[,c('yr_id','pc_vacancy_rate','geozone','id')]
  geoforplot <-  geo
  df <- rbind(geoforplot,reg)
  vplot <-  ggplot(df, aes(x=yr_id)) + 
    geom_line(aes(y=pc_vacancy_rate, col=geozone)) + 
    geom_point(aes(y=pc_vacancy_rate, col=geozone)) + 
    labs(title=paste("Vacancy Rate: ",geo_name, "   datasource: ",ds_id,sep=' '), 
         subtitle=subtitle, 
         caption=paste("Source: Demographic Warehouse Datasource:",dsid,sep=''),
         y="Vacancy %", x="Increment",color=NULL) 
  vplot <- vplot + ylim(ylim_min,ylim_max) +
    scale_color_manual(values = c("#00ba38", "#f8766d")) +
    theme(axis.title.y = element_text(size = 12)) +
    theme(axis.title.x = element_text(size = 12)) +
    theme(axis.text.y = element_text(vjust=0.5, size = 12)) +
    theme(axis.text.x = element_text(angle = 45, vjust=0.5, size = 12))#,  # rotate x axis text
  # panel.grid.minor = element_blank())
  geo$vacant_units <- geo$units - geo$hh
  output_table <- geo %>% select(yr_id,hh,units,vacant_units,pc_vacancy_rate)
  output_table <- output_table[order(output_table$yr_id),]
  output_table <- output_table %>% rename(yr = yr_id, households = hh,vacancy = pc_vacancy_rate )
  tt <- ttheme_default(colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  plotout <- grid.arrange(vplot, tbl,
                          nrow=2,
                          as.table=TRUE,
                          heights=c(1,1)) 
  ggsave(plotout, file= paste(geo_name,"_ds",dsid,"vacancy_",status, ".png", sep=''),
         width=8, height=8, dpi=100)
  #ggsave(plotout, file= paste(geo_name,"_ds",dsid,"vacancy_",status, ".pdf", sep=''),
  #       width=8, height=8, dpi=100)
  
}

for(i in 1:length(not_outliers)) {
  
  for(ds_id in datasource_ids) {
    
    plotdat = subset(vacancy, vacancy$geozone==not_outliers[i] & vacancy$datasource_id==ds_id)
    
    if (nrow(plotdat)==0) {
      next
    }
    
    if (plotdat$id[1] < 20 & plotdat$id[1] > 0) {
      fldr <- 'JUR'
      } else if (plotdat$id[1] > 19 & plotdat$id[1] < 1500) {
        fldr <- 'CityCPA'
      } else if (plotdat$id[1] > 1500 & plotdat$id[1] < 2000) {
          fldr <- 'CountyCPA'
    } else fldr <- ''
    
    outfolder<-paste("..\\output\\vacancy\\",ds_id,"\\",fldr,"\\",sep='')
    ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
    setwd(file.path(maindir,outfolder))
    regvac <- subset(region_vacancy,datasource_id==ds_id)
    plotsubtitle <- paste(toupper(plotdat$geotype[1])," and Region at Forecast Increments",sep='')
    vacancy_plot(plotdat,regvac,plotsubtitle,ymin,ymax,"",not_outliers[i],ds_id)
    }
  }
 

for(i in 1:length(outliers)) {
  vac = rbind(subset(vacancy, vacancy$geozone==outliers[i]),region_vacancy)
  ymax <- max(vac$pc_vacancy_rate)
  ymin <- min(vac$pc_vacancy_rate)
  for(ds_id in datasource_ids) {
    
    plotdat = subset(vacancy, vacancy$geozone==outliers[i] & vacancy$datasource_id==ds_id)
    if (nrow(plotdat)==0) {
      next
    }
    if (plotdat$id[1] < 20 & plotdat$id[1] > 0) {
      fldr <- 'JUR'
    } else if (plotdat$id[1] > 19 & plotdat$id[1] < 1500) {
      fldr <- 'CityCPA'
    } else if (plotdat$id[1] > 1500 & plotdat$id[1] < 2000) {
      fldr <- 'CountyCPA'
    } else fldr <- ''
    
    outfolder<-paste("..\\output\\vacancy\\",ds_id,"\\",fldr,"\\",sep='')
    ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
    setwd(file.path(maindir,outfolder))
    regvac <- subset(region_vacancy,datasource_id==ds_id)
    plotsubtitle <- paste(toupper(plotdat$geotype[1])," and Region at Forecast Increments,   Note:scale change",sep='')
    ymax <- max(vac$pc_vacancy_rate)
    ymin <- min(vac$pc_vacancy_rate)
    vacancy_plot(plotdat,regvac,plotsubtitle,ymin,ymax,"",outliers[i],ds_id)
  }
}





