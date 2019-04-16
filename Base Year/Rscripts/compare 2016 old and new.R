#base year 2016 EDAM to old 2016 ABM comparison


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("sqldf", "rstudioapi", "RODBC", "dplyr", 
              "stringr","tidyverse")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

options(stringsAsFactors=FALSE)


#read in mgra files for 2016 and 2012
mgra<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\mgra13_based_input2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")
mgra_old<-read.csv('T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2016\\mgra13_based_input2016.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")


#ABM version of 2012
#mgra_2012_ABM<-read.csv('T:\\ABM\\release\\ABM\\version_13_3_2\\input\\2012\\mgra13_based_input2012.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

#mgra_2012<-read.csv('T:\\socioec\\Current_Projects\\XPEF06_2012\\abm_csv\\mgra13_based_input2012.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")


#melt each mgra file
mgra_long<-melt(mgra, id.vars=c("mgra"))

mgra_old_long<-melt(mgra_old, id.vars=c("mgra"))

setnames(mgra_long, old="value",new="value")
setnames(mgra_old_long, old="value",new="value_old")

#merge 2016 and 2012 for comparison
mgra_16s<-merge(mgra_long, mgra_old_long, by=c("mgra", "variable"))

#calculate difference from new 2016 to 2012 for each variable
mgra_16s$diff<-mgra_16s$value-mgra_16s$value_old

summary(mgra_16s$diff)

colnames(mgra)

school <- subset(mgra_16s, mgra_16s$variable=="enrollgradekto8"| mgra_16s$variable=="collegeenroll"|mgra_16s$variable=="othercollegeenroll"|
                   mgra_16s$variable=="adultschenrl")
class(school$variable)

school$variable2 <- as.character(school$variable)

summary(school$diff)

school_tot <- aggregate(cbind())

school_diff <- subset(school, school$diff!=0)
head(school_diff)


school_diff$abs_diff <- abs(school_diff$diff)

by(school_diff, school_diff$variable2, sum(school_diff$diff))


sum(school_diff$diff)


summary <- hhinc %>%
  select(count_households_2012,count_households_2016,JUR2,geography_name,geography) %>%
  group_by(JUR2,geography_name,geography) %>%
  summarise(hh2012 = sum(count_households_2012,na.rm=TRUE),hh2016 = sum(count_households_2016,na.rm=TRUE))
tidyverse
