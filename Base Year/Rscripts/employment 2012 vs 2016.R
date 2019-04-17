#base year employment 2012 to 2016 comparison


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "sqldf", "rstudioapi", "RODBC", "dplyr", 
              "stringr")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

options(stringsAsFactors=FALSE)

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=data_cafe; trusted_connection=true')
geo_sql = getSQL("../Queries/geography.sql")
geo<-sqlQuery(channel,geo_sql)
odbcClose(channel)

#create a variable to indicate mgra in a cpa
geo$cpa <- ifelse((geo$jurisdiction==14 | geo$jurisdiction==19),'cpa','not_cpa')
#confirm results of new variable
table(geo$cpa,geo$jurisdiction)

#read in mgra files for 2016 and 2012
mgra<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

testtaz <- unique(mgra$taz[mgra$hhp>0])

testmgra <- unique(mgra$mgra[mgra$hhp>0])
mgra_employ <- sum(mgra$emp_total)


#Series 13 ABM version of 2012
mgra_2012<-read.csv('T:\\ABM\\release\\ABM\\version_13_3_2\\input\\2012\\mgra13_based_input2012.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")



#create civilian employment total for each file
mgra$civ_emp_tot<-mgra$emp_total-mgra$emp_fed_mil
mgra_2012$civ_emp_tot<-mgra_2012$emp_total-mgra_2012$emp_fed_mil


#keep only columns of interest in mgra files
mgra <- select(mgra,mgra,pop,hhp,hh,gq_civ,gq_mil,emp_ag,emp_const_non_bldg_prod,emp_const_non_bldg_office,emp_utilities_prod,emp_utilities_office,
               emp_const_bldg_prod,emp_const_bldg_office,emp_mfg_prod,emp_mfg_office,emp_whsle_whs,
               emp_trans,emp_retail,emp_prof_bus_svcs,emp_prof_bus_svcs_bldg_maint,emp_pvt_ed_k12,
               emp_pvt_ed_post_k12_oth,emp_health,emp_personal_svcs_office,emp_amusement,emp_hotel,
               emp_restaurant_bar,emp_personal_svcs_retail,emp_religious,emp_pvt_hh,emp_state_local_gov_ent,
               emp_fed_non_mil,emp_fed_mil,emp_state_local_gov_blue,emp_state_local_gov_white,emp_public_ed,
               emp_own_occ_dwell_mgmt,emp_fed_gov_accts,emp_st_lcl_gov_accts,emp_cap_accts,emp_total,civ_emp_tot)
               
mgra_2012 <- select(mgra_2012,mgra,pop,hhp,hh,gq_civ,gq_mil,emp_ag,emp_const_non_bldg_prod,emp_const_non_bldg_office,emp_utilities_prod,emp_utilities_office,
                    emp_const_bldg_prod,emp_const_bldg_office,emp_mfg_prod,emp_mfg_office,emp_whsle_whs,
                    emp_trans,emp_retail,emp_prof_bus_svcs,emp_prof_bus_svcs_bldg_maint,emp_pvt_ed_k12,
                    emp_pvt_ed_post_k12_oth,emp_health,emp_personal_svcs_office,emp_amusement,emp_hotel,
                    emp_restaurant_bar,emp_personal_svcs_retail,emp_religious,emp_pvt_hh,emp_state_local_gov_ent,
                    emp_fed_non_mil,emp_fed_mil,emp_state_local_gov_blue,emp_state_local_gov_white,emp_public_ed,
                    emp_own_occ_dwell_mgmt,emp_fed_gov_accts,emp_st_lcl_gov_accts,emp_cap_accts,emp_total,civ_emp_tot)



#melt each mgra file
mgra_long<-melt(mgra, id.vars=c("mgra"))

mgra_2012_long<-melt(mgra_2012, id.vars=c("mgra"))

setnames(mgra_long, old="value",new="value_2016")
setnames(mgra_2012_long, old="value",new="value_2012")

#merge 2016 and 2012 for comparison
mgra_16_12<-merge(mgra_long, mgra_2012_long, by=c("mgra", "variable"))

#calculate difference from new 2016 to 2012 for each variable
mgra_16_12$diff<-mgra_16_12$value_2016-mgra_16_12$value_2012

#merge in geography files
mgra_16_12<-merge(mgra_16_12, geo, by="mgra")

#check results of merge
head(mgra_16_12[mgra_16_12$jurisdiction==1,],15)

#aggregate totals to jurisdiction
emp_jur_16_12<-aggregate(cbind(value_2016,value_2012,diff)~variable+jurisdiction_name, data=mgra_16_12, sum)

head(emp_jur_16_12)

#aggregate the totals by cpa
emp_cpa_16_12 <- subset(mgra_16_12,mgra_16_12$cpa!="not_cpa")
emp_cpa_16_12<-aggregate(cbind(value_2016,value_2012,diff)~variable+jurisdiction_and_cpa_name, data=emp_cpa_16_12, sum)

#aggregate for region totals
emp_reg_16_12<-aggregate(cbind(value_2016,value_2012,diff)~variable, data=mgra_16_12, sum)

write.csv(emp_reg_16_12, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\emp_reg_16_12.csv" )

write.csv(emp_jur_16_12, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\emp_jur_16_12.csv" )

write.csv(emp_cpa_16_12, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\emp_cpa_16_12.csv" )

