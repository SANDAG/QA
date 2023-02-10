# File Comparison between January 2005 to December 2013 OPIS Fuel Price Data Source to Database
#There is a problem with the merge starting around line 200

#function to load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

#identify packages to be loaded
packages <- c("data.table", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","tidyverse", "readxl")
#confirm packages are read in
pkgTest(packages)

#set working directory and access code to read in SQL queries
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#source("../Queries/readSQL.R")

getwd()

#turn off strings reading in as factors
options(stringsAsFactors=FALSE)
channel <- odbcDriverConnect('driver={SQL Server}; server=socioeca8; database=dpoe_stage; trusted_connection=true')

#read in SQL data
sql_query <- 'SELECT * FROM [dpoe_stage].[dbo].[opis_fuel_price_0105_1213]'
database_data <- sqlQuery(channel,sql_query,stringsAsFactors = FALSE)

sql_query1 <- 'SELECT * FROM [dpoe_stage].[dbo].[opis_fuel_price_0114_1217]'
database_data1 <- sqlQuery(channel,sql_query1,stringsAsFactors = FALSE)

sql_query2 <- 'SELECT * FROM [dpoe_stage].[dbo].[opis_fuel_price_0118_0519]'
database_data2 <- sqlQuery(channel,sql_query2,stringsAsFactors = FALSE)

sql_query3 <- 'SELECT * FROM [dpoe_stage].[staging].[opis_fuel_price]'
database_comprehensive <- sqlQuery(channel,sql_query3,stringsAsFactors = FALSE)
odbcClose(channel)

#Read in excel data
#Dataset #1 - January 2005 to December 2013 OPIS Fuel Price Data
Source_data <- read_excel("R:\\DPOE\\OPIS Fuel Price\\SourceData\\OPIS_FUEL_010105to123113.xlsx")
#Dataset #2 - January 2014 to December 2017 OPIS Fuel Price Data
Source_data1 <- read_excel("R:\\DPOE\\OPIS Fuel Price\\SourceData\\SDAG_OPIS retail margin history_020618.xlsx")
#Dataset #3-  January 2018 to May 2019 OPIS Fuel Price Data
Source_data2 <- read_excel("R:\\DPOE\\OPIS Fuel Price\\SourceData\\San Diego County Monthly Jan 2018-May 2019.xlsx")

#View column names in source data
head(Source_data)
head(Source_data1)
head(Source_data2)

#Rename source data. Make sure order is the same as in the database.
Source_data <- plyr::rename(Source_data, c("Region Name"="region", "Product"="product", "Start Date"="start_date", 
               "Station Count"="station_count","Retail Average"="retail_avg"))

Source_data1 <- plyr::rename(Source_data1, c("Region Name"="region", "RP Name"="product", "Start Date"="start_date", "Retail Average"="retail_avg", "Wholesale Average"="wholesale_avg",
                                             "Tax Average"="tax_avg", "Freight Average"="freight_avg", "Margin Average"="margin_avg", "Net Average"="net_avg"))

Source_data2 <- plyr::rename(Source_data2, c("Region Name"="region", "Product"="product", "Start Date"="start_date", "Retail Average"="retail_avg", "Wholesale Average"="wholesale_avg",
                                             "Tax Average"="tax_avg", "Freight Average"="freight_avg", "Margin Average"="margin_avg", "Net Average"="net_avg"))


#Convert field Start Date to a Date field
Source_data$start_date <- as.Date((Source_data$start_date), format = "%Y-%m-%d")
database_data$start_date <- as.Date((database_data$start_date), format = "%Y-%m-%d")

Source_data1$start_date <- as.Date((Source_data1$start_date), format = "%Y-%m-%d")
database_data1$start_date <- as.Date((database_data1$start_date), format = "%Y-%m-%d")

Source_data2$start_date <- as.Date((Source_data2$start_date), format = "%Y-%m-%d")
database_data2$start_date <- as.Date((database_data2$start_date), format = "%Y-%m-%d")

database_comprehensive$start_date <- as.Date(database_comprehensive$start_date)

#Check data types
sapply(Source_data, class)
sapply(database_data, class)
sapply(Source_data1, class)
sapply(database_data1, class)
sapply(Source_data2, class)
sapply(database_data2, class)
sapply(database_comprehensive, class)

#trim whitespace from product column values
Source_data1$product <- trimws(Source_data1$product)
Source_data2$product <- trimws(Source_data2$product)
database_data1$product <- trimws(database_data1$product)
database_data2$product <- trimws(database_data2$product)
database_comprehensive$product <- trimws(database_comprehensive$product)

#check values for the product field
table(database_comprehensive$product)
table(database_data$product)
table(database_data1$product)
table(database_data2$product)
table(Source_data$product)
table(Source_data1$product)
table(Source_data2$product)


#Order data frames for comparison
Source_data <- Source_data[order(Source_data$region, Source_data$product, Source_data$start_date, Source_data$station_count, Source_data$retail_avg),]
database_data <- database_data[order(database_data$region, database_data$product, database_data$start_date, database_data$station_count, database_data$retail_avg),]

Source_data1 <- Source_data1[order(Source_data1$region, Source_data1$product, Source_data1$start_date, Source_data1$retail_avg, Source_data1$wholesale_avg, Source_data1$tax_avg, 
                                   Source_data1$freight_avg),]
database_data1 <- database_data1[order(database_data1$region, database_data1$product, database_data1$start_date, database_data1$retail_avg, database_data1$wholesale_avg, 
                                       database_data1$tax_avg, database_data1$freight_avg, database_data1$margin_avg, database_data1$net_avg),]

Source_data2 <- Source_data2[order(Source_data2$region, Source_data2$product, Source_data2$start_date, Source_data2$retail_avg, Source_data2$wholesale_avg, Source_data2$tax_avg, 
                                   Source_data2$freight_avg),]
database_data2 <- database_data2[order(database_data2$region, database_data2$product, database_data2$start_date, database_data2$retail_avg, database_data2$wholesale_avg, 
                                       database_data2$tax_avg, database_data2$freight_avg, database_data2$margin_avg, database_data2$net_avg),]

#delete rownames for checking files match
rownames(Source_data) <- NULL
rownames(database_data) <- NULL

rownames(Source_data1) <- NULL
rownames(database_data1) <- NULL

rownames(Source_data2) <- NULL
rownames(database_data2) <- NULL

#make source data files data.frame class 
Source_data <- data.frame(Source_data)
Source_data1 <- data.frame(Source_data1)
Source_data2 <- data.frame(Source_data2)


# compare source and database files to ensure they match
all(Source_data == database_data)
identical(Source_data,database_data)
which(Source_data!=database_data, arr.ind=TRUE)

all(Source_data1 == database_data1)
identical(Source_data1,database_data1)
which(Source_data1!=database_data1, arr.ind = TRUE)

all(Source_data2 == database_data2)
identical(Source_data2,database_data2)
which(Source_data2!=database_data2, arr.ind = TRUE)


#compare source files to etl file

#create a factor to identify data by date
database_comprehensive$periodrc <- cut(database_comprehensive$start_date,breaks =as.Date(c('2005-01-01','2014-01-01','2018-01-01','2019-05-02')),labels=c('1','2','3'))

by(database_comprehensive$retail_avg,database_comprehensive$periodrc,summary)
summary(Source_data$retail_avg)
summary(Source_data1$retail_avg)
summary(Source_data2$retail_avg)

head(Source_data)
head(Source_data1)

#melt files for comparison
source_melt <- melt(Source_data, id.vars = c("region","product","start_date"),variable.name="Variable",value.name="Total_source")
source_melt1 <- melt(Source_data1, id.vars = c("region","product","start_date"),variable.name="Variable",value.name="Total_source1")
source_melt2 <- melt(Source_data2, id.vars = c("region","product","start_date"),variable.name="Variable",value.name="Total_source2")
db_comp <- melt(database_comprehensive, id.vars = c("region","product","start_date","periodrc"),variable.name = "Variable",value.name = "Total_db")

unique(db_comp$product)
table(source_melt1$product)

#Rename product values to match on comparison
db_comp$product[db_comp$product=="Unleaded Gas"] <- "Reg"
db_comp$product[db_comp$product=="Midgrade Gas"] <- "Mid"
db_comp$product[db_comp$product=="Premium Gas"] <- "Pre"
db_comp$product[db_comp$product=="Regular Gas"] <- "Reg"


#function to recode values to upper and lower case
topropper <- function(x) {
  # Makes Proper Capitalization out of a string or collection of strings. 
  sapply(x, function(strn)
  { s <- strsplit(strn, "\\s")[[1]]
  paste0(toupper(substring(s, 1,1)), 
         tolower(substring(s, 2)),
         collapse=" ")}, USE.NAMES=FALSE)
}  
#apply function to change capitalizaton
source_melt$product <- topropper(source_melt$product)
#recode to match database data values
source_melt$product[source_melt$product=="Dsl"] <- "Diesel"
source_melt$product[source_melt$product=="Unl"] <- "Reg"

head(db_comp)
head(source_melt)



#####################
#There is a problem with the merge I think


#merge database to source
database2source <-merge(select(db_comp,product,start_date,periodrc,Variable,Total_db),
                        (select(source_melt,product,start_date,Variable,Total_source)),
                        by.a=c("product","start_date","Variable"),by.b=c("product","start_date","Variable"), all=TRUE) 

database2source1 <-merge(select(db_comp,product,start_date,periodrc,Variable,Total_db),
                        (select(source_melt1,product,start_date,Variable,Total_source1)),
                        by.a=c("product","start_date","Variable"),by.b=c("product","start_date","Variable"), all=TRUE) 

database2source2 <-merge(select(db_comp,product,start_date,periodrc,Variable,Total_db),
                        (select(source_melt2,product,start_date,Variable,Total_source2)),
                        by.a=c("product","start_date","Variable"),by.b=c("product","start_date","Variable"), all=TRUE) 

#calculate differences in totals
database2source$diff <- database2source$Total_db-database2source$Total_source
database2source1$diff <- database2source1$Total_db-database2source1$Total_source1
database2source2$diff <- database2source2$Total_db-database2source2$Total_source2
head(database2source)
head(database2source1)
tail(database2source2)

#ensure all differences are zero or NA
summary(database2source$diff[database2source$periodrc==1])
summary(database2source1$diff[database2source1$periodrc==2])
summary(database2source2$diff[database2source2$periodrc==3])

s <- subset(database2source, database2source$periodrc==1)
s1 <- subset(database2source, database2source$periodrc==2)
s2 <- subset(database2source, database2source$periodrc==3)

summary(s$diff)
summary(s1$diff)
summary(s2$diff)
