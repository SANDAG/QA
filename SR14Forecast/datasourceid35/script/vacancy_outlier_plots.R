 # vacancy rate plots compared to Series 13

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("../Queries/readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","gridExtra","grid","gtable") #"ggsci"
pkgTest(packages)

datasource_id_current <- 35


datasource_ids <- c(17,35)
datasource_names <- c("Series 14 (ds 17)","Series 14 (ds 35)")
datasource_name_short <- c("Series 14","Series 14")
datasource_outfolder <- "vacancy_outliers"


# get data from database

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# initialize dataframes
vacancy <- data.frame()
sourcename <- data.frame()

for(i in 1:length(datasource_ids)) {
  # get the name of the datasource
  datasource_name <- readDB("../Queries/datasource_name.sql",datasource_ids[i])
  sourcename <- rbind(sourcename,datasource_name)
  
  # get vacancy data
  vac <- readDB("../Queries/vacancy_ds_id.sql",datasource_ids[i])
  vac$datasource_id = datasource_ids[i]
  vac$series = datasource_names[i]
  vacancy <- rbind(vacancy,vac)
}

# get cpa id
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_ids[i])
odbcClose(channel)

# fix names of sr13 cpas to match sr14 cpas
vacancy <- rename_sr13_cpas(vacancy)

# merge vacancy with datasource name
vacancy <- merge(x = vacancy, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)

# cleanup
rm(vac,datasource_name,sourcename)

# rename San Diego region to '~San Diego Region'
levels(vacancy$geozone) <- c(levels(vacancy$geozone), "San Diego Region")
vacancy$geozone[vacancy$geotype=='region'] <- 'San Diego Region'


# merge vacancy with jurisdiction and cpa id
# note: must be after changing San Diego to San Diego Region 
#       otherwise region will be considered city of San Diego
vacancy <- merge(x = vacancy, y =geo_id,by = "geozone", all.x = TRUE)

# clean up cpa names removing asterick and dashes etc.
vacancy <- rm_special_chr(vacancy)

# add dummy id for region & not in a cpa
vacancy$id[vacancy$geozone=="San Diego Region"] <- 0
vacancy$id[vacancy$geozone=="Not in a CPA"] <- 9999

# check for any double counted rows
#t <- vacancy %>% group_by(geozone) %>% tally()
#subset(t,n>16)



#calculate the effective vacancy rate by subtracting out unoccupiable units from total units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
#vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
#vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$vacancy_rate_effective <- round(1 - (vacancy$hh/(vacancy$units-vacancy$unoccupiable)),digits=4)
# write.csv(vacancy,'vacancy.csv')



# remove unnecessary columns
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 

# convert vacancy rate to percentage
vacancy$vacancy_eff <- vacancy$vacancy_rate_effective * 100
vacancy$vacancy_classic <- vacancy$vacancy_rate * 100

# calculate vacant units
vacancy$vacant_units <- vacancy$units - vacancy$hh

# for series 13 there are no unoccupiable units
vacancy$unoccupiable[vacancy$datasource_id == 13] <- NA
vacancy$vacancy_eff[vacancy$datasource_id == 13] <- NA

# change NaN to NA for prettyplots
vacancy$vacancy_rate_effective[is.nan(vacancy$vacancy_rate_effective)] <- NA
vacancy$vacancy_eff[is.nan(vacancy$vacancy_eff)] <- NA

# factor for plots
vacancy$series <- as.factor(vacancy$series)


#save a time stamped verion of the raw file from SQL
### write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\vacancy",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


################################################################
# region_vacancy
region_vacancy <- subset(vacancy,geozone=='San Diego Region')
##################################################################

# out folder for plots
outfolder<-paste("..\\Output\\",datasource_outfolder,sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))


outliers_by_IQR <- function(df) {
  # get outliers by increment (yr_id)
  iqrdf <- subset(df,series==datasource_names[2] & units >= 500) %>% 
    group_by(yr_id) %>% # group by increment
    mutate(lowerq = quantile(vacancy_classic)[2],
           upperq = quantile(vacancy_classic)[4])
  iqrdf$iqr <- iqrdf$upperq - iqrdf$lowerq
  iqrdf$iqrx1.5 <- iqrdf$iqr * 1.5
  iqrdf$threshold.lower = iqrdf$lowerq - iqrdf$iqrx1.5
  iqrdf$threshold.lower[iqrdf$threshold.lower<0] <- 0
  iqrdf$threshold.upper <- iqrdf$iqrx1.5 + iqrdf$upperq
  list_of_outliers <- unique(subset(iqrdf,(iqrdf$vacancy_classic>iqrdf$threshold.upper | 
                                     iqrdf$vacancy_classic<iqrdf$threshold.lower))$geozone)
  return(list_of_outliers)
}
  

ymax_by_IQR <- function(df) {   
  # get ymax for plot (combine all years)
  ymaxdf <- subset(df,series==datasource_names[2] & units >= 500) %>% 
    summarize(lowerq = quantile(vacancy_classic)[2],
           upperq = quantile(vacancy_classic)[4])
  ymaxdf$iqr <- ymaxdf$upperq - ymaxdf$lowerq
  ymaxdf$iqrx1.5 <- ymaxdf$iqr * 1.5
  ymaxdf$ymin = round((ymaxdf$lowerq - ymaxdf$iqrx1.5),1)
  ymaxdf$ymin[ymaxdf$ymin<0] <- 0
  ymaxdf$ymax <- round((ymaxdf$iqrx1.5 + ymaxdf$upperq),1)
  #ymaxdf = select(ymaxdf, -c(iqr, lowerq, upperq,iqrx1.5))
  return(ymaxdf$ymax)
}


theme_set(theme_bw())

unit_area_plot <- function(df) {
  
  #select variables for area plot
  hh_and_vacant_units <- df %>% select("series", "geozone","yr_id","geotype","name","hh","vacant_units")
  
  # rename variables
  hh_and_vacant_units <- hh_and_vacant_units %>% rename(
    'Occupied Units' = hh,
    'Vacant Units' = vacant_units)
  
  # reshape dataframe from wide to long
  units <- reshape2::melt(hh_and_vacant_units, id.vars = c("series", "geozone","yr_id","geotype","name"))
  
  # area plot of occupied and vacant units
  unitsplot <-  ggplot(units, aes(x=yr_id, y=value, fill=variable)) + geom_area() +
      facet_wrap( ~ series) + scale_y_continuous(labels=scales::comma) + 
      labs(title=paste(df$geozone[1],": Units", sep=' '), 
         caption=paste("vacant units includes unoccupiable units (un_occup)", sep=''),
         y="Number of Units", x="Increment",color=NULL) +
      theme(axis.title.x = element_blank()) +
      theme(axis.title.y = element_text(size = 14)) +
      theme(axis.text.x = element_text(vjust=0.5, size = 12)) +
      theme(axis.text.y = element_text(vjust=0.5, size = 12)) +
      theme(strip.text = element_text(size=14)) +
      theme(plot.title = element_text(size=18)) +
      theme(legend.title = element_blank())  +
      theme(legend.text=element_text(size=10)) + 
      scale_fill_manual(values = c("#014d64","#7ad2f6")) 
  return(unitsplot)
}

#df<-plotdat
#df<- subset(df,datasource_id==datasource_id_current )
#watermark = 'white'
#ylim_min <- ymin
#ylim_max <- ymax
vacancy_line_plot <- function(df,ylim_min,ylim_max,watermarkcolor) {
  # line plot of vacancy rate 
  vacancy_rate <- df %>% select("series", "geozone","yr_id","geotype","name","datasource_id","vacancy_classic","vacancy_eff")
  vac_long <- reshape2::melt(vacancy_rate, id.vars = c("series", "geozone","yr_id","geotype","name","datasource_id"))
  # remove vacancy effective if datasource is 13
  vac_long <- vac_long[!(vac_long$variable=="vacancy_eff" & vac_long$datasource_id == 13),]
  # change scale if outlier
  if (watermarkcolor  == 'grey') {ylim_max <- max(vac_long$value,na.rm=TRUE) + 3}
  vacancyplot <-  ggplot(data=subset(vac_long, !is.na(value)),
                         aes(x=yr_id,y=value,label=value)) + 
          geom_line(aes(y=value,linetype=variable),size=1) + 
          geom_point(aes(y=value),size=1.5) + facet_wrap( ~ series) +
          labs(title=paste(df$geozone[1],": Vacancy Rate", sep=' '), 
          caption=paste("Source: Demographic Warehouse",sep=''),y="% Vacancy", x="Increment",color=NULL) + 
          ylim(ylim_min,ylim_max) +
          scale_color_manual(values = c("#00887d", "#C10534")) +
          scale_linetype_manual(values=c("solid", "dotted")) +
          theme(axis.title.x = element_text(size = 12)) +
          theme(axis.title.y = element_text(size = 14)) +
          theme(axis.text.x = element_text(vjust=0.5, size = 12)) + 
          theme(axis.text.y = element_text(vjust=0.5, size = 12)) +
          theme(strip.text = element_text(size=14)) +
          theme(plot.title = element_text(size=18)) +
          theme(legend.title = element_blank())  +
          theme(legend.text=element_text(size=10)) +
          annotate(geom="text", x=2030, y=10, label='SCALE CHANGE', 
             color=watermark, angle=0, fontface='bold', size=7, alpha=0.5) 
  return(vacancyplot)
}
  
#df<-plotdat1
vacancy_table <- function(df) {
    # table of data
    outt <- df %>% select("series","geozone","yr_id","units","hh","unoccupiable","vacant_units",
                          "vacancy_classic","vacancy_eff")
    
    
    # fill in increments that are missing for each series with NA (e.g. 2012 for sr14)
    #outt <- outt %>% complete(series, nesting(increment, name))  
    outt <- outt[order(outt$yr_id),] # order by year
    outt$name <- NULL # remove name (e.g. Barrio Logan)
    outt$unit_chg <- outt$units-lag(outt$units)
    outt$vacant_chg <- outt$vacant_units-lag(outt$vacant_units)
    outt$hh_chg <- outt$hh-lag(outt$hh)
    outt <- outt %>% select("series","geozone","yr_id","units","unit_chg","hh","unoccupiable","vacant_units","vacant_chg",
                          "vacancy_classic","vacancy_eff")
    # rename variables
    outt <- outt %>% rename(increment = yr_id,occupied = hh,un_occup=unoccupiable,
                            vacant=vacant_units,vacancy=vacancy_classic,vac_eff=vacancy_eff,name=geozone)
    ####################################################################
    
  return(outt)
}
   


# calculate largest vacancy differences

# get just the current datasource id
dfv<- subset(vacancy,datasource_id==datasource_id_current )
#select columns
dfv <- dfv[,c("datasource_id","id",'geozone',"yr_id","units","hh","vacant_units","vacancy_rate")]
# order dataframe for doing lag calculation
dfv <- dfv[order(dfv$datasource_id,dfv$geozone,dfv$yr_id),]

####################################################################
#difference over increments greater than 3%
vr <- dfv %>% 
  group_by(geozone) %>% 
  mutate(change = vacancy_rate - lag(vacancy_rate))
vr$abschg <- abs(vr$change)
vr$change[is.na(vr$change)]<-0
changebyincrement_grthan_3percent <- unique(subset(vr,abschg > .03)$geozone)
print("\n greater than 3% vacancy by increment: \n")
cat(paste(shQuote(changebyincrement_grthan_3percent, type="cmd"), collapse=", "))
####################################################################

####################################################################
#difference over forecast greater than 5%
vr2 <- subset(dfv,yr_id %in% c(2016,2050))
vr2chg <- vr2 %>% 
  group_by(geozone) %>% 
  mutate(change = vacancy_rate - lag(vacancy_rate))
# replace year 2016 with 
ind <- which(is.na(vr2chg$change))
vr2chg$change[ind] <- sapply(ind, function(i) with(vr2chg,change[i+1]))
vr2chg$abschg <- abs(vr2chg$change)
change2016to2050_grthan_5percent <- unique(subset(vr2chg,abschg > .05)$geozone)
print("\n greater than 5% vacancy 2016 to 2050: \n")
cat(paste(shQuote(change2016to2050_grthan_5percent, type="cmd"), collapse=", "))
####################################################################

# geographies with largest differences
chg_gr_3_or_5 <- c(changebyincrement_grthan_3percent,change2016to2050_grthan_5percent)

# outliers at all increments (thresholds are by increment(yr_id))
# determined by IQR * 1.5 (exclude very small CPAs less than 500 units) 
outliers <- outliers_by_IQR(vacancy)


# for plotting need to define all outliers (including small CPAs)
# includes cpas with less than 500 units
ymin <- 0
ymax <- ymax_by_IQR(vacancy)
plot_outliers <- subset(vacancy, vacancy_classic > ymax)
plot_outliers_list <- unique(plot_outliers$geozone)


# all geographies
region = unique(subset(vacancy,geotype=='region')$geozone)
jur_list = unique(subset(vacancy,geotype=='jurisdiction')$geozone)
cpa_list = unique(subset(vacancy,geotype=='cpa')$geozone)
geos <- c(region,jur_list,cpa_list)
geos <- unique(chg_gr_3_or_5)
#create pdf with all plots
pdf(paste("vacancy","_ds",datasource_ids[2],"outliers.pdf",sep=''), 8, 8)
# loop through all geographies
for(i in geos) {
    print(i)
    watermark = 'white'
    plotsuffix <- ''
    plotdat = subset(vacancy, vacancy$geozone==i)
    
    # add watermark if scale changes
    if (i  %in% plot_outliers_list) {watermark = 'grey'} 
    
    if (i %in% outliers) {plotsuffix <- '_outlier'} 
    
    # if no data skip to next jurisdiction or cpa
    if (nrow(plotdat)==0) {next}
    
     # units
    plotdat1<- subset(plotdat,datasource_id==datasource_id_current )
    uplot <- unit_area_plot(plotdat1)
    vlplot <- vacancy_line_plot(plotdat1,ymin,ymax,watermark) # trendline
    vtable <- vacancy_table(plotdat1) # table
  
    # make the table pretty!
    #lefttable <- subset(vtable,series==datasource_names[1])
    righttable <- subset(vtable,series==datasource_names[2])
    #names(lefttable)[names(lefttable)=="increment"] <- datasource_name_short[1]
    #names(righttable)[names(righttable)=="increment"] <- datasource_name_short[2]
    #names(lefttable)[names(lefttable)=="increment"] <- as.character(lefttable$series[1])
    #names(righttable)[names(righttable)=="increment"] <- as.character(righttable$series[1])
    #lefttable$series <- NULL
    righttable$series <- NULL
    tt <- ttheme_default(base_size = 10,colhead=list(fg_params = list(parse=TRUE)))
    # tbl1 <- tableGrob(lefttable, rows=NULL, theme=tt)
    tbl2 <- tableGrob(righttable, rows=NULL, theme=tt)
    
    #grobs = list(vlplot,uplot,tbl1,tbl2),
    plotout <- grid.arrange(
      grobs = list(vlplot,uplot,tbl2),
      widths = c(1,1),
      layout_matrix = rbind(c(1,1),
                            c(2,2),
                            c(3,3)))
    
    ggsave(plotout, file= paste(plotdat$geozone[1],'_',plotdat$id[1],"_vacancy_outliers",plotsuffix,".pdf", sep=''),
           width=8, height=8, dpi=100)
  }
dev.off()



#############################################################
# Calculations for top 10 changes

# get just the current datasource id
countvars<- subset(vacancy,datasource_id==datasource_id_current )

################################################################
# change from 2016 to 2050

vr2050 <- subset(countvars,yr_id %in% c(2016,2050))

vr2050chg <- vr2050 %>% 
  group_by(geozone) %>% 
  mutate(change = vacancy_rate - lag(vacancy_rate))

# replace year 2016 with 
ind <- which(is.na(vr2050chg$change))
vr2050chg$change[ind] <- sapply(ind, function(i) with(vr2050chg,change[i+1]))

vr2050chg$abschg <- abs(vr2050chg$change)


change2016to2050_grthan_5percent <- unique(subset(vr2050chg,abschg > .05)$geozone)
print("\n greater than 5% vacancy 2016 to 2050: \n")
cat(paste(shQuote(change2016to2050_grthan_5percent, type="cmd"), collapse=", "))

write.csv(vr2050chg,"vacancy_rates_chg_2016to2050.csv")

### end change 2016 to 2050
##########################################################


countvars <- countvars[,c("datasource_id","id",'geozone',"yr_id","units","hh","vacant_units","vacancy_rate")]


# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$datasource_id,countvars$geozone,countvars$yr_id),]

#difference over increments
vr <- countvars %>% 
  group_by(geozone) %>% 
  mutate(change = vacancy_rate - lag(vacancy_rate))

vr$abschg <- abs(vr$change)

vr$change[is.na(vr$change)]<-0

changebyincrement_grthan_3percent <- unique(subset(vr,abschg > .03)$geozone)
print("\n greater than 3% vacancy by increment: \n")
cat(paste(shQuote(changebyincrement_grthan_3percent, type="cmd"), collapse=", "))

write.csv(vr,"vacancy_rates_chg_by_increment.csv")
 
###########
# cities and cpas with no change in units
unitchg <- countvars %>% 
  group_by(geozone) %>% 
  mutate(change = units - lag(units))


uc<- unitchg %>% group_by(geozone) %>% mutate(count = sum(change == 0,na.rm = TRUE))

uc['x'] <- 'no'
ind <- which(uc$units != dplyr::lag(uc$units))
uc$x[ind] <-'yes'

inc3 <- subset(uc,count > 1 & yr_id == 2016)
write.csv(inc3,"inc4.csv")

# remove cities or cpas where there are no units e.g. 32nd St, Balboa Park, Flower Hill
uc2 <- uc[uc$geozone %in% uc$geozone[uc$units!=0], ]
uc2$counter <- sequence(rle(as.character(uc2$units))$lengths)
results <- unique(subset(uc2,counter > 2)$geozone)

##########