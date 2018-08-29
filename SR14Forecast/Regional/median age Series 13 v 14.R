#compare Series 13 to Series 14
#run median_age_13.R and median_age_14.R before running this

rm(list = ls(all=TRUE))


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)


#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))



median_age_cpa_13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_cpa_13.csv")
median_age_jur_13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_jur_13.csv")
median_age_region_13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_13.csv")

median_age_cpa_14<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_cpa.csv")
median_age_jur_14<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age_jur.csv")
median_age_region_14<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\median_age.csv")

setnames(median_age_cpa_13, old=c("median_age"),new=c("median_age_13"))
setnames(median_age_cpa_14, old=c("median_age"),new=c("median_age_14"))

median_age_cpa <- merge(median_age_cpa_13, median_age_cpa_14, by.a=c("yr_id", "geozone"), by.b=c("yr_id", "geozone"), all=TRUE)
median_age_cpa$diff<-median_age_cpa$median_age_14-median_age_cpa$median_age_13

setnames(median_age_jur_13, old=c("median_age"),new=c("median_age_13"))
setnames(median_age_jur_14, old=c("median_age"),new=c("median_age_14"))

median_age_jur <- merge(median_age_jur_13, median_age_jur_14, by.a=c("yr_id", "geozone"), by.b=c("yr_id", "geozone"), all=TRUE)
median_age_jur$diff<-median_age_jur$median_age_14-median_age_jur$median_age_13

setnames(median_age_region_13, old=c("median_age"),new=c("median_age_13_region"))
setnames(median_age_region_14, old=c("median_age"),new=c("median_age_14_region"))

median_age_region <- merge(median_age_region_13, median_age_region_14, by.a=c("yr_id", "geozone"), by.b=c("yr_id", "geozone"), all=TRUE)
median_age_region$diff<-median_age_region$median_age_14_region-median_age_region$median_age_13_region

median_age_region <- merge(median_age_region_13, median_age_region_14, by.a=c("yr_id", "geozone"), by.b=c("yr_id", "geozone"), all=TRUE)
median_age_region$diff<-median_age_region$median_age_14_region-median_age_region$median_age_13_region

median_age_cpa1=cbind.data.frame(median_age_cpa$yr_id, median_age_region$yr_id)

median_age_cpa1=merge(median_age_cpa, median_age_region, by="yr_id", all=TRUE)

head(median_age_cpa1)

median_age_cpa$median_age_13_region<-median_age_13_region[match(paste(median_age_cpa$yr_id, median_age_cpa$geozone), paste(median_age_region$yr_id, median_age_region$geozone)), 6]

head(median_age_region)


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\Median_Age_13\\jur"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)



#this creates the list for "i" which is what the loop relies on - like x in a do repeat
jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

head(median_age_jur)
citynames <- data.frame(jur_list, jur_list2)
median_age_jur$jurisdiction_id<-citynames[match(median_age_jur$geozone, citynames$jur_list2),1]
median_age_jur$reg<-median_age_region[match(median_age_jur$yr_id, median_age_region$yr_id),3]

#this is the loop with the subset, the ggplot and the ggsave commands

for(i in 1:length(jur_list)){
  plotdat = subset(median_age_jur, median_age_jur$jurisdiction_id==jur_list[i])
  plot<-ggplot(plotdat,aes(x=yr_id, y=median_age, colour=geozone)) +
    geom_line(size=1)+ 
    geom_line(aes(x=yr_id, y = reg, colour = "Region")) +
    scale_y_continuous(label=comma,limits=c(30.0,47.0))+ 
    labs(title=paste("Median Age ", jur_list2[i],' and\n Region, 2016-2050',sep=''), 
         y=" median age", x="Year",
         caption="Sources: demographic warehouse: dbo.compute_median_age_all_zones 16\nNote:Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
    scale_colour_manual(values = c("blue", "red")) +
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  ggsave(plot, file= paste(results, 'median_age', jur_list[i], ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$median_age,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.median_age","plotdat.reg"),new=c("Year","Jurisdiction Median Age","Region Median Age"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'median_age', jur_list[i], ".png", sep=''))#, scale=2)
}


#median age cpa


#############
head(median_age_cpa)
#cpa with missing data for one or more years - 1401, 1439, 1491, 1911,1483
#this creates the list for "i" which is what the loop relies on 

cpa_list<-unique(median_age_cpa$geozone)

results<-"plots\\Median_Age_13\\cpa"
#median_age_cpa <-subset(unittype_cpa,unittype==0)

median_age_cpa$reg<-median_age_region[match(median_age_cpa$yr_id, median_age_region$yr_id),3]

for(i in 1:length(cpa_list)){
  plotdat = subset(median_age_cpa, median_age_cpa$geozone==cpa_list[i])
  plot<-ggplot(plotdat,aes(x=yr_id, y=median_age, colour=geozone)) +
    geom_line(size=1)+ 
    geom_line(aes(x=yr_id, y = reg, colour = "Region")) +
    scale_y_continuous(label=comma,limits=c(25.0,48.0))+ 
    labs(title=paste("Median Age ", cpa_list[i],' and\n Region, 2016-2050',sep=''), 
         y=" median age", x="Year",
         caption="Sources: demographic warehouse: dbo.compute_median_age_all_zones 16\nNote:Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
    scale_colour_manual(values = c("blue", "red")) +
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  ggsave(plot, file= paste(results, 'median_age', cpa_list[i], ".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$median_age,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.median_age","plotdat.reg"),new=c("Year","CPA Median Age","Region Median Age"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'median_age', cpa_list[i], ".png", sep=''))#, scale=2)
}



