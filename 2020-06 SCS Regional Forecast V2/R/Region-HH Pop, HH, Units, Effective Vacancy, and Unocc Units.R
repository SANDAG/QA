## Project name: SCS Forecast Revised - August 2020
# This script was developed for test 1,2, 8, and 11 of the SCS forecast QA [DS 38] for analysis at three geographic levels: 
# a. Region
# b. Jurisdiction
# c. CPA
# d. Priority Area= In Mobility Hub or Smart Growth Area or both

#Setting up the R environment
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../queries/readSQL.R")
source("mohub_smartgrowth.R")
source("common_functions.R")
source("Data_HH_GQ_Vac_Unocc.R")

# Loading the packages
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)

readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}

# Creating path for saving results
outputfile <- paste("HH_Pop_GQ_Vacancy","_SCS_v2","_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-06 SCS Regional Forecast V2\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))


## 1. Region level analysis

## households
hh_38_region<- hh_38%>%
  filter(geotype== "region")

setnames(hh_38_region, old=c("households","units", "hhp","hhs"), new=c("hh_scs", "units_scs", "hhp_scs", "hhs_scs"))

hh_35_region<- hh_35%>%
  filter(geotype== 'region')

setnames(hh_35_region, old=c("households","units", "hhp","hhs"), new=c("hh_35", "units_35", "hhp_35", "hhs_35"))

## Group quarter 

gq_38_region<- gq_38%>%
  filter(geotype== "region")

setnames(gq_38_region, old=c("gqpop"), new=c("gqpop_scs"))

gq_35_region<- gq_35%>%
  filter(geotype== "region")

setnames(gq_35_region, old=c("gqpop"), new=c("gqpop_35"))

## merging hh with GQ

hh_gq_region_scs <- merge(hh_38_region, gq_38_region, by.x = c("datasource_id", "yr_id", "geotype", "geozone"), by.y = c("datasource_id","yr_id", "geotype", "geozone"), all=TRUE)

hh_gq_region_35 <- merge(hh_35_region, gq_35_region, by.x = c("datasource_id", "yr_id", "geotype", "geozone"), by.y = c("datasource_id","yr_id", "geotype", "geozone"), all=TRUE)

hh_gq_region<- merge(hh_gq_region_scs, hh_gq_region_35, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE) 

hh_gq_region<- subset(hh_gq_region,select= -c(datasource_id.x, datasource_id.y))

# mergine DOF data for comparison
hh_gq_dof_region <- merge(hh_gq_region, dof, by.x = "yr_id", by.y = "yr_id", all=TRUE)
hh_gq_dof_region$dof_pop<- as.numeric(hh_gq_dof_region$dof_pop)

# adding effective vacancy data for comparison

vac_unocc_38_region<- mgra_38%>%
  group_by(yr_id)%>%
  summarise_at(vars(vacancy, unoccupiable), funs(sum))
  
setnames(vac_unocc_38_region, old=c("vacancy","unoccupiable"), new=c("vac_38", "unocc_38"))

vac_unocc_35_region<- mgra_35%>%
  group_by(yr_id)%>%
  summarise_at(vars(vacancy,unoccupiable), funs(sum))

setnames(vac_unocc_35_region, old=c("vacancy","unoccupiable"), new=c("vac_35", "unocc_35"))

vac_unocc_region<- merge(vac_unocc_35_region, vac_unocc_38_region, by.x = "yr_id", by.y = "yr_id", all = TRUE)

hh_gq_dof_region<- merge(hh_gq_dof_region, vac_unocc_region, by = "yr_id", all = TRUE)
                         
#comparing scs, DS 35 (base), and DOF
 
hh_gq_dof_region<- hh_gq_dof_region%>%
  mutate(scs_totpop= hhp_scs + gqpop_scs, 
         dof_scs_pop= dof_pop- scs_totpop, 
         dof_scs_percent_diff= (dof_scs_pop*100)/dof_pop, 
         scs_base_hhp_diff= hhp_scs- hhp_35,
         scs_base_hh_diff= hh_scs- hh_35,
         scs_base_units_diff= units_scs- units_35,
         scs_base_GQ_diff= gqpop_scs- gqpop_35, 
         scs_base_vac_diff= vac_38- vac_35,
         scs_base_unocc_diff= unocc_38- unocc_35)%>%
  mutate_if(is.numeric,round, 3)



## 2. Jurisdiction level analysis

hh_38_jur<- hh_38%>%
  filter(geotype== "jurisdiction")

setnames(hh_38_jur, old=c("households","units", "hhp","hhs"), new=c("hh_scs", "units_scs", "hhp_scs", "hhs_scs"))

hh_35_jur<- hh_35%>%
  filter(geotype== 'jurisdiction')

setnames(hh_35_jur, old=c("households","units", "hhp","hhs"), new=c("hh_35", "units_35", "hhp_35", "hhs_35"))


gq_38_jur<- gq_38%>%
  filter(geotype== "jurisdiction")

setnames(gq_38_jur, old=c("gqpop"), new=c("gqpop_scs"))

gq_35_jur<- gq_35%>%
  filter(geotype== "jurisdiction")

setnames(gq_35_jur, old=c("gqpop"), new=c("gqpop_35"))



hh_gq_jur_scs <- merge(hh_38_jur, gq_38_jur, by.x = c("datasource_id", "yr_id", "geotype", "geozone"), by.y = c("datasource_id","yr_id", "geotype", "geozone"), all=TRUE)

hh_gq_jur_35 <- merge(hh_35_jur, gq_35_jur, by.x = c("datasource_id", "yr_id", "geotype", "geozone"), by.y = c("datasource_id","yr_id", "geotype", "geozone"), all=TRUE)

hh_gq_jur<- merge(hh_gq_jur_scs, hh_gq_jur_35, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE) 

hh_gq_jur<- subset(hh_gq_jur,select= -c(datasource_id.x, datasource_id.y))



hh_gq_jur<- hh_gq_jur%>%
  mutate(scs_base_hhp_diff= hhp_scs- hhp_35,
         scs_base_hh_diff= hh_scs- hh_35,
         scs_base_units_diff= units_scs- units_35,
         scs_base_GQ_diff= gqpop_scs- gqpop_35)%>%
         mutate_if(is.numeric,round, 1)

##adding Jurisdiction ids by merging the two tables

hh_gq_jur<- merge(hh_gq_jur, jur_dt, by.x = "geozone", by.y = "jurisdiction", all= TRUE)

## adding vacany and unoccupiable units to the jurisdiction table 

mgra_38<- merge(dim_mgra, mgra_38, by.x = "mgra_id", by.y = "mgra_id", all= TRUE)
mgra_35<- merge(dim_mgra, mgra_35, by.x = "mgra_id", by.y = "mgra_id", all= TRUE)


vac_occ_38_jur<- mgra_38%>%
  group_by(yr_id, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(vacancy,unoccupiable), funs(sum))
  

vac_occ_35_jur<- mgra_35%>%
  group_by(yr_id, jurisdiction, jurisdiction_id)%>%
  summarise_at(vars(vacancy, unoccupiable), funs(sum))

setnames(vac_occ_38_jur, old=c("vacancy", "unoccupiable"), new=c("vac_38", "unocc_38"))
setnames(vac_occ_35_jur, old=c("vacancy", "unoccupiable"), new=c("vac_35", "unocc_35"))

vac_occ_35_38<- merge(vac_occ_35_jur, vac_occ_38_jur, by.x = c("yr_id", "jurisdiction_id", "jurisdiction"), by.y = c("yr_id", "jurisdiction_id", "jurisdiction"), all = TRUE)

##final jurisdiction df hh_gq_jur_final
hh_gq_jur_final<- merge(hh_gq_jur, vac_occ_35_38, by.x = c("yr_id", "geozone"), by.y = c("yr_id", "jurisdiction"), all= TRUE)


## 3. RHNA Comparison

hh_gq_jur_rhna<- hh_gq_jur%>%
  filter(yr_id== 2020 | yr_id== 2035)%>%
  arrange(yr_id)%>%
  group_by(geozone)%>%
  mutate(housing_diff_scs= units_scs- lag(units_scs, default = NA),
         housing_diff_DS35= units_35- lag(units_35, default = NA))%>%
  filter(yr_id==2035)

hh_gq_jur_rhna<- merge(hh_gq_jur_rhna, rhna, by.x = "geozone", by.y = "jurisdiction", all = TRUE)

hh_gq_jur_rhna<- hh_gq_jur_rhna%>%
  select(c(geozone, yr_id, housing_diff_scs,housing_diff_DS35,units_total_rhna6))


##4. Priority Area Analysis 

## Step 1. We first combine mgra_38 and mgra_pop_38 to have a combined list of all variables at the MGRA level

mgra_all_38<- merge(mgra_38, mgra_pop_38, by = c("mgra_id", "yr_id"), all = TRUE)
setnames(mgra_all_38, old = c("units", "unoccupiable", "occupied", "vacancy", "population"), new = c("units_scs", "unocc_scs", "occup_scs", "vac_scs", "pop_scs"))

mgra_all_35<- merge(mgra_35, mgra_pop_35, by = c("mgra_id", "yr_id"), all = TRUE)

setnames(mgra_all_35, old = c("units", "unoccupiable", "occupied", "vacancy", "population"), new = c("units_35", "unocc_35", "occup_35", "vac_35", "pop_35"))

## Step 2. We first combine mgra_38 and mgra_pop_38 to have a combined list of all variables at the MGRA level

mgra_all<- merge(mgra_all_35, mgra_all_38, by= c("mgra_id", "yr_id"), all = TRUE)

## Step 3. Merging mgra_all with dim_mohub_sg
mgra_pri<- merge(mgra_all, dim_mohub_sg, by= c("mgra_id"), all = TRUE)

## 4a. Region level 

mgra_pri_region<- mgra_pri%>%
  group_by(yr_id, scs_flag)%>%
  summarise_at(vars(units_scs, units_35, pop_scs, pop_35,vac_35, vac_scs, unocc_35, unocc_scs, occup_35, occup_scs), funs(sum))

mgra_pri_region[is.na(mgra_pri_region)]<- 0

## 4b. Jurisdiction level 

mgra_pri_jur<- mgra_pri%>%
  group_by(yr_id, scs_flag, jurisdiction)%>%
  summarise_at(vars(units_scs, units_35, pop_scs, pop_35,vac_35, vac_scs, unocc_35, unocc_scs, occup_35, occup_scs), funs(sum))

mgra_pri_jur[is.na(mgra_pri_jur)]<- 0

mgra_pri_jur_in<- mgra_pri_jur%>%
  filter(scs_flag== 1)
colnames(mgra_pri_jur_in) <- paste(colnames(mgra_pri_jur_in), "in", sep = "_")


mgra_pri_jur_out<- mgra_pri_jur%>%
  filter(scs_flag== 0)

colnames(mgra_pri_jur_out) <- paste(colnames(mgra_pri_jur_out), "out", sep = "_")

mgra_pri_jur_final<- merge(mgra_pri_jur_in, mgra_pri_jur_out, by.x = c("yr_id_in", "jurisdiction_in"), by.y = c("yr_id_out", "jurisdiction_out"), all= TRUE )


## 5a.CPA level

dim_mgra_mohub<- merge(dim_mgra, dim_mohub_sg, by =  c("mgra_id", "jurisdiction"), all=TRUE)
cpa_mgra<- merge(dim_mgra_mohub, mgra_all, by.x = c("mgra_id", "cpa", "jurisdiction"),by.y = c("mgra_id", "cpa.x", "jurisdiction.x"), all= TRUE)

cpa<- cpa_mgra%>%
  group_by(cpa, jurisdiction, yr_id)%>%
  summarise_at(vars(units_scs, units_35, pop_scs, pop_35,vac_35, vac_scs, unocc_35, unocc_scs, occup_35, occup_scs), funs(sum))

##gq_cpa_38<- gq_38%>%
##  filter(geotype== "cpa")


##cpa<- merge(cpa, gq_35, by.x = c("cpa", "yr_id"), by.y = c("geozone", "yr_id"), all = TRUE)
##cpa<- merge(cpa, gq_38, by.x = c("cpa", "yr_id"), by.y = c("geozone", "yr_id"), all = TRUE)


## 5b.CPA level_priority analysis

cpa_mgra[["scs_flag"]][is.na(cpa_mgra[["scs_flag"]])] <- 0

cpa_pri_in<- cpa_mgra%>%
  filter(scs_flag==1)

cpa_pri_in<- cpa_pri_in%>%
  group_by(cpa, yr_id, jurisdiction)%>%
  summarise_at(vars(units_scs, units_35, pop_scs, pop_35,vac_35, vac_scs, unocc_35, unocc_scs, occup_35, occup_scs), funs(sum))

cpa_pri_out<- cpa_mgra%>%
  filter(scs_flag==0)

cpa_pri_out<- cpa_pri_out%>%
  group_by(cpa, yr_id, jurisdiction)%>%
  summarise_at(vars(units_scs, units_35, pop_scs, pop_35,vac_35, vac_scs, unocc_35, unocc_scs, occup_35, occup_scs), funs(sum))

cpa_pri<- merge(cpa_pri_in, cpa_pri_out, by = c("yr_id", "cpa", "jurisdiction"), all= TRUE)

names(cpa_pri) <- gsub(x = names(cpa_pri), pattern = ".x", replacement = "_in")  
names(cpa_pri) <- gsub(x = names(cpa_pri), pattern = ".y", replacement = "_out")  


#saving and formatting output

wb1 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

region = addWorksheet(wb1, "Region", tabColour = "red")
writeData(wb1, "Region", hh_gq_dof_region)
addStyle(wb1,region, style = headerStyle, rows = 1, cols = 1: ncol(hh_gq_dof_region), gridExpand = TRUE)

jurisdiction = addWorksheet(wb1, "Jurisdiction", tabColour = "blue")
writeData(wb1, "Jurisdiction", hh_gq_jur_final)
addStyle(wb1,jurisdiction, style = headerStyle, rows = 1, cols = 1: ncol(hh_gq_jur), gridExpand = TRUE)

rhna = addWorksheet(wb1, "RHNA-DS38", tabColour = "yellow")
writeData(wb1, "RHNA-DS38", hh_gq_jur_rhna)
addStyle(wb1,rhna, style = headerStyle, rows = 1, cols = 1: ncol(hh_gq_jur), gridExpand = TRUE)

pri_reg = addWorksheet(wb1, "PriorityArea_Region", tabColour = "cyan")
writeData(wb1, "PriorityArea_Region", mgra_pri_region)
addStyle(wb1,pri_reg, style = headerStyle, rows = 1, cols = 1: ncol(mgra_pri_region), gridExpand = TRUE)

pri_jur = addWorksheet(wb1, "PriorityArea_Jur", tabColour = "green")
writeData(wb1, "PriorityArea_Jur", mgra_pri_jur_final)
addStyle(wb1,pri_jur, style = headerStyle, rows = 1, cols = 1: ncol(mgra_pri_jur_final), gridExpand = TRUE)

saveWorkbook(wb1, outfile,overwrite=TRUE)

## saving CPA results in separate folder

wb2 = createWorkbook()
headerStyle<- createStyle(fontSize = 12 ,textDecoration = "bold")

cpa1 = addWorksheet(wb2, "CPA", tabColour = "blue")
writeData(wb2, "CPA", cpa)
addStyle(wb2,cpa1, style = headerStyle, rows = 1, cols = 1: ncol(cpa), gridExpand = TRUE)

cpa2 = addWorksheet(wb2, "PriorityArea_CPA", tabColour = "blue")
writeData(wb2, "PriorityArea_CPA", cpa_pri)
addStyle(wb2,cpa2, style = headerStyle, rows = 1, cols = 1: ncol(cpa_pri), gridExpand = TRUE)

saveWorkbook(wb2, outfolder,overwrite=TRUE)



##mohub= addWorksheet(wb1, "Mohub Aggregate", tabColour = "green")
##writeData(wb1, "Mohub Aggregate", mohub_agg)
##addStyle(wb1,mohub, style = headerStyle, rows = 1, cols = 1: ncol(mohub_agg), gridExpand = TRUE)








