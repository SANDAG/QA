#in response to WU email November 5, 2019
#Question: So looks like we keep the non-traveling GQ pop constant at 46K in 2035?
#Data file: T:\socioec\Current_Projects\XPEF23\abm_csv

#read in household files
hh_18 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2018_01.csv")

hh_20 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2020_01.csv")

hh_25 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2025_01.csv")

hh_30 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2030_01.csv")

hh_35 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2035_01.csv")

hh_40 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2040_01.csv")

hh_45 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2045_01.csv")

hh_50 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\households_2050_01.csv")


#read in mgra files
mgra_16 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2016_01.csv")

mgra_18 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2018_01.csv")

mgra_20 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2020_01.csv")

mgra_25 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2025_01.csv")

mgra_30 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2030_01.csv")

mgra_35 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2035_01.csv")

mgra_40 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2040_01.csv")

mgra_45 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2045_01.csv")

mgra_50 <- read.csv("T:\\socioec\\Current_Projects\\XPEF23\\abm_csv\\mgra13_based_input2050_01.csv")

#calculate the total group quarter number
mgra_18$gq18 <- mgra_18$gq_civ+mgra_18$gq_mil
mgra_20$gq20 <- mgra_20$gq_civ+mgra_20$gq_mil
mgra_25$gq25 <- mgra_25$gq_civ+mgra_25$gq_mil
mgra_30$gq30 <- mgra_30$gq_civ+mgra_30$gq_mil
mgra_35$gq35 <- mgra_35$gq_civ+mgra_35$gq_mil
mgra_40$gq40 <- mgra_40$gq_civ+mgra_40$gq_mil
mgra_45$gq45 <- mgra_45$gq_civ+mgra_45$gq_mil
mgra_50$gq50 <- mgra_50$gq_civ+mgra_50$gq_mil

#calculate the group quarter excluded from the household file
excluded_gq_18 <- sum(mgra_18$gq18)-nrow(hh_18[hh_18$bldgsz==9,])
excluded_gq_20 <- sum(mgra_20$gq20)-nrow(hh_20[hh_20$bldgsz==9,])
excluded_gq_25 <- sum(mgra_25$gq25)-nrow(hh_25[hh_25$bldgsz==9,])
excluded_gq_30 <- sum(mgra_30$gq30)-nrow(hh_30[hh_30$bldgsz==9,])
excluded_gq_35 <- sum(mgra_35$gq35)-nrow(hh_35[hh_35$bldgsz==9,])
excluded_gq_40 <- sum(mgra_40$gq40)-nrow(hh_40[hh_40$bldgsz==9,])
excluded_gq_45 <- sum(mgra_45$gq45)-nrow(hh_45[hh_45$bldgsz==9,])
excluded_gq_50 <- sum(mgra_50$gq50)-nrow(hh_50[hh_50$bldgsz==9,])

#view results
excluded_gq_18
excluded_gq_20
excluded_gq_25
excluded_gq_30
excluded_gq_35
excluded_gq_40
excluded_gq_45
excluded_gq_50
