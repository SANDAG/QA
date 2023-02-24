### Project: 2020- 44 2020-44 Regional Forecast AQC
## Test 4: MGRA level exploratory analysis for population and units
## Author: Purva Singh


### Part 1: Setting up the R environment, source files, and packages and output folder
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Loading the packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)


### Part 2: Loading the data and preparing it for analysis

## Database 1: ISAM: mgra_summary table
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=isam; trusted_connection=true')

## Table 1: abm_mgra13_based_input_np

mgra_np <- sqlQuery(channel, 
                    "SELECT * 
FROM  [isam].[xpef33].[abm_mgra13_based_input_np]"
)

odbcClose(channel)


## Database 2: Demographic Warehouse: dim_mgra
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

dim_mgra<- sqlQuery(channel, 
                    "SELECT * 
FROM  [demographic_warehouse].[dim].[mgra_denormalize]
WHERE series =14"
)

odbcClose(channel)


# merging dim_mgra with mgra_39 for further analysis

colnames(mgra_npm)


  

mgra_np_pop<- mgra_np%>%
  select(mgra,yr, pop)%>%
  group_by(mgra, yr)%>%    
  summarise_at(vars(pop), sum)%>%
  spread(yr, pop)

setnames(mgra_np_pop, old=c("2016", "2017", "2018", "2020", "2023","2025","2026","2029" ,"2030","2032" ,"2035", "2040", "2045", "2050"), 
       new=c("pop.2016", "pop.2017","pop.2018", "pop.2020","pop.2023" ,"pop.2025","pop.2026", "pop.2029","pop.2030","pop.2032", "pop.2035", "pop.2040", "pop.2045", "pop.2050"))


mgra_np_units<- mgra_np%>%
  select(mgra,yr, hs)%>%
  group_by(mgra, yr)%>%    
  summarise_at(vars(hs), sum)%>%
  spread(yr, hs)

setnames(mgra_np_units, old=c("2016", "2017", "2018", "2020", "2023","2025","2026","2029" ,"2030","2032" ,"2035", "2040", "2045", "2050"), 
         new=c("units.2016", "units.2017","units.2018", "units.2020","units.2023" ,"units.2025","units.2026", "units.2029","units.2030","units.2032", "units.2035", "units.2040", "units.2045", "units.2050"))



write.csv(mgra_np_pop_units, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\mgra_np_units.csv")


# Scheduled development data for creating SD flags 

### Part 3: Analysis

## cond1= when all population values are zero but units are not zero

mgra_np_pop_units<- merge(mgra_np_pop, mgra_np_units, by = "mgra", all= TRUE)

cond1.1<- mgra_np_pop_units%>%
  filter(pop.2016== 0 & pop.2017== 0& pop.2018==0 & pop.2020== 0 & pop.2023== 0 & pop.2025== 0 & pop.2026== 0 &pop.2029== 0  &pop.2030==0 & pop.2032==0& pop.2035==0 & pop.2040==0 & pop.2045==0 & pop.2050== 0)
  

cond1<- mgra_np_pop_units%>%
  filter(pop.2016== 0 & pop.2017== 0& pop.2018==0 & pop.2020== 0 & pop.2023== 0 & pop.2025== 0 & pop.2026== 0 &pop.2029== 0  &pop.2030==0 & pop.2032==0& pop.2035==0 & pop.2040==0 & pop.2045==0 & pop.2050== 0)%>%
  filter(units.2016!= 0 | units.2017!= 0| units.2018!=0 | units.2020!= 0 | units.2023!= 0 | units.2025!= 0 | units.2026!= 0 |units.2029!= 0  |units.2030!=0 | units.2032!=0| units.2035!=0 | units.2040!=0 | units.2045!=0 | units.2050!= 0)

write.csv(cond1, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond1_pop0_w_units.csv")

## cond2= when 2016, 2017, 2018, 2020 pop is 0 and 2023 is not 0

cond2<- mgra_np_pop_units%>%
  filter(!mgra %in% cond1$mgra)

cond2<- cond2%>%
  filter (pop.2016== 0 & pop.2017== 0 & pop.2018==0 & pop.2020== 0 & pop.2023 !=0)

write.csv(cond2, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond2_pop0_selectyrs.csv")


## cond3= when 2016, 2017, 2018, 2020, 2023, 2025 pop is 0 and 2026 is not 0

cond3<- mgra_np_pop_units%>%
  filter (pop.2016== 0 & pop.2017== 0 & pop.2018==0 & pop.2020== 0 & pop.2023 ==0 
          & pop.2025 ==0 & pop.2026!=0)

write.csv(cond3, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond3_pop0_selectyrs.csv")


## cond4=when all yrs upto 2035 are 0 and then post that not 0 

cond4<- mgra_np_pop_units%>%
  filter (pop.2016== 0 & pop.2017== 0 & pop.2018==0 & pop.2020== 0 & pop.2023 ==0 
          & pop.2025 ==0 & pop.2026 ==0 & pop.2029==0 & pop.2030==0 & pop.2032==0 
          & pop.2035 != 0 & pop.2040!=0 & pop.2045!= 0 & pop.2050 != 0)

write.csv(cond4, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond4_pop0_selectyrs.csv")


## cond5= when all yrs upto 2040 are not 0 and then post that 0 

cond5<- mgra_np_pop_units%>%
  filter (pop.2016!= 0 & pop.2017!= 0 & pop.2018!=0 & pop.2020!= 0 & pop.2023 !=0 
          & pop.2025 !=0 & pop.2026 !=0 & pop.2029!=0 & pop.2030!=0 & pop.2032!=0 
          & pop.2035 != 0 & pop.2040==0 & pop.2045== 0 & pop.2050 == 0)

## cond6= when any of the values is zero (except mgras in cond1 that is not all are zero)
cond6<- mgra_np_pop_units%>%
  filter(!mgra %in% cond1.1$mgra)%>%
  filter ( pop.2020== 0 | pop.2023 ==0 
          | pop.2025 ==0 | pop.2026 ==0 | pop.2029==0 | pop.2030==0 | pop.2032==0 
          | pop.2035 == 0 | pop.2040==0 | pop.2045== 0 | pop.2050 == 0)

write.csv(cond6, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond6_pop0_selectyrs.csv")




## cond7== difference between mean and median increase in population 

# First we remove mgras where all zero populations
cond7<- mgra_np_pop_units%>%
  filter (!mgra %in% cond1.1$mgra)%>%
  filter (!mgra %in% cond2$mgra)%>%
  filter (!mgra %in% cond3$mgra)%>%
  filter (!mgra %in% cond4$mgra)%>%
  filter (!mgra %in% cond6$mgra)%>%
mutate(diff.2017= pop.2017- pop.2016,
         diff.2018= pop.2018- pop.2017,
         diff.2020= pop.2020- pop.2018,
         diff.2023= pop.2023- pop.2020,
         diff.2025= pop.2025- pop.2023,
         diff.2026= pop.2026- pop.2025,
         diff.2029= pop.2029- pop.2026,
         diff.2030= pop.2030- pop.2025,
         diff.2032= pop.2032- pop.2030,
         diff.2035= pop.2035- pop.2032,
         diff.2040= pop.2040- pop.2035,
         diff.2045= pop.2045- pop.2040,
         diff.2050= pop.2050- pop.2045, 
         inc.2017= ((pop.2017/pop.2016)-1)*100,
         inc.2018= ((pop.2018/pop.2017)-1)*100,
         inc.2020= ((pop.2020/pop.2018)-1)*100,
         inc.2023= ((pop.2023/pop.2020)-1)*100,
         inc.2025= ((pop.2025/pop.2023)-1)*100,
         inc.2026= ((pop.2026/pop.2025)-1)*100,
         inc.2029= ((pop.2029/pop.2026)-1)*100,
         inc.2030= ((pop.2030/pop.2029)-1)*100,
         inc.2032= ((pop.2032/pop.2030)-1)*100,
         inc.2035= ((pop.2035/pop.2032)-1)*100,
         inc.2040= ((pop.2040/pop.2035)-1)*100,
         inc.2045= ((pop.2045/pop.2040)-1)*100,
         inc.2050= ((pop.2050/pop.2045)-1)*100)%>%
        mutate_if(is.numeric, round, 1)

cond7$pop.diff.mean<- apply(cond7[,30:42], 1, mean) 
cond7$pop.diff.med<- apply(cond7[,30:42], 1, median)
cond7$mean_med_diff<- cond7$pop.diff.mean- cond7$pop.diff.med

write.csv(cond7, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond7_pop0_selectyrs.csv")

### UNITS

cond8.units<- mgra_np_pop_units%>%
  filter(units.2016!= 0 & units.2017!= 0& units.2018!=0 & units.2020!= 0 & units.2023!= 0 & 
           units.2025!= 0 & units.2026!= 0 &units.2029!= 0  &units.2030!=0 & units.2032!=0& 
           units.2035!=0 & units.2040!=0 & units.2045!=0 & units.2050!= 0)%>%
  mutate(units.diff.2017= units.2017- units.2016,
         units.diff.2018= units.2018- units.2017,
         units.diff.2020= units.2020- units.2018,
         units.diff.2023= units.2023- units.2020,
         units.diff.2025= units.2025- units.2023,
         units.diff.2026= units.2026- units.2025,
         units.diff.2029= units.2029- units.2026,
         units.diff.2030= units.2030- units.2025,
         units.diff.2032= units.2032- units.2030,
         units.diff.2035= units.2035- units.2032,
         units.diff.2040= units.2040- units.2035,
         units.diff.2045= units.2045- units.2040,
         units.diff.2050= units.2050- units.2045)%>%
  filter(units.diff.2017< 0| units.diff.2018<0 | units.diff.2020< 0 | units.diff.2023< 0 | 
           units.diff.2025< 0 | units.diff.2026< 0 |units.diff.2029< 0  |units.diff.2030<0 | units.diff.2032<0| 
           units.diff.2035<0 | units.diff.2040<0 | units.diff.2045<0 | units.diff.2050< 0)


write.csv(cond8.units, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\cond8_units.csv")










#filter(inc.2018> 100 | inc.2020> 100|inc.2025> 100| inc.2030> 100|inc.2035> 100 | inc.2040> 100 | inc.2045> 100 | inc.2050> 100)%>%
#filter (diff.2018> 500 | diff.2020> 500|diff.2025> 500| diff.2030> 500|diff.2035> 500 | diff.2040> 500 | diff.2045> 500 | diff.2050> 500)%>%
#select(c(1:12))

# Filtering cond 5 into those mgras with pop 0 in 2016, 2018, and 2020 

cond5.1<-cond5%>%
  filter(pop.2016== 0 & pop.2018==0 & pop.2020== 0)

# Filtering cond 5 into those mgras with pop 0 in 2016, 2018, 2020, 2025, 2030, and 2035  (There are other combinations too)

cond5.2<- cond5%>%
  filter(pop.2016== 0 & pop.2018==0 & pop.2020== 0 & pop.2025== 0 & pop.2030==0 & pop.2035==0 & pop.2040!=0 & pop.2045!=0 & pop.2050!= 0)


## cond 6-- viewing  mgras with capacity_3 >0

cond6<- mgra_pop_39.3%>%
  filter(capacity_3>0)

### Part 4: Saving the results


write.csv(mgra_np, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\mgra_np_summary.csv")












