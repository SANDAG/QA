# set up workspace
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

# import functions
source("config.R")
source("readSQL.R")
source("common_functions.R")

# import packages
packages <- c("RODBC","tidyverse","openxlsx","hash","plyr", "data.table")
pkgTest(packages)

# initialize start time
sleep_for_a_minute <- function() { Sys.sleep(60) }
start_time <- Sys.time()
sleep_for_a_minute()
end_time <- Sys.time()

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=socioeca8; database=socioec_data_stage; trusted_connection=true')
sql_query <- getSQL("\\\\nasais/DPOE/CTPP/2012-2016/ETL/CTPP ETL 2012-2016.sql")
database_data <- sqlQuery(channel,sql_query,stringsAsFactors = FALSE)

database_data<- data.table::as.data.table( RODBC::sqlQuery(channel, 
paste0("SELECT * 
FROM [dpoe_stage].[fact].[ctpp_2016]"),  ## CTPP_2010 for 2006-2010 data
stringsAsFactors = FALSE), 
stringsAsFactors = FALSE) 
odbcClose(channel)
gc() #release memory
# 
# #########Clean Database Data#########
# # remove unnecessary columns from databased_data
# database_data$createdate <- NULL
# database_data$type <- NULL
# database_data$segment <- NULL
# database_data$yr <- NULL
# 
# # convert w_geoid of database_data to character type
# database_data[,1] <- sapply(database_data[,1],as.character)
# gc() #release memory


# batching importing and merge csv files into dataframes
# 2012-2016
setwd("\\\\nasais/DataSolutions/DPOE/CTPP/2012-2016/Source/Data")
file_names <- dir(path = ".", pattern = ".csv") #where you have your files
t2data <- do.call(rbind,lapply(file_names,fread))
gc() #release memory

# 2006-2010
setwd("\\\\nasais/DataSolutions/DPOE/CTPP/2006-2010/Source/Data")
file_names <- dir(path = ".", pattern = ".csv") #where you have your files
t2data2 <- do.call(rbind,lapply(file_names,fread))
gc() #release memory



# merge all partitions
source_data <- t2data
gc() #release memory

#########Clean Source Data#########
# remove "createdate" from source_data
#source_data$createdate <- NULL

# convert source_data$w_geoid to character
#source_data[,1] <- sapply(source_data[,1],as.character)

# rename the header of source_data based on database_data
names(source_data) <- colnames(database_data)

# Sort source_data and database_data


database_data <- database_data[with(database_data, order(geo_id, tbl_id, line_num))] 

gc() #release memory

source_data <- t2data[
  with(t2data, order(GEOID, TBLID, LINENO ))]


gc() #release memory


#### data cleaning

#remove columns from dataframes 
database_data$ctpp_id <- NULL 
source_data$SOURCE <- NULL 

#rename dataframes headers 
names(source_data) <- colnames(database_data) 

#clean up est and num 
source_data$moe <- gsub("[ ,/,',',*,+,-]","", source_data$moe) 
source_data$est <- gsub("[ ,/,',',*,+,-]","", source_data$est) 
 

#convert est and moe in source_data to numeric 
source_data[,4:5] <- sapply(source_data[,4:5],as.numeric) #4:est, 5:moe 
# gc() #release memory 
 

#sort soruce_data and database_data 
database_data <- database_data[order(database_data$geo_id, database_data$tbl_id, database_data$line_num, database_data$est, database_data$moe),] 
source_data <- source_data[order(source_data$geo_id, source_data$tbl_id, source_data$line_num, source_data$est, source_data$moe),] 
gc() #release memory 


# remove rownames (This works, but looking for other solutions to fix inconsistency of rownames types)
rownames(source_data) <-NULL
rownames(database_data) <-NULL

# checking the geoid,tbl_id, line_num columns

dbase_12<- database_data[,1:3]
dbase_12<- dbase_12[order(dbase_12$geo_id, dbase_12$tbl_id, dbase_12$line_num)]
source_12<- source_data[,1:3]
source_12<- source_12[order(source_12$geo_id, source_12$tbl_id, source_12$line_num)]

identical(source_12, dbase_12)

## checking if geoids and tbl ids are NAs in either datasets
sum(is.na(dbase_12$geo_id))
sum(is.na(dbase_12$tbl_id))
sum(is.na(source_12$tbl_id))
sum(is.na(source_12$geo_id))
sum(is.na(database_data$line_num))
sum(is.na(source_data$line_num))

# checking the est column--- EXPAND THIS!!!

dbase_est<- database_data[, 4]
dbase_est<- dbase_est[order(dbase_est$est)]
sum(is.na(dbase_est$est)) ## 50687505 NAs in dbase which are numeric form
gc()

source_est<- source_data[, 4]
source_est<- source_est[order(source_est$est)]
sum(is.na(source_est$est)) ## THIS will result in 0 NAS since all are characters with blanks instead of NAS

## recoding empty cells as NAs in the source data

source_est[source_est == ""] <- NA
sum(is.na(source_est$est)) ## THIS will RESULT in 41123952 NAs 

gc()

## converting source_est from character to numeric coerces NAs 
source_est$est<- as.numeric(source_est$est)
sum(is.na(source_est$est)) ## THIS WILL RESULT in 50687505 NAs

## finding which geoid and tbl_id have NAs introduced by coercion 

dbase_test<- database_data[,1:4]
source_test<- source_data[,1:4]

gc()

source_test[source_test == ""] <- NA

source_test2<- source_test%>%
  filter(is.na(est))

source_test3<- source_test
source_test3$est<- as.numeric(source_test3$est)

source_test3<- source_test3%>%
  filter(is.na(est))

dbase_est_na<- database_data%>%   ## this step confirms that source_test 3 is identical to database records with NAs
  select(geo_id, tbl_id, line_num, est)%>%
  filter(is.na(est))
  
identical(source_test3, dbase_est_na)  

## comparing source_test2 and source_test3

source_test2$est<- as.numeric(source_test2$est)

diff<- setdiff(source_test3, source_test2)
diff<- diff[order(diff$tbl_id)]

test5<- source_data%>%
  filter(est== "^")



# checking moe

dbase_5<- database_data[,5]
sum(is.na(dbase_5$moe))
source_5<- source_data[,5]
source_5[source_5 == ""] <- NA
source_5$moe<- as.numeric(source_5$moe)
sum(is.na(source_5$moe))

identical(dbase_5, source_5)

-----------------------------------------------------------------------
  
  ####Check Data Types and Values####
#Check data types
str(source_data)
str(database_data)

# mode(attr(source_data, "row.names")) #chr
# storage.mode(attr(source_data, "row.names")) #chr
# mode(attr(database_data, "row.names")) #num
# storage.mode(attr(database_data, "row.names")) #int


# compare files 
all(source_data == database_data) #chekc cell values only 
all.equal(source_data, database_data) #chekc cell values and data types and will return the conflicted cells 
identical(source_data, database_data) #chekc cell values and data types 
which(source_data!=database_data, arr.ind = TRUE) #which command shows exactly which columns are incorrect 

# compare files by columns (i.e., geo_id, tbl_id, line_num) 
all(source_data[1:3] == database_data[1:3]) #chekc cell values only 
all.equal(source_data[1:3], database_data[1:3]) #chekc cell values and data types and will return the conflicted cells 
identical(source_data[1:3], database_data[1:3]) #chekc cell values and data types 
which(source_data[1:3]!=database_data[1:3], arr.ind = TRUE) #which command shows exactly which columns are incorrect 
 

# compare files by columns (i.e., moe) 
all(source_data[5] == database_data[5]) #chekc cell values only 
all.equal(source_data[5], database_data[5]) #chekc cell values and data types and will return the conflicted cells 
identical(source_data[5], database_data[5]) #chekc cell values and data types 
which(source_data[5]!=database_data[5], arr.ind = TRUE) #which command shows exactly which columns are incorrect 
 
### display running time of R code ### 
end_time - start_time 

### code for troubleshooting and testing ### 
## check original values in est subset 
# head(source_data, 1) 
# head(database_data, 1) 
# s <- tail(source_data, 100000) 
# d <- tail(database_data, 100000) 
# all.equal(s$est, d$est) 
# all.equal(source_data[4], database_data[4]) 
# file = "R:/DPOE/CTPP/2012-2016/Source/Data/CA_2012thru2016_B306201.csv" 
# B306201 <- do.call(rbind,lapply(file,fread)) 
# B306201 <- as.data.frame(B306201) 
# B306201$SOURCE <- NULL 
# sub306201 <- subset(B306201, GEOID == 'C6000US06115000014790686972') 
# sub306201_2 <- subset(B306201, GEOID == 'C6000US06115000014850604576') 


# #TEST Code for small subset 
# setwd("G:/New folder/SourceFiles/subset2") 
# file_names <- dir("G:/New folder/SourceFiles/subset2") #where you have your files 
# subset2 <- do.call(rbind,lapply(file_names,read.csv)) 
# a = substr(subset2$w_geocode,1,4) == "6073" 
# subset2 <- subset2[a,] 
# gc() 
 

# #test code for string cleaning 
# c <-  "******ce,7382+/-  " 
# c <- "NA666" 
# c <- "" 
# gsub("","999", c) 
# gsub("[NA, ,/,',',*,+,-]","", c) 
 

# #count number of rows through a series of csv files 
# setwd("G:/New folder/SourceFiles/All") 
# filelist = list.files() 
# total_nrows = 0 
# for (f in filelist){ 
#   # file_names <- dir("G:/New folder/SourceFiles/All") #where you have your files 
#   nrows = length(count.fields(f, skip = 1)) #skip header 
#   total_nrows = total_nrows + nrows 
# } 
