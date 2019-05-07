#base year household 2016 id27 to id17 comparison


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("sqldf", "rstudioapi", "RODBC", "tidyverse", "reshape")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

options(stringsAsFactors=FALSE)
options(scipen=9)

#read in household files for 2016 ID27 and ID17
hh<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\households_2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")
hh_old<-read.csv('T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2016\\households.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

#median hhincome, unique taz and unique mgra
median(hh$hinc)
taz_unique <- unique(hh$taz)
mgra_unique <- unique(hh$mgra)

median(hh_old$hinc)
taz_old_unique <- unique(hh_old$taz)
mgra_old_unique <- unique(hh_old$MGRA)

#exclude variables that don't make sense
hh %<>% select(-c(hhid,household_serial_no,taz,hinc,bldgsz,version,poverty))
hh_old %<>% select(-c(hhid,household_serial_no,taz,hinc,bldgsz,version,poverty))

#melt household file
hh_long<-melt(hh, id.vars=c("mgra"))
hh_old_long<-melt(hh_old, id.vars=c("MGRA"))

#count records
hh_tot  <- hh_long %>% group_by(variable,value) %>% tally()
hh_old_tot  <- hh_old_long %>% group_by(variable,value) %>% tally()

setnames(hh_tot, old="n",new="sum_id27")
setnames(hh_old_tot, old="n",new="sum_id17")

#merge 2016 ID27 with ID17 for comparison
hh_merge<-merge(hh_tot, hh_old_tot, by=c("variable","value"))

#calculate difference from ID27 to ID17 for each variable
hh_merge$diff<-hh_merge$sum_id27-hh_merge$sum_id17

head(hh_merge)
hh_summary <- hh_merge %>%
  group_by(variable) %>%
  summarise(sum_id27 = sum(sum_id27,na.rm=TRUE),sum_id17 = sum(sum_id17,na.rm=TRUE),diff = sum(diff,na.rm=TRUE))


write.csv(hh_merge, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\hh id27 to id17.csv",row.names = FALSE )
write.csv(hh_summary, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\hh id27 to id17 summary.csv",row.names = FALSE )
