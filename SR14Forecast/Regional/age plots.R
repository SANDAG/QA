#age category plots

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable", "openxlsx")
pkgTest(packages)


age_cpa<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 3\\dem_age_cpa.csv" )
age_jur<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 3\\dem_age_jurisdiction.csv" )
age_reg<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 3\\dem_age_region.csv" )
age_cpa_13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13_cpa.csv" )
age_jur_13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13_jurisdiction.csv" )
age_reg_13<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\dem_age13_region.csv" )

head(age_jur)
head(age_reg)
head(age_jur_13)
head(age_reg_13)
table(age_jur$Year)
head(age_reg)
table(age_jur_13$Year)
head(age_reg_13)



#check column number for region number
age_jur$reg<-age_reg[match(age_jur$yr_id, age_reg$yr_id),9]


vac_jur$reg<-vac_region[match(vac_jur$yr_id, vac_region$yr_id),8]

##Jurisdiction plots and tables



jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")

citynames <- data.frame(jur_list, jur_list2)
vac_jur$jurisdiction_id<-citynames[match(vac_jur$geozone, citynames$jur_list2),1]
vac_jur$reg<-vac_region[match(vac_jur$yr_id, vac_region$yr_id),9]


for(i in jur_list) { 
  plotdat = subset(vac_jur, vac_jur$jurisdiction_id==jur_list[i])
  plot<- ggplot(plotdat, aes(x=yr_id, y=rate, colour=geozone))+
    geom_line(size=1)+
    geom_line(aes(x=yr_id, y=reg, colour="Region")) +
    scale_y_continuous(labels = comma, limits=c(0,10))+
    labs(title=paste("Effective Vacancy Rate ", jur_list2[i],'\nand Region, 2016-2050',sep=""),
         caption="Source: demographic_warehouse: fact.housing,dim.mgra, dim.structure_type\nhousehold.datasource_id = 16\nNotes:Unoccupiable units are not included. Out of range data may not appear on the plot.\nRefer to the table below for those related data results.",
         y="Vacancy Rate", 
         x="Year")+
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  ggsave(plot, file= paste(results, 'vacancy', jur_list2[i], "16 Effective.png", sep=''))#, scale=2)
  #sortdat <- plotdat[order(plotdat$geozone,plotdat$yr_id),]
  output_table<-data.frame(plotdat$yr_id,plotdat$unoccupiable,plotdat$rate,plotdat$reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.unoccupiable","plotdat.rate","plotdat.reg"),new=c("Year","Unoccupiable","Jur Vac Rate","Reg Vac Rate"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  #tt <- ttheme_default(core = list(fg_params=list(cex = 1.0)),
  #                    colhead = list(fg_params=list(cex = 1.0)),
  #                   rowhead = list(fg_params=list(cex = 1.0)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results,'vacancy',jur_list2[i], "16 Effective.png", sep=''))#, scale=2))
}

head(plotdat)

#####################
