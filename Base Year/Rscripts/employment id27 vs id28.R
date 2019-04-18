#base year employment 2016 id27 to id28 comparison


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
mgra_id27<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")
mgra_id28<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

testtaz <- unique(mgra_id27$taz[mgra_id27$hhp>0])

testmgra <- unique(mgra_id27$mgra[mgra_id27$hhp>0])
mgra_employ_id27 <- sum(mgra_id27$emp_total)


#create civilian employment total for each file
mgra_id27$civ_emp_tot<-mgra_id27$emp_total-mgra_id27$emp_fed_mil
mgra_id28$civ_emp_tot<-mgra_id28$emp_total-mgra_id28$emp_fed_mil


#keep only columns of interest in mgra files
mgra_id27 <- select(mgra_id27,mgra,pop,hhp,hh,gq_civ,gq_mil,emp_ag,emp_const_non_bldg_prod,emp_const_non_bldg_office,emp_utilities_prod,emp_utilities_office,
               emp_const_bldg_prod,emp_const_bldg_office,emp_mfg_prod,emp_mfg_office,emp_whsle_whs,
               emp_trans,emp_retail,emp_prof_bus_svcs,emp_prof_bus_svcs_bldg_maint,emp_pvt_ed_k12,
               emp_pvt_ed_post_k12_oth,emp_health,emp_personal_svcs_office,emp_amusement,emp_hotel,
               emp_restaurant_bar,emp_personal_svcs_retail,emp_religious,emp_pvt_hh,emp_state_local_gov_ent,
               emp_fed_non_mil,emp_fed_mil,emp_state_local_gov_blue,emp_state_local_gov_white,emp_public_ed,
               emp_own_occ_dwell_mgmt,emp_fed_gov_accts,emp_st_lcl_gov_accts,emp_cap_accts,emp_total,civ_emp_tot)
               
mgra_id28 <- select(mgra_id28,mgra,pop,hhp,hh,gq_civ,gq_mil,emp_ag,emp_const_non_bldg_prod,emp_const_non_bldg_office,emp_utilities_prod,emp_utilities_office,
                    emp_const_bldg_prod,emp_const_bldg_office,emp_mfg_prod,emp_mfg_office,emp_whsle_whs,
                    emp_trans,emp_retail,emp_prof_bus_svcs,emp_prof_bus_svcs_bldg_maint,emp_pvt_ed_k12,
                    emp_pvt_ed_post_k12_oth,emp_health,emp_personal_svcs_office,emp_amusement,emp_hotel,
                    emp_restaurant_bar,emp_personal_svcs_retail,emp_religious,emp_pvt_hh,emp_state_local_gov_ent,
                    emp_fed_non_mil,emp_fed_mil,emp_state_local_gov_blue,emp_state_local_gov_white,emp_public_ed,
                    emp_own_occ_dwell_mgmt,emp_fed_gov_accts,emp_st_lcl_gov_accts,emp_cap_accts,emp_total,civ_emp_tot)



#melt each mgra file
mgra_id27_long<-melt(mgra_id27, id.vars=c("mgra"))

mgra_id28_long<-melt(mgra_id28, id.vars=c("mgra"))

setnames(mgra_id27_long, old="value",new="value_id27")
setnames(mgra_id28_long, old="value",new="value_id28")

#merge 2016 and 2012 for comparison
mgra_27_28<-merge(mgra_id27_long, mgra_id28_long, by=c("mgra", "variable"))

#calculate difference from new 2016 to 2012 for each variable
mgra_27_28$diff<-mgra_27_28$value_id28-mgra_27_28$value_id27



#script is updated to here
###########################
###########################
###########################










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

