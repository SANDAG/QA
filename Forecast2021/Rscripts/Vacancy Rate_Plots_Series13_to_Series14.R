# vacancy rate plots compared to Series 13

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

packages <- c("RODBC","tidyverse","gridExtra","grid","gtable") #"ggsci"
pkgTest(packages)

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
vacancy <- rm_special_chr(vacancy)

#calculate the effective vacancy rate by subtracting out unoccupiable units
vacancy$occupiable_unit<-vacancy$units-vacancy$unoccupiable
vacancy$available <-(vacancy$occupiable_unit-vacancy$hh)
vacancy$vacancy_rate_effective <-(vacancy$available/vacancy$occupiable_unit)
vacancy$vacancy_rate_effective <-round(vacancy$vacancy_rate_effective,digits=4)
vacancy$available <- NULL
vacancy$occupiable_unit <- NULL 

# for series 13 there are no unoccupiable units
if (datasource_ids[1]==13) {
  vacancy$unoccupiable[vacancy$series == datasource_names[1]] <- NA
}

# calculate vacant units
vacancy$vacant_units <- vacancy$units - vacancy$hh


# convert vacancy rate to percentage
vacancy$pc_vacancy_rate_wo_unoccupiable <- vacancy$vacancy_rate_effective * 100
vacancy$pc_vacancy_rate <- vacancy$vacancy_rate * 100


#save a time stamped verion of the raw file from SQL
### write.csv(vacancy, paste("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\vacancy\\vacancy",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


################################################################
# region_vacancy
region_vacancy <- subset(vacancy,geozone=='~San Diego Region')
##################################################################

# out folder for plots
outfolder<-paste("..\\output\\",datasource_outfolder,"\\plots\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))


# function to determine outliers by IQR at every increment for Series 14
outliers_by_IQR <- function(df) {
  # outliers determined by IQR * 1.5 (exclude very small CPAs less than 500 units) 
  geo_vac <- subset(df,units >= 500 & series==datasource_names[2])
  
  alloutliers <- data.frame()
  allranges <- data.frame()
  increments <- unique(geo_vac$yr_id)
  # get outliers at any increment
  for(i in 1:length(increments)) {
    geo_increment <- subset(geo_vac,yr_id==increments[i])
    lowerq = quantile(geo_increment$pc_vacancy_rate)[2]
    upperq = quantile(geo_increment$pc_vacancy_rate)[4]
    iqr = upperq - lowerq #Or use IQR(data)
    mild.threshold.upper = (iqr * 1.5) + upperq
    mild.threshold.lower = lowerq - (iqr * 1.5)
    thresholds <- data.frame(increments[i],round(mild.threshold.lower[[1]],1),round(mild.threshold.upper[[1]],1))
    names(thresholds)<-c("increment","threshold.lower","threshold.upper")
    allranges <- rbind(allranges,thresholds)
    outliersonly <- subset(geo_increment,(pc_vacancy_rate>mild.threshold.upper | 
                                 pc_vacancy_rate<mild.threshold.lower))
    outliersonly$threshold.lower <- mild.threshold.lower
    outliersonly$threshold.upper <- mild.threshold.upper
    alloutliers <- rbind(alloutliers,outliersonly)
    
  }
  # list all geographies that had outliers at any increment
  all_outlier_list <- unique(alloutliers$geozone)
  allranges <- allranges[order(allranges$increment),]
  allranges$threshold.lower[allranges$threshold.lower<0] <- 0
  write.csv(allranges,"IQR.csv",row.names=FALSE)
  return(all_outlier_list)
}


# get quantiles as dataframe
def_quantile <- function(df) {
  geo_vac <- subset(df,units >= 500 & series==datasource_names[2])
  q <- as.data.frame(quantile(geo_vac$pc_vacancy_rate))
  quantiles <- cbind(row.names(q),q)
  rownames(quantiles) <- NULL
  names(quantiles) <- c('quartile','percent_vacancy')
  quantiles$percent_vacancy <- round(quantiles$percent_vacancy,1)
  return(quantiles)
}


theme_set(theme_bw())


# vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s,prefix,plotsuffix)
vacancy_plot_all_in_one <- function(geo,ylim_min,ylim_max,geo_name,status,pre,suf) {
  
  # for watermark: "SCALE CHANGE"
  if (status =='outlier') {colortouse = 'grey'} else {colortouse='white'}
  
  df <- geo
  df$vacancy_rate_effective[is.nan(df$vacancy_rate_effective)] <- NA
  df$pc_vacancy_rate_wo_unoccupiable[is.nan(df$pc_vacancy_rate_wo_unoccupiable)] <- NA
  df$series <- as.factor(df$series)
  df$vacant_units <- df$units - df$hh
  if (datasource_ids[1]==13) {
    df$pc_vacancy_rate_wo_unoccupiable[df$series == datasource_names[1]] <- NA}
  df$geozone[df$geozone == "~San Diego Region"] <- "San Diego Region"
  
  hh_and_vacant_units <- df %>% select("series", "geozone","yr_id","geotype","name","hh","vacant_units")
  vacancy_rate <- df %>% select("series", "geozone","yr_id","geotype","name","pc_vacancy_rate","pc_vacancy_rate_wo_unoccupiable")
  
  long <- reshape2::melt(hh_and_vacant_units, id.vars = c("series", "geozone","yr_id","geotype","name"))
  long2 <- reshape2::melt(vacancy_rate, id.vars = c("series", "geozone","yr_id","geotype","name"))
  
  levels(long2$variable) <- c(levels(long2$variable), "vacancy_classic","vacancy_eff")
  
  long2$variable[long2$variable == 'pc_vacancy_rate'] <- "vacancy_classic"
  long2$variable[long2$variable == 'pc_vacancy_rate_wo_unoccupiable'] <- "vacancy_eff"
  if (datasource_ids[1]==13) {
    long2<-long2[!(long2$variable=="vacancy_eff" & long2$series == datasource_names[1]),]}
  
  long$variable = factor(long$variable, levels=c("hh","vacant_units"))
  levels(long$variable) <- c("Occupied Units","Vacant Units")
  
  if (s  == 'outlier') {
    if (max(long2$value,na.rm=TRUE) <= 42) {
      ylim_max <- 42
    } else {ylim_max <- max(long2$value,na.rm=TRUE)}
  } 
  
  
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
          theme(legend.text=element_text(size=10)) + 
          scale_fill_manual(values = c("#014d64","#7ad2f6")) 
      
    # line plot of vacancy rate    
    vacancyplot <-  ggplot(data=subset(long2, !is.na(value)),
                           aes(x=yr_id,y=value,label=value)) + 
        # geom_line(aes(y=value, col=series,linetype=variable),size=1.5) + 
        geom_line(aes(y=value,linetype=variable),size=1) + 
        geom_point(aes(y=value),size=1.5) + facet_wrap( ~ series) +
        theme(strip.text = element_text(size=14)) +
        labs(title=paste(df$geozone[1],": Vacancy Rate", sep=' '), 
           caption=paste("Source: Demographic Warehouse",sep=''),
           y="% Vacancy", x="Increment",color=NULL) 
    vacancyplot <- vacancyplot + ylim(ylim_min,ylim_max) +
        scale_color_manual(values = c("#00887d", "#C10534")) +
        scale_linetype_manual(values=c("solid", "dotted")) +
        theme(axis.title.y = element_text(size = 14)) +
        theme(axis.title.x = element_text(size = 12)) +
        theme(axis.text.y = element_text(vjust=0.5, size = 12)) +
        theme(axis.text.x = element_text(vjust=0.5, size = 12)) + 
        theme(plot.title = element_text(size=18)) +
        theme(legend.title = element_blank())  +
        theme(legend.text=element_text(size=10)) +
        annotate(geom="text", x=2030, y=10, label='SCALE CHANGE', 
               color=colortouse, angle=0, fontface='bold', size=7, alpha=0.5) 
      
    # table of data
    outt <- df %>% select("series","geozone","yr_id","units","hh","unoccupiable","vacant_units",
                          "pc_vacancy_rate","pc_vacancy_rate_wo_unoccupiable")
    # rename variables
    outt <- outt %>% rename(increment = yr_id,occupied = hh,un_occup=unoccupiable,
                            vacant=vacant_units,vacancy=pc_vacancy_rate,vac_eff=pc_vacancy_rate_wo_unoccupiable,name=geozone)
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
    if (datasource_ids[1]==13) {
      d2012 <- data.frame("2012",NA,NA,NA,NA,NA,NA)
      names(d2012) <- c("increment","units","occupied","un_occup","vacant","vac_eff","vacancy")
      d2018 <- data.frame("2018",NA,NA,NA,NA,NA,NA)
      names(d2018) <- c("increment","units","occupied","un_occup","vacant","vac_eff","vacancy")
      out132020 <- rbind(out13, d2018)
      out142020 <- rbind(out14, d2012)}
    
    if (datasource_ids[1]==17) {
      d2016 <- data.frame("2016",NA,NA,NA,NA,NA,NA)
      names(d2016) <- c("increment","units","occupied","un_occup","vacant","vac_eff","vacancy")
      out132020 <- rbind(out13)
      out142020 <- rbind(out14, d2016)}
    
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
    ggsave(plotout, file= paste(pre,df$geozone[1],"_units_and_vacancy",suf,".pdf", sep=''),
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
mild.threshold.lower = round((quantiles_df$percent_vacancy[2] - (iqr * 1.5)),1)
mild.threshold.lower
ymin <- 0

# include all geographies including CPAs with less than 500 units
plot_outliers <- subset(vacancy, pc_vacancy_rate > mild.threshold.upper)
plot_outliers_list <- unique(plot_outliers$geozone)



#for(i in 1:length(geo_list)) {
for(i in 1:5) { # test plot loop for CPA outlier
  
    plotdat = subset(vacancy, vacancy$geozone==geo_list[i])
    
    ymax <- mild.threshold.upper
    
    if (geo_list[i]  %in% plot_outliers_list) {
      s = 'outlier'
    } else {
      s = ''
    }
    
    if (geo_list[i]  %in% outliers) {
      plotsuffix <- 'outlier'} 
    else {
      plotsuffix <- ''  
      }
    
    if (nrow(plotdat)==0) {
      next
    }
    
    if (plotdat$id[1] < 20 & plotdat$id[1] > 0) {
      fldr <- 'JUR'
      prefix <- '2'
      } else if (plotdat$id[1] > 19 & plotdat$id[1] < 1500) {
        fldr <- 'CityCPA'
        prefix <- '3'
      } else if (plotdat$id[1] > 1500 & plotdat$id[1] < 2000) {
          fldr <- 'CountyCPA'
          prefix <- '4'
      } else if (geo_list[i] == 'Not in a CPA') {
        fldr <- ''
        prefix <- '5'
    } else {
          fldr <- ''
          prefix <-'1'
    }
    
    if (geo_list[i] %in% outliers) {
      prefix <- paste('0outlier','_',prefix,sep='')}
    
    print(geo_list[i])
    vacancy_plot_all_in_one(plotdat,ymin,ymax,geo_list[i],s,prefix,plotsuffix)

  }

##############################################################
# create divider pdf pages
#############################################################

### first page - cover page

# count total number of unique geographies, jurisdictions, cpas 
totalgeo <- length(unique(vacancy$geozone))
geo0 <- subset(vacancy,units==0) # geographies w/ no residential units
geonot0 <- subset(vacancy,units!=0) # have residential units
n0 <- length(unique(subset(geo0,!(geozone %in% unique(geonot0$geozone)))$geozone))
nplots <- totalgeo - n0 # total number of plots
njur <- length(unique(subset(vacancy,geotype=='jurisdiction')$geozone))
ncpa <- length(unique(subset(vacancy,geotype=='cpa' & geozone != 'Not in a CPA')$geozone))

no_units_string <- paste( unique(subset(geo0,!(geozone %in% unique(geonot0$geozone) ))$geozone), 
                          collapse=",  "  )
coverlabel = textGrob("Vacancy Rate Plots for Region, Jurisdictions and CPAs\n",
                   x = unit(.1, "npc"), just = c("left"), 
                   gp = gpar(fontsize = 20))

sources = textGrob(paste("\n\nSource: Demographic Warehouse: ",datasource_names[2], 
                            " and ",datasource_names[1],sep=''),
                      x = unit(.1, "npc"), just = c("left"), 
                      gp = gpar(fontsize = 10))
plotout <- grid.arrange(
  grobs = list(coverlabel,sources),
  widths = c(1,1,1),
  heights = c(3,1,1,3),
  layout_matrix = rbind(c(NA,NA,NA),
                        c(1,1,1),
                        c(2,2,2),
                        c(NA,NA,NA)),
  bottom = textGrob(
    paste("Total geographies:",totalgeo,",  Total plots:",nplots,"    \n",
          "Count of geography by type:    ",
          "(cities including unincorporated = ",njur,
          ", cpas = ",ncpa,", region = 1",",  \'Not in a CPA\' = 1)   \n",
          "Excluded geo w no res units (n = ",n0,"): ",
          gsub('(.{1,70})(\\s|$)', '\\1    \n', no_units_string),sep=''),
    gp = gpar(fontface = 3, fontsize = 11),
    hjust = 1,
    x = 1
  ))
ggsave(plotout, file= paste("0AAACoverPage", ".pdf", sep=''),
       width=10, height=6, dpi=100)
# end first page
########################################################################

# outlier description page w boxplot and thresholds table

IQR_df <- read.csv(file="IQR.csv", header=TRUE, sep=",")

# outliers
outlier_string <- paste(sort(outliers),collapse=",  ")
# outlier description
outlierdef = textGrob(paste("Outliers defined as vacancy rate less than Q1-1.5*IQR or greater than Q3+1.5*IQR,\n",
                            "where Q1 and Q3 are the first and third quartile and IQR is the interquartile range\n",
                            "and units > 500",
                             sep=''),gp = gpar(fontsize = 10))
# list of outliers
outlierlist = textGrob(paste("Outliers (n=",length(outliers),"): ",
                      gsub('(.{1,70})(\\s|$)', '\\1\n', outlier_string ), # add line returns to string
                      sep=''),gp = gpar(fontsize = 10))
# list of outliers where units less than 500
vac2 <- subset(vacancy, series==datasource_names[2])
poutliers <- subset(vac2, pc_vacancy_rate > mild.threshold.upper)
poutlierslist <- unique(poutliers$geozone)
sm_outliers <- poutlierslist[!(poutlierslist %in% outliers)]
sm_outlierlist <- paste( sm_outliers, collapse=",  "  )

# create table w thresholds
tt <- ttheme_default(base_size = 8   ,colhead=list(fg_params = list(parse=TRUE)))
table <- tableGrob(IQR_df,theme=tt)
title <- textGrob("Vacancy Rate Thresholds for Outlier Identification",gp=gpar(fontsize=8))
footnote <- textGrob(paste("Outliers defined for geographies with units>500\n", 
                           "Threshold is Q1-1.5*IQR and Q3+1.5*IQR",
                      sep=''),
                     x=0, hjust=0,
                     gp=gpar( fontsize=6,fontface="italic"))
padding <- unit(0.5,"line")
table <- gtable_add_rows(table, 
                         heights = grobHeight(title) + padding,
                         pos = 0)
table <- gtable_add_rows(table, 
                         heights = grobHeight(footnote)+ padding)
table <- gtable_add_grob(table, list(title, footnote),
                         t=c(1, nrow(table)), l=c(1,2), 
                         r=ncol(table))

# create boxplot to show outliers
source = datasource_names[2]
boxplot_df <- subset(vacancy,series==source)
n <- length(unique(boxplot_df$geozone))
vacbox <- ggplot(boxplot_df, aes(x=as.factor(yr_id),y=pc_vacancy_rate)) + 
  geom_boxplot() + 
  labs(title=paste("Vacancy at Forecast Increments (n=",n," at each increment)",sep=''), 
       subtitle="Outliers shown as points on plot (whisker length is 1.5*IQR)",
       caption=paste("Source: Demographic Warehouse: ",source,sep=''),
       y="Vacancy %", x="Increment",
       color=NULL)  +
  theme(plot.title = element_text(size=8),
        plot.subtitle = element_text(size=6),
        plot.caption = element_text(size=6, face = "italic"))
# create outlier methodology page w boxplot and table
plotout <- grid.arrange(
  grobs = list(outlierdef,vacbox,table,outlierlist),
  widths = c(1, 1),
  heights = c(1,2,1),
  layout_matrix = rbind(c(1, 1),c(2, 3),c(4, 4)),
  top=paste("Outlier Methodology and Results",sep=''),
  bottom = textGrob(paste("Excluded outliers where units<500 (n = ",length(sm_outliers),"): ",
  gsub('(.{1,80})(\\s|$)', '\\1    \n', sm_outlierlist ),sep=''),gp = gpar(fontface = 3, fontsize = 8),
hjust = 1,
x = 1
))
ggsave(plotout, file= paste("0AACoverPage", ".pdf", sep=''),
       width=10, height=6, dpi=100)
# END outlier description page
###########################################################################

# create all other divider pages
create_divider_page <- function(section_name,idx) {
  pagetext <- textGrob(paste("\n\n\n                               ",
                             section_name,sep=''),
                       x = unit(.1, "npc"), just = c("left"), 
                       gp = gpar(fontsize = 12)) 
  file_output <- paste(idx,"AA",section_name,".pdf", sep='')
  ggsave(pagetext,file=file_output,width=10, height=6, dpi=100)
}

sectionnames <- c("Outliers","Region","Jurisdictions","City CPAs","County CPAs","NOT IN A CPA")

counter <- 0
for(aname in sectionnames) {
  create_divider_page(aname,counter)
  counter <- counter + 1
}

# output all data
write.csv(vacancy,"vacancy.csv")

