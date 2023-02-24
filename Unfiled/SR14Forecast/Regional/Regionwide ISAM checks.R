#ISAM Regionwide Forecast total population by gender check
#there was an issue saving to Phase 3 folder so the final file was manually moved to Phase 3 after saving to Results folder

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable", "openxlsx")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=isam; trusted_connection=true')

isam_HH <-sqlQuery(channel,"SELECT yr
              ,COUNT(sex) as sex_count_hh
              ,COUNT(CASE WHEN sex = 'F' THEN sex  END) as female_hh
              ,COUNT(CASE WHEN sex = 'M' THEN sex  END) as male_HH
              ,COUNT(sex) - (COUNT(CASE WHEN sex = 'F' THEN sex  END) + COUNT(CASE WHEN sex = 'M' THEN sex  END)) as diff
              FROM isam.xpef05.household_population
              GROUP BY yr 
              ORDER BY yr DESC, sex_count_hh DESC")


isam_GQ <-sqlQuery(channel,"SELECT yr
                      ,COUNT(sex) as sex_count_gq
                      ,COUNT(CASE WHEN sex = 'F' THEN sex  END) as female_gq
                      ,COUNT(CASE WHEN sex = 'M' THEN sex  END) as male_gq
                      ,COUNT(sex) - (COUNT(CASE WHEN sex = 'F' THEN sex  END) + COUNT(CASE WHEN sex = 'M' THEN sex  END)) as diff_gq
                      FROM isam.xpef05.gq_population
                      GROUP BY yr 
                      ORDER BY yr DESC, sex_count_gq DESC")

write.csv(isam_HH, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\isam_hh_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(isam_GQ, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\isam_gq_sql",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))


tail(isam_GQ)
tail(isam_HH)

isam_tot_gender <- merge(isam_HH, isam_GQ, by.a="yr", by.b="yr", all=TRUE)

isam_tot_gender$isam_tot_pop<-isam_tot_gender$sex_count_hh+isam_tot_gender$sex_count_gq

head(isam_tot_gender)
isam_tot_gender$female_tot<- isam_tot_gender$female_hh + isam_tot_gender$female_gq
isam_tot_gender$male_tot<- isam_tot_gender$male_HH + isam_tot_gender$male_gq

write.csv(isam_tot_gender,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\isam_tot_gender.csv")


