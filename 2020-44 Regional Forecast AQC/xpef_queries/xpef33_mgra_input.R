#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')



mgra_input<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [yr]
                  ,[mgra]
      ,sum([emp_ag]) as [emp_ag]
      ,sum([emp_const_non_bldg_prod]) as [emp_const_non_bldg_prod] 
      ,sum([emp_const_non_bldg_office]) as [emp_const_non_bldg_office]
      ,sum([emp_utilities_prod]) as [emp_utilities_prod]
      ,sum([emp_utilities_office]) as [emp_utilities_office]
      ,sum([emp_const_bldg_prod]) as [emp_const_bldg_prod]
      ,sum([emp_const_bldg_office]) as [emp_const_bldg_office]
      ,sum([emp_mfg_prod]) as [emp_mfg_prod]
      ,sum([emp_mfg_office]) as [emp_mfg_office]
      ,sum([emp_whsle_whs]) as [emp_whsle_whs]
      ,sum([emp_trans]) as [emp_trans]
      ,sum([emp_retail]) as [emp_retail]
      ,sum([emp_prof_bus_svcs]) as [emp_prof_bus_svcs]
      ,sum([emp_prof_bus_svcs_bldg_maint]) as [emp_prof_bus_svcs_bldg_maint]
      ,sum([emp_pvt_ed_k12]) as [emp_pvt_ed_k12]
      ,sum([emp_pvt_ed_post_k12_oth]) as [emp_pvt_ed_post_k12_oth]
      ,sum([emp_health]) as [emp_health] 
      ,sum([emp_personal_svcs_office]) as [emp_personal_svcs_office]
      ,sum([emp_amusement]) as [emp_amusement]
      ,sum([emp_hotel]) as [emp_hotel]
      ,sum([emp_restaurant_bar]) as [emp_restaurant_bar]
      ,sum([emp_personal_svcs_retail]) as [emp_personal_svcs_retail]
      ,sum([emp_religious]) as [emp_religious]
      ,sum([emp_pvt_hh]) as [emp_pvt_hh]
      ,sum([emp_state_local_gov_ent]) as [emp_state_local_gov_ent]
      ,sum([emp_fed_non_mil]) as [emp_fed_non_mil]
      ,sum([emp_fed_mil]) as [emp_fed_mil]
      ,sum([emp_state_local_gov_blue]) as [emp_state_local_gov_blue]
      ,sum([emp_state_local_gov_white]) as [emp_state_local_gov_white]
      ,sum([emp_public_ed]) as [emp_public_ed]
      ,sum([emp_own_occ_dwell_mgmt]) as [emp_own_occ_dwell_mgmt]
      ,sum([emp_fed_gov_accts]) as [emp_fed_gov_accts]
      ,sum([emp_st_lcl_gov_accts]) as [emp_st_lcl_gov_accts]
      ,sum([emp_cap_accts]) as [emp_cap_accts]
      ,sum([emp_total]) as [emp_total]
      ,sum([enrollgradekto8]) as [enrollgradekto8]
      ,sum([enrollgrade9to12]) as [enrollgrade9to12]
      ,sum([collegeenroll]) as [collegeenroll]
      ,sum([othercollegeenroll]) as [othercollegeenroll]
      ,sum([adultschenrl]) as [adultschenrl]
      ,sum([hstallsoth]) as [hstallsoth]
      ,sum([hstallssam]) as [hstallssam]
      ,avg([hparkcost]) as [hparkcost]
      ,sum([dstallsoth]) as [dstallsoth]
      ,sum([dstallssam]) as [dstallssam]
      ,avg([dparkcost]) as [dparkcost]
      ,sum([mstallsoth]) as [mstallsoth]
      ,sum([mstallssam]) as [mstallssam]
      ,avg([mparkcost]) as [mparkcost]
      ,sum([hotelroomtotal]) as hotel_total
  FROM [isam].[xpef33].[abm_mgra13_based_input_np]
  GROUP BY [yr]
  ,[mgra]
  ORDER BY [yr]
                         ,[mgra]"),
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

#final<- y[,list(
#  pstudent=sum(pstudent),
#  pop=sum(pop)),
#  by=c("jurisdiction", "yr", "rac1p","ptype","pstudent", "pemploy","age_rc")]

#saveout merged table
write.csv(y, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Results//PowerBI//syn_persons_jur.csv")
