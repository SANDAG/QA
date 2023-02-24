#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16; database=demographic_warehouse; trusted_connection=true')



mgra_input<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [yr]
      ,[mgra]
      ,[emp_ag]
      ,[emp_const_non_bldg_prod]
      ,[emp_const_non_bldg_office]
      ,[emp_utilities_prod]
      ,[emp_utilities_office]
      ,[emp_const_bldg_prod]
      ,[emp_const_bldg_office]
      ,[emp_mfg_prod]
      ,[emp_mfg_office]
      ,[emp_whsle_whs]
      ,[emp_trans]
      ,[emp_retail]
      ,[emp_prof_bus_svcs]
      ,[emp_prof_bus_svcs_bldg_maint]
      ,[emp_pvt_ed_k12]
      ,[emp_pvt_ed_post_k12_oth]
      ,[emp_health]
      ,[emp_personal_svcs_office]
      ,[emp_amusement]
      ,[emp_hotel]
      ,[emp_restaurant_bar]
      ,[emp_personal_svcs_retail]
      ,[emp_religious]
      ,[emp_pvt_hh]
      ,[emp_state_local_gov_ent]
      ,[emp_fed_non_mil]
      ,[emp_fed_mil]
      ,[emp_state_local_gov_blue]
      ,[emp_state_local_gov_white]
      ,[emp_public_ed]
      ,[emp_own_occ_dwell_mgmt]
      ,[emp_fed_gov_accts]
      ,[emp_st_lcl_gov_accts]
      ,[emp_cap_accts]
      ,[emp_total]
      ,[enrollgradekto8]
      ,[enrollgrade9to12]
      ,[collegeenroll]
      ,[othercollegeenroll]
      ,[adultschenrl]
      ,[hstallsoth]
      ,[hstallssam]
      ,[hparkcost]
      ,[numfreehrs]
      ,[dstallsoth]
      ,[dstallssam]
      ,[dparkcost]
      ,[mstallsoth]
      ,[mstallssam]
      ,[mparkcost]
      ,[hotelroomtotal]
  FROM [isam].[xpef33].[abm_mgra13_based_input_np]
  GROUP BY [yr]
  ,[mgra]
  ,[emp_ag]
      ,[emp_const_non_bldg_prod]
      ,[emp_const_non_bldg_office]
      ,[emp_utilities_prod]
      ,[emp_utilities_office]
      ,[emp_const_bldg_prod]
      ,[emp_const_bldg_office]
      ,[emp_mfg_prod]
      ,[emp_mfg_office]
      ,[emp_whsle_whs]
      ,[emp_trans]
      ,[emp_retail]
      ,[emp_prof_bus_svcs]
      ,[emp_prof_bus_svcs_bldg_maint]
      ,[emp_pvt_ed_k12]
      ,[emp_pvt_ed_post_k12_oth]
      ,[emp_health]
      ,[emp_personal_svcs_office]
      ,[emp_amusement]
      ,[emp_hotel]
      ,[emp_restaurant_bar]
      ,[emp_personal_svcs_retail]
      ,[emp_religious]
      ,[emp_pvt_hh]
      ,[emp_state_local_gov_ent]
      ,[emp_fed_non_mil]
      ,[emp_fed_mil]
      ,[emp_state_local_gov_blue]
      ,[emp_state_local_gov_white]
      ,[emp_public_ed]
      ,[emp_own_occ_dwell_mgmt]
      ,[emp_fed_gov_accts]
      ,[emp_st_lcl_gov_accts]
      ,[emp_cap_accts]
      ,[emp_total]
      ,[enrollgradekto8]
      ,[enrollgrade9to12]
      ,[collegeenroll]
      ,[othercollegeenroll]
      ,[adultschenrl]
      ,[hstallsoth]
      ,[hstallssam]
      ,[hparkcost]
      ,[numfreehrs]
      ,[dstallsoth]
      ,[dstallssam]
      ,[dparkcost]
      ,[mstallsoth]
      ,[mstallssam]
      ,[mparkcost]
      ,[hotelroomtotal]
  ORDER BY [yr]
                         ,[mgra]
                         ,[emp_ag]
      ,[emp_const_non_bldg_prod]
      ,[emp_const_non_bldg_office]
      ,[emp_utilities_prod]
      ,[emp_utilities_office]
      ,[emp_const_bldg_prod]
      ,[emp_const_bldg_office]
      ,[emp_mfg_prod]
      ,[emp_mfg_office]
      ,[emp_whsle_whs]
      ,[emp_trans]
      ,[emp_retail]
      ,[emp_prof_bus_svcs]
      ,[emp_prof_bus_svcs_bldg_maint]
      ,[emp_pvt_ed_k12]
      ,[emp_pvt_ed_post_k12_oth]
      ,[emp_health]
      ,[emp_personal_svcs_office]
      ,[emp_amusement]
      ,[emp_hotel]
      ,[emp_restaurant_bar]
      ,[emp_personal_svcs_retail]
      ,[emp_religious]
      ,[emp_pvt_hh]
      ,[emp_state_local_gov_ent]
      ,[emp_fed_non_mil]
      ,[emp_fed_mil]
      ,[emp_state_local_gov_blue]
      ,[emp_state_local_gov_white]
      ,[emp_public_ed]
      ,[emp_own_occ_dwell_mgmt]
      ,[emp_fed_gov_accts]
      ,[emp_st_lcl_gov_accts]
      ,[emp_cap_accts]
      ,[emp_total]
      ,[enrollgradekto8]
      ,[enrollgrade9to12]
      ,[collegeenroll]
      ,[othercollegeenroll]
      ,[adultschenrl]
      ,[hstallsoth]
      ,[hstallssam]
      ,[hparkcost]
      ,[numfreehrs]
      ,[dstallsoth]
      ,[dstallssam]
      ,[dparkcost]
      ,[mstallsoth]
      ,[mstallssam]
      ,[mparkcost]
      ,[hotelroomtotal]"),
                  stringsAsFactors = FALSE))


#retreive tables using sql code
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[jurisdiction]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  WHERE [series]=14
                  GROUP BY [mgra]
                         ,[jurisdiction]"),
                  stringsAsFactors = FALSE))

library(dplyr)
dim_mgra<-d_mgra %>% group_by(mgra) %>% mutate(counter = row_number(mgra))

dim_test<- dim_mgra %>% 
  tidyr::pivot_wider(id_cols=mgra,
                     names_from=counter,
                     names_prefix="jurisdiction_",
                     values_from=jurisdiction,
                     values_fill=NA)



library(data.table)

y<- merge(mgra_input,
          dim_test,
          by="mgra",
          allow.cartesian = TRUE,
          all.x=TRUE)


y$jurisdiction<- ifelse(is.na(y$jurisdiction_2), y$jurisdiction_1, "Mixed")

final<- y[,list(
  emp_ag=sum(emp_ag),
  emp_const_non_bldg_prod=sum(emp_const_non_bldg_prod),
  emp_const_non_bldg_office=sum(emp_const_non_bldg_office),
  emp_utilities_prod=sum(emp_utilities_prod),
  emp_utilities_office=sum(emp_utilities_office),
  emp_const_bldg_prod=sum(emp_const_bldg_prod),
  emp_const_bldg_office=sum(emp_const_bldg_office),
  emp_mfg_prod=sum(emp_mfg_prod),
  emp_mfg_office=sum(emp_mfg_office),
  emp_whsle_whs=sum(emp_whsle_whs),
  emp_trans=sum(emp_trans),
  emp_retail=sum(emp_retail),
  emp_prof_bus_svcs=sum(emp_prof_bus_svcs),
  emp_prof_bus_svcs_bldg_maint=sum(emp_prof_bus_svcs_bldg_maint),
  emp_pvt_ed_k12=sum(emp_pvt_ed_k12),
  emp_pvt_ed_post_k12_oth=sum(emp_pvt_ed_post_k12_oth),
  emp_health=sum(emp_health), 
  emp_personal_svcs_office=sum(emp_personal_svcs_office),
  emp_amusement=sum(emp_amusement),
  emp_hotel=sum(emp_hotel),
  emp_restaurant_bar=sum(emp_restaurant_bar),
  emp_personal_svcs_retail=sum(emp_personal_svcs_retail),
  emp_religious=sum(emp_religious),
  emp_pvt_hh=sum(emp_pvt_hh),
  emp_state_local_gov_ent=sum(emp_state_local_gov_ent),
  emp_fed_non_mil=sum(emp_fed_non_mil),
  emp_fed_mil=sum(emp_fed_mil),
  emp_state_local_gov_blue=sum(emp_state_local_gov_blue),
  emp_state_local_gov_white=sum(emp_state_local_gov_white),
  emp_public_ed=sum(emp_public_ed),
  emp_own_occ_dwell_mgmt=sum(emp_own_occ_dwell_mgmt),
  emp_fed_gov_accts=sum(emp_fed_gov_accts),
  emp_st_lcl_gov_accts=sum(emp_st_lcl_gov_accts),
  emp_cap_accts=sum(emp_cap_accts),
  emp_total=sum(emp_total),
  enrollgradekto8=sum(enrollgradekto8),
  enrollgrade9to12=sum(enrollgrade9to12),
  collegeenroll=sum(collegeenroll),
  othercollegeenroll=sum(othercollegeenroll),
  adultschenrl=sum(adultschenrl),
  hstallsoth=sum(hstallsoth),
  hstallssam=sum(hstallssam),
  hparkcost=mean(hparkcost),
  dstallsoth=sum(dstallsoth),
  dstallssam=sum(dstallssam),
  dparkcost=mean(dparkcost),
  mstallsoth=sum(mstallsoth),
  mstallssam=sum(mstallssam),
  mparkcost=mean(mparkcost),
  hotel_total=sum(hotelroomtotal)),
  by=c("jurisdiction", "yr")]

#saveout merged table
write.csv(final, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Results//PowerBI//mgra_input_jur.csv")
