#fix variables in 2016 and add to the rbind

#fix geography merge

install.packages("reshape2")

library(scales)
library(sqldf)
library(rstudioapi)
library(RODBC)
library(dplyr)
library(reshape2)
library(ggplot2)
library(data.table)
library(stringr)
#library(wesanderson)
#library(RColorBrewer)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#read in files

mgra2016<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2018<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2018_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2020<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2020_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2025<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2025_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2030<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2030_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2035<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2035_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2040<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2040_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2045<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2045_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

mgra2050<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\Test files\\mgra13_based_input2050_01.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

geography<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Data Files\\geography.csv',stringsAsFactors = FALSE,fileEncoding="UTF-8-BOM")

colnames(mgra2016)<- tolower(colnames(mgra2016))


#add year variable
mgra2016$year<-2016
mgra2018$year<-2018
mgra2020$year<-2020
mgra2025$year<-2025
mgra2030$year<-2030
mgra2035$year<-2035
mgra2040$year<-2040
mgra2045$year<-2045
mgra2050$year<-2050

#fix Rbind when 2016 matches
mgra_all<-rbind(mgra2018,mgra2020,mgra2025,mgra2030,mgra2035,mgra2040,mgra2045,mgra2050)

emp_keep<-c(
"emp_ag",
"emp_const_non_bldg_prod",
"emp_const_non_bldg_office",
"emp_utilities_prod",
"emp_utilities_office",
"emp_const_bldg_prod",
"emp_const_bldg_office",
"emp_mfg_prod",
"emp_mfg_office",
"emp_whsle_whs",
"emp_trans",
"emp_retail",
"emp_prof_bus_svcs",
"emp_prof_bus_svcs_bldg_maint",
"emp_pvt_ed_k12",
"emp_pvt_ed_post_k12_oth",
"emp_health",
"emp_personal_svcs_office",
"emp_amusement",
"emp_hotel",
"emp_restaurant_bar",
"emp_personal_svcs_retail",
"emp_religious",
"emp_pvt_hh",
"emp_state_local_gov_ent",
"emp_fed_non_mil",
"emp_fed_mil",
"emp_state_local_gov_blue",
"emp_state_local_gov_white",
"emp_public_ed",
"emp_own_occ_dwell_mgmt",
"emp_fed_gov_accts",
"emp_st_lcl_gov_accts",
"emp_cap_accts",
"emp_total")


emp_keep2<-c(
  "emp_state_local_gov_ent",
  "emp_fed_non_mil",
  "emp_fed_mil",
  "emp_state_local_gov_blue",
  "emp_state_local_gov_white",
  "emp_public_ed",
  "emp_total")

#fix
#mgra_all<-merge(mgra_all, geography, by.a="mgra", all=TRUE)

melt_mgra<-melt(mgra_all, id.vars=c("mgra", "year"))

emp_mgra<-melt_mgra[melt_mgra$variable %in% emp_keep,]

emp_aggregate<-aggregate(value~variable+year, data=emp_mgra, sum)

write.csv(emp_aggregate,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\region employment aggregated.csv" )

head(emp_aggregate)

rm(mgra2018,mgra2020,mgra2025,mgra2030,mgra2035,mgra2040,mgra2045,mgra2050)

tapply(emp_mgra$value, emp_mgra$variable, summary)

emp_desc<-with(emp_aggregate, aggregate(value, list("variable"=variable), summary))

write.csv(emp_desc,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\region employment descriptives.csv" )



#this is the path to folder to save the plots
results<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Scripts\\output\\"



emp_mgra2<-emp_aggregate[emp_aggregate$variable %in% emp_keep2,]

emp_types2<-ggplot(data=emp_mgra2, aes(x=year, y=value, group=variable, colour=variable)) +
  geom_line(size=1.5) +
  labs(title="SD Regionwide Employment Projections", y="Employment/Jobs", x=" Year",
       caption="Source:mgra projection files")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,40000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(filename = "employment_mgra.pdf", plot=emp_types2)

emp_types<-ggplot(data=emp_aggregate, aes(x=year, y=value, group=variable, colour=variable)) +
  geom_line(size=1.5) +
  labs(title="SD Regionwide Employment Projections", y="Employment/Jobs", x=" Year",
       caption="Source:mgra projection files")+
  expand_limits(y = c(1, 3000000))+
  scale_y_continuous(labels= comma, limits = c(0,100000))+
  theme_bw(base_size = 16)+
  theme(legend.position = "bottom",
        legend.title=element_blank())

ggsave(filename = "employment_mgra.pdf", plot=emp_types)

#use emp_keep as the list for "i" 
#this is the loop with the subset, the ggplot and the ggsave commands
for(i in emp_keep){
  plot<-ggplot(subset(emp_mgra, emp_mgra$variable==emp_keep[i]),  
               aes(x=year, y=value, color=emp_keep)) +
    geom_line(size=1.5) +
    labs(title="SD Regionwide Employment Projections", y="Employment/Jobs ", x=" Year",
         caption="Source: mgra files")+
    expand_limits(y = c(1, 3000000))+
    scale_y_continuous(labels= comma, limits = c(1,30000))+
    theme_bw(base_size = 16)+
    theme(legend.position = "bottom",
          legend.title=element_blank())
  ggsave(plot, file= paste(results, 'emp_mgra', emp_keep[i], ".pdf", sep=''), scale=2)
}

mgra_wide <- dcast(emp_aggregate, variable ~ year,sum)







#add dcast here for calculation and output of percent difference


