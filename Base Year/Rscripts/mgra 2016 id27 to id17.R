#base year 2016 EDAM to old 2016 ABM comparison


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("sqldf", "rstudioapi", "RODBC", "tidyverse")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

options(stringsAsFactors=FALSE)
options(scipen=9)

#read in mgra files for 2016 ID27 and ID17
mgra<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")
mgra_old<-read.csv('T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2016\\mgra13_based_input2016.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

mgra %<>% select(-c(taz,hhs,emp_ag,emp_const_non_bldg_prod,emp_const_non_bldg_office,emp_utilities_prod,emp_utilities_office,
                          emp_const_bldg_prod,emp_const_bldg_office,emp_mfg_prod,emp_mfg_office,emp_whsle_whs,
                          emp_trans,emp_retail,emp_prof_bus_svcs,emp_prof_bus_svcs_bldg_maint,emp_pvt_ed_k12,
                          emp_pvt_ed_post_k12_oth,emp_health,emp_personal_svcs_office,emp_amusement,emp_hotel,
                          emp_restaurant_bar,emp_personal_svcs_retail,emp_religious,emp_pvt_hh,emp_state_local_gov_ent,
                          emp_fed_non_mil,emp_fed_mil,emp_state_local_gov_blue,emp_state_local_gov_white,emp_public_ed,
                          emp_own_occ_dwell_mgmt,emp_fed_gov_accts,emp_st_lcl_gov_accts,emp_cap_accts))

mgra_old %<>% select(-c(taz,hhs,emp_ag,emp_const_non_bldg_prod,emp_const_non_bldg_office,emp_utilities_prod,emp_utilities_office,
                          emp_const_bldg_prod,emp_const_bldg_office,emp_mfg_prod,emp_mfg_office,emp_whsle_whs,
                          emp_trans,emp_retail,emp_prof_bus_svcs,emp_prof_bus_svcs_bldg_maint,emp_pvt_ed_k12,
                          emp_pvt_ed_post_k12_oth,emp_health,emp_personal_svcs_office,emp_amusement,emp_hotel,
                          emp_restaurant_bar,emp_personal_svcs_retail,emp_religious,emp_pvt_hh,emp_state_local_gov_ent,
                          emp_fed_non_mil,emp_fed_mil,emp_state_local_gov_blue,emp_state_local_gov_white,emp_public_ed,
                          emp_own_occ_dwell_mgmt,emp_fed_gov_accts,emp_st_lcl_gov_accts,emp_cap_accts))
#melt each mgra file
mgra_long<-melt(mgra, id.vars=c("mgra"))

mgra_old_long<-melt(mgra_old, id.vars=c("mgra"))

setnames(mgra_long, old="value",new="value_id27")
setnames(mgra_old_long, old="value",new="value_id17")

#merge 2016 ID27 with ID17 for comparison
mgra_16s<-merge(mgra_long, mgra_old_long, by=c("mgra", "variable"))

#calculate difference from new 2016 to 2012 for each variable
mgra_16s$diff<-mgra_16s$value_id27-mgra_16s$value_id17

mgra_17_27<-aggregate(cbind(value_id27,value_id17,diff)~variable, data=mgra_16s, sum)

#subset a file
mgra_17_27_diff <- subset(mgra_17_27, mgra_17_27$diff!=0)

write.csv(mgra_17_27, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\mgra id27 to id17.csv",row.names = FALSE )

write.csv(mgra_17_27_diff, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\mgra id27 to id17 difference.csv",row.names = FALSE )




# #script for school differences specifically
# school <- subset(mgra_16s, mgra_16s$variable=="enrollgradekto8"| mgra_16s$variable=="collegeenroll"|mgra_16s$variable=="othercollegeenroll"|
#                    mgra_16s$variable=="adultschenrl")
# class(school$variable)
# 
# school$variable2 <- as.character(school$variable)
# 
# summary(school$diff)
# 
# #sum variables
# school_summary <- school_diff %>%
#   select(value_id27,value_id17,diff,variable2) %>%
#   group_by(variable2) %>%
#   summarise(id27_tot = sum(value_id27,na.rm=TRUE),id17_tot = sum(value_id17,na.rm=TRUE),diff_tot = sum(diff,na.rm=TRUE))




