#Purpose: Script to be used on a re-occuring basis to QA/QC unemployment data weekly. 
#Test 1: Confirm  ZIP codes in output datafile match master list (109 total) 
#Test 2: Confirm LBF totals match previous LBF total
#Test 3: Confirm percentages in most recent date column (last column in dataset) are calculated correctly based on preceeding column
#Test 4: Confirm that rows in modified file equal values in original file
# containing whole number divided by LBF value in same row. 
#Authors: Kelsie Telson and Purva Singh

#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))



#Package test and loading necessary packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable","readxl", "openxlsx", "tidyverse", "compareDF")
pkgTest(packages)



#open connection to retreive entire raw data (all geographies) from database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
raw_dt<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [socioec_data].[ags].[vi_ags_ZI_latest_release]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)
RODBC::odbcClose(channel)

#retrieve San Diego county only data from database
SDraw_dt<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [socioec_data].[ags].[vi_ags_San_Diego_ZIP_latest_release]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#retrieve master SD zip code list and map window ZIP codes from Sharepoint site
sd_zip<- read_excel("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report\\Data\\ags ZIP codes.xlsx", 
                   sheet = "Sheet1",
                   range= "A1:A110")
mapwin_zip_base<- read_excel("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report\\Data\\May 4\\AGS_SD_ZIPcodes_names_April25_QA.xlsx",
                        sheet= "MapWindow_ZIPcodes")

#removing last two lines from mapwin_zip sharepoint dataset
n<-dim(mapwin_zip_base)[1]
mapwin_zip<-mapwin_zip_base[1:(n-2),]

## Comparing that SD_zip is a correct subset of raw_dt
sd_zip_check<- raw_dt%>%
  filter(ZI %in% sd_zip$ZI)

sd_zip_check<- sd_zip_check[order(sd_zip_check$ZI),]
SDraw_dt<-SDraw_dt[order(SDraw_dt$ZI),]

identical(sd_zip_check$ZI, SDraw_dt$ZI)
identical(sd_zip_check$PU02MAY, SDraw_dt$PU02MAY)
identical(sd_zip_check$UE02MAY, SDraw_dt$UE02MAY)

## Subsetting the latest dataset to mapwindow ZIP codes using base file  
mapwin_zip<- SDraw_dt%>%
  filter(ZI %in% mapwin_zip_base$ZI)


mapwin<- function(df){
  df1<- df%>%
    summarise(sum(LBF))
  colnames_df <- t(t(colnames(df)))
  n<- (length(colnames(df)))-1
  value<-substring((colnames(df[n])),3,7)
  df2<- read_csv("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report\\Data\\LBF_Total.csv")
  df2<- df2%>%
    rbind(list(value,df1[1,1]))
  df2<-df2[!duplicated(df2[('Date')]),]
write.csv(df2,"C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report\\Data\\LBF_Total.csv", row.names = FALSE, append = TRUE ) 
return(df2)
}

lbf<- mapwin(mapwin_zip)


##Test 1: Comparing total LBF number from the previous file with the current number 

lbf$QA_check <- ifelse(lbf$LBF == lag(lbf$LBF),TRUE,FALSE)
test1<- lbf

## Test 2: Validate AGS calculated percentage column for most current week 

test2<- mapwin_zip%>%
  mutate(PU_QA_calc= ((mapwin_zip$UE02MAY/mapwin_zip$LBF)*100))%>%
  mutate_if(is.numeric,round, 2)%>%
  mutate(PU_Check= PU_calc==PU02MAY)
  
        
## Test 3: Confirm zip code values for counts, percentages, and names in [MapWindow_ZIPcodes] match [vi_ags_ZI_latest_release]  

test3<- subset(SDraw_dt, 
               select=c("ZI","LBF", "UE25APR", "PU25APR", "qa_perc", "test3"))
sd_zip_check<- raw_dt%>%
  filter(ZI %in% sd_zip$ZI)

sd_zip_check<- sd_zip_check[order(sd_zip_check$ZI),]
SDraw_dt<-SDraw_dt[order(SDraw_dt$ZI),]

identical(sd_zip_check$ZI, SDraw_dt$ZI)
identical(sd_zip_check$PU02MAY, SDraw_dt$PU02MAY)
identical(sd_zip_check$UE02MAY, SDraw_dt$UE02MAY)


SDraw_dt$test4<- if(SDraw_dt$ZI==raw_dt$ZI) {SDraw_dt$UE25APR==raw_dt$UE25APR}


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

