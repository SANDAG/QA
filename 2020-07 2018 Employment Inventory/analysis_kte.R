#Purpose: 2018 Employment Inventory
#Author: Kelsie Telson

#load useful functions
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


connect_datawarehouse <- function() {
  
  # Connect to Datahub using RODBC package
  channel <- RODBC::odbcDriverConnect(
    paste0("driver={SQL Server}; server=sql2014b8;
             database=EMPCORE;
             trusted_connection=true"))
  
  # Return open RODBC connection
  return(channel)
}



packages <- c("RODBC","tidyverse","openxlsx","hash","readtext","data.table","dplyr")
pkgTest(packages)


# connect to database
channel <- connect_datawarehouse()

#retrieve data from sql server
#note: variables [SHAPE] and [GDB_GEOMATTR_DATA] not included due to memory restrictions
raw_dt <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("
SELECT [OBJECTID]
      ,[Status]
      ,[Score]
      ,[Match_type]
      ,[Match_addr]
      ,[emp_id]
      ,[dba]
      ,[address]
      ,[city]
      ,[zip]
      ,[emp1]
      ,[emp2]
      ,[emp3]
      ,[payroll]
      ,[naics]
      ,[own]
      ,[meei]
      ,[init]
      ,[end_]
      ,[react]
      ,[Run]
      ,[Check_]
      ,[flag]
      ,[Move]
      ,[Comment]
      ,[MGRA13]
  FROM [EMPCORE].[dbo].[CA_EDD_EMP2018]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)


#note: variables [SHAPE] and [GDB_GEOMATTR_DATA] not included due to memory restrictions
raw_dt_hqd <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [OBJECTID]
      ,[emp_id]
      ,[sub_emp_id]
      ,[dba]
      ,[Comment]
      ,[Check_]
      ,[share]
      ,[MGRA13]
  FROM [EMPCORE].[dbo].[CA_EDD_EMP2018HQD]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)



#Test 2c/2d
summary(raw_dt)

test2c_na<-as.data.table(raw_dt %>%
  select(everything()) %>%
  summarise_all(funs(sum(is.na(.)))))

test2c_zeros<-rbind(table(raw_dt$zip==0),
      table(raw_dt$emp1==0),
      table(raw_dt$emp2==0),
      table(raw_dt$emp3==0),
      table(raw_dt$payroll==0))
test2c_zeros<- as.data.table(cbind(variable=c("zip", "emp1", "emp2", "emp3", "payroll"),
                                   test2c_zeros))
setnames(test2c_zeros, old = c('FALSE','TRUE'), new = c('Not Zero','Zero'))

#Test 9
raw_dt$emp_1_2_diff<-raw_dt$emp2-raw_dt$emp1
raw_dt$emp_2_3_diff<-raw_dt$emp3-raw_dt$emp2
raw_dt$emp_net_diff<-raw_dt$emp3-raw_dt$emp1

summary(raw_dt)

ggplot(data=subset(raw_dt, !is.na(emp_1_2_diff)), aes(emp_1_2_diff))+
  geom_histogram()

#Test 7
test7<- as.data.table(cbind(variable=c("emp1","emp2", "emp3", "payroll"),
              rbind(sum(raw_dt$emp1, na.rm=TRUE),
                    sum(raw_dt$emp2, na.rm=TRUE),
                    sum(raw_dt$emp3, na.rm=TRUE),
                    sum(raw_dt$payroll, na.rm=TRUE)),
              bls=c(1458131,1461622,1466234,21848394370))) #values found on bls website, screenshot in project folder

test7$V2<- as.numeric(test7$V2)
test7$bls<- as.numeric(test7$bls)
test7$diff<- test7$V2-test7$bls


