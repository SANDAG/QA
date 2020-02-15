#school point 2019 data checks
#perform geospatial checks in ArcMap

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2","lubridate", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

options(scipen=999)
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
closeB4open <- select(school, schoolID,openDate,ClosedDate) %>% filter(school$closed_rc<school$open_rc) 
head(closeB4open)

#charter school variable
table(school$charter)
tail(school[school$charter=="No Data",],7)
head(school[school$district=="Pauma Elementary",],7)

#gsoffered school variable - Grades offered
table(school$gsOffered)
tail(school[school$gsOffered==" ",],9)
d1 <- subset(school[school$gsOffered=='N/A',])

#private school variable
table(school$priv)
table(school$socType,school$priv)

#region id variable
table(school$regionID)
tail(school)

# out folder
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

write.csv(school_dup, "Schools with duplicate cdsCodes.csv", overwrite=TRUE)
write.csv(school_dup, "Schools with open after close date.csv", overwrite=TRUE)







##################
#######################
####################


#####################





head(private)
priv_test<-subset(schoolpt, socType=='Private')
head(priv_test)

head(schoolpt)

head(private)
public_sd<-subset(public, County=='San Diego')
unique(public_sd$County)
unique(public_sd$GSoffered)
unique(schoolpt$gsOffered)
unique(private_sd$GSoffered)
colnames(private_sd)

#save out for coding public school grades offered to categories in school point data
grades_pub<-data.frame(table(public$GSoffered))
grades_schoolpt<-data.frame(table(schoolpt$gsOffered))
grades_pub_served<-data.frame(table(public$GSserved))
class(grades_pub$Var1)
class(grades_schoolpt$Var1)
class(grades_pub_served$Var1)

head(grades_pub)
head(grades_schoolpt)
head(grades_pub_served)

setnames(grades_schoolpt, old = "Freq", new = "pt_freq")
setnames(grades_pub, old = "Freq", new = "pub_freq")         
setnames(grades_pub_served, old = "Freq", new = "pubserved_freq")         

grades_pub$Var1<-as.character(grades_pub$Var1)
grades_pub$letter<-"'"
grades_pub$range<-as.character(paste(grades_pub$letter, grades_pub$Var1, sep=" "))

grades_schoolpt$Var1<-as.character(grades_schoolpt$Var1)
grades_schoolpt$letter<-"'"
grades_schoolpt$range<-as.character(paste(grades_schoolpt$letter, grades_schoolpt$Var1, sep=" "))

grades_pub_served$Var1<-as.character(grades_pub_served$Var1)
grades_pub_served$letter<-"'"
grades_pub_served$range<-as.character(paste(grades_pub_served$letter, grades_pub_served$Var1, sep=" "))


write.csv(grades_pub,"M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\public_grades.csv")
write.csv(grades_schoolpt,"M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\schoolpt_grades.csv")
write.csv(grades_pub_served,"M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\public_grades_served.csv")

############################
############################
#crosstab
#addmargins(xtabs( ~ public.StatusType + public.ClosedDate, data=closed_s))



colnames(public)


######this pulls out NAs
openEQclose<-public[public$OpenDate==public$ClosedDate,]
###################

diegovalley<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\DS cleaning files\\DiegoValleyCharterSchools.csv')

diegovalley<-read.delim2("K:\\box1\\gis\\Schools\\Schools2018\\DiegoValleyCharterSchools.csv.txt")

file.exists('M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\DS cleaning files\\DiegoValleyCharterSchools.txt')

file.exists("K:\\box1\\gis\\Schools\\Schools2018\\DiegoValleyCharterSchools.csv")
getwd()