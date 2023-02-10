#Service Request ID: 2021-32 Employment Center QC
#Author: Purva Singh
# SME: Michelle Posada and Darpan Beri 
# This script checks whether the data for the employment centers (district 2) and 
# economic workshop jurisdictions were correctly extracted for each of the jurisdiction from the source file 
# Source file:  "C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Service Requests//2021//2021-32 Employment Center District 2//Data//Copy of All EC data 071819 - QC Copy.xlsx"
# Employment Center excel file: "C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Service Requests//2021//2021-32 Employment Center District 2//Data//District-2 EC data - QC Copy.xlsx"
# Economic Workshop data packets: C://Users//psi//San Diego Association of Governments//Data Science and Analytics Department - Packets for Jurisdictions//

### Part 1: Setting up the R environment and loading packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse", "rio", "purrr")
pkgTest(packages)

### Part 2: Loading the required datasets
tab_names<- excel_sheets(path= "C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Service Requests//2021//2021-32 Employment Center District 2//Data//District-2 EC data - QC Copy.xlsx")
print(tab_names)
source<- lapply(tab_names, function(x) read_excel(path = "C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Service Requests//2021//2021-32 Employment Center District 2//Data//Copy of All EC data 071819 - QC Copy.xlsx", sheet = x))
emp_cent<- lapply(tab_names, function(x) read_excel(path = "C://Users//psi//San Diego Association of Governments//SANDAG QA QC - Documents//Service Requests//2021//2021-32 Employment Center District 2//Data//District-2 EC data - QC Copy.xlsx", sheet = x))



### Part 3: QC checks

### employment Center checks 

emp_names<- c("Alpine", "El Cajon",
             "Jamacha",
             "La Mesa",
             "Lake Murray",
             "Lakeside",
             "Lemon Grove",
             "Mid-City",
             "Mission Gorge",
             "Poway",
             "Ramona",
             "Rancho Bernardo",
             "Santee",
             "Scripps Poway",
             "San Diego State University",
             "Spring Valley",
             "El Cajon - Gillespie Field")

source_ex<- lapply(source, function(x) dplyr::filter(x, employment_center_name %in% emp_names))


test<- function(i, list1, list2){
  df<- as.data.frame(list1[i]) 
  df2<- as.data.frame(list2[i])
  n<- ncol(df2)
  df1<- df[,c(1:n)]
  print(all_equal(df1, df2))
}

for (i in 1: length(source_ex))
{test(i, source_ex, emp_cent)}


### Data Packets for economic workshop 



filenames <- list.files("C:/Users/psi/San Diego Association of Governments/Data Science and Analytics Department - Packets for Jurisdictions/", pattern= "*EC data.xlsx", recursive=TRUE)

path<- "C:/Users/psi/San Diego Association of Governments/Data Science and Analytics Department - Packets for Jurisdictions/"

lst_of_frames=paste0("C:/Users/psi/San Diego Association of Governments/Data Science and Analytics Department - Packets for Jurisdictions/", filenames) 

cv<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[1] , sheet = x))
dm<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[2] , sheet = x))
en<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[3] , sheet = x))
im<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[4] , sheet = x))
lg<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[5] , sheet = x))
oc<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[6] , sheet = x))
sa<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[7] , sheet = x))
vi<- lapply(tab_names, function(x) read_excel(path = lst_of_frames[8] , sheet = x))



## Get a list of geographies 

test2<- function(i, list1, list2){
  jur<- unique(unlist(lapply(list1, function(x) unique(x[,"employment_center_name"]))))
  list3<- lapply(list2, function(x) dplyr::filter(x, employment_center_name %in% jur))
  df<- as.data.frame(list1[i]) 
  df2<- as.data.frame(list3[i])
  df1<- df2[,c(1:ncol(df))]
  print(all_equal(df, df1))
}

for (i in 1: length(source))
{test2(i, vi, source)}


unique(unlist(lapply(vi, function(x) unique(x[,"employment_center_name"]))))

### For Oceanside: Oceanside - San Luis Rey Mission and Oceanside Civic Center are missing. 


