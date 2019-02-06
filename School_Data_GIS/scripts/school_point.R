#school data checks


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2","lubridate", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../queries/readSQL.R")

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014b8;trusted_connection=true')
schoolpt_sql = getSQL("../queries/school_point.sql")
schoolpt<-sqlQuery(channel,schoolpt_sql)
odbcClose(channel)

private<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\CA Dept of Ed data\\privateschools1617.csv")
public<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\CA Dept of Ed data\\pubschls.csv")

head(private)
priv_test<-subset(schoolpt, socType=='Private')
head(priv_test)

head(schoolpt)

head(private)

unique(schoolpt$gsOffered)

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

addmargins(xtabs( ~ public.StatusType + public.ClosedDate, data=closed_s))


table(closed_s$public.StatusType)
sch_merge<-subset(closed_s, public.StatusType=='Merged')

public$OpenDate<-as.Date((public$OpenDate), format='%m/%d/%Y')
public$ClosedDate<-as.Date((public$ClosedDate), format='%m/%d/%Y')


######this is wrong
openEQclose<-public[public$OpenDate==public$ClosedDate,]
###################


