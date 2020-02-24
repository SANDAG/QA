#school point 2019 data checks

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}
packages <- c("data.table", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2","lubridate", 
              "stringr","openxlsx")
pkgTest(packages)

options(scipen=999, digits = 15)
options(stringsAsFactors = FALSE)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
#open channel to database

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8;trusted_connection=true')

#exclude Shape column due to size
school <- sqlQuery(channel, "SELECT [OBJECTID]
      ,[schoolID]
      ,[cdsCode]
      ,[district]
      ,[name]
      ,[addr]
      ,[city]
      ,[zip]
      ,[openDate]
      ,[charter]
      ,[docType]
      ,[socType]
      ,[gsOffered]
      ,[shrtName]
      ,[priv]
      ,[ClosedDate]
      ,[Phantom]
      ,[Notes]
      ,[Check_]
      ,[regionID]
  FROM [SPACECORE].[gis].[SCHOOL]"
)

head(school)

table(school$docType)
length(unique(school$docType))
table(school$socType)
length(unique(school$socType))
table(school$Phantom)

#a review of this table shows that openDate may not be the official school opening date - more than 365 schools have the opendata of 7-1-1980.
table(school$openDate,school$socType)

#create subset for district office records - these records are offices not schools
district_office <- subset(school,school$socType=="District Office")

head(district_office)
table(district_office$OBJECTID)
table(district_office$charter)
table(district_office$docType)
table(district_office$gsOffered)
table(district_office$priv)

#confirm schoolID values are unique, integer, and 4-6 characters
length(unique(school$schoolID))
class(school$schoolID)
table(nchar(school$schoolID))
summary(school$schoolID)

#confirm CDS Code values are valid
length(unique(school$cdsCode))
table(nchar(school$cdsCode))
summary(school$cdsCode)
#review record with short CDS code
head(school[nchar(school$cdsCode)==10,])

##identify CDS code duplicates and review - some codes are used more than once for open schools and the comments variable provides justification in most cases
school$dup <- duplicated(school$cdsCode)
#recode duplicates that are closed - not really duplicates
school$dup[!is.na(school$ClosedDate)] <-FALSE
#create object of  duplicates and order
sch_dup <- subset(school,school$dup==TRUE)
sch_dup <- sch_dup[order(sch_dup$cdsCode),]
#create a dataframe with all records with  matching CDScodes 
school_dup <- data.frame(school[school$cdsCode %in% sch_dup$cdsCode,])
school_dup$dup <- NULL 
#sort file for review
school_dup <- school_dup[order(school_dup$cdsCode),]
#review of notes variable indicates that notes could be consistent for duplicates


#district
length(unique(school$district))
table(school$district)

#city - review of values shows data are not clean
table(school$city)

#open date
table(school$openDate)
#keep only date not minutes and seconds
school$open_rc <- substr(school$openDate, start = 1, stop = 10)
#recode to date type
school$open_rc <- as.Date(school$open_rc, "%Y-%m-%d")
#check date class
class(school$open_rc)
#sort file by date
school <- school[order(school$open_rc),]
table(school$open_rc)

#closed date
#keep only date - not minutes and seconds
school$closed_rc <- substr(school$ClosedDate, start = 1, stop = 10)
#recode closed date to date type
school$closed_rc <- as.Date(school$ClosedDate,"%Y-%m-%d")
class(school$closed_rc)
school <- school[order(school$closed_rc),]
#check closed date is reasonable
table(school$closed_rc)
#check that closed date is after open date
closeB4open <- select(school, schoolID,open_rc,closed_rc) %>% filter(school$closed_rc<school$open_rc) 
head(closeB4open)

#charter school variable
table(school$charter)
tail(school[school$charter=="No Data",],7)
head(school[school$district=="Pauma Elementary",],7)

#gsoffered school variable - Grades offered
table(school$gsOffered)
tail(school[school$gsOffered==" ",],9)
#check that records with NA are district offices
d1 <- subset(school[school$gsOffered=='N/A',])

#private school variable
table(school$priv)
table(school$socType,school$priv, useNA = "always")
school_private <- subset(school[(is.na(school$socType) & school$priv=="Y"),])

#region id variable
table(school$regionID)
tail(school)
city2region <- subset(school[school$regionID=="2" & school$city=="La Mesa",])

# out folder
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

head(school_dup$cdsCode)

#turn off scientific notation
school_dup$cdsCode <- format(school_dup$cdsCode, scientific = FALSE)
school_private$cdsCode <- format(school_private$cdsCode, scientific = FALSE)
closeB4open$cdsCode <- format(closeB4open$cdsCode, scientific = FALSE)
city2region$cdsCode <- format(city2region$cdsCode, scientific = FALSE)

#create Excel output
wb = createWorkbook()

school_dup_sht <- addWorksheet(wb, "SchoolDups",tabColour="purple")
writeData(wb, school_dup_sht,school_dup)

school_private_sht <- addWorksheet(wb, "SchoolPrivate",tabColour="purple")
writeData(wb, school_private_sht,school_private)

closeB4open_sht <- addWorksheet(wb, "closeB4open",tabColour="purple")
writeData(wb, closeB4open_sht,closeB4open)

city2region_sht <- addWorksheet(wb, "city2region",tabColour="purple")
writeData(wb, city2region_sht,city2region)

saveWorkbook(wb, "SchoolPoint2019QA.xlsx",overwrite=TRUE)







