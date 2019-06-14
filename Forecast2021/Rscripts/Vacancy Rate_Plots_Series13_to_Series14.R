# vacancy rate plots compared to Series 13


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}
packages <- c("RODBC","tidyverse","gridExtra","grid") #"ggsci"
pkgTest(packages)

# get data from database
source("../Queries/readSQL.R")
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# initialize dataframes
vacancy <- data.frame()
sourcename <- data.frame()


# change these 3 lines depending on datasource ids
# **********************************************************
############################################################
datasource_ids = c(13,28)
datasource_names = c("Series 13 (ds 13)","Series 14 (ds 28)")
datasource_outfolder = "ds13ds28"
############################################################
# **********************************************************

for(i in 1:length(datasource_ids)) {
  
  # get the name of the datasource
  ds_sql = getSQL("../Queries/datasource_name.sql")
  ds_sql <- gsub("ds_id", datasource_ids[i],ds_sql)
  datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  sourcename <- rbind(sourcename,datasource_name)
  
  # get vacancy data
  Vacancy_sql = getSQL("../Queries/vacancy_ds_id.sql")
  Vacancy_sql <- gsub("ds_id", datasource_ids[i],Vacancy_sql)
  vac<-sqlQuery(channel,Vacancy_sql,stringsAsFactors = FALSE)
  vac$datasource_id = datasource_ids[i]
  vac$series = datasource_names[i]
  vacancy <- rbind(vacancy,vac)
  
}

# get cpa id
geo_id_sql = getSQL("../Queries/get_cpa_and_jurisdiction_id.sql")
geo_id<-sqlQuery(channel,geo_id_sql,stringsAsFactors = FALSE)

odbcClose(channel)

###############################################################################
# rename series 13 CPA to the same name as Series 14 CPA names
vacancy$geozone[vacancy$geozone == "City Heights"] <- "Mid-City:City Heights"
vacancy$geozone[vacancy$geozone == "Normal Heights"] <- "Mid-City:Normal Heights"
vacancy$geozone[vacancy$geozone == "Kensington-Talmadge"] <- "Mid-City:Kensington-Talmadge"
vacancy$geozone[vacancy$geozone == "Ncfua Reserve"] <- "NCFUA Reserve"
vacancy$geozone[vacancy$geozone == "Ncfua Subarea 2"] <- "NCFUA Subarea 2"
vacancy$geozone[vacancy$geozone == "Nestor"] <- "Otay Mesa-Nestor"
vacancy$geozone[vacancy$geozone == "Encanto"] <- "Southeastern:Encanto Neighborhoods"
vacancy$geozone[vacancy$geozone == "Eastern Area"] <- "Mid-City:Eastern Area"
vacancy$geozone[vacancy$geozone == "Southeastern San Diego"] <- "Southeastern:Southeastern San Diego"
###############################################################################

# merge vacancy with datasource name
vacancy <- merge(x = vacancy, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)


# cleanup
rm(vac,datasource_name,sourcename)


# rename San Diego region to 'San Diego Region' and then aggregate
# since city of san diego and san diego region are both named san diego

levels(vacancy$geozone) <- c(levels(vacancy$geozone), "~San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- '~San Diego Region'

# merge vacancy with jurisdiction and cpa id
# note: must be after changing San Diego to San Diego Region 
#       otherwise region will be considered city of San Diego
vacancy <- merge(x = vacancy, y =geo_id,by = "geozone", all.x = TRUE)

# add dummy id for region
vacancy$id[vacancy$geozone=="~San Diego Region"] <- 9999


# check for any double counted rows
#t <- vacancy %>% group_by(geozone) %>% tally()
#subset(t,n>16)

# clean up cpa names removing asterick and dashes etc.
vacancy$geozone <- gsub("\\*","",vacancy$geozone)
vacancy$geozone <- gsub("\\-","_",vacancy$geozone)
vacancy$geozone <- gsub("\\:","_",vacancy$geozone)


#calculate the effective vacancy rate by subtracting out unoccupiable units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 

# convert vacancy rate to percentage
vacancy$pc_vacancy_rate_wo_unoccupiable <- vacancy$vacancy_rate_effective * 100
vacancy$pc_vacancy_rate <- vacancy$vacancy_rate * 100


#save a time stamped verion of the raw file from SQL
### write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\vacancy",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


################################################################
# region_vacancy
region_vacancy <- subset(vacancy,geozone=='~San Diego Region')
##################################################################


# function to determine outliers by IQR
outliers_by_IQR <- function(df) {
  # outliers determined by IQR * 1.5 (exclude very small CPAs less than 500 units) 
  # geo_vac <- subset(df,units >= 500)
  geo_vac <- subset(df,units >= 500 & series=="Series 14 (ds 28)")
  
  lowerq = quantile(geo_vac$pc_vacancy_rate)[2]
  upperq = quantile(geo_vac$pc_vacancy_rate)[4]
  iqr = upperq - lowerq #Or use IQR(data)
  mild.threshold.upper = (iqr * 1.5) + upperq
  mild.threshold.lower = lowerq - (iqr * 1.5)
  
  # outliers have a vacancy rate outside  
  # of IQR * 1.5 for any year (of all jurisdictions or CPAs)
 
  # include all geographies (include those with units < 500)
  outliersonly <- subset(df,(pc_vacancy_rate>mild.threshold.upper | 
                                  pc_vacancy_rate<mild.threshold.lower))
  outliersonly$threshold.lower <- mild.threshold.lower
  outliersonly$threshold.upper <- mild.threshold.upper
  return(outliersonly)
}

# function to determine plot limits
xy_limits <- function(geo_vac_in_limits) {
  yminplot <- min(geo_vac_in_limits$pc_vacancy_rate)
  ymaxplot <- max(geo_vac_in_limits$pc_vacancy_rate)
  limitsforplot <- c(yminplot,ymaxplot)
  return(limitsforplot)
}

theme_set(theme_bw())

vacancy_plot_all_in_one <- function(geo,ylim_min,ylim_max,geo_name,status) {
  
  # for watermark: "SCALE CHANGE"
  if (status =='outlier') {colortouse = 'grey'} else {colortouse='white'}
  
  df <- geo
  df$series <- as.factor(df$series)
  df$vacant_units <- df$units - df$hh
  
  hh_and_vacant_units <- df %>% select("series", "geozone","yr_id","geotype","name","hh","vacant_units")
  vacancy_rate <- df %>% select("series", "geozone","yr_id","geotype","name","pc_vacancy_rate")
  
  long <- reshape2::melt(hh_and_vacant_units, id.vars = c("series", "geozone","yr_id","geotype","name"))
  long2 <- reshape2::melt(vacancy_rate, id.vars = c("series", "geozone","yr_id","geotype","name"))
  
  long$variable = factor(long$variable, levels=c("hh","vacant_units"))
  levels(long$variable) <- c("Occupied Units","Vacant Units")
  
  if (sum(long$value) != 0) { # plot only if there is data
    
    # area plot of occupied and vacant units
    unitsplot <-  ggplot(long, aes(x=yr_id, y=value, fill=variable)) + geom_area() +
          facet_wrap( ~ series) + scale_y_continuous(labels=scales::comma) + 
          labs(title=paste(df$geozone[1],": Units", sep=' '), 
             y="Number of Units", x="Increment",color=NULL) +
          theme(axis.title.y = element_text(size = 14)) +
          theme(axis.title.x = element_blank()) +
          theme(axis.text.y = element_text(vjust=0.5, size = 12)) +
          theme(axis.text.x = element_text(vjust=0.5, size = 12)) +
          theme(strip.text = element_text(size=14)) +
          theme(plot.title = element_text(size=18)) +
          theme(legend.title = element_blank())  +
          theme(legend.text=element_text(size=14)) + 
          scale_fill_manual(values = c("#014d64","#7ad2f6")) 
      
    # line plot of vacancy rate    
    vacancyplot <-  ggplot(long2, aes(x=yr_id,y=value,label=value)) + 
        geom_line(aes(y=value, col=series),size=1.5) + 
        geom_point(aes(y=value),size=2) + facet_wrap( ~ series) +
        theme(strip.text = element_text(size=14)) +
        labs(title=paste(df$geozone[1],": Vacancy Rate", sep=' '), 
           caption=paste("Source: Demographic Warehouse",sep=''),
           y="% Vacancy", x="Increment",color=NULL) 
    vacancyplot <- vacancyplot + ylim(ylim_min,ylim_max) +
        scale_color_manual(values = c("#00887d", "#C10534")) +
        theme(axis.title.y = element_text(size = 14)) +
        theme(axis.title.x = element_text(size = 12)) +
        theme(axis.text.y = element_text(vjust=0.5, size = 12)) +
        theme(axis.text.x = element_text(vjust=0.5, size = 12)) + 
        theme(plot.title = element_text(size=18)) +
        theme(legend.text=element_text(size=14)) +
        annotate(geom="text", x=2030, y=10, label='SCALE CHANGE', 
               color=colortouse, angle=0, fontface='bold', size=7, alpha=0.5) 
      
    # table of data
    outt <- df %>% select("series","geozone","yr_id","units","hh","vacant_units","pc_vacancy_rate")
    # rename variables
    outt <- outt %>% rename(increment = yr_id, occupied = hh,vacant=vacant_units,vacancy = pc_vacancy_rate,name=geozone )
    # series 13
    out13 <- subset(outt,series=="Series 13 (ds 13)")
    out13$series <- NULL
    out13$name <- NULL
    # series 14
    out14 <- subset(outt,series== "Series 14 (ds 28)")
    out14$series <- NULL
    out14$name <- NULL

    # set years 2012 to NA for series 14 and year 2018 to NA for series 13
    d2012 <- data.frame("2012",NA,NA,NA,NA)
    names(d2012) <- c("increment","units","occupied","vacant","vacancy")
    d2018 <- data.frame("2018",NA,NA,NA,NA)
    names(d2018) <- c("increment","units","occupied","vacant","vacancy")
    out132020 <- rbind(out13, d2018)
    out142020 <- rbind(out14, d2012)
    
    # order by year
    out132020 <- out132020[order(out132020$increment),]
    out142020 <- out142020[order(out142020$increment),]
    
    # rename increment to series for table output
    out132020 <- out132020 %>% rename('Series 13' = increment )
    out142020 <- out142020 %>% rename('Series 14' = increment )

  
    tt <- ttheme_default(base_size = 7,colhead=list(fg_params = list(parse=TRUE)))
    tbl13 <- tableGrob(out132020, rows=NULL, theme=tt)
    tbl14 <- tableGrob(out142020, rows=NULL, theme=tt)
  
    
    plotout <- grid.arrange(
      grobs = list(vacancyplot,unitsplot,tbl13,tbl14),
      widths = c(1,1),
      layout_matrix = rbind(c(1,1),
                            c(2,2),
                            c(3, 4)))
    
    #ggsave(plotout, file= paste(df$geozone[1],"_units_and_vacancy", ".png", sep=''),
    #      width=8, height=8, dpi=100)
    ggsave(plotout, file= paste(df$geozone[1],"_units_and_vacancy", ".pdf", sep=''),
           width=8, height=8, dpi=100)
    
  }
}

# all geographies
geo_list = unique(vacancy$geozone)

# outliers determined by IQR * 1.5 (exclude very small CPAs less than 500 units) 
dfoutliers <- outliers_by_IQR(vacancy)

outliers <- unique(dfoutliers$geozone)
not_outliers <- geo_list[!geo_list %in% outliers]
# subset vacany dataframe to just the geographies that don't have outliers
# to get max and min y limits for plot for all jurs except outliers
vacancy_not_outliers <- subset(vacancy, geozone %in% not_outliers & units >= 500)

ymin_ymax <- xy_limits(vacancy_not_outliers)
ymin <- ymin_ymax[1]
ymax <- ymin_ymax[2]
ymax


# for(i in 1:length(not_outliers)) {
for(i in 1:length(geo_list)) {  
  
    plotdat = subset(vacancy, vacancy$geozone==geo_list[i])
    
    if (geo_list[i]  %in% outliers) {
      s = 'outlier'
      ymax <- max(plotdat$pc_vacancy_rate)
    } else {
      s = 'not_outlier'
      ymax <- ymin_ymax[2]
    }

    
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
    
    outfolder<-paste("..\\output\\vacancy\\",datasource_outfolder,"\\",fldr,"\\",sep='')
    ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
    setwd(file.path(maindir,outfolder))
    

    vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s)

  }


#  outliers where units greater than 500

outliers
outlierdat = subset(dfoutliers,  units >= 500 & series =="Series 14 (ds 28)")
outliers_gr_500 <- unique(outlierdat$geozone)
outliers_gr_500



# for(i in 1:length(not_outliers)) {
for(i in 1:length(outliers_gr_500)) {  
  
  plotdat = subset(vacancy, geozone==outliers_gr_500[i])
  ymax <- max(plotdat$pc_vacancy_rate)
  s = 'outlier'
  
  if (nrow(plotdat)==0) {
    next
  }
  fldr <- 'high_vacancy'
  
  outfolder<-paste("..\\output\\vacancy\\",datasource_outfolder,"\\",fldr,"\\",sep='')
  ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
  setwd(file.path(maindir,outfolder))
  
  vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s)
  
}


# units greater than 500
vacancy_gr_500 <- subset(vacancy,units >= 500 & series=="Series 14 (ds 28)")

geo_gr_500 <- unique(vacancy_gr_500$geozone)
length(geo_gr_500)

q <- as.data.frame(quantile(vacancy_gr_500$pc_vacancy_rate))
quantiles <- cbind(row.names(q),q)
rownames(quantiles) <- NULL
names(quantiles) <- c('quartile','percent_vacancy')
quantiles$percent_vacancy <- round(quantiles$percent_vacancy,1)

lowerq = round(quantile(vacancy_gr_500$pc_vacancy_rate)[2],1)
upperq = round(quantile(vacancy_gr_500$pc_vacancy_rate)[4],1)
iqr = upperq - lowerq #Or use IQR(data)
mild.threshold.upper = round(((iqr * 1.5) + upperq),1)
mild.threshold.lower = lowerq - (iqr * 1.5)
mild.threshold.upper



vacbox <- ggplot(vacancy_gr_500, aes(x=as.factor(yr_id),y=pc_vacancy_rate)) + 
  geom_boxplot() + 
  labs(title="Vacancy at Forecast Increments (all jurisdictions and CPAs with units > 500)", 
       subtitle="Outliers are defined as 1.5 times IQR", 
       y="Vacancy %", x="Increment",
       color=NULL)  # title and caption
#vacbox <- vacbox + annotate("text", x = 2020, y = 60, label = "Some text")

tt <- ttheme_default(base_size = 10,colhead=list(fg_params = list(parse=TRUE)))
quant <- tableGrob(quantiles, rows=NULL, theme=tt)
lab = textGrob((paste("Outliers defined as 1.5 * IQR (interquartile range)\n","IQR = ",
                      upperq," minus ",lowerq," = ",iqr,"    ","1.5 * ",
                      iqr," = ",mild.threshold.upper,"\n\nVacancy threshold is",mild.threshold.upper, 
                      "percent for QA purposes",sep = " ")),
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 14))
plotout <- grid.arrange(
  grobs = list(vacbox,quant,lab),
  widths = c(2,1,1),
  layout_matrix = rbind(c(1,1,2),
                        c(3,3,3)))

#ggsave(plotout, file= paste("vacancy_boxplot_500", ".png", sep=''),
#       width=10, height=6, dpi=100)

ggsave(plotout, file= paste("vacancy_boxplot_500", ".pdf", sep=''),
       width=10, height=6, dpi=100)





