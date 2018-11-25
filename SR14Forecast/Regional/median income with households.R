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

#access file per Wu and Ying
inc_abm_13_2020<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2020\\households.csv", stringsAsFactors = FALSE)
inc_abm_13_2025<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2025\\households.csv", stringsAsFactors = FALSE)
inc_abm_13_2035<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2035\\households.csv", stringsAsFactors = FALSE)
inc_abm_13_2050<- read.csv("T:\\ABM\\release\\ABM\\archive\\version_13.2.2\\input\\2050\\households.csv", stringsAsFactors = FALSE)

#add vector to indicate file for bind preparation
inc_abm_13_2020$yr = 2020
inc_abm_13_2025$yr = 2025
inc_abm_13_2035$yr = 2035
inc_abm_13_2050$yr = 2050

#combine each year file
inc_abm_13<-rbind(inc_abm_13_2020,inc_abm_13_2025,inc_abm_13_2035,inc_abm_13_2050)

#remove group quarters to compare with demographic warehouse
#head(inc_abm_13)
# HHT column - Household/family type:
# 0.       Not in universe (vacant or GQ)
# 1.       Family household:married-couple
# 2.       Family household:male householder,no wife present
# 3.       Family household:female householder,no husband present
# 4.       Nonfamily household:male householder, living alone
# 5.       Nonfamily household:male householder, not living alone
# 6.       Nonfamily household:female householder, living alone
# 7.       Nonfamily household:female householder, not living alone
inc_abm_13 = subset(inc_abm_13,inc_abm_13$HHT!=0)

#select columns of interest, rename columns, create a hh variable to allow for counting cases
inc_abm_13<-select(inc_abm_13, MGRA, HINCCAT1, yr)
setnames(inc_abm_13, old=c("MGRA","HINCCAT1"), new=c("mgra","income_group_id"))
inc_abm_13$hh<-1
head(inc_abm_13)

#count households by income group and geography
inc_abm_13 <-aggregate(hh~yr + mgra + income_group_id, data= inc_abm_13, sum,na.rm = TRUE)
tail(inc_abm_13)

#SQL query isn't working above so currently accesses file from project folder
geography <-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 4\\median_income\\geography.csv", stringsAsFactors = FALSE)
#rename column name with strange characters
colnames(geography)[1]<-"mgra_13"

#combine county and city cpa info into one column
geography$cocpa_13<-as.numeric(geography$cocpa_13)
geography$cicpa_13<-as.numeric(geography$cicpa_13)
geography$cpa_13<- ifelse(is.na(geography$cicpa_13) & !is.na(geography$cocpa_13), geography$cocpa_13, geography$cicpa_13)
summary(geography$cpa_13)
head(geography)
#merge income file with geography file
inc_abm_13 <- merge(inc_abm_13, geography, by.x="mgra", by.y="mgra_13")

#areas not in a CPA are coded as 0
inc_abm_13$cpa_13[is.na(inc_abm_13$cpa_13)]<- 0

inc_abm_13$income_group_id <-as.character(inc_abm_13$income_group_id)

#create files for cpa and jur and region
inc_abm_13_jur<-inc_abm_13
inc_abm_13_cpa<-inc_abm_13
inc_abm_13_region<-inc_abm_13

#aggregate hh count to city or cpa by year and income group 
inc_abm_13_jur<-aggregate(hh~jurisdiction_2015+yr+income_group_id, data = inc_abm_13_jur, sum)
inc_abm_13_cpa<-aggregate(hh~cpa_13+yr+income_group_id, data = inc_abm_13_cpa, sum)
inc_abm_13_region<-aggregate(hh~yr+income_group_id, data = inc_abm_13_region, sum)

#add in the lower and upper bound of income groups for median income calculation
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

inc_abm_13_region$lower_bound[inc_abm_13_region$income_group_id=="1"]<- 0
inc_abm_13_region$upper_bound[inc_abm_13_region$income_group_id=="1"]<- 29999
inc_abm_13_region$lower_bound[inc_abm_13_region$income_group_id=="2"]<- 30000
inc_abm_13_region$upper_bound[inc_abm_13_region$income_group_id=="2"]<- 59999
inc_abm_13_region$lower_bound[inc_abm_13_region$income_group_id=="3"]<- 60000
inc_abm_13_region$upper_bound[inc_abm_13_region$income_group_id=="3"]<- 99999
inc_abm_13_region$lower_bound[inc_abm_13_region$income_group_id=="4"]<- 100000
inc_abm_13_region$upper_bound[inc_abm_13_region$income_group_id=="4"]<- 149999
inc_abm_13_region$lower_bound[inc_abm_13_region$income_group_id=="5"]<- 150000
inc_abm_13_region$upper_bound[inc_abm_13_region$income_group_id=="5"]<- 349999

#calculate the interval with for median income calculation
#LH added one to interval calculation because it looks like there is a rounding thing happening in SQL script results - keep or delete?
inc_abm_13_jur$interval_width<-inc_abm_13_jur$upper_bound-inc_abm_13_jur$lower_bound +1
inc_abm_13_cpa$interval_width<-inc_abm_13_cpa$upper_bound-inc_abm_13_cpa$lower_bound +1
inc_abm_13_region$interval_width<-inc_abm_13_region$upper_bound-inc_abm_13_region$lower_bound +1

inc_abm_13_jur<- inc_abm_13_jur[order(inc_abm_13_jur$jurisdiction_2015,inc_abm_13_jur$yr,inc_abm_13_jur$income_group_id),]
inc_abm_13_cpa<- inc_abm_13_cpa[order(inc_abm_13_cpa$cpa_13,inc_abm_13_cpa$yr,inc_abm_13_cpa$income_group_id),]
inc_abm_13_region<- inc_abm_13_region[order(inc_abm_13_region$yr,inc_abm_13_region$income_group_id),]

head(inc_abm_13_jur,15)
head(inc_abm_13_cpa,15)
head(inc_abm_13_region)

#test case: north park cpa
#cpa_1428<-subset(inc_abm_13_cpa, inc_abm_13_cpa$cpa_13==1428)
#head(cpa_1428,12)

#calculate cumulative sum which requires data.table
inc_abm_13_jur <- data.table(inc_abm_13_jur)
inc_abm_13_jur[, cum_sum := cumsum(hh), by=list(yr, jurisdiction_2015)]
inc_abm_13_jur<-as.data.frame.matrix(inc_abm_13_jur) 

inc_abm_13_cpa <- data.table(inc_abm_13_cpa)
inc_abm_13_cpa[, cum_sum := cumsum(hh), by=list(yr, cpa_13)]
inc_abm_13_cpa<-as.data.frame.matrix(inc_abm_13_cpa) 


inc_abm_13_region <- data.table(inc_abm_13_region)
inc_abm_13_region[, cum_sum := cumsum(hh), by=list(yr)]
inc_abm_13_region<-as.data.frame.matrix(inc_abm_13_region) 

#create new file needed for median income calculation
inc_dist_jur<-inc_abm_13_jur
inc_dist_cpa<-inc_abm_13_cpa
inc_dist_region<-inc_abm_13_region

head(inc_dist_jur)
head(inc_dist_cpa)
head(inc_dist_region)

#create files with total number of households and half households by year by jur and cpa for median inc calculation
num_hh_jur<-aggregate(hh~yr+jurisdiction_2015, data = inc_abm_13_jur, sum)
num_hh_jur$hh_half<-num_hh_jur$hh/2.0
# to match median from stored procedure, do not round half hh
# num_hh_jur$hh_half<-round(num_hh_jur$hh_half, digits = 0)
head(num_hh_jur)


num_hh_cpa<-aggregate(hh~yr+cpa_13, data = inc_abm_13_cpa, sum)
num_hh_cpa$hh_half<-num_hh_cpa$hh/2.0
# to match median from stored procedure, do not round half hh
# num_hh_cpa$hh_half<-round(num_hh_cpa$hh_half, digits = 0)
head(num_hh_cpa)


num_hh_region<-aggregate(hh~yr, data = inc_abm_13_region, sum)
num_hh_region$hh_half<-num_hh_region$hh/2.0
# to match median from stored procedure, do not round half hh
# num_hh_cpa$hh_half<-round(num_hh_cpa$hh_half, digits = 0)
head(num_hh_region)

cum_dist_jur<-inc_dist_jur
cum_dist_cpa<-inc_dist_cpa
cum_dist_region<-inc_dist_region

cum_dist_jur$hh_full<-num_hh_jur[match(paste(cum_dist_jur$jurisdiction_2015, cum_dist_jur$yr), paste(num_hh_jur$jurisdiction_2015, num_hh_jur$yr)),"hh"]
cum_dist_cpa$hh_full<-num_hh_cpa[match(paste(cum_dist_cpa$cpa_13, cum_dist_cpa$yr), paste(num_hh_cpa$cpa_13, num_hh_cpa$yr)),"hh"]
cum_dist_region$hh_full<-num_hh_region[match(paste(cum_dist_region$yr), paste(num_hh_region$yr)),"hh"]


cum_dist_jur$hh_half<-num_hh_jur[match(paste(cum_dist_jur$jurisdiction_2015, cum_dist_jur$yr), paste(num_hh_jur$jurisdiction_2015, num_hh_jur$yr)),"hh_half"]
cum_dist_cpa$hh_half<-num_hh_cpa[match(paste(cum_dist_cpa$cpa_13, cum_dist_cpa$yr), paste(num_hh_cpa$cpa_13, num_hh_cpa$yr)),"hh_half"]
cum_dist_region$hh_half<-num_hh_region[match(paste(cum_dist_region$yr), paste(num_hh_region$yr)),"hh_half"]



head(inc_dist_jur)
head(cum_dist_jur,8)

head(inc_dist_cpa)
head(cum_dist_cpa,8)
class(cum_dist_cpa)

head(inc_dist_region)
head(cum_dist_region)

##########


#calculate median income for jur

cum_dist_jur <- data.table(cum_dist_jur)
cum_dist_jur$med_inc<-cum_dist_jur$lower_bound+((cum_dist_jur$hh_half-(cum_dist_jur$cum_sum-cum_dist_jur$hh))/cum_dist_jur$hh)*cum_dist_jur$interval_width
cum_dist_jur <- as.data.frame.matrix(cum_dist_jur)
cum_dist_jur$med_inc<-round(cum_dist_jur$med_inc,digits=0)

cum_dist_jur$keep <- NA
cum_dist_jur$keep <- 0
cum_dist_jur$keep[cum_dist_jur$cum_sum>cum_dist_jur$hh_half] <- 1

cum_dist_jur<- subset(cum_dist_jur, cum_dist_jur$keep==1)

cum_dist_jur<-cum_dist_jur %>% group_by(jurisdiction_2015, yr) %>% summarise(count=n(), med_inc.13.2.2=first(med_inc))

head(cum_dist_jur)
#change class to data frame after the group by command
cum_dist_jur= as.data.frame(cum_dist_jur)

#calculate median income for cpa

cum_dist_cpa <- data.table(cum_dist_cpa)
cum_dist_cpa$med_inc<-cum_dist_cpa$lower_bound+((cum_dist_cpa$hh_half-(cum_dist_cpa$cum_sum-cum_dist_cpa$hh))/cum_dist_cpa$hh)*cum_dist_cpa$interval_width
cum_dist_cpa$med_inc<-round(cum_dist_cpa$med_inc,digits=0)
cum_dist_cpa <- as.data.frame.matrix(cum_dist_cpa)

cum_dist_cpa$keep <- NA
cum_dist_cpa$keep <- 0
cum_dist_cpa$keep[cum_dist_cpa$cum_sum>cum_dist_cpa$hh_half] <- 1

cum_dist_cpa<- subset(cum_dist_cpa, cum_dist_cpa$keep==1)

cum_dist_cpa<-cum_dist_cpa %>% group_by(cpa_13, yr) %>% summarise(count=n(), med_inc.13.2.2=first(med_inc))

#change class to data frame after the group by command
cum_dist_cpa= as.data.frame(cum_dist_cpa)

#rm(inc_abm_13_2020,inc_abm_13_2025,inc_abm_13_2035,inc_abm_13_2050)
#test case-north park
#cum_dist_1428<-subset(cum_dist_cpa, cpa_13==1428)
#head(cum_dist_1428)

#calculate median income for region

cum_dist_region <- data.table(cum_dist_region)
cum_dist_region$med_inc<-cum_dist_region$lower_bound+((cum_dist_region$hh_half-(cum_dist_region$cum_sum-cum_dist_region$hh))/cum_dist_region$hh)*cum_dist_region$interval_width
cum_dist_region$med_inc<-round(cum_dist_region$med_inc,digits=0)
cum_dist_region <- as.data.frame.matrix(cum_dist_region)

cum_dist_region$keep <- NA
cum_dist_region$keep <- 0
cum_dist_region$keep[cum_dist_region$cum_sum>cum_dist_region$hh_half] <- 1

cum_dist_region<- subset(cum_dist_region, cum_dist_region$keep==1)

cum_dist_region<-cum_dist_region %>% group_by(yr) %>% summarise(count=n(), med_inc.13.2.2=first(med_inc))

#change class to data frame after the group by command
cum_dist_region= as.data.frame(cum_dist_region)
cum_dist_region

# add series 14 median income

datasource_id=17

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#region median income for SR14
median_income_reg_sql = getSQL("../Queries/median_income_region_ds_id.sql")
median_income_reg_sql <- gsub("ds_id", datasource_id, median_income_reg_sql)
mi_reg<-sqlQuery(channel,median_income_reg_sql,stringsAsFactors = FALSE)
setnames(mi_reg, "median_inc", "med_inc_reg")
head(mi_reg)

#jurisdiction median income for SR14
median_income_jur_sql = getSQL("../Queries/median_income_jur_ds_id.sql")
median_income_jur_sql <- gsub("ds_id", datasource_id, median_income_jur_sql)
mi_jur<-sqlQuery(channel,median_income_jur_sql,stringsAsFactors = FALSE)
# get cpa_id that corresponds to cpa_name
#jur_id_sql = 'SELECT  distinct(cpa_id),[cpa] FROM [demographic_warehouse].[dim].[mgra_denormalize] WHERE series = 14'
#jur_id<-sqlQuery(channel,jur_id_sql,stringsAsFactors = FALSE)

#cpa median income for SR14
median_income_cpa_sql = getSQL("../Queries/median_income_cpa_ds_id.sql")
median_income_cpa_sql <- gsub("ds_id", datasource_id, median_income_cpa_sql)
mi_cpa<-sqlQuery(channel,median_income_cpa_sql,stringsAsFactors = FALSE)
# get cpa_id that corresponds to cpa_name
cpa_id_sql = 'SELECT  distinct(cpa_id),[cpa] FROM [demographic_warehouse].[dim].[mgra_denormalize] WHERE series = 14'
cpa_id<-sqlQuery(channel,cpa_id_sql,stringsAsFactors = FALSE)
odbcClose(channel)

mi_cpa$cpa_id<-cpa_id[match(mi_cpa$geozone,cpa_id$cpa),"cpa_id"]

names(mi_jur)[names(mi_jur) == 'median_inc'] <- paste('med_inc_ds_id_',datasource_id,sep="")
names(mi_cpa)[names(mi_cpa) == 'median_inc'] <- paste('med_inc_ds_id_',datasource_id,sep="")

mi_cpa<- subset(mi_cpa, mi_cpa$cpa_id!=0)

mi_reg = subset(mi_reg, !(yr_id %in% c(2016,2018,2030,2040,2045)))
mi_jur = subset(mi_jur, !(yr_id %in% c(2016,2018,2030,2040,2045)))
mi_cpa = subset(mi_cpa, !(yr_id %in% c(2016,2018,2030,2040,2045)))

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
tempdir<-"temp_files\\"
ifelse(!dir.exists(file.path(maindir,tempdir)), dir.create(file.path(maindir,tempdir), showWarnings = TRUE, recursive=TRUE),0)
write.csv(mi_cpa, paste(tempdir,"mi_cpa_demographic_warehouse",".csv",sep=""))
write.csv(cum_dist_cpa, paste(tempdir,"mi_cpa_abm",".csv",sep=""))
# write.csv(mi_cpa, paste(tempdir,"mi_cpa_demographic_warehouse",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


################################################################

#check for negative median income
#neg<- subset(cum_dist_test2, cum_dist_test2$med_inc<1)


#median income is not available in id=17 for cpa=1401 & 1483 for the 4 ABM years; for 1467 (NCFUA Reserve), mi is only available for 2050; 
#there is mi in ABM SR 13 for all those years and cpas. 
head(mi_jur)
head(cum_dist_jur)

jur_name<-c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
            "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")
jur_num<-1:19
jur_1<-data.frame(jur_name,jur_num)

cum_dist_jur$jur_name<-jur_1[match(cum_dist_jur$jurisdiction_2015, jur_1$jur_num), "jur_name"]


head(jur_1)
head(cum_dist_jur)


mi_jur<- merge(mi_jur,cum_dist_jur,by.x=c("geozone", "yr_id"), by.y=c("jur_name", "yr"), all=TRUE)
mi_cpa<- merge(mi_cpa,cum_dist_cpa,by.x=c("cpa_id", "yr_id"), by.y=c("cpa_13", "yr"), all=TRUE)

mi_jur$med_inc_reg<-mi_reg[match(mi_jur$yr_id, mi_reg$yr_id), "med_inc_reg"]
mi_jur$med_inc_reg_SR13<-cum_dist_region[match(mi_jur$yr_id, cum_dist_region$yr), "med_inc.13.2.2"]



#Jurisdiction plots


head(mi_jur)

results<-"plots\\median_income\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

for(i in 1:length(jur_name)) { 
  plotdat = subset(mi_jur, mi_jur$geozone==jur_name[i])
  ySR14= paste('med_inc_ds_id_',datasource_id,sep="")
  plot<- ggplot(plotdat, aes(x=yr_id))+
    geom_line(aes_string(y=ySR14, color='"SR14"')) +
    geom_point(aes_string(y=ySR14, color='"SR14"'), size=2, alpha=0.3) +
    geom_line(aes(y= med_inc.13.2.2, color="SR13")) +
    geom_point(aes(y= med_inc.13.2.2, color="SR13"), size=2, alpha=0.3) +
    geom_line(aes(y= med_inc_reg, color="Reg_SR14")) +
    geom_point(aes(y= med_inc_reg, color="Reg_SR14"), size=2, alpha=0.3) +
    scale_y_continuous(labels = comma, limits=c(20000,120000))+
    labs(title=paste("Median Income ", jur_name[i],' SR13 and SR14,\n 2020-2050',sep=""),
         y="Median Income", 
         x="Year")+
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'median income ', jur_name[i], "13_14.png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat[[ySR14]],plotdat$med_inc.13.2.2,plotdat$med_inc_reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat..ySR14..","plotdat.med_inc.13.2.2","plotdat.med_inc_reg"),new=c("Year","SR14 median income","SR13 median income","SR14 region med inc"))
  tt <- ttheme_default(base_size=9,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay,
                       bottom = textGrob(paste("Sources: SR14: demographic warehouse: dbo.compute_median_income_all_zones ",datasource_id,
                                               " SR13: version.13.2.2 households.csv file"),
                                         x = .01, y = 0.5, just = 'left', gp = gpar(fontsize = 6.5)))
  ggsave(output, width=6, height=8, dpi=100, file= paste(results,'median income ',jur_name[i], "13_14.png", sep=''))#, scale=2))
}



write.csv(mi_jur,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\median_income\\mi_jur_14.csv")
write.csv(cum_dist_jur,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase 6\\median_income\\mi_jur_13.2.2.csv")


#######################
#######################

#cpa plots

#sets geozone to cpa_id when geozone is NA
#mi_cpa$geozone<- ifelse(is.na(mi_cpa$geozone) & !is.na(mi_cpa$cpa_id), mi_cpa$cpa_id, mi_cpa$geozone)

#delete cases with no data for both SR
mi_cpa<-subset(mi_cpa, !is.na(mi_cpa$geozone))
mi_cpa$med_inc.13.2.2<-round(mi_cpa$med_inc.13.2.2, digits = 0)
head(mi_cpa)

mi_cpa$med_inc_reg<-mi_reg[match(mi_cpa$yr_id, mi_reg$yr_id), "med_inc_reg"]

cpa_list<-unique(mi_cpa$geozone)

results<-"plots\\median_income\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in 1:length(cpa_list)) { 
  plotdat = subset(mi_cpa, mi_cpa$geozone==cpa_list[i])
  plot<- ggplot(plotdat, aes(x=yr_id))+
    geom_line(aes(y=med_inc_ds_id_17, color="SR14"))+
    geom_line(aes(y= med_inc.13.2.2, color="SR13")) +
    geom_line(aes(y= med_inc_reg, color="Reg_SR14")) +
    scale_y_continuous(labels = comma, limits=c(20000,120000))+
    labs(title=paste("Median Income ", cpa_list[i],' SR13 and SR14,\n 2020-2050',sep=""),
         y="Median Income", 
         x="Year")+
    theme_bw(base_size = 12)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'median income ', cpa_list[i], "13_14.png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$med_inc_ds_id_17,plotdat$med_inc.13.2.2,plotdat$med_inc_reg)
  setnames(output_table, old=c("plotdat.yr_id","plotdat.med_inc_ds_id_17","plotdat.med_inc.13.2.2","plotdat.med_inc_reg"),new=c("Year","SR14 median income","SR13 median income","SR14 region med inc"))
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




