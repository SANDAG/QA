# check base year denisty variables in mgra file

# Variables to check: 
#   TotInt Total intersections 
#   DUDen Dwelling unit density 
#   EmpDen Employment density 
#   PopDen Population density 
#   RetEmpDen Retail employment density 
#   TotIntBin Total intersection bin 
#   EmpDenBin Employment density bin 
#   DuDenBin Dwelling unit density bin

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}
# "summarytools"
packages <- c("RODBC","tidyverse","gridExtra","grid")
pkgTest(packages)


# mgra13_based_input####.csv
input_file14 =  "T:\\socioec\\Current_Projects\\XPEF11\\abm_csv\\mgra13_based_input2016_02.csv" # series 14
input_file13 =  "T:\\devel\\sr13\\4Ds\\13_3_3\\2012\\mgra13_based_input2012_updated.csv" # series 13

# read series 14 base year file
mgra_base_yr_density_variables_series14 <- read.csv(input_file14, stringsAsFactors = FALSE)

# read series 13 base year file
mgra_base_yr_density_variables_series13 <- read.csv(input_file13, stringsAsFactors = FALSE)

# select only columns of interest before joining dataframes
d14 <- mgra_base_yr_density_variables_series14 %>% select(totint:dudenbin)
d14$source <- 'Series 14'
d13 <- mgra_base_yr_density_variables_series13 %>% select(totint:dudenbin)
d13$source <- 'Series 13'


############################################################################

# calculate summary statistics
my.summary <- function(x, na.rm=TRUE){
  result <- c(Mean=round(mean(x, na.rm=na.rm),2),
              SD=round(sd(x, na.rm=na.rm),2),
              Median=round(median(x, na.rm=na.rm),2),
              Min=round(min(x, na.rm=na.rm),0),
              Min_ne_0 =min(x[x != 0]), # minimum excluding zeros
              Max=round(max(x, na.rm=na.rm),2), 
              NAs = round(sum(is.na(x)),0),
              Zeros = round(sum(x==0),0),
              Count=round(length(x),0))
}


summarystat13 <- as.data.frame(sapply(d13[,1:5], my.summary))
summarystat13$series <- 'series13'
summarystat13$index <- 1
summarystat14 <- as.data.frame(sapply(d14[,1:5], my.summary))
summarystat14$series <- 'series14'
summarystat14$index <- 2

# make row names a column and remove row names
summarystat13  <- cbind(stats = rownames(summarystat13), summarystat13 )
rownames(summarystat13) <- NULL
summarystat14  <- cbind(stats = rownames(summarystat14), summarystat14 )
rownames(summarystat14) <- NULL
summarystat <- rbind(summarystat13,summarystat14)

# arrange descriptive statistics in format that is easy to plot
sr13_long <- gather(summarystat13, "variable","value",2:6) #variable,value,c(duden,empden,popden,totint,retempden))
sr13_wide <- spread(sr13_long,stats,value)
sr14_long <- gather(summarystat14, "variable","value",2:6) #variable,value,c(duden,empden,popden,totint,retempden))
sr14_wide <- spread(sr14_long,stats,value)
stats <- rbind(sr13_wide,sr14_wide)
diff <- merge(sr13_long,sr14_long, by = c('stats','variable'),suffixes =c(".series13",".series14"), sort = TRUE)
diff$difference <- diff$value.series14 - diff$value.series13
diff <- diff %>% select(stats,variable, difference)
diff_wide <- spread(diff,stats,difference)
diff_wide$series <- "difference"
diff_wide$index <- 3
stats <- rbind(stats,diff_wide)

#cleanup
rm(summarystat13,summarystat14)
rm(sr13_long,sr14_long,sr13_wide,sr14_wide)
rm(diff,diff_wide)
# order by stat
summarystat <- summarystat[order(summarystat$stats),]
# add column to sort variables

stats$variable_order <- 1
stats$variable_order[stats$variable=='empden'] <- 2
stats$variable_order[stats$variable=='duden'] <- 3
stats$variable_order[stats$variable=='retempden'] <- 4
stats$variable_order[stats$variable=='totint'] <- 5

# write output
outfolder = paste("..\\output",sep='')
dir.create(file.path(outfolder), showWarnings = FALSE)
setwd(file.path(outfolder))

# write.csv(summarystat,'summarystats.csv',row.names = F)
write.csv(stats,'stats.csv',row.names = F)

#cleanup
rm(summarystat)
rm(stats)

##############################################################################

# join dataframes for series 13 and series 14
dall_wide <- rbind(d14,d13)

rm(d14)
rm(d13)

##############################################################################

# check bin variables
# DuDenBin Dwelling unit density bin
# EmpDenBin Employment density bin 
# TotIntBin Total intersection bin

cut_into_bins <- function (r, df,density_variable,calculated_column,orig_bin_col,diff_col) {
  # cut column into bins
  df[[calculated_column]] <- cut(df[[density_variable]], ranges, labels=c(1,2,3), include.lowest=TRUE)
  # convert factor to numeric for each bin
  df[[calculated_column]] <- as.numeric(as.character(df[[calculated_column]]))
  # set bin to zero for condition where all other density variables equal zero
  df[[calculated_column]][(df$popden==0) & (df$duden==0) 
                        & (df$empden==0)  & (df$totintbin==0) ] <- 0
  # calculate difference between bin variable in file and calculated bin variable
  df[[diff_col]] <- as.numeric(df[[orig_bin_col]]) - as.numeric(df[[calculated_column]])
  return(df)
}

counts_per_bin <- function (df,density_variable,calculated_column,series,diff_column) {
  orig_counts <- df %>% group_by_(series,density_variable)  %>% tally()
  calculated_counts <- df %>% group_by_(series,calculated_column)  %>% tally()
  # rename variables before joining
  orig_counts <-  rename_(orig_counts, .dots = setNames(c("n",density_variable), c(density_variable,"bin"))) 
  calculated_counts <-  rename_(calculated_counts, .dots = setNames(c("n",calculated_column), c(calculated_column,"bin")))
  orig_and_calc_bins <- orig_counts  %>% inner_join(calculated_counts,by = c("source","bin"))
  orig_and_calc_bins[[diff_column]] <- orig_and_calc_bins[[density_variable]] - orig_and_calc_bins[[calculated_column]]
  # print(orig_counts)
  return(orig_and_calc_bins)
}

# cut denisty columns into 4 bins
ranges <- c(0,5,10,100000)
dall_wide <- cut_into_bins(ranges, dall_wide,"duden","dudenbin_QAcalculated","dudenbin","dudenbin_diff")
ranges <- c(0,10,30,100000)
dall_wide <- cut_into_bins(ranges, dall_wide,"empden","empdenbin_QAcalculated","empdenbin","empdenbin_diff")
ranges <- c(0,79.99,129.99,100000)
dall_wide <- cut_into_bins(ranges, dall_wide,"totint","totintbin_QAcalculated","totintbin","totintbin_diff")

# count rows per bin: 0-4
dudenbin_result <- counts_per_bin(dall_wide,"dudenbin","dudenbin_QAcalculated","source","dudenbin_diff")
empdenbin_result <- counts_per_bin(dall_wide,"empdenbin","empdenbin_QAcalculated","source","empdenbin_diff")
totintbin_result <- counts_per_bin(dall_wide,"totintbin","totintbin_QAcalculated","source","totintbin_diff")

# merge result tibbles
du_emp <- dudenbin_result %>% inner_join(empdenbin_result, by = c("source","bin"))
du_emp_totint <- du_emp %>% inner_join(totintbin_result, by = c("source","bin"))

# clean up
rm(du_emp)
rm(dudenbin_result)
rm(empdenbin_result)
rm(totintbin_result)

# add name of input file to results
du_emp_totint$input_file <- " "
du_emp_totint$input_file[du_emp_totint$source == 'Series 13'] <- input_file13
du_emp_totint$input_file[du_emp_totint$source == 'Series 14'] <- input_file14

# write output
outfolder = paste("..\\output",sep='')
dir.create(file.path(outfolder), showWarnings = FALSE)
setwd(file.path(outfolder))

# checks that the binning of the density variables was correct according 
# to the published ranges of the bins
# for dudenbin,empdenbin,totintbin 

# write.csv(du_emp_totint, file = "density_bin_column_QA.csv", row.names = F)

# double check results - there should be no rows where the difference is not zero
subset(dall_wide,dudenbin_diff!=0)
subset(dall_wide,empdenbin_diff!=0)
subset(dall_wide,totintbin_diff!=0)


# rearrange dataframe to compare series 13 and series 14
densityBins <- du_emp_totint %>% select(source,bin, dudenbin,empdenbin,totintbin)
densityBins_longformat <- gather(densityBins,density_var,value,c(dudenbin,empdenbin,totintbin))
densityBins_wideformat <- spread(densityBins_longformat,source,value)
densityBins_compare <- arrange(densityBins_wideformat, density_var, bin)
densityBins_compare['difference'] <- densityBins_compare['Series 14'] - densityBins_compare['Series 13']
densityBins_compare_long <- gather(densityBins_compare,series,value,c("Series 13","Series 14","difference"))
densityBins_compare_long$index <- 1
densityBins_compare_long$index[densityBins_compare_long$series=="Series 14"] <- 2
densityBins_compare_long$index[densityBins_compare_long$series=="difference"] <- 3
densityBins_compare_long$density.ranges <- 'Zero'
densityBins_compare_long$density.ranges[densityBins_compare_long$bin==1] <- 'Low'
densityBins_compare_long$density.ranges[densityBins_compare_long$bin==2] <- 'Medium'
densityBins_compare_long$density.ranges[densityBins_compare_long$bin==3] <- 'High'
densityBins_compare[['percent_change']] <- round(100* (densityBins_compare[['Series 14']] - densityBins_compare[['Series 13']])/densityBins_compare[['Series 13']],2)

rm(densityBins_longformat)
rm(densityBins_wideformat)

# keep code might be useful later
# compare_density_bins <- densityBins %>% 
#   gather(variable, value, -(source:bin)) %>%
#   unite(temp, source, variable) %>%
#   spread(temp, value)


#write.csv(densityBins_compare, file = "density_bin_compare_series13_series14.csv", row.names = F)
#write.csv(densityBins, file = "density_bin_variables_as_headers_13_14.csv", row.names = F)
write.csv(densityBins_compare_long, file = "density_bin_variables_long.csv", row.names = F)

#cleanup
rm(densityBins)
rm(densityBins_compare)
rm(densityBins_compare_long)
rm(du_emp_totint)
# rm(dall_wide)

#######################################################################################
# Create wide dataframe to calculate percent differences across mgras

d14a <- mgra_base_yr_density_variables_series14 %>% select(mgra,totint:retempden)
d13a <- mgra_base_yr_density_variables_series13 %>% select(mgra,totint:retempden)
d13_d14_wide <- merge(d13a, d14a, by=c("mgra"),suffixes = c(".series13",".series14"))

n <- 7L
# percent difference
percent_diffs <- d13_d14_wide
percent_diffs[,(dim(d13_d14_wide)[2]+ 1):(dim(d13_d14_wide)[2] + 5)] <- 
  sapply(n:dim(d13_d14_wide)[2], function(x) setNames(((abs(d13_d14_wide[x] - d13_d14_wide[x-5])) / d13_d14_wide[x-5]),
                                                      paste0("percentdiff_", names(d13a)[x-5])))
# add absolute difference
percent_diffs[,(dim(percent_diffs)[2]+ 1):(dim(percent_diffs)[2] + 5)] <- 
  sapply(n:dim(d13_d14_wide)[2], function(x) setNames(((abs(d13_d14_wide[x] - d13_d14_wide[x-5]))),
                                                      paste0("absdiff_", names(d13a)[x-5])))

head(percent_diffs)

write.csv(percent_diffs, file = "density_variables_series13_series14.csv",row.names = F)

rm(percent_diffs)


#######################################################################################

# Create long dataframe for histograms
d13aa <- plyr::rename(d13a, c("totint"="Total intersections","duden"="Dwelling unit density",
                       "empden"="Employment density","popden"="Population density",
                       "retempden"="Retail employment density")) 
d13aa$mgra <- NULL
d13_long <- gather(d13aa, density.variable, value, factor_key=TRUE)

d13_long$source <- 'Series 13'

d14aa <- plyr::rename(d14a, c("totint"="Total intersections","duden"="Dwelling unit density",
                              "empden"="Employment density","popden"="Population density",
                              "retempden"="Retail employment density")) 
d14aa$mgra <- NULL
d14_long <- gather(d14aa, density.variable, value, factor_key=TRUE)

d14_long$source <- 'Series 14'

histdata <- rbind(d13_long, d14_long)

#cleanup
rm(d13aa,d13_long,d14aa,d14_long,d14a,d13a)

#### DATA CHECKS #####################################################

# 5 variables x 23002 mgra x 2 series = 230020 rows in dataframe

# 1. check 23002 mgra values for each variable 
histdata  %>% group_by(source,density.variable) %>%  tally()

# 2. check 23002 sum # of NOT NA values
histdata %>% group_by(source,density.variable) %>% summarise_all(function(x) sum(!is.na(x)))
######################################################################

# PLOT DATA

options(scipen = 999)

# prepare data for plotting
data_for_plot <- function(df,plot_var,var_level) {
  plotdata <- subset(df,density.variable %in% c(plot_var))
  plotdata$density.sr13.sr14 <- plotdata$density.variable
  # add level to factor
  levels(plotdata$density.sr13.sr14) <- c(levels(plotdata$density.sr13.sr14),var_level)
  # add series 13 and 14 variable to plot
  plotdata$density.sr13.sr14[plotdata$density.variable==plot_var] <- var_level
  return(plotdata)
}

# count number of MGRAs in dataframe
countmgras <- function(df,plotvar,series) {
  countofrows <- length(which(df$density.variable==plotvar & df$source == series))
  return(countofrows)
}

# plot data
plot_for_loop <- function(df,count13,count14,xlabel1,xlabel2,title,plotname,num13x,num14x,plotcaption) {
  
  # plot series 13 and series 14 next to each other
  p1 <- ggplot(df,aes(value,fill=source)) + 
    geom_histogram(alpha=0.5,binwidth=1) + 
    facet_wrap(density.variable ~ source,ncol=2)
  # formatting
  p1 <- p1 + xlab(xlabel1) +
    ylab("MGRA count") +
    theme(legend.position = "none") +
    theme(legend.title = element_text(size=6, face="bold")) +
    theme(legend.text = element_text(size = 5)) +
    theme(axis.title.x = element_text(face="bold", size=8),
          axis.text.x  = element_text(angle=45, vjust=0.5, size=8)) +
    theme(axis.title.y = element_text(face="bold", size=8),
          axis.text.y  = element_text(vjust=0.5, size=8)) +
    theme(strip.text.x = element_text(size=8)) +
    labs(caption = plotcaption) +
    theme(plot.caption = element_text(size=6))
  
  # overlay plots series 13 and 14
  p2 <- ggplot(histdata_for_plots,aes(value,fill=source)) + 
    geom_histogram(alpha=0.5,binwidth=1,position="identity") + 
    facet_wrap(~density.sr13.sr14,ncol=1) 
  # formatting
  p2 <- p2 + xlab(xlabel2) +
    ylab("MGRA count") +
    theme(legend.position = "none") +
    theme(axis.title.x = element_text(face="bold", size=8),
          axis.text.x  = element_text(angle=45, vjust=0.5, size=8)) +
    theme(axis.title.y = element_text(face="bold", size=8),
          axis.text.y  = element_text(vjust=0.5, size=8)) +
    theme(strip.text.x = element_text(size=8)) +
    labs(caption = paste("# excluded: ",num13x,' sr13 & ',num14x,' sr14',sep='')) +
    theme(plot.caption = element_text(size=6))
  
  g <- grid.arrange(p1, p2,widths = c(2,1), nrow = 1, 
                    top = textGrob(paste(title,
                                         "n=",count13," sr13","    n=",count14," sr14",sep=''),
                                   gp=gpar(fontsize=12,font=3)))
  
  ggsave(file=plotname, g,width = 6, 
         height = 4, dpi = 1000, units = "in", device='png') #saves g
  
  
}

# count number of MGRAs in dataframe
lengthremoved <- function(df,cutoff,densityvar,series) {
  countofrows <- length(which(df$value < cutoff & df$density.variable==densityvar & df$source == series))
  return(countofrows)
}
# count number of MGRAs in dataframe
lengthkept <- function(df,cutoff,densityvar,series) {
  countofrows <- length(which(df$value >= cutoff & df$density.variable==densityvar & df$source == series))
  return(countofrows)
}


########### PLOTS for population density
density_cutoff <- 0
variable_to_plot <- "Population density"
axis_label <- "Population Density (population per acre)"
title_to_plot <- "Population Density by MGRA (population per acre)\n"
level_to_add <- "Population density\n\nSeries 13 & Series 14"
plotout <- paste(variable_to_plot,"all.png",sep='')
histdata_for_plots <- data_for_plot(histdata,variable_to_plot,level_to_add)
num13 <- countmgras(histdata_for_plots,variable_to_plot,'Series 13')
num14 <- countmgras(histdata_for_plots,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- "* includes all MGRAs"
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)

# only plot values 1 or greater
plotout <- paste(variable_to_plot,"magnify.png",sep='')
density_cutoff <- 1
num13 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
num14 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- paste("* excludes MGRAs where ", variable_to_plot," < ",density_cutoff,sep='')
histdata_for_plots <- subset(histdata_for_plots,value >= density_cutoff)
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)


########### PLOTS for dwelling unit density
density_cutoff <- 0
variable_to_plot <- "Dwelling unit density"
axis_label <- "Dwelling unit Density (dwelling unit per acre)"
title_to_plot <- "Dwelling unit Density by MGRA (dwelling unit per acre)\n"
level_to_add <- "Dwelling unit density\n\nSeries 13 & Series 14"
plotout <- paste(variable_to_plot,"all.png",sep='')
histdata_for_plots <- data_for_plot(histdata,variable_to_plot,level_to_add)
num13 <- countmgras(histdata_for_plots,variable_to_plot,'Series 13')
num14 <- countmgras(histdata_for_plots,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- "* includes all MGRAs"
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)

# only plot values 1 or greater
plotout <- paste(variable_to_plot,"magnify.png",sep='')
density_cutoff <- 1
num13 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
num14 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- paste("* excludes MGRAs where ", variable_to_plot," < ",density_cutoff,sep='')
histdata_for_plots <- subset(histdata_for_plots,value >= density_cutoff)
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)


########### PLOTS for interesections 
density_cutoff <- 0
variable_to_plot <- "Total intersections"
axis_label <- "Total intersections"
title_to_plot <- "Total Intersections by MGRA (per 1/2 mile buffer around mgra)\n"
level_to_add <- "Total intersections\n\nSeries 13 & Series 14"
plotout <- paste(variable_to_plot,"all.png",sep='')
histdata_for_plots <- data_for_plot(histdata,variable_to_plot,level_to_add)
num13 <- countmgras(histdata_for_plots,variable_to_plot,'Series 13')
num14 <- countmgras(histdata_for_plots,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- "* includes all MGRAs"
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)

# only plot values 1 or greater
plotout <- paste(variable_to_plot,"magnify.png",sep='')
density_cutoff <- 1
num13 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
num14 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- paste("* excludes MGRAs where ", variable_to_plot," < ",density_cutoff,sep='')
histdata_for_plots <- subset(histdata_for_plots,value >= density_cutoff)
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)


########### PLOTS for Employment density
density_cutoff <- 0
variable_to_plot <- "Employment density"
axis_label <- "Employment density (employees per acre)"
title_to_plot <- "Employment density by MGRA (employees per acre)\n"
level_to_add <- "Employment density\n\nSeries 13 & Series 14"
plotout <- paste(variable_to_plot,"all.png",sep='')
histdata_for_plots <- data_for_plot(histdata,variable_to_plot,level_to_add)
num13 <- countmgras(histdata_for_plots,variable_to_plot,'Series 13')
num14 <- countmgras(histdata_for_plots,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- "* includes all MGRAs"
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)

# only plot values 1 or greater
plotout <- paste(variable_to_plot,"magnify.png",sep='')
density_cutoff <- 1
num13 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
num14 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- paste("* excludes MGRAs where ", variable_to_plot," < ",density_cutoff,sep='')
histdata_for_plots <- subset(histdata_for_plots,value >= density_cutoff)
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)


########### PLOTS for Retail Employment density
density_cutoff <- 0
variable_to_plot <- "Retail employment density"
axis_label <- "Retail employment density (retail employees per acre)"
title_to_plot <- "Retail employment density by MGRA (retail employees per acre)\n"
level_to_add <- "Retail employment density\n\nSeries 13 & Series 14"
plotout <- paste(variable_to_plot,"all.png",sep='')
histdata_for_plots <- data_for_plot(histdata,variable_to_plot,level_to_add)
num13 <- countmgras(histdata_for_plots,variable_to_plot,'Series 13')
num14 <- countmgras(histdata_for_plots,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- "* includes all MGRAs"
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)

# only plot values 1 or greater
plotout <- paste(variable_to_plot,"magnify.png",sep='')
density_cutoff <- 1
num13 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
num14 <- lengthkept(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
removed13 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 13')
removed14 <- lengthremoved(histdata_for_plots,density_cutoff,variable_to_plot,'Series 14')
captiontoplot <- paste("* excludes MGRAs where ", variable_to_plot," < ",density_cutoff,sep='')
histdata_for_plots <- subset(histdata_for_plots,value >= density_cutoff)
plot_for_loop(histdata_for_plots,num13,num14,axis_label,variable_to_plot,
              title_to_plot,plotout,removed13,removed14,captiontoplot)


