#Purpose: Script to be used on a re-occuring basis to QA/QC unemployment data weekly. 
#Test 1: Confirm  ZIP codes in datafile match master list (109 total) 
#Test 2: Confirm LBF column equals total as provided by Stephanie (defined as "x" in script)
#Test 3: Confirm percentages in most recent date column (last column in dataset) are calculated correctly based on preceeding column
# containing whole number divided by LBF value in same row. 
#Authors: Kelsie Telson and Purva Singh

#total for LBF (manually update as needed based on Stephanie)
x<- 1734783

#load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable","readxl", "openxlsx", "tidyverse")
pkgTest(packages)

#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#open connection to retreive data from database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
raw_dt<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [ws].[dbo].[ags_4_27_2020_sd_zips]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#rename columns of interest into friendly names (always last two columns in data pull because those are the most recent)
rename <- function(x, y, z) {
  x %>% 
    rename_at(
      vars(
        names(.) %>%
          tail(y)),
      funs(paste(z))
    )
}

raw_dt<- raw_dt %>% rename(., y = 2, z = c("number", "percent"))


#retrieve master zip code list from Sharepoint site
zip<- read_excel("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report\\Data\\ags ZIP codes.xlsx", 
                   sheet = "Sheet1",
                   range= "A1:A110")

##Test 1
#sort both files by Zip code
raw_dt<-raw_dt[order(raw_dt$ZI),]
zip<-zip[order(zip$ZI),]
#create object with Zip code and flag for TRUE/FALSE
test1<- as.data.table(list(raw_dt$ZI, raw_dt$ZI==zip$ZI))

##Test 2
test2<-as.data.table(sum(raw_dt$LBF)==x)

##Test 3
#recreate percentage for QA comparison
raw_dt$qa_perc <- raw_dt$number/raw_dt$LBF
raw_dt$qa_perc<- (raw_dt$qa_perc*100)
#create column with flag for TRUE/FALSE
raw_dt$test3<- as.data.table(round(raw_dt$percent, digits=2)==round(raw_dt$qa_perc, digits=2))
#create object with variables of interest
test3<- subset(raw_dt, 
               select=c("ZI","LBF", "number", "percent", "qa_perc", "test3"))


#############################################################
#Saving data 
wb= createWorkbook()

test_1 <- addWorksheet(wb, "Test 1",tabColour="purple")
writeData(wb,test_1, test1)

test_2 <- addWorksheet(wb, "Test 2",tabColour="red")
writeData(wb,test_2, test2)

test_3 <- addWorksheet(wb, "Test 3",tabColour="green")
writeData(wb,test_3, test3)


#saving excel in output folder of the working directory
maindir<-setwd("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report")

# excel workbook output file name and folder with timestamp
now <- format(Sys.time(), "%Y%m%d")
outputfile <- paste("Weekly_","Unemployment","_QA_",now,".xlsx",sep='')
print(paste("output filename: ",outputfile))


outfolder<-paste("Results/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- paste(maindir,"/",outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))

saveWorkbook(wb, outfile,overwrite=TRUE)

