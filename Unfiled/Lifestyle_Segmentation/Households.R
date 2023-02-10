#Project Name- Lifestyle Segmentation
#PS created script on 4/25

maindir= (dirname(rstudioapi::getActiveDocumentContext()$path))

setwd(maindir)



# excel workbook output file name and folder with timestamp
now <- Sys.time()
#outputfile <- paste("Ethnicity","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile <- paste("Households","_PRIZM","_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))

outfolder<-paste("../Output/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- paste(maindir,"/",outfolder,outputfile,sep='')
#outfile2 <- paste(maindir,"/",outfolder,outputfile2,sep='')
print(paste("output filepath: ",outfile))

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "reshape2", 
              "stringr","tidyverse", "hash", "openxlsx")
pkgTest(packages)

source("SegmentationAnalysis_functions.R")

getwd()

#getting the data

setwd("C:/Users/psi/OneDrive - San Diego Association of Governments/QA/Lifestyle Segmentation")

input<- read.xlsx('hh_input.xlsx', sheet = 2)
output<- read.xlsx('hh_output.xlsx', sheet = 2)

#subsetting input data to remove CBSA Code, CBSA name, State Name, City name, and col 126 onwards

input<- subset(input, select = c(-CBSA_CODE, -YCOORD, -XCOORD, -STNAME, -CTYNAME, -CBSA_NAME))

data.frame(colnames(input)) #Returns column index numbers in table format,df=DataFrame name.
input<- subset(input, select = c(1:75))

#checking input file if total hh number matches hh in columns across 

input<- input %>%
  mutate(HHtotal = select(., c(7:75)) %>% 
           rowSums(na.rm = TRUE))

input$HHtotal_Check<- input$CYHH3==input$HHtotal

#renaming columns in input for ease of matching
for ( col in 7:75){
  colnames(input)[col] <-  sub("PZPCY", "PZ", colnames(input)[col])
}


#renaming columns in output for ease of matching
for ( col in 7:ncol(output)){
  colnames(output)[col] <-  sub("SANDAG.Grp.", "SG", colnames(output)[col])
}

#creating cross walk

input2<- crosswalk(input)

data.frame(colnames(input2))

#Input Output & Cross-walk check
output_check<- subset(output, select= c(1:5))
output_check<- crosswalk_test(output_check, input2, output)
output_check$ID_check<- input$ID== output$ID
output_check$tract_check<- input$TRACT== output$TRACT


data.frame(colnames(output_check))

#Saving data 


wb= createWorkbook()


inp <- addWorksheet(wb, "Input_Raw",tabColour="purple")
writeData(wb,inp, input)

outp <- addWorksheet(wb, "Output_Raw",tabColour="yellow")
writeData(wb, outp,output)

outchk <- addWorksheet(wb, "QA_Test",tabColour="red")
writeData(wb, outchk,output_check)




#saving excel in output folder of the working directory
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

getwd()
saveWorkbook(wb, outfile,overwrite=TRUE)







