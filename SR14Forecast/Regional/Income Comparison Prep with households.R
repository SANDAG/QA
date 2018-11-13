pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#bring data in from SQL
#channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=data_cafe; trusted_connection=true')
#geo_sql = getSQL("../Queries/geography.sql")
#geography<-sqlQuery(channel,geo_sql)
#odbcClose(channel)

options('scipen'=10)

inc_abm_13_2020_test<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2020\\mgra13_based_input2020.csv", stringsAsFactors = FALSE)
#inc_abm_13_2025<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2025\\mgra13_based_input2025.csv", stringsAsFactors = FALSE)
#inc_abm_13_2035<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2035\\mgra13_based_input2035.csv", stringsAsFactors = FALSE)
#inc_abm_13_2050<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2050\\mgra13_based_input2050.csv", stringsAsFactors = FALSE)


inc_abm_13_2020<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2020\\households.csv", stringsAsFactors = FALSE)
inc_abm_13_2025<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2025\\households.csv", stringsAsFactors = FALSE)
inc_abm_13_2035<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2035\\households.csv", stringsAsFactors = FALSE)
inc_abm_13_2050<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2050\\households.csv", stringsAsFactors = FALSE)


inc_abm_13_2020$yr = 2020
inc_abm_13_2025$yr = 2025
inc_abm_13_2035$yr = 2035
inc_abm_13_2050$yr = 2050

inc_abm_13<-rbind(inc_abm_13_2020,inc_abm_13_2025,inc_abm_13_2035,inc_abm_13_2050)

inc_abm_13<-select(inc_abm_13, MGRA, HINCCAT1, yr)
setnames(inc_abm_13, old=c("MGRA","HINCCAT1"), new=c("mgra","income_group_id"))
inc_abm_13$hh<-1
head(inc_abm_13)

inc_abm_13 <-aggregate(hh~yr + mgra + income_group_id, data= inc_abm_13, sum,na.rm = TRUE)
tail(inc_abm_13)

inc_2020<-subset(inc_abm_13_2020, inc_abm_13_2020$BLDGSZ==9)
table(inc_2020$HINCCAT1)


#SQL query isn't working above so currently accesses file from project folder
geography <-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\median_income\\geography.csv", stringsAsFactors = FALSE)
colnames(geography)[1]<-"mgra_13"

geography$cocpa_13<-as.numeric(geography$cocpa_13)
geography$cicpa_13<-as.numeric(geography$cicpa_13)

geography$cpa_13<- ifelse(is.na(geography$cicpa_13) & !is.na(geography$cocpa_13), geography$cocpa_13, geography$cicpa_13)

summary(geography$cpa_13)
head(geography)

inc_abm_13 <- merge(inc_abm_13, geography, by.x="mgra", by.y="mgra_13")

#areas not in a CPA are coded as 0
inc_abm_13$cpa_13[is.na(inc_abm_13$cpa_13)]<- 0

inc_abm_13_cpa<-inc_abm_13
inc_abm_13_cpa$income_group_id <-as.character(inc_abm_13_cpa$income_group_id)

inc_abm_13_cpa<-aggregate(hh~cpa_13+yr+income_group_id, data = inc_abm_13_cpa, sum)

inc_abm_13_cpa<- inc_abm_13_cpa[order(inc_abm_13_cpa$cpa_13,inc_abm_13_cpa$yr,inc_abm_13_cpa$income_group_id),]
head(inc_abm_13_cpa,15)

inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="1"]<- 0
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="1"]<- 29999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="2"]<- 30000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="2"]<- 59999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="3"]<- 60000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="3"]<- 99999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="4"]<- 100000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="4"]<- 149999
inc_abm_13_cpa$lower_bound[inc_abm_13_cpa$income_group_id=="5"]<- 150000
inc_abm_13_cpa$upper_bound[inc_abm_13_cpa$income_group_id=="5"]<- 349999


#I added one to interval calculation because it looks like there is a rounding thing happening in SQL script results - keep or delete?
inc_abm_13_cpa$interval_width<-inc_abm_13_cpa$upper_bound-inc_abm_13_cpa$lower_bound +1

cpa_1428<-subset(inc_abm_13_cpa, inc_abm_13_cpa$cpa_13==1428)
head(cpa_1428,12)

inc_abm_13_cpa <- data.table(inc_abm_13_cpa)
inc_abm_13_cpa[, cum_sum := cumsum(hh), by=list(yr, cpa_13)]

inc_abm_13_cpa<-as.data.frame.matrix(inc_abm_13_cpa) 

inc_dist<-inc_abm_13_cpa

#create file with total number of households by year by cpa for median inc calculation
num_hh_cpa<-aggregate(hh~yr+cpa_13, data = inc_abm_13_cpa, sum)

num_hh_cpa$hh_half<-num_hh_cpa$hh/2.0
num_hh_cpa$hh_half<-round(num_hh_cpa$hh_half, digits = 0)

head(num_hh_cpa)

cum_dist<-inc_dist

cum_dist$hh_full<-num_hh_cpa[match(paste(cum_dist$cpa_13, cum_dist$yr), paste(num_hh_cpa$cpa_13, num_hh_cpa$yr)),"hh"]

cum_dist$hh_half<-num_hh_cpa[match(paste(cum_dist$cpa_13, cum_dist$yr), paste(num_hh_cpa$cpa_13, num_hh_cpa$yr)),"hh_half"]

head(inc_dist)
head(cum_dist,8)


##########
#calculate median income
cum_dist$med_inc<-cum_dist$lower_bound+((cum_dist$hh_half-(cum_dist$cum_sum-cum_dist$hh))/cum_dist$hh)*cum_dist$interval_width

cum_dist$med_inc<-round(cum_dist$med_inc,digits=0)

cum_dist$keep <- NA
cum_dist$keep <- 0
cum_dist$keep[cum_dist$cum_sum>cum_dist$hh_half] <- 1

cum_dist<- subset(cum_dist, cum_dist$keep==1)

cum_dist<-cum_dist %>% group_by(cpa_13, yr) %>% summarise(count=n(), med_inc.13.2.2=first(med_inc))

#change class to data frame after the group by command
cum_dist= as.data.frame(cum_dist)

rm(inc_abm_13_2020,inc_abm_13_2025,inc_abm_13_2035,inc_abm_13_2050)

cum_dist_1428<-subset(cum_dist, cpa_13==1428)
head(cum_dist_1428)

# add series 14 median income

datasource_id=17

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

median_income_cpa_sql = getSQL("../Queries/median_income_cpa_ds_id.sql")
median_income_cpa_sql <- gsub("ds_id", datasource_id, median_income_cpa_sql)
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
# get cpa_id that corresponds to cpa_name
cpa_id_sql = 'SELECT  distinct(cpa_id),[cpa] FROM [demographic_warehouse].[dim].[mgra_denormalize] WHERE series = 14'
cpa_id<-sqlQuery(channel,cpa_id_sql,stringsAsFactors = FALSE)
odbcClose(channel)

mi_cpa$cpa_id<-cpa_id[match(mi_cpa$geozone,cpa_id$cpa),"cpa_id"]

names(mi_cpa)[names(mi_cpa) == 'median_inc'] <- paste('med_inc_ds_id_',datasource_id,sep="")

mi_cpa<- subset(mi_cpa, mi_cpa$cpa_id!=0)

mi_cpa = subset(mi_cpa, !(yr_id %in% c(2016,2018,2030,2040,2045)))

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
tempdir<-"temp_files\\"
ifelse(!dir.exists(file.path(maindir,tempdir)), dir.create(file.path(maindir,tempdir), showWarnings = TRUE, recursive=TRUE),0)
write.csv(mi_cpa, paste(tempdir,"mi_cpa_demographic_warehouse",".csv",sep=""))
write.csv(cum_dist, paste(tempdir,"mi_cpa_abm",".csv",sep=""))
# write.csv(mi_cpa, paste(tempdir,"mi_cpa_demographic_warehouse",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


################################################################

#check for negative median income
#neg<- subset(cum_dist_test2, cum_dist_test2$med_inc<1)

#median income is not available in id=17 for cpa=1401 & 1483 for the 4 ABM years; for 1467 (NCFUA Reserve), mi is only available for 2050; 
#there is mi in ABM SR 13 for all those years and cpas. 

mi_cpa<- merge(mi_cpa,cum_dist,by.x=c("cpa_id", "yr_id"), by.y=c("cpa_13", "yr"), all=TRUE)

#calculate number and percent changes
#mi_cpa_13_14 <- mi_cpa[order(mi_cpa_13_14$cpa_id,mi_cpa_13_14$yr_id),]
#mi_cpa_13_14$mi_numchg13<-ave(mi_cpa_13_14$med_inc.13.2.2, factor(mi_cpa_13_14$cpa_id), FUN=function(x) c(NA,diff(x)))
#mi_cpa_13_14$mi_pctchg13<- ave(mi_cpa_13_14$med_inc.13.2.2, factor(mi_cpa_13_14$cpa_id), FUN=function(x) c(NA,diff(x)/x*100))
#mi_cpa_13_14$mi_pctchg13<-round(mi_cpa_13_14$mi_pctchg13,digits=2)
#mi_cpa_13_14$mi_numchg14<- ave(mi_cpa_13_14$med_inc_ds_id_17, factor(mi_cpa_13_14$cpa_id), FUN=function(x) c(NA,diff(x)))
#mi_cpa_13_14$mi_pctchg14<- ave(mi_cpa_13_14$med_inc_ds_id_17, factor(mi_cpa_13_14$cpa_id), FUN=function(x) c(NA,diff(x)/x*100))
#mi_cpa_13_14$mi_pctchg14<-round(mi_cpa_13_14$mi_pctchg14,digits=2)


head(cum_dist)
head(mi_cpa)


#######################
#######################

#cpa plots

#sets geozone to cpa_id when geozone is NA
#mi_cpa$geozone<- ifelse(is.na(mi_cpa$geozone) & !is.na(mi_cpa$cpa_id), mi_cpa$cpa_id, mi_cpa$geozone)

#delete cases with no data for both SR
mi_cpa<-subset(mi_cpa, !is.na(mi_cpa$geozone))
mi_cpa$med_inc.13.2.2<-round(mi_cpa$med_inc.13.2.2, digits = 0)
head(mi_cpa)

cpa_list<-unique(mi_cpa$geozone)

results<-"plots\\median_income\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


    for(i in 1:length(cpa_list)) { 
    plotdat = subset(mi_cpa, mi_cpa$geozone==cpa_list[i])
    plot<- ggplot(plotdat, aes(x=yr_id, y=med_inc_ds_id_17, colour="SR14"))+
      geom_line(size=1)+
      geom_line(aes(x=yr_id, y= med_inc.13.2.2, colour="SR13")) +
      scale_y_continuous(labels = comma, limits=c(0,200000))+
      labs(title=paste("Median Income ", cpa_list[i],' SR13 and SR14,\n 2020-2050',sep=""),
           y="Median Income", 
           x="Year")+
      theme_bw(base_size = 12)+
      theme(legend.position = "bottom",
            legend.title=element_blank())
    ggsave(plot, file= paste(results, 'median income ', cpa_list[i], "13_14.png", sep=''))#, scale=2)
    output_table<-data.frame(plotdat$yr_id,plotdat$med_inc_ds_id_17,plotdat$med_inc.13.2.2)
    setnames(output_table, old=c("plotdat.yr_id","plotdat.med_inc_ds_id_17","plotdat.med_inc.13.2.2"),new=c("Year","SR14 median income","SR13 median income"))
    tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
    tbl <- tableGrob(output_table, rows=NULL, theme=tt)
    lay <- rbind(c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(1,1,1,1,1),
                 c(2,2,2,2,2),
                 c(2,2,2,2,2))
    output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay,
                         bottom = textGrob("Source: demographic warehouse: dbo.compute_median_income_all_zones 17\nversion.13.2.2 household file\nNotes:Unoccupiable units are included. Out of range data may not appear on the plot.\nRefer to the table below for those related data results.",
                                           x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 6.5)))
    ggsave(output, file= paste(results,'median income ',cpa_list[i], "13_14.png", sep=''))#, scale=2))
}
    
    
write.csv(mi_cpa,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\median_income\\mi_cpa_13.2.2.csv")

write.csv(mi_cpa, paste(tempdir,"mi_cpa_demographic_warehouse",".csv",sep=""))


cpa_high<-lapply(mi_cpa, function(x) x[mi_cpa$median_inc > 100000])
unique(cpa_high$geozone)
cpa_subset<-lapply(mi_cpa, function(x) x[mi_cpa$median_inc < 50000]) 
unique(cpa_subset$geozone)











#######################################
#######################################
#jur

#should we match to jurisdiction_2015 or 2016
inc_abm_13_jur <- aggregate (cbind(cat1, cat2, cat3, cat4, cat5)~jurisdiction_2015+yr, data=inc_abm_13, sum)
inc_abm_13_jur <- melt(inc_abm_13_jur, id.vars=c("jurisdiction_2015", "yr"))
setnames(inc_abm_13_jur,old=c("variable","value"),new=c("income_group_id","hh"))


inc_abm_13_jur$income_group_id <-as.character(inc_abm_13_jur$income_group_id)
inc_abm_13_jur$income_group_id[inc_abm_13_jur$income_group_id=="cat1"]<- "1"
inc_abm_13_jur$income_group_id[inc_abm_13_jur$income_group_id=="cat2"]<- "2"
inc_abm_13_jur$income_group_id[inc_abm_13_jur$income_group_id=="cat3"]<- "3"
inc_abm_13_jur$income_group_id[inc_abm_13_jur$income_group_id=="cat4"]<- "4"
inc_abm_13_jur$income_group_id[inc_abm_13_jur$income_group_id=="cat5"]<- "5"

inc_abm_13_jur$lower_bound[inc_abm_13_jur$income_group_id=="1"]<- 0
inc_abm_13_jur$upper_bound[inc_abm_13_jur$income_group_id=="1"]<- 29999
inc_abm_13_jur$lower_bound[inc_abm_13_jur$income_group_id=="2"]<- 30000
inc_abm_13_jur$upper_bound[inc_abm_13_jur$income_group_id=="2"]<- 59999
inc_abm_13_jur$lower_bound[inc_abm_13_jur$income_group_id=="3"]<- 60000
inc_abm_13_jur$upper_bound[inc_abm_13_jur$income_group_id=="3"]<- 99999
inc_abm_13_jur$lower_bound[inc_abm_13_jur$income_group_id=="4"]<- 100000
inc_abm_13_jur$upper_bound[inc_abm_13_jur$income_group_id=="4"]<- 149999
inc_abm_13_jur$lower_bound[inc_abm_13_jur$income_group_id=="5"]<- 150000
inc_abm_13_jur$upper_bound[inc_abm_13_jur$income_group_id=="5"]<- 349999


inc_abm_13_jur$interval_width<-inc_abm_13_jur$upper_bound-inc_abm_13_jur$lower_bound +1

inc_abm_13_jur<- inc_abm_13_jur[order(inc_abm_13_jur$jurisdiction_2015,inc_abm_13_jur$yr),]

inc_abm_13_jur <- data.table(inc_abm_13_jur)
inc_abm_13_jur[, cum_sum := cumsum(hh), by=list(yr, jurisdiction_2015)]

inc_abm_13_jur<-as.data.frame.matrix(inc_abm_13_jur) 

num_hh_jur<-aggregate(hh~jurisdiction_2015+yr, data = inc_abm_13_jur, sum)

inc_dist<-inc_abm_13_jur

num_hh_jur$hh_half<-num_hh_jur$hh/2.0

cum_dist<-inc_dist

cum_dist$hh_full<-num_hh_jur[match(paste(cum_dist$jurisdiction_2015, cum_dist$yr), paste(num_hh_jur$jurisdiction_2015, num_hh_jur$yr)),"hh"]

cum_dist$hh_half<-num_hh_jur[match(paste(cum_dist$jurisdiction_2015, cum_dist$yr), paste(num_hh_jur$jurisdiction_2015, num_hh_jur$yr)),"hh_half"]

head(inc_dist)
head(cum_dist,15)

##########################################
##########################################





####################################
####################################
#jur



inc13_jur <- aggregate(cbind(cat1, cat2, cat3, cat4, cat5)~jurisdiction_2015+yr, data = inc13geo,sum)
inc13_jur <- melt(inc13_jur, id.vars=c("jurisdiction_2015", "yr"))

inc13_reg <- aggregate (c(i1,i2,i3,i4,i5,i6,i7,i8,i9,i10)~+yr, data = inc13geo,sum)                       
summary(Inc13geo$jurisdiction_2015)
class(Inc13geo$jurisdiction_2015)
table(Inc13geo$jurisdiction_2015)
class(inc13geo$i1)

inc13_reg <- aggregate(i1~yr+jurisdiction_2015, data = inc13geo,sum) 





