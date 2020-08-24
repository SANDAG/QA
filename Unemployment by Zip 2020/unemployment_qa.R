#Purpose: Script to be used on a re-occuring basis to QA/QC unemployment data weekly. 
#Step 1: Comparing entire raw dataset with the San Diego only raw dataset to ensure correct subsetting
#Step 2: Load the latest AGS dataset, previous week's AGS dataset and perform the following QA checks: 
  #Test 1: Match ZIP codes, UE and PU of the latest AGS dataset with San Diego dataset to ensure correct subsetting 
  #Test 2: Match LBF, AGS names, ZIP codes of latest AGs dataset with previous week's dataset to ensure that ZIP level LBF are unchanged 
           #and 91 ZIP codes are same in both 
  #Test 3: Validate AGS calculated percentage column for most current week 
  #Test 4: Compare region's LBF total,UE, and PU for latest week with previous week to ensure they remain unchanged 
#Step3: Perform additional calculations for cross checking DAS calculations
#Authors: Kelsie Telson and Purva Singh


#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

getwd()


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

#retrieve San Diego county only data from database
SDraw_dt<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [socioec_data].[ags].[vi_ags_San_Diego_ZIP_latest_release]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

RODBC::odbcClose(channel)

#retrieve master SD zip code list from Sharepoint site
sd_zip<- read_excel("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-04 Weekly Employment Report\\Data\\ags ZIP codes.xlsx", 
                   sheet = "Sheet1",
                   range= "A1:A110")

## Step 1: Comparing that SD_zip is a correct subset of raw_dt from the data wareshouse 

#Subsetting raw data for San Diego for cross-check 
sd_zip_check<- raw_dt%>%
  filter(ZI %in% sd_zip$ZI)

#Creating function to that cross checks raw_dt and SDraw_dt for ZIP, UE, and PU for latest week


identical_check<- function(df,df2){
df<- df[order(df$ZI),]
df2<- df2[order(df2$ZI),]
df2$ZI_check<- df$ZI  == df2$ZI
n<- length(colnames(df))
var_name<-colnames(df)[n-1]
var_name<- substring(var_name,3,
)
var1<- paste("PU",var_name,sep = "")
var2<- paste("UE",var_name,sep = "")
df2$PU_check<- df[[var1]]==df2[[var1]]
df2$UE_check<- df[[var2]]==df2[[var2]]
return(df2)
  
}

SDraw_dt<- identical_check(sd_zip_check,SDraw_dt)


#Loading the new AGS dataset

mapwin_zip_new<- read_excel("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-04 Weekly Employment Report\\Data\\August 24\\AGS_SD_ZIPcodes_names_August15.xlsx",
                            sheet= "MapWindow_ZIPcodes")

mapwin_zip_new<-mapwin_zip_new[order(mapwin_zip_new$ZI),]


# Step 2: Loading the latest AGS datasets and conducting the 4 QA tests

##selecting the latest weekly data  [depending on whether the UE/PE data is in the last column or not, we might have to change n]

n<- length(colnames(mapwin_zip_new))
var_name<-colnames(mapwin_zip_new)[n-2]
var_name<- substring(var_name,3,
)
var1<- paste("PU",var_name,sep = "")
var2<- paste("UE",var_name,sep = "")

## Test 1: Comparing AGS data with SD raw data from database 

## Subsetting the SD raw data to mapwindow ZIP codes 
test1_crosscheck<- SDraw_dt%>%
  filter(ZI %in% mapwin_zip_new$ZI)


test1<- mapwin_zip_new%>%     ## if you get error in this code chunk, check code line 97 if n-2 is correct
  mutate(ZIP_check= test1_crosscheck$ZI== mapwin_zip_new$ZI, 
         AGS_name_check= test1_crosscheck$ags_name== mapwin_zip_new$ags_name, 
         LBF_check= test1_crosscheck$LBF== mapwin_zip_new$LBF,
         UE_check= test1_crosscheck[[var2]]== mapwin_zip_new[[var2]],
         PU_check= test1_crosscheck[[var1]]== mapwin_zip_new[[var1]])

# Test 2: Comparing with previous week's file 

##loading the previous week's file for comparison and naming it base file (make change to the file path, folder name, file name)

mapwin_zip_base<- read_excel("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-04 Weekly Employment Report\\Data\\August 14\\AGS_SD_ZIPcodes_names_August8.xlsx",
                             sheet= "MapWindow_ZIPcodes")


test2<- mapwin_zip_new%>%
mutate(ZIP_check_base= mapwin_zip_base$ZI== mapwin_zip_new$ZI, 
AGS_name_check_base= mapwin_zip_base$ags_name== mapwin_zip_new$ags_name, 
LBF_check_base= mapwin_zip_base$LBF== mapwin_zip_new$LBF)

## Test 3: Validate AGS calculated percentage column for most current week 
  
test3<- mapwin_zip_new%>%
  mutate(PU_QA_calc= ((mapwin_zip_new[[var2]]/mapwin_zip_new$LBF)*100))%>%
  mutate_if(is.numeric,round, 2)%>%
  mutate(PU_calc_check= PU_QA_calc==mapwin_zip_new[[var1]])


##incase the code above does not work, use the manual code below

#test3<- mapwin_zip_new%>%
  #mutate(PU_QA_calc= ((mapwin_zip_new$UE02MAY/mapwin_zip_new$LBF)*100))%>%
  #mutate_if(is.numeric,round, 2)%>%
  #mutate(PU_calc_check= PU_QA_calc==PU02MAY)

## Test 4: Comparing LBF Totals 

test4<- mapwin_zip_base%>%
  summarise(sum(LBF))== mapwin_zip_new%>% summarise(sum(LBF))


# Test 5: Comparing LBF and UE values between previous week and this week's data

r<- grep("UE", colnames(mapwin_zip_base))


test5<- data.frame(mapwin_zip_new[r]== mapwin_zip_base[r])

test5$LBF<- mapwin_zip_base$LBF== mapwin_zip_new$LBF


# Test 6: Checking dates are correct and consistent 

#manual

##Step 3: Perform additional calculations for  cross checking DAS numbers

#ZIP level

i<- grep(var1, colnames(mapwin_zip_new))
j<- grep(var2, colnames(mapwin_zip_new))


zip_calc<- mapwin_zip_new%>%
  mutate(change= (mapwin_zip_new[[i]]-mapwin_zip_new[[i-1]]))%>%
  mutate(percent_change= ((mapwin_zip_new[[j]]/mapwin_zip_new[[j-1]])-1)*100)%>%
  mutate_if(is.numeric,round, 1)



#Regional Aggregates- writing a function for this to store historical data for each week

p<- grep("UE", colnames(mapwin_zip_new))

zip_calc2<- mapwin_zip_new[p]
zip_calc2$LBF<- mapwin_zip_new$LBF

zip_calc2<- zip_calc2%>%
  summarise_if(is.numeric, sum)
zip_calc2<- (zip_calc2[,1:(ncol(zip_calc2)-1)]/zip_calc2$LBF)
zip_calc2<- zip_calc2*100

zip_calc2$avgPU_July18<- mean(mapwin_zip_new[[var1]])


zip_calc2<- round(zip_calc2, 3)


## Comparing data change
zip_base<- mapwin_zip_base[p-1]
zip_base$LBF<- mapwin_zip_base$LBF
zip_base<- zip_base%>%
  summarise_if(is.numeric, sum)
zip_base<- (zip_base[,1:(ncol(zip_base))]/zip_base$LBF)
zip_base<- zip_base*100
zip_base<- zip_base[,2:ncol(zip_base)]
#zip_base$UE18JUL<- "NA" #Purva, I commented this out because I wasn't sure of the purpose,
#thinking it was just intented for last week?- KT

zip_base[3,]<- zip_calc2[,1:ncol((zip_calc2)-1)]

zip_base<- zip_base[-2,]




#############################################################
#Saving data 
wb= createWorkbook()

test_1 <- addWorksheet(wb, "Test 1",tabColour="purple")
writeData(wb,test_1, test1)

test_2 <- addWorksheet(wb, "Test 2",tabColour="red")
writeData(wb,test_2, test2)

test_3 <- addWorksheet(wb, "Test 3",tabColour="green")
writeData(wb,test_3, test3)

test_4 <- addWorksheet(wb, "Test 4",tabColour="yellow")
writeData(wb,test_4, test4)

test_5 <- addWorksheet(wb, "Test 5",tabColour="red")
writeData(wb,test_5, test5)

Regional_calc<- addWorksheet(wb, "Regional Agg",tabColour="cyan")
writeData(wb,Regional_calc, zip_calc2)

comparison<- addWorksheet(wb, "Regional Agg Comparison",tabColour="blue")
writeData(wb,comparison, zip_base)




#saving excel in output folder of the working directory
setwd("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-04 Weekly Employment Report\\Results")


# excel workbook output file name and folder with timestamp - this part didnt work for me last time so I just formatted and renamed the CSV
now <- format(Sys.time(), "%Y%m%d")
outputfile <- paste("Weekly_","Unemployment","_QA_",now,".xlsx",sep='')
print(paste("output filename: ",outputfile))

outfolder<- ("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2020\\2020-04 Weekly Employment Report\\Results")


outfile <- paste(outfolder,outputfile,sep='\\')
print(paste("output filepath: ",outfile))

outfile

saveWorkbook(wb, outfile,overwrite=TRUE)

saveWorkbook(wb,outfile, overwrite = TRUE)
outfile

