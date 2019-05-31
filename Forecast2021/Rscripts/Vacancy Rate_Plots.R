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

datasource_ids = c(28)

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

# merge vacancy with datasource name
vacancy <- merge(x = vacancy, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)


# cleanup
rm(vac,datasource_name,sourcename)


#save a time stamped verion of the raw file from SQL
# write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\vacancy_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


# note city of san diego and san diego region are both named san diego
# rename San Diego region to 'San Diego Region' and then aggregate
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "~San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- '~San Diego Region'

# merge vacancy with jurisdiction and cpa id
# note: must be after change San Diego to San Diego Region 
#       otherwise region will be considered city of San Diego
geo_id <- subset(geo_id,id != 1493) # database error
vacancy <- merge(x = vacancy, y =geo_id,by = "geozone", all.x = TRUE)
# add dummy id for region
vacancy$id[vacancy$geozone=="~San Diego Region"] <- 9999

# had to remove CPA id for via de la valle 1493
# sql query to check database for error
# SELECT * 
#   FROM [demographic_warehouse].[dim].[mgra_denormalize]
# WHERE cpa = 'Via De La Valle' and series = 14 and cpa_id = 1493
# SELECT * 
#   FROM [demographic_warehouse].[dim].[mgra_denormalize]
# WHERE mgra_id = 1401333804
# SELECT * 
#   FROM [demographic_warehouse].[dim].[mgra_denormalize]
# WHERE cpa_id = 1493

# find any double counted rows
# t <- vacancy %>% group_by(geozone) %>% tally()
# subset(t,n>8)
# subset(vacancy,geozone=='Via De La Valle')

# clean up names
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)


#calculate the effective vacancy rate subtracting out unoccupiable units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 

vacancy$pc_vacancy_rate <- vacancy$vacancy_rate * 100

# region_vacancy
region_vacancy <- subset(vacancy,geozone=='~San Diego Region')
reg <- region_vacancy[,c('yr_id','pc_vacancy_rate','geozone','id')]


# function to determine outliers by IQR
outliers_by_IQR <- function(df,geography) {
  geo_list = unique(subset(df, geotype==geography)[["geozone"]])
  geo_vac <- subset(vacancy, geotype==geography)
  lowerq = quantile(geo_vac$pc_vacancy_rate)[2]
  upperq = quantile(geo_vac$pc_vacancy_rate)[4]
  iqr = upperq - lowerq #Or use IQR(data)
  mild.threshold.upper = (iqr * 1.5) + upperq
  mild.threshold.lower = lowerq - (iqr * 1.5)
  # outliers have a vacancy rate outside  
  # of IQR * 1.5 for any year (of all jurisdictions or CPAs)
  outside_limits <- unique(subset(geo_vac,
                                  (pc_vacancy_rate>mild.threshold.upper | 
                                     pc_vacancy_rate<mild.threshold.lower))[["geozone"]])
  return(outside_limits)
}

# function to determine plot limits
xy_limits <- function(geo_vac_in_limits) {
  # use actual min and max for plots not 1.5*IQR
  # could be less than 1.5*IQR.  
  yminplot <- min(geo_vac_in_limits$pc_vacancy_rate)
  ymaxplot <- max(geo_vac_in_limits$pc_vacancy_rate)
  limitsforplot <- c(yminplot,ymaxplot)
  return(limitsforplot)
}


# function to plot data
vacancy_plot <- function(geo,reg,subtitle,ylim_min,ylim_max,status,geo_name) {
  geoforplot <-  geo[,c('yr_id','pc_vacancy_rate','geozone','id')]
  df <- rbind(geoforplot,reg)
  vplot <-  ggplot(df, aes(x=yr_id)) + 
            geom_line(aes(y=pc_vacancy_rate, col=geozone)) + 
            geom_point(aes(y=pc_vacancy_rate, col=geozone)) + 
            labs(title=paste("Vacancy Rate: ",geo_name,sep=' '), 
            subtitle=subtitle, 
            caption=paste("Source: Demographic Warehouse Datasource:",plotsource,sep=''),
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
  ggsave(plotout, file= paste(df$id[1], geo_name,"_ds",plotsource,"vacancy_",status, ".png", sep=''),
         width=8, height=8, dpi=100)
  
}

##################################################################
# plot CPA
geo_list = unique(subset(vacancy, geotype=="cpa")[["geozone"]])

# boxplot
outfolder<-"..\\output\\vacancy\\boxplot\\"
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

cpa_vac <- subset(vacancy, geotype=="cpa")
cpabox <- ggplot(cpa_vac, aes(x=as.factor(yr_id),y=pc_vacancy_rate)) + 
  geom_boxplot() + 
  labs(title="Vacancy Rate at Forecast Increments: all CPAs", 
       subtitle="Outliers by IQR", 
       caption=paste("Source: Demographic Warehouse Datasource:",plotsource,sep=''),
       y="Vacancy %", x="Increment",
       color=NULL)  # title and caption
ggsave(cpabox, file= paste("cpa_boxplot","_ds",plotsource,"vacancy", ".png", sep=''),
       width=10, height=6, dpi=100)

# CPA
outfolder<-"..\\output\\vacancy\\CPAplots\\"
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

outliers <- outliers_by_IQR(vacancy,"cpa")
not_outliers <- geo_list[!geo_list %in% outliers]

# subset vacany dataframe to just the geographies that don't have outliers
# to get max and min to use for all plots without outliers
vacancy_not_outliers <- subset(vacancy, geozone %in% not_outliers)
ymin_ymax <- xy_limits(vacancy_not_outliers)
ymin <- ymin_ymax[1]
ymax <- ymin_ymax[2]


for(i in 1:length(not_outliers)) {
  plotdat = subset(vacancy, vacancy$geozone==not_outliers[i])
  plotsubtitle <- "CPA and Region at Forecast Increments"
  vacancy_plot(plotdat,reg,plotsubtitle,ymin,ymax,"",not_outliers[i])
}

# (outlier defined by 1.5 * IQR)
for(i in 1:length(outliers)){
  plotdat = subset(vacancy, vacancy$geozone==outliers[i])
  pgeo <-  plotdat[,c('yr_id','pc_vacancy_rate','geozone','id')]
  vac <- rbind(pgeo,reg)
  ymax <- max(vac$pc_vacancy_rate)
  ymin <- min(vac$pc_vacancy_rate)
  plotsubtitle <- "CPA and Region at Forecast Increments: Outlier as defined by 1.5 * IQR\nnote: scale change"
  vacancy_plot(plotdat,reg,plotsubtitle,ymin,ymax,"Outlier",outliers[i])
}

############################################
# jurisdiction
geo_list = unique(subset(vacancy, geotype=="jurisdiction")[["geozone"]])

outfolder<-"..\\output\\vacancy\\boxplot\\"
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

jur_vac <- subset(vacancy, geotype=="jurisdiction")
jurbox <- ggplot(jur_vac, aes(x=as.factor(yr_id),y=pc_vacancy_rate)) + 
  geom_boxplot() + 
  labs(title="Vacancy Rate at Forecast Increments: all CPAs", 
            subtitle="Outliers by IQR", 
       caption=paste("Source: Demographic Warehouse Datasource:",plotsource,sep=''),
       y="Vacancy %", x="Increment",
       color=NULL)  # title and caption
ggsave(jurbox, file= paste("jur_boxplot","_ds",plotsource,"vacancy", ".png", sep=''),
       width=10, height=6, dpi=100)


# jurisdiction 
outfolder<-"..\\output\\vacancy\\JURplots\\"
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

outliers <- outliers_by_IQR(vacancy,"jurisdiction")
not_outliers <- geo_list[!geo_list %in% outliers]

# subset vacany dataframe to just the geographies that don't have outliers
# to get max and min y limits for plot for all jurs except outliers
vacancy_not_outliers <- subset(vacancy, geozone %in% not_outliers)
ymin_ymax <- xy_limits(vacancy_not_outliers)
ymin <- ymin_ymax[1]
ymax <- ymin_ymax[2]


for(i in 1:length(not_outliers)) {
  plotdat = subset(vacancy, vacancy$geozone==not_outliers[i])
  plotsubtitle <- "Jurisdiction and Region at Forecast Increments"
  vacancy_plot(plotdat,reg,plotsubtitle,ymin,ymax,"",not_outliers[i])
}

# (outlier defined by 1.5 * IQR)
for(i in 1:length(outliers)){
  plotdat = subset(vacancy, vacancy$geozone==outliers[i])
  pgeo <-  plotdat[,c('yr_id','pc_vacancy_rate','geozone','id')]
  vac <- rbind(pgeo,reg)
  ymax <- max(vac$pc_vacancy_rate)
  ymin <- min(vac$pc_vacancy_rate)
  plotsubtitle <- "Jurisdiction and Region at Forecast Increments: Outlier as defined by 1.5 * IQR\nnote: scale change"
  vacancy_plot(plotdat,reg,plotsubtitle,ymin,ymax,"Outlier",outliers[i])
}
