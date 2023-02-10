### Project: 2020- 44 2020-44 Regional Forecast AQC
### Author: Purva Singh

### This script is for Test 1 of the test plan. 
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

readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}

# Creating path for saving results
outputfile <- paste("2020-44_QC_PSI",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))

### Part 2: Loading the dataset

# Flatfiles

csv_2016<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2016_04_np.csv")
csv_2018<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2018_04_np.csv")
csv_2020<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2020_04_np.csv")
csv_2023<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2023_04_np.csv")
csv_2025<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2025_04_np.csv")
csv_2026<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2026_04_np.csv")
csv_2029<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2029_04_np.csv")
csv_2030<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2030_04_np.csv")
csv_2032<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2032_04_np.csv")
csv_2035<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2035_04_np.csv")
csv_2040<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2040_04_np.csv")
csv_2045<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2045_04_np.csv")
csv_2050<- read.csv("C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Data//mgra13_based_input2050_04_np.csv")



# Database 
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=isam; trusted_connection=true')

db_agg <- sqlQuery(channel, 
                 "SELECT * 
FROM  [isam].[xpef33].[abm_mgra13_based_input_np]"
)
odbcClose(channel)


# 2016

csv_2016<- csv_2016%>%
  arrange(mgra)

db_2016<-  db_agg%>%
  filter(yr== 2016)%>%
select(-yr)%>%
arrange(mgra)

colnames(db_2016)== colnames(csv_2016)
class(db_2016)== class(csv_2016)
comp2016<- as.data.frame(csv_2016- db_2016)

write.csv(comp2016, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2016.csv")

# 2018
csv_2018<- csv_2018%>%
  arrange(mgra)

db_2018<-  db_agg%>%
  filter(yr== 2018)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2018)== colnames(csv_2018)
class(db_2018)== class(csv_2018)
comp2018<- as.data.frame(csv_2018- db_2018)

write.csv(comp2018, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2018.csv")



# 2020

csv_2020<- csv_2020%>%
  arrange(mgra)

db_2020<-  db_agg%>%
  filter(yr== 2020)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2020)== colnames(csv_2020)
class(db_2020)== class(csv_2020)
comp2020<- as.data.frame(csv_2020- db_2020)

write.csv(comp2020, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2020.csv")

#2023

csv_2023<- csv_2023%>%
  arrange(mgra)

db_2023<-  db_agg%>%
  filter(yr== 2023)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2023)== colnames(csv_2023)
class(db_2023)== class(csv_2023)
comp2023<- as.data.frame(csv_2023- db_2023)

write.csv(comp2023, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2023.csv")

# 2025

csv_2025<- csv_2025%>%
  arrange(mgra)

db_2025<-  db_agg%>%
  filter(yr== 2025)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2025)== colnames(csv_2025)
class(db_2025)== class(csv_2025)
comp2025<- as.data.frame(csv_2025- db_2025)

write.csv(comp2025, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2025.csv")

# 2026

csv_2026<- csv_2026%>%
  arrange(mgra)

db_2026<-  db_agg%>%
  filter(yr== 2026)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2026)== colnames(csv_2026)
class(db_2026)== class(csv_2026)
comp2026<- as.data.frame(csv_2026- db_2026)

write.csv(comp2026, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2026.csv")

# 2029

csv_2029<- csv_2029%>%
  arrange(mgra)

db_2029<-  db_agg%>%
  filter(yr== 2029)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2029)== colnames(csv_2029)
class(db_2029)== class(csv_2029)
comp2029<- as.data.frame(csv_2029- db_2029)

write.csv(comp2029, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2029.csv")



# 2030

csv_2030<- csv_2030%>%
  arrange(mgra)

db_2030<-  db_agg%>%
  filter(yr== 2030)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2030)== colnames(csv_2030)
class(db_2030)== class(csv_2030)
comp2030<- as.data.frame(csv_2030- db_2030)

write.csv(comp2030, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2030.csv")

# 2032

csv_2032<- csv_2032%>%
  arrange(mgra)

db_2032<-  db_agg%>%
  filter(yr== 2032)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2032)== colnames(csv_2032)
class(db_2032)== class(csv_2032)
comp2032<- as.data.frame(csv_2032- db_2032)

write.csv(comp2032, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2032.csv")


# 2035

csv_2035<- csv_2035%>%
  arrange(mgra)

db_2035<-  db_agg%>%
  filter(yr== 2035)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2035)== colnames(csv_2035)
class(db_2035)== class(csv_2035)
comp2035<- as.data.frame(csv_2035- db_2035)

write.csv(comp2035, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2035.csv")


# 2040

csv_2040<- csv_2040%>%
  arrange(mgra)

db_2040<-  db_agg%>%
  filter(yr== 2040)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2040)== colnames(csv_2040)
class(db_2040)== class(csv_2040)
comp2040<- as.data.frame(csv_2040- db_2040)

write.csv(comp2040, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2040.csv")

# 2045

csv_2045<- csv_2045%>%
  arrange(mgra)

db_2045<-  db_agg%>%
  filter(yr== 2045)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2045)== colnames(csv_2045)
class(db_2045)== class(csv_2045)
comp2045<- as.data.frame(csv_2045- db_2045)

write.csv(comp2045, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2045.csv")

# 2050

csv_2050<- csv_2050%>%
  arrange(mgra)

db_2050<-  db_agg%>%
  filter(yr== 2050)%>%
  select(-yr)%>%
  arrange(mgra)

colnames(db_2050)== colnames(csv_2050)
class(db_2050)== class(csv_2050)
comp2050<- as.data.frame(csv_2050- db_2050)

write.csv(comp2050, "C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\QA\\QA\\QA\\2020-44 Regional Forecast AQC\\Results\\2050.csv")
