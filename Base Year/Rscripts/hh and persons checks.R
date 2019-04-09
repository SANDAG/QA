#hh and persons base year 2016
#created 4/8/2019

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
#DELETE?
#source("../Queries/readSQL.R")
#######

# hh
hh <- read.csv("T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\households_2016_01.csv",stringsAsFactors = FALSE)


median(hh$hinc)


# persons
persons<- read.csv("T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\persons_2016_01.csv",stringsAsFactors = FALSE)


median(persons$age)


#EXECUTE dbo.compute_median_income_all_zones 27, 'region'

#EXECUTE dbo.compute_median_age_all_zones 27, 'region'

head(hh)

hh2persons <- merge(hh,persons,by.x = "hhid",by.y = "hhid",all = TRUE)
head(hh2persons)

###recheck - why doesn't this work? needs to be ifelse

hh2persons$ethn <- NULL
hh2persons$ethn <- hh2persons$hisp
hh2persons$ethn[hh2persons$ethn==1] <-0
hh2persons$ethn[hh2persons$ethn==2] <-10
hh2persons$ethn[hh2persons$ethn==0] <- hh2persons$rac1p
table(hh2persons$ethn[hh2persons$hht==0])

table(hh2persons$ethn,hh2persons$unittype)
table(hh2persons$rac1p,hh2persons$hisp)

table(hh2persons$rac1p,hh2persons$ethn)
##############

#VALUE LABELS 
#ethn 1 "White" 2 "Black" 3 "Amer Ind" 4 "Alaska Nat" 5 "Amer Ind\Alk Nat" 6 "Asian" 7 "Hawaiian\PI" 8 "Other" 9 "2+ other" 10 "Hispanic". 
#unittype 0 "household" 1 "non-institutional group quarters

hh_only <- subset(hh2persons, hh2persons$unittype==0)

table(hh_only$ethn,hh_only$unittype)
table(hh_only$rac1p,hh_only$hisp)
