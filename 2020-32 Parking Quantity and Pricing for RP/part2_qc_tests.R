### Author: Kelsie Telson and Purva Singh
### Project: 2020- 32 Regional Plan Parking
### Purpose: Apply validation tests to output data

### Part 1: Setting up the R environment and loading required packages

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("readSQL.R")
source("common_functions.R")


# Loading the packages
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)

readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}

### Part 2: Loading the data
parking2016<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2016_02_np.csv")
parking2025<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2025_02_np.csv")
parking2035<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2035_02_np.csv")
parking2050<- read.csv("C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-32 Regional Plan Parking//Data//mgra13_based_input2050_02_np.csv")


### Part 3: Applying QC testing

##Test 1: Confirm parking stalls [parkarea] are equal to the baseline (2016)

#define test 1 function
test1<- function(input1,
                 input2) {
  test<-ifelse(input1$parkarea==input2$parkarea,TRUE,FALSE)
  
  print(table(test))
}

#apply test 1 function to all files
test1(input1=parking2016,input2=parking2025) #pass
test1(input1=parking2016,input2=parking2035) #pass
test1(input1=parking2016,input2=parking2050) #pass



