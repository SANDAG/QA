
library(rstudioapi)
library(plyr)
library(dplyr)
library(sqldf)
library(data.table)
library(RODBC)


#Connect to demographic warehouse through SQL
channel <- odbcDriverConnect('driver={SQL Server};server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#Save SQL views as data frames 
sr13 <- sqlQuery(channel, 
                 "SELECT *
                 FROM [demographic_warehouse].[dbo].[vi_emp_Sr13]")
sr14 <- sqlQuery(channel, 
                 "SELECT *
                  FROM [demographic_warehouse].[dbo].[vi_emp]")
View(sr13)
View(sr14)

#Create timestamp file of SQL queries used 
write.csv(sr13, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\emp13vs14check",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))
write.csv(sr14, paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\time stamp files\\emp13vs14check",format(Sys.time(), "_%Y%m%d_%H%M%S"),".csv",sep=""))

#Merge SQL views by geozone, sector name, and year
sr13vs14 <- merge(sr13, sr14, by = c("geozone", "full_name", "yr_id"), all = FALSE)

#Subset dataframe to exclude duplicate fields
sr13vs14 <- subset(sr13vs14, select = c("yr_id", "geozone", "employment_type_id.x", "full_name", "geotype.x", "jobs.x", "jobs.y"))

#Rename columns
setnames(sr13vs14, old = c("employment_type_id.x", "geotype.x", "jobs.x", "jobs.y"), new = c("employement_type_id", "geotype", "jobs_SR13", "jobs_ID17"))

#Create Change column
sr13vs14$ch <- sr13vs14$jobs_ID17 - sr13vs14$jobs_SR13

#Create Percent Change Column 
sr13vs14$pct_chg <- (sr13vs14$change/sr13vs14$jobs_SR13)*100
sr13vs14$pct_chg <- round(sr13vs14$pct_chg, digits = 2)
View(sr13vs14)

write.csv(sr13vs14,"M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\Results\\Phase 4\\Trends\\emp\\Emp_13vs17_Check.csv")



