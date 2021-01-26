#HH estimate script
#DOF number of households is "occupied"
#Check 2011-2018 estimates to DOF - delete 2010 data out of those checks
#add checks for 2010 estimates to Decennial Census data

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")


getwd()
options(stringsAsFactors=FALSE)

ds_id=26
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh<-sqlQuery(channel,hh_sql)
gq_sql = getSQL("../Queries/group_quarter.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq<-sqlQuery(channel,gq_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop<-sqlQuery(channel,totpop_sql)
odbcClose(channel)


#aggregate gq pop only - exclude hh pop
gq <-aggregate(pop~yr_id + geozone + geotype, subset(gq, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq, old="pop", new="gqpop")

#clean up geozone for merge
totpop$geozone <- gsub("\\*","",totpop$geozone)
totpop$geozone <- gsub("\\-","_",totpop$geozone)
totpop$geozone <- gsub("\\:","_",totpop$geozone)
gq$geozone <- gsub("\\*","",gq$geozone)
gq$geozone <- gsub("\\-","_",gq$geozone)
gq$geozone <- gsub("\\:","_",gq$geozone)
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)



est <- merge(totpop, gq, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est <- merge(est, hh, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)

est <- subset(est, est$geotype!="cpa")
est <- subset(est, est$geotype!="tract")
#change integer to numeric type
est$pop <- as.numeric(est$pop)
est$gqpop <- as.numeric(est$gqpop)
est$households <- as.numeric(est$households)
est$hhp <- as.numeric(est$hhp)

#levels(est$geozone) <- c(levels(est$geozone), "San Diego Region")
est$geozone[est$geotype=='region'] <- 'San Diego Region'

#################
#dof to estimate checkS
#################

dof<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\DOF\\E-5_DOF_formatted.csv')

#rename first column to get rid of strange character
setnames(dof, 1, "Geography") 

dof$Geography <- gsub("\\:","_",dof$Geography)

#change column type from character to numeric - loop doesn't work
#type2num <-c("Total","Household","Group.Quarters","Housing.units","Single.Detached","Single.Attached","Two.to.Four","Five.Plus","Mobile.Homes","Occupied","Vacancy.Rate")
#for(i in type2num) { 
#dof$type2num[i] <- as.numeric(gsub(",", "", dof$type2num[i]))
#}


#strip commas and change type to numeric
dof$Total <- as.numeric(gsub(",", "", dof$Total))
dof$Household<-as.numeric(gsub(",", "", dof$Household))
dof$Group.Quarters<-as.numeric(gsub(",", "", dof$Group.Quarters))
dof$Total.1<-as.numeric(gsub(",", "", dof$Total.1))
dof$Single.Detached<-as.numeric(gsub(",", "", dof$Single.Detached))
dof$Single.Attached<-as.numeric(gsub(",", "", dof$Single.Attached))
dof$Two.to.Four<-as.numeric(gsub(",", "", dof$Two.to.Four))
dof$Five.Plus<-as.numeric(gsub(",", "", dof$Five.Plus))
dof$Mobile.Homes <- as.numeric(gsub(",", "", dof$Mobile.Homes))
dof$Occupied <- as.numeric(gsub(",", "", dof$Occupied))
dof$Vacancy.Rate <- as.numeric(substr(dof$Vacancy.Rate,0,nchar(dof$Vacancy.Rate)-1))

any(is.na(dof$Total))

#rename dof columns before merge
setnames(dof, old=c("Total","Household","Group.Quarters","Total.1","Single.Detached","Single.Attached","Mobile.Homes","Occupied","Vacancy.Rate",
                    "Persons.per.Household","year"), new=c("pop_dof","hhp_dof","gqpop_dof","hu_dof","sfd_dof","sfa_dof","mh_dof","households_dof",
                    "vac_dof","hhs_dof","yr_id"))
         
setnames(est, old=c("pop","gqpop","households","hhp","hhs"), new=c("pop_est","gqpop_est","households_est",
                                                                                         "hhp_est","hhs_est"))

est$geozone <- gsub("^\\s+|\\s+$", "", est$geozone)
dof$Geography <- gsub("^\\s+|\\s+$", "", dof$Geography)
dof$Geography <- gsub('"', "", dof$Geography)

#rename column values
dof$Geography[dof$Geography=="Balance Of County"]<- "Unincorporated"
dof$Geography[dof$Geography=="County Total"]<- "San Diego Region"
dof<-dof[!dof$Geography=="Incorporated",]

#merge dof and estimates for comparison
dof2est <- merge(dof,est, by.x = c("yr_id","Geography"), by.y = c("yr_id", "geozone"), all=TRUE)

table(dof2est$yr_id)
dof2est$tot_pop_diff <- dof2est$pop_dof-dof2est$pop_est
dof2est$hhp_diff <- dof2est$hhp_dof-dof2est$hhp_est
dof2est$gqpop_diff <- dof2est$gqpop_dof-dof2est$gqpop_est
dof2est$hhs_diff <- dof2est$hhs_dof-dof2est$hhs_est
dof2est$households_diff <- dof2est$households_dof-dof2est$households_est

head(dof2est,8)
#dof2est_2018 <- dof2est[dof2est$yr_id==2018,]
#head(dof2est_2018,8)

dof2est <- dof2est[order(dof2est$Geography, dof2est$yr_id),]

write.csv(dof2est,"M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\DOF differences all geographies.csv")

reg_jur_pop <- subset(dof2est, dof2est$geotype=='region'|dof2est$geotype=='jurisdiction')
by(reg_jur_pop$tot_pop_diff,reg_jur_pop$Geography, sum )

colnames(reg_jur_pop)

reg_jur_pop$DOF2estflag[reg_jur_pop$tot_pop_diff!=0 | reg_jur_pop$hhp_diff!=0 | reg_jur_pop$gqpop_diff!=0 | reg_jur_pop$hhs_diff!=0 | reg_jur_pop$households_diff!=0] <-1 
reg_jur_pop$popflag[reg_jur_pop$tot_pop_diff!=0 ] <-1 
reg_jur_pop$hhpflag[reg_jur_pop$hhp_diff!=0] <-1 
reg_jur_pop$gqpopflag[reg_jur_pop$gqpop_diff!=0 ] <-1 
reg_jur_pop$hhsflag[reg_jur_pop$hhs_diff!=0] <-1
reg_jur_pop$hhflag[reg_jur_pop$households_diff!=0] <-1
table(reg_jur_pop$DOF2estflag)
table(reg_jur_pop$popflag)
table(reg_jur_pop$hhpflag)
table(reg_jur_pop$gqpopflag)
table(reg_jur_pop$hhsflag)
table(reg_jur_pop$hhflag)

reg_jur_pop_diff <-subset(reg_jur_pop, reg_jur_pop$DOF2estflag==1) 

write.csv(reg_jur_pop[,c("yr_id","Geography","pop_dof","pop_est","tot_pop_diff","gqpop_dof","gqpop_est","gqpop_diff","hhp_dof","hhp_est","hhp_diff","hhs_dof",
                         "hhs_est","hhs_diff","households_dof","households_est","households_diff")],
                          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\DOF differences jur & reg.csv", row.names=FALSE)

write.csv(reg_jur_pop_diff[,c("yr_id","Geography","popflag","hhpflag","gqpopflag","hhsflag","hhflag","pop_dof","pop_est","tot_pop_diff","gqpop_dof","gqpop_est","gqpop_diff",
                              "hhp_dof","hhp_est","hhp_diff","hhs_dof","hhs_est","hhs_diff","households_dof","households_est","households_diff")],
          "M:\\Technical Services\\QA Documents\\Projects\\Estimates\\4_Data Files\\DOF differences jur & reg_differences.csv", row.names=FALSE)


