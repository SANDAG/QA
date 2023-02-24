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

hh_var18<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 5\\hh_hhp_hhs_hu_vac_age_comparison.csv", stringsAsFactors = FALSE)
hh_var17<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 5\\hh_hhp_hhs_hu_vac_age_comparison17.csv", stringsAsFactors = FALSE)

hh_var17[c("hh_numchg", "hhp_numchg", "hhs_numchg", "hh_pctchg", "hhp_pctchg", "hhs_pctchg", "units_numchg", "units_pctchg", "vac_numchg", "vac_pctchg", "age_numchg", "age_pctchg")]<-list(NULL)
hh_var18[c("hh_numchg", "hhp_numchg", "hhs_numchg", "hh_pctchg", "hhp_pctchg", "hhs_pctchg", "units_numchg", "units_pctchg", "vac_numchg", "vac_pctchg", "age_numchg", "age_pctchg")]<-list(NULL)

hh_var17$geozone[hh_var17$geotype=="region"]<- "Region"
hh_var17$geozone[hh_var17$geozone=="Los PeÃ±asquitos Canyon Preserve"]<- "Los Peñasquitos Canyon Preserve"
hh_var17$geozone[hh_var17$geozone=="Rancho PeÃ±asquitos"]<- "Rancho Peñasquitos"

hh_var17$geozone <- gsub("\\*","",hh_var17$geozone)
hh_var17$geozone <- gsub("\\-","_",hh_var17$geozone)
hh_var17$geozone <- gsub("\\:","_",hh_var17$geozone)


hh_var18$geozone <- gsub("\\*","",hh_var18$geozone)
hh_var18$geozone <- gsub("\\-","_",hh_var18$geozone)
hh_var18$geozone <- gsub("\\:","_",hh_var18$geozone)

head(hh_var18)
head(hh_var17)


setnames(hh_var18, old =c("households", "hhp", "hhs", "units", "unoccupiable", "vac_rate", "median_age"), new = c("households_18", "hhp_18", "hhs_18", "units_18", "unoccupiable_18", "vac_rate_18", "median_age_18"))
setnames(hh_var17, old =c("households", "hhp", "hhs", "units", "unoccupiable", "vac_rate", "median_age"), new = c("households_17", "hhp_17", "hhs_17", "units_17", "unoccupiable_17", "vac_rate_17", "median_age_17"))

hh_var_17_18<- merge(hh_var17, hh_var18, by.a= c("yr_id", "geozone"), by.b= C("yr_id", "geozone"), all=TRUE)
head(hh_var_17_18)

hh_var_17_18<- hh_var_17_18[c("yr_id","geotype", "geozone", "households_17", "households_18", "hhp_17", "hhp_18", "hhs_17", "hhs_18", "units_17", "units_18", "unoccupiable_17", "unoccupiable_18", "vac_rate_17", "vac_rate_18", "median_age_17", "median_age_18")]


class(hh_var18$yr_id)
class(hh_var17$yr_id)
class(hh_var18$geozone)
class(hh_var17$geozone)

hh_var_17_18$households_numchg<- hh_var_17_18$households_18 - hh_var_17_18$households_17
hh_var_17_18$hhp_numchg<- hh_var_17_18$hhp_18 - hh_var_17_18$hhp_17
hh_var_17_18$hhs_numchg<- hh_var_17_18$hhs_18 - hh_var_17_18$hhs_17
hh_var_17_18$units_numchg<- hh_var_17_18$units_18 - hh_var_17_18$units_17
hh_var_17_18$unoccupiable_numchg<- hh_var_17_18$unoccupiable_18 - hh_var_17_18$unoccupiable_17
hh_var_17_18$vac_rate_numchg<- hh_var_17_18$vac_rate_18 - hh_var_17_18$vac_rate_17
hh_var_17_18$median_age_numchg<- hh_var_17_18$median_age_18 - hh_var_17_18$median_age_17

hh_var_17_18$hh_pctchg<- ((hh_var_17_18$households_17 - hh_var_17_18$households_18)/hh_var_17_18$households_17)*100
hh_var_17_18$hhp_pctchg<- ((hh_var_17_18$hhp_17 - hh_var_17_18$hhp_18)/hh_var_17_18$hhp_17)*100
hh_var_17_18$hhs_pctchg<- ((hh_var_17_18$hhs_17 - hh_var_17_18$hhs_18)/hh_var_17_18$hhs_17)*100
hh_var_17_18$units_pctchg<- ((hh_var_17_18$units_17 - hh_var_17_18$units_18)/hh_var_17_18$units_17)*100
hh_var_17_18$unoccupiable_pctchg<- ((hh_var_17_18$unoccupiable_17 - hh_var_17_18$unoccupiable_18)/hh_var_17_18$unoccupiable_17) *100
hh_var_17_18$vac_rate_pctchg<- ((hh_var_17_18$vac_rate_17 - hh_var_17_18$vac_rate_18)/hh_var_17_18$vac_rate_17) *100
hh_var_17_18$median_age_pctchg<- ((hh_var_17_18$median_age_17 - hh_var_17_18$median_age_18)/hh_var_17_18$median_age_17)*100

hh_var_17_18$hh_pctchg<-round(hh_var_17_18$hh_pctchg,digits=2)
hh_var_17_18$hhp_pctchg<-round(hh_var_17_18$hhp_pctchg,digits=2)
hh_var_17_18$hhs_pctchg<-round(hh_var_17_18$hhs_pctchg,digits=2)
hh_var_17_18$units_pctchg<-round(hh_var_17_18$units_pctchg,digits=2)
hh_var_17_18$unoccupiable_pctchg<-round(hh_var_17_18$unoccupiable_pctchg,digits=2)
hh_var_17_18$vac_rate_pctchg<-round(hh_var_17_18$vac_rate_pctchg,digits=2)
hh_var_17_18$median_age_pctchg<-round(hh_var_17_18$median_age_pctchg,digits=2)


Households<- hh_var_17_18[c("yr_id","geotype", "geozone", "households_17", "households_18", "households_numchg","hh_pctchg")]
Household_pop <- hh_var_17_18[c("yr_id","geotype", "geozone", "hhp_17", "hhp_18", "hhp_numchg", "hhp_pctchg")]
Household_Size<- hh_var_17_18[c("yr_id","geotype", "geozone", "hhs_17", "hhs_18", "hhs_numchg", "hhs_pctchg")]
Units<- hh_var_17_18[c("yr_id","geotype", "geozone", "units_17", "units_18", "units_numchg", "units_pctchg")]
unoccupiable<- hh_var_17_18[c("yr_id","geotype", "geozone", "unoccupiable_17","unoccupiable_18", "unoccupiable_numchg", "unoccupiable_pctchg")]
Vacancy_rate<- hh_var_17_18[c("yr_id","geotype", "geozone", "vac_rate_17", "vac_rate_18", "vac_rate_numchg", "vac_rate_pctchg")]
Median_Age<- hh_var_17_18[c("yr_id","geotype", "geozone", "median_age_17", "median_age_18", "median_age_numchg", "median_age_pctchg")]


write.csv(Households, "Households.csv")
write.csv(Household_pop, "Household_pop.csv")
write.csv(Household_Size, "Household_Size.csv")
write.csv(Units, "Units.csv")
write.csv(unoccupiable, "unoccupiable.csv")
write.csv(Vacancy_rate, "Vacancy_rate.csv")
write.csv(Median_Age, "Median_Age.csv")

summary(hh_var_17_18$units_numchg)


Units_FlagAger


