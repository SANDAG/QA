pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
dem_sql = getSQL("../Queries/age_ethn_gender.sql")
dem<-sqlQuery(channel,dem_sql)
odbcClose(channel)

head(dem)
dem<- dem[order(dem$geotype,dem$geozone,dem$yr_id),]
write.csv(dem, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\dem_test.csv" )

dem$geozone<-revalue(dem$geozone, c("Los Penasquitos Canyon Preserve" = "Los Penas. Can. Pres."))

#aggregate total counts by year for age, gender and ethnicity
dem_age<-aggregate(pop~age_group_id+yr_id, data=dem, sum)
dem_gender<-aggregate(pop~sex_id+yr_id, data=dem, sum)
dem_ethn<-aggregate(pop~ethnicity_id+yr_id, data=dem, sum)

#calculate total change and percent change by year for age, gender and ethnicity
dem_age <- dem_age[order(dem_age$age_group_id,dem_age$yr_id),]
dem_age$N_chg <- dem_age$pop - lag(dem_age$pop)
dem_age$N_pct <- (dem_age$N_chg / lag(dem_age$pop))*100
dem_age$N_pct<-sprintf("%.2f",dem_age$N_pct)

head(dem_gender)
dem_gender <- dem_gender[order(dem_gender$sex_id,dem_gender$yr_id),]
dem_gender$N_chg <- dem_gender$pop - lag(dem_gender$pop)
dem_gender$N_pct <- (dem_gender$N_chg / lag(dem_gender$pop))*100
dem_gender$N_pct<-sprintf("%.2f",dem_gender$N_pct)

head(dem_ethn)
dem_ethn <- dem_ethn[order(dem_ethn$ethnicity_id,dem_ethn$yr_id),]
dem_ethn$N_chg <- dem_ethn$pop - lag(dem_ethn$pop)
dem_ethn$N_pct <- (dem_ethn$N_chg / lag(dem_ethn$pop))*100
dem_ethn$N_pct<-sprintf("%.2f",dem_ethn$N_pct)



#recode NA values for 2016 perchange
dem_age$N_chg[dem_age$yr_id == 2016] <- 0
dem_age$N_pct[dem_age$yr_id == 2016] <- 0




dem_jur = subset(dem,geotype=='jurisdiction')
colnames(dem_jur)[colnames(dem_jur)=="geozone"] <- "cityname"

dem_cpa = subset(dem,geotype=='cpa')
colnames(dem_cpa)[colnames(dem_cpa)=="geozone"] <- "cpaname"

dem_region = subset(dem,geotype=='region')
colnames(dem_region)[colnames(dem_region)=="geozone"] <- "SanDiegoRegion"

dem_jur$regN_chg<-dem_region[match(dem_jur$yr_id, dem_region$yr_id),7]
dem_cpa$regN_chg<-dem_region[match(dem_cpa$yr_id, dem_region$yr_id),7]

dem_jur$regN<-dem_region[match(dem_jur$yr_id, dem_region$yr_id),4]
dem_cpa$regN<-dem_region[match(dem_cpa$yr_id, dem_region$yr_id),4]

dem_jur$regN_pct<-dem_region[match(dem_jur$yr_id, dem_region$yr_id),8]
dem_cpa$regN_pct<-dem_region[match(dem_cpa$yr_id, dem_region$yr_id),8]

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\dem\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

dem_jur$year<- "y"
dem_jur$yr <- as.factor(paste(dem_jur$year, dem_jur$yr, sep = ""))
dem_jur$N <-  dem_jur$households


write.csv(dem_region, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\dem_region.csv" )
write.csv(dem_jur, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\dem_jur.csv" )
write.csv(dem_cpa, "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\dem_cpa.csv" )


jur_list = unique(dem_jur[["cityname"]])

for(i in jur_list) { #1:length(unique(dem_jur[["cityname"]]))){
  plotdat = subset(dem_jur, dem_jur$cityname==i)
  ravg = max(plotdat$regN,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = regN/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
         caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=14")+
    scale_fill_manual(values = c("red", "blue"))+
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 7))
  #ggsave(plot, file= paste(results, 'unittype_jur', jur_list[i], ".png", sep=''))
  output_table<-data.frame(plotdat$yr_id,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$regN_chg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr_id == 'y2016'] <- ''
  output_table$plotdat.regN_chg[output_table$plotdat.yr_id == 'y2016'] <- ''
  demtitle = paste("dem ",i,sep='')
  setnames(output_table, old=c("plotdat.yr_id","plotdat.N","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.regN_chg",
                               "plotdat.regN_pct"),new=c("Year",demtitle,"Chg", "Pct","dem Region","Chg","Pct"))
  tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
    lay <- rbind(c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(2,2,2,2,2),
                 c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'households', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



dem_cpa$year<- "y"
dem_cpa$yr <- as.factor(paste(dem_cpa$year, dem_cpa$yr, sep = ""))
dem_cpa$N <-  dem_cpa$households

cpa_list = unique(dem_cpa[["cpaname"]])

results<-"plots\\dem\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in cpa_list) { 
  plotdat = subset(dem_cpa, dem_cpa$cpaname==i)
  ravg = max(plotdat$regN,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 1
  plot<-ggplot(plotdat,aes(x=yr, y=N_chg,fill=cpaname)) +
    geom_bar(stat = "identity") +
    geom_line(aes(y = regN/ravg, group=1,colour = "Region"),size=2) +
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg in Region",label=comma)) +
    labs(title=paste("Change in Number of Households\n ", i,' and Region',sep=''), 
         y=paste("Chg in ",i,sep=''), x="Year",
    caption="Sources: demographic_warehouse.fact.population\n demographic_warehouse.dim.mgra\n housing.datasource_id=14")+
    scale_fill_manual(values = c("blue", "red"))+
    guides(fill = guide_legend(order = 1))+
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption=element_text(size=7))
  output_table<-data.frame(plotdat$yr_id,plotdat$N,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$regN_chg,plotdat$regN_pct)
  output_table$plotdat.N_chg[output_table$plotdat.yr == 'y2016'] <- ''
  output_table$plotdat.regN_chg[output_table$plotdat.yr == 'y2016'] <- ''
  demtitle = paste("dem", "\n","in ",i)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.N","plotdat.N_chg","plotdat.N_pct","plotdat.regN","plotdat.regN_chg",
                               "plotdat.regN_pct"),new=c("Year",demtitle,"Chg", "Pct","dem Region","Chg","Pct"))
  tt <- ttheme_default(base_size=8,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
 
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(output, file= paste(results, 'households', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}
