### Project: 2020- 44 2020-44 Regional Forecast AQC
### Author: Purva Singh

### This script is for Test 2 of the test plan. 
### The test plan can be found here: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={65dc7eb6-3ac3-4140-96b7-25c09e5f502d}&action=edit&wd=target%28Test%20Plan.one%7C8d0200b0-42be-45fb-92dd-16395ee1c99c%2FTest%20Plan%7Cfd152376-3142-43da-acf5-0d4073bc605b%2F%29

### Part 1: Setting up the R environment and loading packages


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)



### Part 2: Loading the data set: This test utilizes the following X data tables from two databases: 

## Database 1: isam 

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=isam; trusted_connection=true')

# table 1: abm_mgra13_based_input_np

mgra_np <- sqlQuery(channel, 
                   "SELECT * 
FROM  [isam].[xpef33].[abm_mgra13_based_input_np]"
)

# table 2: abm_syn_households 

hh <- sqlQuery(channel,"SELECT *
     FROM [isam].[xpef33].[abm_syn_households]")



# table 3: abm_syn_persons
rm(pers)

pers<- sqlQuery(channel,
"SELECT [yr]
      ,([hhid]) 
      ,count ([perid]) as employed 
 FROM [isam].[xpef33].[abm_syn_persons]
  WHERE ptype= 1  
  GROUP BY hhid, yr" )

gc()


odbcClose(channel)


## Database 2: demographic_warehouse

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#table 4: dim_mgra
dim_mgra<- sqlQuery(channel, 
                    "SELECT * 
FROM  [demographic_warehouse].[dim].[mgra_denormalize]
WHERE series =14"
)

# table 5: fact.household

housing_dw <- sqlQuery(channel, 
                       "SELECT [datasource_id]
      ,[yr_id]
      ,[mgra_id]
      ,count ([housing_id]) as hh
      ,sum([units]) as units
      ,sum([unoccupiable]) as unoccupiable
      ,sum([occupied]) as occupied
      ,sum([vacancy]) as vacancy
  FROM [demographic_warehouse].[fact].[housing]
  WHERE datasource_id = 38
  GROUP BY [datasource_id]
      ,[yr_id]
      ,[mgra_id]
  ORDER BY [datasource_id]
      ,[yr_id]
      ,[mgra_id]"
)

hh_dw<- merge(housing_dw, dim_mgra, by = "mgra_id", all =  TRUE)

# table 6: fact.population
pop_dw <- sqlQuery(channel, 
                   "SELECT * 
FROM  [demographic_warehouse].[fact].[population]
WHERE datasource_id =38"
)

pop_dw_mgra<- merge(pop_dw, dim_mgra, by= "mgra_id", all= TRUE)

# table 7: 

jobs_dw <- sqlQuery(channel, 
                   "SELECT * 
FROM  [demographic_warehouse].[fact].[jobs]
WHERE datasource_id =38"
)

jobs_dw_mgra<- merge(jobs_dw, dim_mgra, by= "mgra_id", all= TRUE)

rm(jobs_dw)
gc()

### Part 3: Analysis: 

#1. Total population

total_pop<- pop_dw_mgra%>%
  group_by(mgra, yr_id)%>%
  summarize_at(vars(population), sum)%>%
  arrange(mgra)


total_pop_final<- merge (total_pop, mgra_np, by.x = c("mgra", "yr_id"),by.y = c("mgra", "yr"), all = TRUE) 

total_pop_final<- total_pop_final%>%
  select(c("mgra", "yr_id", "population", "pop"))%>%
  mutate(diff= population- pop)%>%
  filter(diff!=0)

write.xlsx(total_pop_final, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\Test 3\\test3_pop.xlsx")


#2. Households population 

housing_pop<- pop_dw_mgra%>%
  filter(housing_type_id== 1)%>%
  arrange(mgra)%>%
  group_by(mgra, yr_id)%>%
  summarize_at(vars(population), sum)%>%
  arrange(mgra)


housing_pop_final<- merge (housing_pop, mgra_np, by.x = c("mgra", "yr_id"),by.y = c("mgra", "yr"), all = TRUE) 

housing_pop_final<- housing_pop_final%>%
  select(c("mgra", "yr_id", "population", "hhp"))%>%
  mutate(diff= population- hhp)%>%
  filter(diff >0 |diff<0)

write.xlsx(housing_pop_final, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\Test 3\\test3_hhpop.xlsx")



#3. housing units, vacancy, unoccupiable units

# merging with dim_mgra to create cross between mgra and mgra_id

hh_units<- merge(housing_dw, dim_mgra, by = "mgra_id", all= TRUE)

colnames(hh_units)

hh_units<- hh_units%>%
  select(c("mgra_id", "mgra", "yr_id", "units", "unoccupiable", "occupied", "vacancy", "mgra"))%>%
  group_by(mgra, yr_id)%>%
  summarise_at(vars(units, vacancy, unoccupiable, occupied, vacancy), sum)%>%
  arrange(mgra)


hh_units_final<- merge(hh_units, mgra_np, by.x = c("mgra","yr_id"), by.y = c("mgra","yr"),all= TRUE)

hh_units_final<- hh_units_final%>%
  select(mgra, yr_id, units, vacancy, occupied, unoccupiable, hs, hs_sf, hs_mf, hs_mh)%>%
  mutate(diff= units- hs)%>%
  filter(diff!=0)


write.xlsx(hh_units_final, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\Test 3\\test3_units.xlsx")


#4. Jobs 

#dw

jobs_dw_all<- jobs_dw_mgra%>%
  select(mgra, yr_id, jobs)%>%
  group_by(mgra, yr_id)%>%
  summarise_at(vars(jobs), sum)

# isam


jobs_mgra_np<- mgra_np%>%
  filter((yr== "2016" | yr== "2018"| yr== "2020" |
            yr== "2025" | yr== "2030" | yr== "2035" | 
            yr== "2040" | yr== "2045" | yr== "2050"))%>%
  select(mgra, yr, emp_total)

jobs_final<- merge(jobs_mgra_np, jobs_dw_all, by.x = c("mgra", "yr"),by.y = c("mgra", "yr_id"), all= TRUE)

jobs_final$diff<- jobs_final$emp_total- jobs_final$jobs

jobs_final<- jobs_final%>%
  filter(diff!= 0)

write.xlsx(jobs_final, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\Test 3\\test3_jobs.xlsx")




#### Backup code for traditional years: 
##hh_type0_hhid<- hh_type0_hhid%>%
  ##filter((yr_id== "2016" | yr_id== "2018"| yr_id== "2020" |
    ##        yr_id== "2025" | yr_id== "2030" | yr_id== "2035" | 
      ##      yr_id== "2040" | yr_id== "2045" | yr_id== "2050"))