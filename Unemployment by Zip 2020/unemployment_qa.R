#Purpose: Script to be used on a re-occuring basis to QA/QC unemployment data weekly. 
#Authors: Kelsie Telson and Purva Singh


#load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","gtable")
pkgTest(packages)

#set working directory to access files and save to
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

#open connection to retreive data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
raw_dt<-data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT *
                          FROM [ws].[dbo].[ags_4_27_2020_sd_zips]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#define x as most recent date variable













#############################################################
#Saving data 
wb= createWorkbook()

inp <- addWorksheet(wb, "Input_Raw",tabColour="purple")
writeData(wb,inp, input)

outchk <- addWorksheet(wb, "QA_Test",tabColour="red")
writeData(wb, outchk,output_check)


#saving excel in output folder of the working directory
setwd("C:\\Users\\kte\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Weekly Employment Report\\Results")

# excel workbook output file name and folder with timestamp
now <- Sys.time()
#outputfile <- paste("Ethnicity","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile <- paste("Employment_","Weekly_","QA","DATE",".xlsx",sep='')
print(paste("output filename: ",outputfile))


outfile <- paste(maindir,"/",outfolder,outputfile,sep='')

outfolder<-paste("..\\Results\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

getwd()
saveWorkbook(wb, outfile,overwrite=TRUE)
