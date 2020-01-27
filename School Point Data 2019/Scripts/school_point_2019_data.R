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
table(school$socType)
table(school$Phantom)
table(school$openDate,school$socType)

#create subset for district office records
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
head(school[nchar(school$cdsCode)==10,])

##identify CDS code duplicates and review - some codes are used more than once for open schools and the comments variable provides justification in most cases
school$dup <- duplicated(school$cdsCode)

table(school$dup)
head(school)

sch_dup <- subset(school,school$dup==TRUE)
sch_dup <- sch_dup[order(sch_dup$cdsCode),]
length(unique(sch_dup))

school$dup_all[school$cdsCode %in% sch_dup$cdsCode] <- 1
table(school$dup_all)

close_date <- subset(school, school$dup_all==1)
close_date$no_date[is.na(close_date$ClosedDate)] <-1 
table(close_date$no_date)
length(unique(close_date$cdsCode[is.na(close_date$no_date)]))
close_date <- close_date[order(close_date$cdsCode),]

#district
length(unique(school$district))
table(school$district)

#city
table(school$city)

table(school$openDate)

school$open_rc <- as.Date(school$openDate, "YY-mm-dd")

head(school, 12)

head(school[!is.na(school$ClosedDate),], 12)

class(school$ClosedDate)
class(school$openDate)

class(school$open_rc)

school$open_rc <- substr(school$openDate, start = 1, stop = 10)

school$open_rc <- as.Date(school$open_rc, "%Y-%m-%d")

school <- school[order(school$open_rc),]

head(school, 12)
tail(school[!is.na(school$open_rc),], 12)

##############
##############


names(public)<-tolower(names(public))
names(private)<-tolower(names(private))
names(schoolpt)<-tolower(names(schoolpt))
names(schoolpoly)<-tolower(names(schoolpoly))

#change private names to match public
names(private) <- gsub(".", "", names(private), fixed = TRUE)
setnames (private, old='publicdistrict', new='district')
#calc gsoffered for private
private$gsoffered<-as.character(paste(private$lowgrade, private$highgrade, sep="-"))

public$cdscode<-format(public$cdscode, scientific = FALSE)
private$cdscode<-format(private$cdscode, scientific = FALSE)
schoolpt$cdscode<-format(schoolpt$cdscode, scientific = FALSE)

#format dates
public$opendate<-as.Date(public$opendate, "%m/%d/%Y")
public$closedate<-as.Date(public$closeddate, "%m/%d/%Y")
schoolpt$opendate<-as.Date(schoolpt$opendate, "%m/%d/%Y")
schoolpt$closeddate<-as.Date(schoolpt$closeddate, "%m/%d/%Y")


#select columns of interest
public<-select(public,statustype, street,cdscode,charter,city,closeddate,district,doctype,gsoffered,
                  gsserved,school,opendate,county,soctype,zip)
private<-select(private,street,cdscode,city,gsoffered,school,county,district,zip)

#create columns needed before merge
private$priv<-"Y"
private$charter<-"N"
private$soctype<-"Private"
public$priv<-"N"

public<-subset(public, county=='San Diego')
private<-subset(private, county=='San Diego')


#check that all public schools with gsoffered value of no data do not have data for gsserved
#if there were data in gsserved it should override the no data value in gsoffered
public_nogs<-subset(public, public$gsoffered=='No Data' & public$county=='San Diego')
public_nogs<-if(all(public_nogs$gsoffered==public_nogs$gsserved)) print('match') else print ('no match') 

#check for duplicates by cdscode in each source file 
dups_private <-private[duplicated(private$cdscode)|duplicated(private$cdscode, fromLast=TRUE),]
dups_private
dups_public <-public[duplicated(public$cdscode)|duplicated(public$cdscode, fromLast=TRUE),]
dups_public
dups_schoolpt <-schoolpt[duplicated(schoolpt$cdscode)|duplicated(schoolpt$cdscode, fromLast=TRUE),]
dups_schoolpt <-dups_schoolpt[order(dups_schoolpt),]
write.csv(dups_schoolpt, "M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\Result data files\\dups_by_cds_schoolpt.csv")
table(dups_schoolpt$cdscode) 

#check for duplicates by schoolid
dups_schoolpt_id <-schoolpt[duplicated(schoolpt$schoolid)|duplicated(schoolpt$schoolid, fromLast=TRUE),]
dups_schoolpt_id
dups_schoolpoly_id <-schoolpoly[duplicated(schoolpoly$schoolid)|duplicated(schoolpoly$schoolid, fromLast=TRUE),]
dups_schoolpt_id

#check that closed schools have a closed date
public_1<-subset(public_1, County=='San Diego')
public_1$close_flag[((is.na(public_1$ClosedDate)) & (public_1$StatusType='Closed'))|((!is.na(public_1$ClosedDate)) & (public_1$StatusType!='Closed'))]<-1
public_1$close_flag[(public_1$ClosedDate=='No Data') & (public_1$StatusType=='Closed')]<-1
public_1$close_flag2[(public_1$ClosedDate!='No Data') & (public_1$StatusType!='Closed')]<-1
public_1$close_flag
public_1$close_flag2

table(public_1$close_flag)
table(public_1$close_flag2)
table(public_1$StatusType)


table(public_1$ClosedDate)


head(public_1$StatusType)
#list schools with missing schoolid
schoolpt[is.na(schoolpt$opendate), "schoolid"]

doe<-rbind.fill(public, private)

doe$in_doe<-1
schoolpt$in_pt<-1

doe2schpt<-merge(doe, schoolpt, by.x = 'cdscode', by.y = 'cdscode', all = TRUE)
doe2schpt$in_doe[is.na(doe2schpt$in_doe)]<-9
doe2schpt$in_pt[is.na(doe2schpt$in_pt)]<-9

doe2schpt$matched<-ifelse(doe2schpt$in_doe==doe2schpt$in_pt,'1',
                            ifelse(doe2schpt$in_doe!=doe2schpt$in_pt,'0', '9'))
                          
table(doe2schpt$matched)

unmatched<-subset(doe2schpt, matched==0)
write.csv(dups_schoolpt, "M:\\Technical Services\\QA Documents\\Projects\\School Spacecore\\Data files\\Result data files\\doe2pt_unmatched_schools.csv")




doe2schpt$unmatched_2<-ifelse(doe2schpt$in_doe==doe2schpt$in_pt,'0',
                            ifelse(is.na(doe2schpt$in_doe)|
                                   is.na(doe2schpt$in_pt),'1', '9'))


GROUP_COMPAS$cbt_high <- ifelse(GROUP_COMPAS$CognitiveBehavior=='H'|
                                  GROUP_COMPAS$CriminalOpportunity=='H'|
                                  GROUP_COMPAS$CriminalAssociatesPeers=='H'|
                                  GROUP_COMPAS$CriminalPersonality=='H'|
                                  GROUP_COMPAS$FamilyCriminality=='H'|
                                  GROUP_COMPAS$SocialAdjustment=='H','H',
                                ifelse(is.na(GROUP_COMPAS$AssessmentDate), NA, 'L'))



head(doe)
head(schoolpt)
class(public$cdscode)

#merge with pt file

#merge pt with poly














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