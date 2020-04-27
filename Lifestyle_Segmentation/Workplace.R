#Project Name- Lifestyle Segmentation
#PS created script on 4/25
#KTE modified script on 4/27

maindir= (dirname(rstudioapi::getActiveDocumentContext()$path))

setwd(maindir)



# excel workbook output file name and folder with timestamp
now <- Sys.time()
#outputfile <- paste("Ethnicity","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile <- paste("Workplace","_PRIZM","_QA",".xlsx",sep='')
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
              "stringr","tidyverse", "hash", "openxlsx", "readxl")
pkgTest(packages)

source("SegmentationAnalysis_functions.R")

getwd()

#getting the data

setwd("C:\\Users\\kte\\OneDrive - San Diego Association of Governments\\Lifestyle Segmentation")

input<- read_excel('Prizm 2020 Workplace San Diego BG Input.xlsx', sheet = "2020")
output<- read_excel('San_Diego_County_by_BG_2020_Emp_Ct_by_SANDAG_Groups Output.xlsx', sheet = "Output")


data.frame(colnames(input)) #Returns column index numbers in table format,df=DataFrame name.
input<- subset(input, select = c(1:71))

#checking input file if total jobs number matches jobs in columns across 
input<- input %>%
  mutate(WRKtotal = select(., c(3:71)) %>% 
           rowSums(na.rm = TRUE))

input$WORKtotal_Check<- input$WRKPOP_C==input$WRKtotal


#renaming columns in output for ease of matching
for ( col in 7:ncol(output)){
  colnames(output)[col] <-  sub("SANDAG.Grp.", "SG", colnames(output)[col])
}


##############################################
#Modified code from above for workplace file.


#function for creating workplace crosswalk
work_crosswalk<- function(df){
  df<- df%>% as_tibble()%>%
    mutate(
      SG1= WPPZP01+ WPPZP03+WPPZP07+WPPZP08,
      SG2= WPPZP09+ WPPZP12,
      SG3= WPPZP02+ WPPZP05+WPPZP06+WPPZP10+WPPZP11+ WPPZP14+WPPZP15+WPPZP16,
      SG4= WPPZP04+ WPPZP25,
      SG5= WPPZP13+ WPPZP21+WPPZP31+WPPZP34+WPPZP35,
      SG6= WPPZP17+ WPPZP18+WPPZP19+WPPZP20+WPPZP22+WPPZP24,
      SG7= WPPZP32+ WPPZP36+WPPZP41+WPPZP43+WPPZP49+ WPPZP52+WPPZP53+WPPZP67,
      SG8= WPPZP40+ WPPZP47+WPPZP48+WPPZP50+WPPZP54 ,
      SG9= WPPZP42+ WPPZP45+WPPZP56+WPPZP61,
      SG10= WPPZP26+ WPPZP30+WPPZP33+WPPZP37+WPPZP44+ WPPZP59+WPPZP60+WPPZP63+WPPZP65+WPPZP66,
      SG11= WPPZP23+ WPPZP27+WPPZP28+WPPZP29+WPPZP38+ WPPZP39+WPPZP46+WPPZP51+ WPPZP55+ WPPZP57+ WPPZP58+WPPZP62+ 
        WPPZP64+ WPPZP68)
  
  return(df)}


#function for testing crosswalk 

crosswalk_test<- function(df,df1,df2){
  df<- df%>% as_tibble()%>%
    mutate(
      SG1= df1$SG1==df2$SG1,
      SG2= df1$SG2==df2$SG2,
      SG3= df1$SG3==df2$SG3,
      SG4= df1$SG4==df2$SG4,
      SG5= df1$SG5==df2$SG5,
      SG6= df1$SG6==df2$SG6,
      SG7= df1$SG7==df2$SG7,
      SG8= df1$SG8==df2$SG8,
      SG9= df1$SG9==df2$SG9,
      SG10= df1$SG10==df2$SG10,
      SG11= df1$SG11==df2$SG11,
    )
  return(df)
}


#crosswalking mapping 
input$SG1<- input$WPPZP01+ input$WPPZP03+input$WPPZP07+input$WPPZP08
input$SG2<- input$WPPZP09+ input$WPPZP12
input$SG3<- input$WPPZP02+ input$WPPZP05+input$WPPZP06+input$WPPZP10+input$WPPZP11+ input$WPPZP14+input$WPPZP15+input$WPPZP16
input$SG4<- input$WPPZP04+ input$WPPZP25
input$SG5<- input$WPPZP13+ input$WPPZP21+input$WPPZP31+input$WPPZP34+input$WPPZP35
input$SG6<- input$WPPZP17+ input$WPPZP18+input$WPPZP19+input$WPPZP20+input$WPPZP22+input$WPPZP24
input$SG7<- input$WPPZP32+ input$WPPZP36+input$WPPZP41+input$WPPZP43+input$WPPZP49+ input$WPPZP52+input$WPPZP53+input$WPPZP67
input$SG8<- input$WPPZP40+ input$WPPZP47+input$WPPZP48+input$WPPZP50+input$WPPZP54 
input$SG9<- input$WPPZP42+ input$WPPZP45+input$WPPZP56+input$WPPZP61
input$SG10<- input$WPPZP26+ input$WPPZP30+input$WPPZP33+input$WPPZP37 + input$WPPZP44+ input$WPPZP59+input$WPPZP60+input$WPPZP63+input$WPPZP65+input$WPPZP66
input$SG11<- (input$WPPZP23+ input$WPPZP27+input$WPPZP28+input$WPPZP29+ input$WPPZP38+ input$WPPZP39+input$WPPZP46+input$WPPZP51+ input$WPPZP55+ input$WPPZP57+
                input$WPPZP58+input$WPPZP62+ input$WPPZP64+ input$WPPZP68)




#creating cross walk

input2<- work_crosswalk(input)

data.frame(colnames(input2))

#Input Output & Cross-walk check
output_check<- subset(output, select = c(1:4))
output_check$ID_check<- input$CODE== output$ID
output_check<- crosswalk_test(output_check, input2, output)

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







