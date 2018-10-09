pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

#setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

hh_var18<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 5\\hh_hhp_hhs_hu_vac_age_comparison.csv"
hh_var17<-"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 4\\hh_hhp_hhs_hu_vac_age_comparison.csv"

