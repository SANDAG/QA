#DOF totals
#waiting for feedback from EDAM before merging raw data to demographic warehouse. Expectation was that data would match but it doesn't.
#QA is waiting for reason so we can rework test if necessary.
#manual check to socioeconomic data shows a match between download and DOF uploaded.


dof <- read.csv("M:\\Technical Services\\QA Documents\\Projects\\Forecast 2021\\Data files\\DOF\\P3_Complete.csv")

head(dof)

dof <- subset(dof, dof$fips==6073 & dof$year<2017)

#confirm only San Diego region included
table(dof$fips)

head(dof,20)

#sum of region population
dof_sums <- dof %>%
  select(year, perwt) %>%
  group_by(year) %>%
  summarise(pop_tot = sum(perwt,na.rm=TRUE))

head(dof_sums[dof_sums$year==2018 | dof_sums$year==2050,])


gender_sums <- dof %>%
  select(year, sex, perwt) %>%
  group_by(year, sex) %>%
  summarise(gender_pop = sum(perwt,na.rm=TRUE))

head(gender_sums[gender_sums$year==2018 | gender_sums$year==2050,])

race_sums <- dof %>%
  select(year, race7, perwt) %>%
  group_by(year, race7) %>%
  summarise(race_pop = sum(perwt,na.rm=TRUE))

head(race_sums[race_sums$year==2018 | race_sums$year==2050,],20)

age_sums <- dof %>%
  select(year, agerc, perwt) %>%
  group_by(year, agerc) %>%
  summarise(age_pop = sum(perwt,na.rm=TRUE))

head(age_sums[age_sums$year==2018 | age_sums$year==2050,],20)
