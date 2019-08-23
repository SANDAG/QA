

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","gridExtra","grid","scales")
pkgTest(packages)



channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#create dataframes
 hhp <- data.frame()
 sourcename <- data.frame()
 hh <- data.frame()

 for(i in 1:length(datasource_ids)) {
   # get the name of the datasource
   datasource_name <- readDB("../Queries/datasource_name.sql",datasource_ids[i])
   sourcename <- rbind(sourcename,datasource_name)
 
   # get hhpop data
   hh <- readDB("../Queries/hh_hhp_hhs_ds_id.sql",datasource_ids[i])
   hh$datasource_id = datasource_ids[i]
   hh$series = datasource_names[i]
   hhp <- rbind(hhp,hh)
 }

# get cpa id
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_ids[i])
odbcClose(channel)

rm(hh)

# fix names of sr13 cpas to match sr14 cpas
hhp <- rename_sr13_cpas(hhp)

hhp <- subset(hhp, yr_id==2012 | yr_id==2016 | yr_id==2018 | yr_id==2020 | yr_id==2025 | yr_id==2030 | yr_id==2035 | yr_id==2040 | yr_id==2045 | yr_id==2050)

hhp <- hhp %>% select(datasource_id,yr_id,geotype,geozone,hhp,series)

# remove special characters like * from names of cpas
hhp <- rm_special_chr(hhp)
hhp <- subset(hhp,geozone != 'Not in a CPA')


head(hhp)
hhp <- hhp[order(hhp$datasource_id,hhp$geotype,hhp$geozone,hhp$yr_id),]
hhp$N_chg <- ave(hhp$hhp, factor(hhp$geozone), FUN=function(x) c(NA,diff(x)))
hhp$N_pct <- (hhp$N_chg / lag(hhp$hhp))*100
hhp$N_pct <- round(hhp$N_pct, digits = 2)

# write.csv(hhp,'hhp.csv')


hhp$N_chg[hhp$yr_id == 2012] <- 0
hhp$N_pct[hhp$yr_id == 2012] <- 0
hhp$N_chg[hhp$yr_id == 2016] <- 0
hhp$N_pct[hhp$yr_id == 2016] <- 0
hhp$N_pct[is.nan(hhp$N_pct)] <- 0


hhp_region = subset(hhp,geotype=='region')

hhp_region <- hhp_region %>% rename('reg'= N_chg,'regN' = hhp, 'regN_pct' = N_pct)
region <- hhp_region %>% select(datasource_id,yr_id,regN,reg,regN_pct)
#merge(hhp,hhp_region)
hhpmerge <- merge(x = hhp, y = region ,by = c("datasource_id","yr_id"), all = TRUE)
hhpmerge$plotlegend <- paste(hhpmerge$series,' Region HHPop change',sep='')

colnames(hhp_region)[colnames(hhp_region)=="geozone"] <- "SanDiegoRegion"

hhp_jur = subset(hhpmerge,geotype=='jurisdiction')
colnames(hhp_jur)[colnames(hhp_jur)=="geozone"] <- "cityname"

hhp_cpa = subset(hhpmerge,geotype=='cpa')
colnames(hhp_cpa)[colnames(hhp_cpa)=="geozone"] <- "cpaname"

# hhp_jur$reg<-hhp_region[match(hhp_jur$yr_id, hhp_region$yr_id) & match(hhp_jur$datasource_id, hhp_region$datasource_id),"N_chg"]
# hhp_cpa$reg<-hhp_region[match(hhp_cpa$yr_id, hhp_region$yr_id) & match(hhp_jur$datasource_id, hhp_region$datasource_id),"N_chg"]
# 
# hhp_jur$regN<-hhp_region[match(hhp_jur$yr_id, hhp_region$yr_id) & match(hhp_jur$datasource_id, hhp_region$datasource_id),"hhp"]
# hhp_cpa$regN<-hhp_region[match(hhp_cpa$yr_id, hhp_region$yr_id) & match(hhp_jur$datasource_id, hhp_region$datasource_id),"hhp"]
# 
# hhp_jur$regN_pct<-hhp_region[match(hhp_jur$yr_id, hhp_region$yr_id) & match(hhp_jur$datasource_id, hhp_region$datasource_id),"N_pct"]
# hhp_cpa$regN_pct<-hhp_region[match(hhp_cpa$yr_id, hhp_region$yr_id) & match(hhp_jur$datasource_id, hhp_region$datasource_id),"N_pct"]

##test Dave's qa parameters

#create subset of cases
hhp_change <- subset(hhp, N_chg>7500 & N_pct>20.0)
#create unique list of geozone that are within parameters
hhp_chg_geos <- unique(hhp_change$geozone)
#create dataset with all records for geozone within parameters
hhp_out_of_range <- hhp [hhp$geozone %in% hhp_chg_geos,]

write.csv(hhp_out_of_range,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 8\\hhp_out_of_range.csv", row.names=FALSE)



maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hh_pop\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

##Jurisdiction

hhp_jur$year<- "y"
hhp_jur$yr <- as.factor(paste(hhp_jur$year, hhp_jur$yr, sep = ""))
hhp_jur$N <-  hhp_jur$hhp

jur_list = unique(hhp_jur[["cityname"]])


for(i in jur_list) { #1:length(unique(hhp_jur[["cityname"]]))){
  plotdat = subset(hhp_jur, hhp_jur$cityname==i)
  # plotdat = subset(plotdat, datasource_id==29)
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr_id, y=N_chg,fill=cityname)) +
    geom_bar(stat = "identity") + 
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    geom_line(aes(y = reg/ravg, group=1,colour = plotlegend),size=2) +
    labs(title=paste("Change in Household Population\n ", i,' and Region',sep=''), 
         y=paste("Change in ",i,sep=''), x="Year",
         caption=paste("Sources: Demographic Warehouse\n datasource_id= ",
                       datasource_ids[1]," and ",datasource_ids[2],sep='')) + 
    theme_bw(base_size = 14) +
    theme(axis.title.y = element_text(face = "bold", size = 16),
          #plot.background = element_rect(fill = "#FED633"),
          plot.title = element_text(hjust = 0.5),
          panel.grid.major = element_line(linetype = "dashed"),
          panel.grid.minor = element_line(linetype = "dotted"),
          legend.title = element_blank(),
          # axis.text.y = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1) ) +
    scale_fill_manual(values = c("blue", "red"))   +
    guides(fill = guide_legend(order = 1))+ facet_grid(. ~ series) 
    
  
    # theme(legend.position = "bottom",legend.title=element_blank()) +
    
    #output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct,plotdat$series)
    output_table <- plotdat %>% select("yr_id","hhp","N_chg","N_pct","regN","reg","regN_pct","series")
    
    outt <- output_table %>% complete(series, nesting(yr_id))  
    outt <- outt[order(outt$yr_id),] # order by year
    # outt$name <- NULL # remove name (e.g. Barrio Logan)
    
    
    lefttable <- subset(outt,series==datasource_names[1])
    righttable <- subset(outt,series==datasource_names[2])
    names(lefttable)[names(lefttable)=="increment"] <- datasource_name_short[1]
    names(righttable)[names(righttable)=="increment"] <- datasource_name_short[2]
    lefttable$series <- NULL
    righttable$series <- NULL
    tt <- ttheme_default(base_size = 7,colhead=list(fg_params = list(parse=TRUE)))
    tbl1 <- tableGrob(lefttable, rows=NULL, theme=tt)
    tbl2 <- tableGrob(righttable, rows=NULL, theme=tt)  
    lay <- rbind(c(1,1,1,1),
                 c(1,1,1,1),
                 c(1,1,1,1),
                 c(2,2,3,3),
                 c(2,2,3,3))
    output<-grid.arrange(plot,tbl1,tbl2,ncol=2,as.table=TRUE,layout_matrix=lay)
    
 ggsave(output, file= paste(results, 'total household pop', i, datasource_ids[2],".png", sep=''),
         width=10, height=8, dpi=100)#, scale=2)
}

##cpa

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hh_pop\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


hhp_cpa$year<- "y"
hhp_cpa$yr <- as.factor(paste(hhp_cpa$year, hhp_cpa$yr, sep = ""))
hhp_cpa$N <-  hhp_cpa$hhp

cpa_list = unique(hhp_cpa[["cpaname"]])

for(i in cpa_list) { 
  plotdat = subset(hhp_cpa, hhp_cpa$cpaname==i)
  # plotdat = subset(plotdat, datasource_id==29)
  ravg = max(plotdat$reg,na.rm=TRUE)/max(plotdat$N_chg,na.rm=TRUE)
  ravg[which(!is.finite(ravg))] <- 0
  plot<-ggplot(plotdat,aes(x=yr_id, y=N_chg,fill=cpaname)) +
    geom_bar(stat = "identity") + 
    scale_y_continuous(label=comma,sec.axis = 
                         sec_axis(~.*ravg, name = "Chg Region",label=comma)) +
    geom_line(aes(y = reg/ravg, group=1,colour = plotlegend),size=2) +
    labs(title=paste("Change in Household Population\n ", i,' and Region',sep=''), 
         y=paste("Change in ",i,sep=''), x="Year",
         caption=paste("Sources: Demographic Warehouse\n datasource_id= ",
                       datasource_ids[1]," and ",datasource_ids[2],sep='')) + 
    theme_bw(base_size = 14) +
    theme(axis.title.y = element_text(face = "bold", size = 16),
          #plot.background = element_rect(fill = "#FED633"),
          plot.title = element_text(hjust = 0.5),
          panel.grid.major = element_line(linetype = "dashed"),
          panel.grid.minor = element_line(linetype = "dotted"),
          legend.title = element_blank(),
          # axis.text.y = element_blank(),
          axis.text.x = element_text(angle = 45, hjust = 1) ) +
    scale_fill_manual(values = c("blue", "red"))   +
    guides(fill = guide_legend(order = 1))+ facet_grid(. ~ series) 
  
  
  # theme(legend.position = "bottom",legend.title=element_blank()) +
  
  #output_table<-data.frame(plotdat$yr_id,plotdat$hhp,plotdat$N_chg,plotdat$N_pct,plotdat$regN,plotdat$reg,plotdat$regN_pct,plotdat$series)
  output_table <- plotdat %>% select("yr_id","hhp","N_chg","N_pct","regN","reg","regN_pct","series")
  
  outt <- output_table %>% complete(series, nesting(yr_id))  
  outt <- outt[order(outt$yr_id),] # order by year
  # outt$name <- NULL # remove name (e.g. Barrio Logan)
  
  
  lefttable <- subset(outt,series==datasource_names[1])
  righttable <- subset(outt,series==datasource_names[2])
  names(lefttable)[names(lefttable)=="increment"] <- datasource_name_short[1]
  names(righttable)[names(righttable)=="increment"] <- datasource_name_short[2]
  lefttable$series <- NULL
  righttable$series <- NULL
  tt <- ttheme_default(base_size = 7,colhead=list(fg_params = list(parse=TRUE)))
  tbl1 <- tableGrob(lefttable, rows=NULL, theme=tt)
  tbl2 <- tableGrob(righttable, rows=NULL, theme=tt)  
  lay <- rbind(c(1,1,1,1),
               c(1,1,1,1),
               c(1,1,1,1),
               c(2,2,3,3),
               c(2,2,3,3))
  output<-grid.arrange(plot,tbl1,tbl2,ncol=2,as.table=TRUE,layout_matrix=lay)
  
  ggsave(output, file= paste(results, 'total household pop', i, datasource_ids[2],".png", sep=''),
         width=10, height=8, dpi=100)#, scale=2)
} 





