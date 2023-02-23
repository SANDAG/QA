# hhp rate plots compared to Series 13


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}
packages <- c("RODBC","tidyverse","gridExtra","grid") #"ggsci"
pkgTest(packages)

# # get data from database
# source("../Queries/readSQL.R")
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("C:/QA/readSQL.R")

# initialize dataframes
hhp <- data.frame()
sourcename <- data.frame()


# change these 3 lines depending on datasource ids
# **********************************************************
############################################################
datasource_ids = c(13,28)
datasource_names = c("Series 13 (ds 13)","Series 14 (ds 28)")
datasource_name_short = c("Series 13","Series 14")
datasource_outfolder = "ds13ds28"
############################################################
# **********************************************************

for(i in 1:length(datasource_ids)) {
  
  # get the name of the datasource
  # ds_sql = getSQL("../Queries/datasource_name.sql")
  ds_sql = getSQL("C:/QA/datasource_name.sql")
  ds_sql <- gsub("ds_id", datasource_ids[i],ds_sql)
  datasource_name<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  sourcename <- rbind(sourcename,datasource_name)
  
  # get hhp data
  hhp_sql = getSQL("C:/QA/hh_hhp_hhs_ds_id.sql")
  hhp_sql <- gsub("ds_id", datasource_ids[i],hhp_sql)
  vac<-sqlQuery(channel,hhp_sql,stringsAsFactors = FALSE)
  vac$datasource_id = datasource_ids[i]
  vac$series = datasource_names[i]
  hhp <- rbind(hhp,vac)
  
}

# get cpa id
# geo_id_sql = getSQL("../Queries/get_cpa_and_jurisdiction_id.sql")
geo_id_sql = getSQL("C:/QA/get_cpa_and_jurisdiction_id.sql")
geo_id<-sqlQuery(channel,geo_id_sql,stringsAsFactors = FALSE)

odbcClose(channel)

###############################################################################
# rename series 13 CPA to the same name as Series 14 CPA names
hhp$geozone[hhp$geozone == "City Heights"] <- "Mid-City:City Heights"
hhp$geozone[hhp$geozone == "Normal Heights"] <- "Mid-City:Normal Heights"
hhp$geozone[hhp$geozone == "Kensington-Talmadge"] <- "Mid-City:Kensington-Talmadge"
hhp$geozone[hhp$geozone == "Ncfua Reserve"] <- "NCFUA Reserve"
hhp$geozone[hhp$geozone == "Ncfua Subarea 2"] <- "NCFUA Subarea 2"
hhp$geozone[hhp$geozone == "Nestor"] <- "Otay Mesa-Nestor"
hhp$geozone[hhp$geozone == "Encanto"] <- "Southeastern:Encanto Neighborhoods"
hhp$geozone[hhp$geozone == "Eastern Area"] <- "Mid-City:Eastern Area"
hhp$geozone[hhp$geozone == "Southeastern San Diego"] <- "Southeastern:Southeastern San Diego"
###############################################################################

# merge hhp with datasource name
hhp <- merge(x = hhp, y =sourcename[ , c("name","datasource_id")],by = "datasource_id", all.x = TRUE)


# cleanup unnecessary dataframe
rm(vac,datasource_name,sourcename)


# rename San Diego region to 'San Diego Region' and then aggregate
# since city of san diego and san diego region are both named san diego

levels(hhp$geozone) <- c(levels(hhp$geozone), "~San Diego Region")
hhp$geozone[hhp$geotype=='region'] <- '~San Diego Region'

# merge hhp with jurisdiction and cpa id
# note: must be after changing San Diego to San Diego Region 
#       otherwise region will be considered city of San Diego
hhp <- merge(x = hhp, y =geo_id,by = "geozone", all.x = TRUE)

# add dummy id for region
hhp$id[hhp$geozone=="~San Diego Region"] <- 9999


# check for any double counted rows
#t <- hhp %>% group_by(geozone) %>% tally()
#subset(t,n>16)

# clean up cpa names removing asterick and dashes etc.
hhp$geozone <- gsub("\\*","",hhp$geozone)
hhp$geozone <- gsub("\\-","_",hhp$geozone)
hhp$geozone <- gsub("\\:","_",hhp$geozone)


# #calculate the effective vacancy rate by subtracting out unoccupiable units
# vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
# vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
# vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
# vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
# vacancy$available <- NULL
# vacancy$occupiable_unit <- NULL 


# vacancy$unoccupiable[vacancy$series == datasource_names[1]] <- NA

# # convert vacancy rate to percentage
# vacancy$pc_vacancy_rate_wo_unoccupiable <- vacancy$vacancy_rate_effective * 100
# vacancy$pc_vacancy_rate <- vacancy$vacancy_rate * 100


#save a time stamped verion of the raw file from SQL
### write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\vacancy",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


################################################################
# region_hhp
region_hhp <- subset(hhp,geozone=='~San Diego Region')  #6/19
##################################################################


# # function to determine outliers by IQR at every increment for Series 14
# outliers_by_IQR <- function(df) {
#   # outliers determined by IQR * 1.5 (exclude very small CPAs less than 500 units) 
#   geo_vac <- subset(df,units >= 500 & series==datasource_names[2])
#   
#   alloutliers <- data.frame()
#   increments <- unique(geo_vac$yr_id)
#   # get outliers at any increment
#   for(i in 1:length(increments)) {
#     geo_increment <- subset(geo_vac,yr_id==increments[i])
#     lowerq = quantile(geo_increment$pc_vacancy_rate)[2]
#     upperq = quantile(geo_increment$pc_vacancy_rate)[4]
#     iqr = upperq - lowerq #Or use IQR(data)
#     mild.threshold.upper = (iqr * 1.5) + upperq
#     mild.threshold.lower = lowerq - (iqr * 1.5)
#     outliersonly <- subset(geo_increment,(pc_vacancy_rate>mild.threshold.upper | 
#                                             pc_vacancy_rate<mild.threshold.lower))
#     outliersonly$threshold.lower <- mild.threshold.lower
#     outliersonly$threshold.upper <- mild.threshold.upper
#     alloutliers <- rbind(alloutliers,outliersonly)
#     
#   }
#   # list all geographies that had outliers at any increment
#   all_outlier_list <- unique(alloutliers$geozone)
#   return(all_outlier_list)
# }


# # get quantiles as dataframe
# def_quantile <- function(df) {
#   geo_vac <- subset(df,units >= 500 & series==datasource_names[2])
#   q <- as.data.frame(quantile(geo_vac$pc_vacancy_rate))
#   quantiles <- cbind(row.names(q),q)
#   rownames(quantiles) <- NULL
#   names(quantiles) <- c('quartile','percent_vacancy')
#   quantiles$percent_vacancy <- round(quantiles$percent_vacancy,1)
#   return(quantiles)
# }
# 
# 
# theme_set(theme_bw())

# hhp_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s,prefix)
hhp_plot_all_in_one <- function(geo,ylim_min,ylim_max,geo_name,status,pre) {
  
  # for watermark: "SCALE CHANGE"
  if (status =='outlier') {colortouse = 'grey'} else {colortouse='white'}
  
  df <- geo
  df$series <- as.factor(df$series)
  # df$vacant_units <- df$units - df$hh
  
  hh_and_vacant_units <- df %>% select("series", "geozone","yr_id","geotype","name","hh","vacant_units")
  hhp_rate <- df %>% select("series", "geozone","yr_id","geotype","name","pc_vacancy_rate")
  
  long <- reshape2::melt(hh_and_vacant_units, id.vars = c("series", "geozone","yr_id","geotype","name"))
  long2 <- reshape2::melt(vacancy_rate, id.vars = c("series", "geozone","yr_id","geotype","name"))
  
  long$variable = factor(long$variable, levels=c("hh","vacant_units"))
  levels(long$variable) <- c("Occupied Units","Vacant Units")
  
  if (sum(long$value) != 0) { # plot only if there is data
    
    # area plot of occupied and vacant units
    unitsplot <-  ggplot(long, aes(x=yr_id, y=value, fill=variable)) + geom_area() +
      facet_wrap( ~ series) + scale_y_continuous(labels=scales::comma) + 
      labs(title=paste(df$geozone[1],": Units", sep=' '), 
           caption=paste("vacant units includes unoccupiable units (un_occup)", sep=''),
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
    outt <- df %>% select("series","geozone","yr_id","units","hh","unoccupiable","vacant_units","pc_vacancy_rate")
    # rename variables
    outt <- outt %>% rename(increment = yr_id,occupied = hh,un_occup=unoccupiable,
                            vacant=vacant_units,vacancy = pc_vacancy_rate,name=geozone)
    # series 13
    out13 <- subset(outt,series==datasource_names[1])
    out13$series <- NULL
    out13$name <- NULL
    # series 14
    out14 <- subset(outt,series== datasource_names[2])
    out14$series <- NULL
    out14$name <- NULL
    
    # ugly code to make nice tables!
    # set years 2012 to NA for series 14 and year 2018 to NA for series 13
    d2012 <- data.frame("2012",NA,NA,NA,NA,NA)
    names(d2012) <- c("increment","units","occupied","un_occup","vacant","vacancy")
    d2018 <- data.frame("2018",NA,NA,NA,NA,NA)
    names(d2018) <- c("increment","units","occupied","un_occup","vacant","vacancy")
    
    out132020 <- rbind(out13, d2018)
    out142020 <- rbind(out14, d2012)
    
    # order by year
    out132020 <- out132020[order(out132020$increment),]
    out142020 <- out142020[order(out142020$increment),]
    
    # rename increment to series for table output
    #out132020 <- out132020 %>% rename("Series 13" = increment ) #datasource_name_short[1]
    
    names(out132020)[names(out132020)=="increment"] <- datasource_name_short[1]
    names(out142020)[names(out142020)=="increment"] <- datasource_name_short[2]
    
    
    
    
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
    ggsave(plotout, file= paste(pre,df$geozone[1],"_units_and_vacancy", ".pdf", sep=''),
           width=8, height=8, dpi=100)
    
  }
}

# all geographies
geo_list = unique(vacancy$geozone)

# outliers at all increments
# determined by IQR * 1.5 (exclude very small CPAs less than 500 units) 
outliers <- outliers_by_IQR(vacancy)

# note: outliers defined above only includes those with units > 500
# for plotting need to define all outliers (including small CPAs)

quantiles_df <- def_quantile(vacancy)
iqr = quantiles_df$percent_vacancy[4] - quantiles_df$percent_vacancy[2]
mild.threshold.upper = round(((iqr * 1.5) + quantiles_df$percent_vacancy[4]),1)
mild.threshold.upper

ymin <- 0

# include all geographies including CPAs with less than 500 units
plot_outliers <- subset(vacancy, pc_vacancy_rate > mild.threshold.upper)
plot_outliers_list <- unique(plot_outliers$geozone)


outfolder<-paste("..\\output\\vacancy\\",datasource_outfolder,"\\plots\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

for(i in 1:length(geo_list)) {
  # for(i in 1:5) { # test plots with short loop
  
  plotdat = subset(vacancy, vacancy$geozone==geo_list[i])
  
  if (geo_list[i]  %in% plot_outliers_list) {
    s = 'outlier'
    if (max(plotdat$pc_vacancy_rate) <= 42) {
      ymax <- 42
    } else {ymax <- max(plotdat$pc_vacancy_rate)}
  } else {
    s = 'not_outlier'
    ymax <- mild.threshold.upper
  }
  
  
  if (nrow(plotdat)==0) {
    next
  }
  
  if (plotdat$id[1] < 20 & plotdat$id[1] > 0) {
    fldr <- 'JUR'
    prefix <- '1'
  } else if (plotdat$id[1] > 19 & plotdat$id[1] < 1500) {
    fldr <- 'CityCPA'
    prefix <- '2'
  } else if (plotdat$id[1] > 1500 & plotdat$id[1] < 2000) {
    fldr <- 'CountyCPA'
    prefix <- '3'
  } else {
    fldr <- ''
    prefix <-'4'
  }
  
  vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s,prefix)
  
}


# create divider pdf pages

lab = textGrob("\n\n\n Vacancy Rate for Jurisdictions\n\n
               (vacancy plots on the same scale unless indicated otherwise)",
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 12))
ggsave(lab, file= paste("1AAJurisdictions", ".pdf", sep=''),
       width=10, height=6, dpi=100)
lab = textGrob("\n\n\n Vacancy Rate for City CPAs\n\n
               (vacancy plots on the same scale unless indicated otherwise)",
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 12))
ggsave(lab, file= paste("2AACityCPA", ".pdf", sep=''),
       width=10, height=6, dpi=100)

lab = textGrob("\n\n\n Vacancy Rate for Unincorporated CPAs\n\n
               (vacancy plots on the same scale unless indicated otherwise)",
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 12))
ggsave(lab, file= paste("3AACountyCPAs", ".pdf", sep=''),
       width=10, height=6, dpi=100)
lab = textGrob("\n\n\n Vacancy Rate for Region and *NOT IN A CPA*\n\n
               (vacancy plots on the same scale unless indicated otherwise)",
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 12))
ggsave(lab, file= paste("4AARegion", ".pdf", sep=''),
       width=10, height=6, dpi=100)


#  outliers where units greater than 500
outfolder<-paste("..\\output\\vacancy\\",datasource_outfolder,"\\","outliers_gr_500units\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))


outliersdf <- subset(vacancy,geozone %in% outliers)
ymax <- max(outliersdf$pc_vacancy_rate)

for(i in 1:length(outliers)) {  
  
  plotdat = subset(vacancy, geozone==outliers[i])
  
  s = '' # do not add water mark to plot
  
  if (nrow(plotdat)==0) {
    next
  }
  
  if (plotdat$id[1] < 20 & plotdat$id[1] > 0) {
    fldr <- 'JUR'
    prefix <- '1'
  } else if (plotdat$id[1] > 19 & plotdat$id[1] < 1500) {
    fldr <- 'CityCPA'
    prefix <- '2'
  } else if (plotdat$id[1] > 1500 & plotdat$id[1] < 2000) {
    fldr <- 'CountyCPA'
    prefix <- '3'
  } else {
    fldr <- ''
    prefix <-'4'
  }
  
  
  vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s,prefix)
  
}


source = datasource_names[2]
boxplot_df <- subset(vacancy,units >= 500 & series==source)
vacbox <- ggplot(boxplot_df, aes(x=as.factor(yr_id),y=pc_vacancy_rate)) + 
  geom_boxplot() + 
  labs(title="Vacancy at Forecast Increments (all jurisdictions and CPAs with units > 500)", 
       subtitle="Outliers are defined as 1.5 times IQR (shown as points on plot)",
       caption=paste("Source: Demographic Warehouse: ",source, sep=''),
       y="Vacancy %", x="Increment",
       color=NULL)  # title and caption
tt <- ttheme_default(base_size = 10,colhead=list(fg_params = list(parse=TRUE)))
quant <- tableGrob(quantiles_df, rows=NULL, theme=tt)
lab = textGrob(paste("note: vacancy calculation includes all units\n\nOutliers shown as points on plot are defined as:\n", "1.5 * IQR at any increment\n",
                     "e.g. for all increments combined:","\n    ",
                     "= 1.5 * (",quantiles_df$percent_vacancy[4],"- ",quantiles_df$percent_vacancy[2],
                     ") + ",quantiles_df$percent_vacancy[4]," = ",mild.threshold.upper,
                     "\nupper vacancy threshold = ",mild.threshold.upper,"%\n\n",
                     "Number of unique outliers =",length(outliers), "\n\n Plots for each unique outlier on following pages",
                     sep = " "),
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 10))
plotout <- grid.arrange(
  grobs = list(vacbox,quant,lab),
  widths = c(2,1,1),
  layout_matrix = rbind(c(1,1,NA),
                        c(2,3,NA)))

#ggsave(plotout, file= paste("vacancy_boxplot_500", ".png", sep=''),
#       width=10, height=6, dpi=100)

ggsave(plotout, file= paste("0vacancy_boxplot_units_grth_500", ".pdf", sep=''),
       width=10, height=6, dpi=100)




# include all geographies including CPAs with less than 500 units
plot_outliers_sm <- subset(vacancy, pc_vacancy_rate > mild.threshold.upper & units < 500 &
                             series==source)
plot_outliers_list_sm <- unique(plot_outliers_sm$geozone)

for(i in 1:length(plot_outliers_list_sm)) {  
  
  plotdat = subset(vacancy, geozone==plot_outliers_list_sm[i])
  
  if (max(plotdat$pc_vacancy_rate) > max(outliersdf$pc_vacancy_rate)) {
    s = 'outlier'
    ymax <- max(plotdat$pc_vacancy_rate)
  }
  else {
    ymax <- max(outliersdf$pc_vacancy_rate)
    s = ''
  }
  
  if (nrow(plotdat)==0) {
    next
  }
  
  prefix <- 6
  
  vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s,prefix)
  
}

lab = textGrob("\n\n\n Outliers where units < 500\n\n",
               x = unit(.1, "npc"), just = c("left"), 
               gp = gpar(fontsize = 12))

ggsave(lab, file= paste("5TitlePage", ".pdf", sep=''),
       width=10, height=6, dpi=100)


# write.csv(vacancy,"vacancy.csv")

