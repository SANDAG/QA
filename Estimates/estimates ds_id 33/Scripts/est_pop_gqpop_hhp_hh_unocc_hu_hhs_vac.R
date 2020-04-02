#HH estimate script
#calculates differences across datasource ids and within current vintage and outputs separate files
#KT PS - I don't know if we need to check unoccupied. PS there isn't this number in DOF estimates is there? 
#############
#############
#updated to datasource_id 27 on 4/8/19

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")
source("functions_for_percent_change.R")
source("common_functions.R")

getwd()
options(stringsAsFactors=FALSE)


outputfile <- paste("Units_HH_Pop_Vac","_Est19","_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\Estimates\\Results\\",sep='')
outfile <- paste(outfolder,outputfile,sep='')
print(paste("output filepath: ",outfile))

outputfile2 <- paste("Units_HH_Pop_Vac_Version_Comparison",".xlsx",sep='')
print(paste("output filename: ",outputfile2))
outfolder<-paste("C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\Estimates\\Results\\",sep='')
outfile2 <- paste(outfolder,outputfile2,sep='')
print(paste("output filepath: ",outfile2))

ds_id=33

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh_33<-sqlQuery(channel,hh_sql)
gq_sql = getSQL("../Queries/group_quarter.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq_33<-sqlQuery(channel,gq_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop_33 <-sqlQuery(channel,totpop_sql)
odbcClose(channel)


ds_id=27

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
hh_sql <- gsub("ds_id", ds_id,hh_sql)
hh_27<-sqlQuery(channel,hh_sql)
gq_sql = getSQL("../Queries/group_quarter.sql")
gq_sql <- gsub("ds_id", ds_id,gq_sql)
gq_27<-sqlQuery(channel,gq_sql)
totpop_sql = getSQL("../Queries/total_population.sql")
totpop_sql <- gsub("ds_id", ds_id,totpop_sql)
totpop_27<-sqlQuery(channel,totpop_sql)
odbcClose(channel)

## Part 1- Test #25 in Test Plan

#aggregate gq pop only - exclude hh pop
gq_27 <-aggregate(pop~yr_id + geozone + geotype, subset(gq_27
                                                        , housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq_27, old="pop", new="gqpop_27")

gq_33 <-aggregate(pop~yr_id + geozone + geotype, subset(gq_33, housing_type_id!=1), sum,na.rm = TRUE)
setnames(gq_33, old="pop", new="gqpop_33")

#clean up geozone for merge
totpop_33$geozone <- gsub("\\*","",totpop_33$geozone)
totpop_33$geozone <- gsub("\\-","_",totpop_33$geozone)
totpop_33$geozone <- gsub("\\:","_",totpop_33$geozone)
gq_33$geozone <- gsub("\\*","",gq_33$geozone)
gq_33$geozone <- gsub("\\-","_",gq_33$geozone)
gq_33$geozone <- gsub("\\:","_",gq_33$geozone)
hh_33$geozone <- gsub("\\*","",hh_33$geozone)
hh_33$geozone <- gsub("\\-","_",hh_33$geozone)
hh_33$geozone <- gsub("\\:","_",hh_33$geozone)


totpop_27$geozone <- gsub("\\*","",totpop_27$geozone)
totpop_27$geozone <- gsub("\\-","_",totpop_27$geozone)
totpop_27$geozone <- gsub("\\:","_",totpop_27$geozone)
gq_27$geozone <- gsub("\\*","",gq_27$geozone)
gq_27$geozone <- gsub("\\-","_",gq_27$geozone)
gq_27$geozone <- gsub("\\:","_",gq_27$geozone)
hh_27$geozone <- gsub("\\*","",hh_27$geozone)
hh_27$geozone <- gsub("\\-","_",hh_27$geozone)
hh_27$geozone <- gsub("\\:","_",hh_27$geozone)

#merge data and calculate the vacancy rate
est_33 <- merge(totpop_33, gq_33, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est_33 <- merge(est_33, hh_33, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
setnames(est_33, old="units",new="hu")
#calculate vac rate
est_33$vac <- ((est_33$hu-est_33$households)/est_33$hu)*100
est_33$vac <- round(est$vac,digits = 2)

head(est_33)

est_27 <- merge(totpop_27, gq_27, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
est_27 <- merge(est_27, hh_27, by.x = c("yr_id", "geotype", "geozone"), by.y = c("yr_id", "geotype", "geozone"), all=TRUE)
setnames(est_27, old="units",new="hu")
#calculate vac rate
est_27$vac <- ((est_27$hu-est_27$households)/est_27$hu)*100
est_27$vac <- round(est_27$vac,digits = 2)
est_27$vac <- round(est_27$vac,digits = 2)

head(est_27)


#change integer to numeric type
est_33$pop <- as.numeric(est_33$pop)
est_33$gqpop_33 <- as.numeric(est_33$gqpop_33)
est_33$households <- as.numeric(est_33$households)
est_33$hhp <- as.numeric(est_33$hhp)
est_33$hu <- as.numeric(est_33$hu)
est_33$vac<- round(est_33$vac, digits = 2)
#est$mf <- as.numeric(est$mf)
#est$mh <- as.numeric(est$mh)
#est$sfmu <- as.numeric(est$sf)
#est$sf <- as.numeric(est$sf)

head(est_33)

est_27$pop <- as.numeric(est_27$pop)
est_27$gqpop_27 <- as.numeric(est_27$gqpop_27)
est_27$households <- as.numeric(est_27$households)
est_27$hhp <- as.numeric(est_27$hhp)
est_27$hu <- as.numeric(est_27$hu)
# est_24$mf <- as.numeric(est_24$mf)
# est_24$mh <- as.numeric(est_24$mh)
# est_24$sfmu <- as.numeric(est_24$sfmu)
# est_24$sf <- as.numeric(est_24$sf)

head(est_27)

est_33$geozone[est_33$geotype=='region'] <- 'San Diego Region'
est_27$geozone[est_27$geotype=='region'] <- 'San Diego Region'

         
setnames(est_27, old=c("pop","gqpop_27","households","hhp","hhs", "hu","vac"), new=c("pop_27","gqpop_27","households_27",
                                                                                                 "hhp_27","hhs_27","hu_27","vac_27"))

est_33$geozone <- gsub("^\\s+|\\s+$", "", est_33$geozone)
est_27$geozone <- gsub("^\\s+|\\s+$", "", est_27$geozone)

est_33_27 <- merge(est_33,est_27, by.x = c("yr_id","geozone","geotype"), by.y = c("yr_id", "geozone","geotype"), all=TRUE)

#confirm expected records are in dataframe
table(est_33_27$yr_id)
table(est_33_27$geozone)
table(est_33_27$geotype)

# Removing 'not in CPA' and Zip which is not 
est_33_27<- subset(est_33_27,geozone != 'Not in a CPA')
est_33_27<-subset(est_33_27, geotype!= 'zip')

#Removing 2019 since ds_id 27 will not have 2019 and have data till 2018 only

est_33_27<-subset(est_33_27, yr_id!= 2019)

#Subsetting cpa, jurisdiction and region 


#calculate number change
est_33_27$tot_pop_numchg <- est_33_27$pop-est_33_27$pop_27
est_33_27$hhp_numchg <- est_33_27$hhp-est_33_27$hhp_27
est_33_27$gqpop_numchg <- est_33_27$gqpop_33-est_33_27$gqpop_27
est_33_27$hh_numchg <- est_33_27$households-est_33_27$households_27
est_33_27$hu_numchg <- est_33_27$hu-est_33_27$hu_27
#est_24_27$sfa_numchg <- est_24_27$sfa-est_24_27$sfa_24
#est_24_27$sfd_numchg <- est_24_27$sfd-est_24_27$sfd_24
#est_24_27$mf_numchg <- est_24_27$mf-est_24_27$mf_24
#est_24_27$mh_numchg <- est_24_27$mh-est_24_27$mh_24
est_33_27$hhs_numchg <- est_33_27$hhs-est_33_27$hhs_27
est_33_27$vac_numchg <- est_33_27$vac-est_33_27$vac_27
est_33_27$vac_numchg<- round(est_33_27$vac_numchg,digits=2)

head(subset(est_33_27, est_33_27$geotype.x=="jurisdiction"), 8)

#calculate percent change
#calc for percent change for vac is based on rate so different
est_33_27$tot_pop_pctchg <- (est_33_27$tot_pop_numchg/est_33_27$pop_27)*100
est_33_27$tot_pop_pctchg <- round(est_33_27$tot_pop_pctchg,digits=2)
est_33_27$hhp_pctchg <- (est_33_27$hhp_numchg/est_33_27$hhp_27)*100
est_33_27$hhp_pctchg <- round(est_33_27$hhp_pctchg,digits=2)
est_33_27$gqpop_pctchg <- (est_33_27$gqpop_numchg/est_33_27$gqpop_27)*100
est_33_27$gqpop_pctchg <- round(est_33_27$gqpop_pctchg,digits=2)
est_33_27$hh_pctchg <- (est_33_27$hh_numchg/est_33_27$households_27)*100
est_33_27$hh_pctchg <- round(est_33_27$hh_pctchg,digits=2)
est_33_27$hu_pctchg <- (est_33_27$hu_numchg/est_33_27$hu_27)*100
est_33_27$hu_pctchg <- round(est_33_27$hu_pctchg,digits=2)
est_33_27$hhs_pctchg <- (est_33_27$hhs_numchg/est_33_27$hhs_27)*100
est_33_27$hhs_pctchg <- round(est_33_27$hhs_pctchg,digits=2)


est_33_27 <- est_33_27[order(est_33_27$geozone, est_33_27$yr_id),]

#wait until EDAM changes the values for the units by type names
#add sfd and sfa

##############
###############
# est_24_27$mf_pctchg <- (est_24_27$mf_numchg/est_24_27$mf_24)*100
# est_24_27$mf_pctchg <- round(est_24_27$mf_pctchg,digits=2)
# est_24_27$mh_pctchg <- (est_24_27$mh_numchg/est_24_27$mh_24)*100
# est_24_27$mh_pctchg <- round(est_24_27$mh_pctchg,digits=2)

head(est_33_27[est_33_27$geotype=="region",],10)
#set Inf values to NA for later calculations
est_33_27$tot_pop_pctchg[is.infinite(est_33_27$tot_pop_pctchg)] <-NA
est_33_27$hhp_pctchg[is.infinite(est_33_27$hhp_pctchg)] <-NA 
est_33_27$hhs_pctchg[is.infinite(est_33_27$hhs_pctchg)] <-NA 
est_33_27$hh_pctchg[is.infinite(est_33_27$hh_pctchg)] <-NA
est_33_27$hu_pctchg[is.infinite(est_33_27$hu_pctchg)] <-NA 
est_33_27$gqpop_pctchg[is.infinite(est_33_27$gqpop_pctchg)] <-NA 
est_33_27$hhp_pctchg[is.infinite(est_33_27$hhp_pctchg)] <-NA 
est_33_27$vac[is.infinite(est_33_27$vac)] <-NA 
est_33_27$vac_27[is.infinite(est_33_27$vac_27)] <-NA
est_33_27$vac_numchg[is.infinite(est_33_27$vac_numchg)] <-NA

head(est_33_27[est_33_27$geotype=="region",],10)

#calculating pass fail

cutoff<- 5
est_33_27$totpop_pass.or.fail <- case_when(abs(est_33_27$tot_pop_pctchg)> cutoff~ "fail", TRUE~ "pass")  
est_33_27$hh_pass.or.fail <- case_when(abs(est_33_27$hh_pctchg)> cutoff~ "fail", TRUE~ "pass")  
est_33_27$hhp_pass.or.fail <- case_when(abs(est_33_27$hhp_pctchg)> cutoff~ "fail", TRUE~ "pass")
est_33_27$hhs_pass.or.fail <- case_when(abs(est_33_27$hhs_pctchg)> cutoff~ "fail", TRUE~ "pass")
est_33_27$hu_pass.or.fail <- case_when(abs(est_33_27$hu_pctchg)> cutoff~ "fail", TRUE~ "pass")
est_33_27$gq_pass.or.fail <- case_when(abs(est_33_27$gqpop_pctchg)> cutoff~ "fail", TRUE~ "pass")
est_33_27$vac_pass.or.fail <- case_when(abs(est_33_27$vac_numchg)> cutoff~ "fail", TRUE~ "pass")

head(est_33_27[est_33_27$geotype=="region",],10)

est_33_27_cpa<-subset(est_33_27, geotype == 'cpa') 
est_33_27_jur<-subset(est_33_27, geotype == 'jurisdiction') 
est_33_27_region<- subset(est_33_27, geotype == 'region') 



#saving output in OneDrive
wb1 = createWorkbook()

#add summary worksheet
cpa = addWorksheet(wb1, "CPA", tabColour = "red")
jur = addWorksheet(wb1, "Jurisdiction", tabColour = "blue")
region = addWorksheet(wb1, "Region", tabColour = "green")


headerstyle<- createStyle(fontSize = 11, textDecoration = "Bold", wrapText = TRUE, fgFill = "#1eadfa", halign = "center" )


writeData(wb1, "CPA", est_33_27_cpa, headerStyle = headerstyle)
writeData(wb1, "Jurisdiction", est_33_27_jur, headerStyle = headerstyle)
writeData(wb1, "Region", est_33_27_region, headerStyle = headerstyle)

#Formatting sheets



#addStyle(wb1,cpa, style = headerstyle, rows = 1, cols= 1:32, gridExpand = TRUE)
#addStyle(wb1, jur, style = headerstyle, rows = 1, cols= 1:32, gridExpand = TRUE)
#addStyle(wb1, reg, style = headerstyle, rows = 1, cols= 1:32, gridExpand = TRUE)

negStyle <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")
posStyle <- createStyle(fontColour = "#006100", bgFill = "#C6EFCE")

conditionalFormatting(wb1, cpa, cols=1: ncol(est_33_27_jur) , rows= 2: nrow(est_33_27_cpa), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb1, cpa, cols=1: ncol(est_33_27_jur) , rows= 2: nrow(est_33_27_cpa), type="contains", rule="pass", style = posStyle)
freezePane(wb1, cpa, firstRow = TRUE)
conditionalFormatting(wb1, jur, cols=1: ncol(est_33_27_jur) , rows= 2: nrow(est_33_27_cpa), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb1, jur, cols=1: ncol(est_33_27_jur) , rows= 2: nrow(est_33_27_cpa), type="contains", rule="pass", style = posStyle)
freezePane(wb1, jur, firstRow = TRUE)
conditionalFormatting(wb1, region, cols=1: ncol(est_33_27_jur) , rows= 2: nrow(est_33_27_cpa), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb1, region, cols=1: ncol(est_33_27_jur) , rows= 2: nrow(est_33_27_cpa), type="contains", rule="pass", style = posStyle)
freezePane(wb1, region, firstRow = TRUE)


aligncenter = createStyle(halign = "center")

addStyle(wb1, cpa, style=aligncenter, cols=1: ncol(est_33_27_jur), rows=2: nrow(est_33_27_cpa), gridExpand=TRUE)
addStyle(wb1, jur, style=aligncenter, cols=1: ncol(est_33_27_jur), rows=2: nrow(est_33_27_cpa), gridExpand=TRUE)
addStyle(wb1, region, style=aligncenter, cols=1: ncol(est_33_27_jur), rows=2: nrow(est_33_27_cpa), gridExpand=TRUE)


setColWidths(wb1,cpa, cols= 1: ncol(est_33_27_jur), widths = 12)
setColWidths(wb1,cpa, cols = 2, widths = 26)

setColWidths(wb1,jur, cols= 1: ncol(est_33_27_jur), widths = 12)
setColWidths(wb1,jur, cols = 2, widths = 26)

setColWidths(wb1,region, cols= 1: ncol(est_33_27_jur), widths = 12)
setColWidths(wb1,region, cols = 2, widths = 26)


# out folder for wb1
setwd(file.path(outfolder))

#commenting out the oufile which is duplicate of outfile2 with _QA nomenclature
#saveWorkbook(wb, outfile,overwrite=TRUE)
saveWorkbook(wb1, outfile2,overwrite=TRUE)


#write.csv(est_33_27,"C:\\Users\\psi\\OneDrive - San Diego Association of Governments\\Estimates\\Results\\Estimates_QA_PS.csv" )


#Part 2

#calculate incremental change in ID 33 data
#percent change for vac is difference of rates across vintages
est_33 <- rm_special_chr(est_33)
est <- subset(est_33,geozone != 'Not in a CPA')
est<-subset(est, geotype!= 'region')

# order dataframe for doing lag calculation
est <- est[order(est$geotype,est$geozone,est$yr_id),]


#pass fail calculation 
cutoff<- .05
pop<- calculate_pct_chg(est,pop)
pop$pass.or.fail<- case_when(abs(pop$percent_change)> cutoff~ "fail", TRUE~ "pass")  

households <- calculate_pct_chg(est, households)
households$pass.or.fail <- case_when(abs(households$percent_change)> cutoff~ "fail", TRUE~ "pass")  

hhp <- calculate_pct_chg(est, hhp)
hhp$pass.or.fail<- case_when(abs(hhp$percent_change)> cutoff~ "fail", TRUE~ "pass") 

hhs <- calculate_pct_chg(est, hhs)
hhs$pass.or.fail<- case_when(abs(hhs$percent_change)> cutoff~ "fail", TRUE~ "pass") 

hu <- calculate_pct_chg(est, hu)
hu$pass.or.fail<- case_when(abs(hu$percent_change)> cutoff~ "fail", TRUE~ "pass") 

gq <- calculate_pct_chg(est, gqpop_33)
gq$pass.or.fail<- case_when(abs(gq$percent_change)> cutoff~ "fail", TRUE~ "pass") 

vac<- calculate_num_chg(est, vac)
vac$pass.or.fail<- case_when(abs(vac$change)> cutoff~ "fail", TRUE~ "pass") 

#hhp <- calculate_pct_chg(est, hhp)
#hhp <- calculate_pass_fail2(hhp,.05)
#hhs <- calculate_pct_chg(est, hhs)
#hhs <- calculate_pass_fail2(hhs,.05)
#hu <- calculate_pct_chg(est, hu)
#hu <- calculate_pass_fail2(hu,.05)
#gq <- calculate_pct_chg(est, gqpop_33)
#gq <- calculate_pass_fail2(hu,.05)
#vacancy (using numeric change function and pass fail 3 function)
#vac<- calculate_num_chg(est, vac)
#vac<- calculate_pass_fail2(vac, .05)


##Alternative method for calcuating numeric change, % change and pass fail is commented out below:
#households
#est$hh_chg <- est$households - lag(est$households)
#est$hh_pct <- est$hh_chg / lag(est$households)*100
#est$hh_pct<-round(est$hh_pct,digits=2)
#household population
##est$hhp_chg <- est$hhp - lag(est$hhp)
##est$hhp_pct <- (est$hhp_chg / lag(est$hhp))*100
#est$hhp_pct<-round(est$hhp_pct,digits=2)
#household size
#est$hhs_chg <- est$hhs - lag(est$hhs)
#est$hhs_pct <- (est$hhs_chg / lag(est$hhs))*100
#est$hhs_pct<-round(est$hhs_pct,digits=2)
#housing units 
#est$hu_chg <- est$hu - lag(est$hu)
#est$hu_pct <- (est$hu_chg / lag(est$hu))*100
#est$hu_pct<-round(est$hu_pct,digits=2)
#group quarters
#est$gq_chg <- est$gqpop_33 - lag(est$gqpop_33)
#est$gq_pct <- (est$gq_chg / lag(est$gq_chg))*100
#est$gq_pct<-round(est$gq_pct,digits=2)
#vacancy
#est$vac_chg <- est$vac - lag(est$vac)

# create dataframe of failed geos for summary tab

pop_failed<- get_fails(pop)
pop_failed$pop<- 'fail'
households_failed <- get_fails(households)
households_failed$hh <- 'fail'
hhp_failed <- get_fails(hhp)
hhp_failed$hhp <- 'fail'
hu_failed <- get_fails(hu)
hu_failed$units <- 'fail'
hhs_failed <- get_fails(hhs)
hhs_failed$hhs <- 'fail'
gq_failed <- get_fails(gq)
gq_failed$gqpop <- 'fail' 
vac_failed <- get_fails(vac)
vac_failed$vac <- 'fail' 

# summary dataframe - merge all variables
allvars <- Reduce(function(x, y) merge(x, y, all=TRUE), 
                  list(pop_failed, households_failed,hhp_failed,hu_failed, hhs_failed, gq_failed,vac_failed))
allvars <- allvars[order(allvars['hh'],allvars['hhp'],allvars['geotype'],allvars['geozone']),]
ids <- rep(1:2, times=nrow(allvars)/2)    ##1:2 represents shade coding for excel, used later
if (length(ids) < nrow(allvars)) {ids<-c(ids,1)}
allvars$id <- ids
allvars[is.na(allvars)] <- 'pass'


##create dataframe for cpa, jur, and zip

pop_cpa <- subset(pop, geotype== 'cpa')
pop_jur <- subset(pop, geotype== 'jurisdiction')
pop_zip <- subset(pop, geotype== 'zip')
pop_zip$geozone<- as.numeric(pop_zip$geozone)


hh_cpa <- subset(households, geotype== 'cpa')
hh_jur <- subset(households, geotype== 'jurisdiction')
hh_zip <- subset(households, geotype== 'zip')
hh_zip$geozone<- as.numeric(hh_zip$geozone)

hhp_cpa <- subset(hhp, geotype== 'cpa')
hhp_jur <- subset(hhp, geotype== 'jurisdiction')
hhp_zip <- subset(hhp, geotype== 'zip')
hhp_zip$geozone<- as.numeric(hhp_zip$geozone)

hhs_cpa <- subset(hhs, geotype== 'cpa')
hhs_jur <- subset(hhs, geotype== 'jurisdiction')
hhs_zip <- subset(hhs, geotype== 'zip')
hhs_zip$geozone<- as.numeric(hhs_zip$geozone)

hu_cpa <- subset(hu, geotype== 'cpa')
hu_jur <- subset(hu, geotype== 'jurisdiction')
hu_zip <- subset(hu, geotype== 'zip')
hu_zip$geozone<- as.numeric(hu_zip$geozone)

gq_cpa <- subset(gq, geotype== 'cpa')
gq_jur <- subset(gq, geotype== 'jurisdiction')
gq_zip <- subset(gq, geotype== 'zip')
gq_zip$geozone<- as.numeric(gq_zip$geozone)

vac_cpa <- subset(vac, geotype== 'cpa')
vac_jur <- subset(vac, geotype== 'jurisdiction')
vac_zip <- subset(vac, geotype== 'zip')
vac_zip$geozone<- as.numeric(vac_zip$geozone)

########################################################### 
# create excel workbook

wb = createWorkbook()


#add summary worksheet
summary = addWorksheet(wb, "Summary of Findings", tabColour = "red")
# add table of contents
tableofcontents = addWorksheet(wb, "TableofContents")

#formatting sheets
headerStylecontents <- createStyle(fontSize = 14,textDecoration = "bold")
writeData(wb, tableofcontents, x = "Worksheet Name", startCol = 1, startRow = 1)
writeData(wb, tableofcontents, x = "Worksheet Description", startCol = 2, startRow = 1)
writeData(wb, tableofcontents, x = "Test Criteria", startCol = 3, startRow = 1)
setColWidths(wb, tableofcontents, cols = c(1,2), widths = c(45,45))
addStyle(wb, tableofcontents, style = headerStylecontents, rows = 1, cols = ncol1:3, gridExpand = TRUE)




#adding content to the sheets
writeFormula(wb, tableofcontents, startRow = 5, 
             x = makeHyperlinkString(sheet = "Summary of Findings", row = 1, col = 1,text = "Summary of Findings"))
writeData(wb, tableofcontents,x = "Geographies that failed for any variable: Total Population, Housing units,Households,Household Population, Household size, Group Quarter Population,Vacancy Rate ", startRow = 5, startCol = 2)


# add comments to sheets with cutoff
# create dictionary hash of comments
fullname <- hash()
fullname['pop'] <- "Total Population"
fullname['hu'] <- "Housing units"
fullname['hh'] <- "Households"
fullname['hhp'] <- "Household Population"
fullname['hhs'] <- "Household Size"
fullname['gq'] <- "Group Quarter Population"
fullname['vac'] <- "Vacancy Rate"

# add comments to sheets with cutoff
# create dictionary hash of comments
acceptance_criteria <- hash()
acceptance_criteria['pop'] <- ">5%"
acceptance_criteria['hu'] <- ">5%"
acceptance_criteria['hh'] <- ">5%"
acceptance_criteria['hhp'] <- ">5%"
acceptance_criteria['hhs'] <- ">5%"
acceptance_criteria['gq'] <- ">5%"
acceptance_criteria['Vac'] <- ">5%"



writeData(wb, summary, x = "List of geographies that failed for any of the following variables: Total Population, Housing units,Households,Household Population, Household size, Group Quarter Population,Vacancy Rate", 
          startCol = 1, startRow = 1)
headerStyleforsummary <- createStyle(fontSize = 12 ,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)


# add summary table of cutoffs
writeData(wb, summary, x = "Variable", startCol = 1, startRow = nrow(allvars)+6)
writeData(wb, summary, x = "Description", startCol = 2, startRow = nrow(allvars)+6)
writeData(wb, summary, x = "Test Criteria", startCol = 3, startRow = nrow(allvars)+6)
headerStyle1 <- createStyle(fontSize = 12, halign = "center" ,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(allvars)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)


tableStyle1 <- createStyle(fontSize = 10, halign = "center")
tableStyle2 <- createStyle(fontSize = 10, halign = "left")

#test criteria at bottom

writeData(wb, summary, x = "pop", startCol = 1, startRow = nrow(allvars)+7)
writeData(wb, summary, x = "Total Population", startCol = 2, startRow = nrow(allvars)+7)
writeData(wb, summary, x = acceptance_criteria[['pop']], startCol = 3, startRow = nrow(allvars)+7)

writeData(wb, summary, x = "hu", startCol = 1, startRow = nrow(allvars)+8)
writeData(wb, summary, x = "Number of housing units", startCol = 2, startRow = nrow(allvars)+8)
writeData(wb, summary, x = acceptance_criteria[['hu']], startCol = 3, startRow = nrow(allvars)+8)

writeData(wb, summary, x = "hh", startCol = 1, startRow = nrow(allvars)+9)
writeData(wb, summary, x = "Number of households", startCol = 2, startRow = nrow(allvars)+9)
writeData(wb, summary, x = acceptance_criteria[['hh']], startCol = 3, startRow = nrow(allvars)+9)

writeData(wb, summary, x = "hhp", startCol = 1, startRow = nrow(allvars)+10)
writeData(wb, summary, x = "Household Population", startCol = 2, startRow = nrow(allvars)+10)
writeData(wb, summary, x = acceptance_criteria[['hhp']], startCol = 3, startRow = nrow(allvars)+10)

writeData(wb, summary, x = "hhs", startCol = 1, startRow = nrow(allvars)+11)
writeData(wb, summary, x = "Household Size", startCol = 2, startRow = nrow(allvars)+11)
writeData(wb, summary, x = acceptance_criteria[['hhs']], startCol = 3, startRow = nrow(allvars)+11)

writeData(wb, summary, x = "gq", startCol = 1, startRow = nrow(allvars)+12)
writeData(wb, summary, x = "Group Quarter Population", startCol = 2, startRow = nrow(allvars)+12)
writeData(wb, summary, x = acceptance_criteria[['gq']], startCol = 3, startRow = nrow(allvars)+12)

writeData(wb, summary, x = "vac", startCol = 1, startRow = nrow(allvars)+13)
writeData(wb, summary, x = "Vacancy Rate", startCol = 2, startRow = nrow(allvars)+13)
writeData(wb, summary, x = acceptance_criteria[['Vac']], startCol = 3, startRow = nrow(allvars)+13)

addStyle(wb, summary, tableStyle1, rows = (nrow(allvars)+7):(nrow(allvars)+13), cols = 1, gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, tableStyle2, rows = (nrow(allvars)+7):(nrow(allvars)+13), cols = 2:3, gridExpand = TRUE,stack = TRUE)


#writing data to summary sheet
writeData(wb,summary,allvars,startCol = 1, startRow = 4, headerStyle = headerStyleforsummary)



for (index in 1:nrow(allvars)) { 
  row = allvars[index, ]
  if ((row$hh == 'fail') & (row$geotype == 'cpa')) {
  rnfail = max(which((hh_cpa$geozone ==row$geozone) & (hh_cpa['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 3, 
                 x = makeHyperlinkString(sheet = 'hh_cpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hh == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((hh_jur$geozone ==row$geozone) & (hh_jur['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 3, 
                 x = makeHyperlinkString(sheet = 'hh_jur', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hh == 'fail') & (row$geotype == 'zip')) {
    rnfail = max(which((hhh_zip$geozone ==row$geozone) & (hh_zip['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 3, 
                 x = makeHyperlinkString(sheet = 'hh_zip', row = rnfail, col = 3,text = "fail"))
  }
  
  if ((row$hhp == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((hhp_cpa$geozone ==row$geozone) & (hhp_cpa['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 4, 
                 x = makeHyperlinkString(sheet = 'hhp_cpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hhp == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((hhp_jur$geozone ==row$geozone) & (hhp_jur['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 4, 
                 x = makeHyperlinkString(sheet = 'hhp_jur', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hhp == 'fail') & (row$geotype == 'zip')) {
    rnfail = max(which((hhp_zip$geozone ==row$geozone) & (hhp_zip['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 4, 
                 x = makeHyperlinkString(sheet = 'hhp_zip', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hhs == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((hhs_cpa$geozone ==row$geozone) & (hhs_cpa['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 5, 
                 x = makeHyperlinkString(sheet = 'hhs_cpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hhs == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((hhs_jur$geozone ==row$geozone) & (hhs_jur['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 5, 
                 x = makeHyperlinkString(sheet = 'hhs_jur', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hhs == 'fail') & (row$geotype == 'zip')) {
    rnfail = max(which((hhs_zip$geozone ==row$geozone) & (hhs_zip['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 5, 
                 x = makeHyperlinkString(sheet = 'hhs_zip', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$units == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((hu_cpa$geozone ==row$geozone) & (hu_cpa['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 6, 
                 x = makeHyperlinkString(sheet = 'hu_cpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$units == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((hu_jur$geozone ==row$geozone) & (hu_jur['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 6, 
                 x = makeHyperlinkString(sheet = 'hu_jur', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$units == 'fail') & (row$geotype == 'zip')) {
    rnfail = max(which((hu_zip$geozone ==row$geozone) & (hu_zip['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 6, 
                 x = makeHyperlinkString(sheet = 'hu_zip', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$gqpop == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((gq_cpa$geozone ==row$geozone) & (gq_cpa['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 7, 
                 x = makeHyperlinkString(sheet = 'gq_cpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$gqpop == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((gq_jur$geozone ==row$geozone) & (gq_jur['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 7, 
                 x = makeHyperlinkString(sheet = 'gq_jur', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$gqpop == 'fail') & (row$geotype == 'zip')) {
    rnfail = max(which((gq_zip$geozone ==row$geozone) & (gq_zip['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 7, 
                 x = makeHyperlinkString(sheet = 'gq_zip', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$vac == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((vac_cpa$geozone ==row$geozone) & (vac_cpa['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 8, 
                 x = makeHyperlinkString(sheet = 'vac_cpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$vac == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((vac_jur$geozone ==row$geozone) & (vac_jur['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 8, 
                 x = makeHyperlinkString(sheet = 'vac_jur', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$vac == 'fail') & (row$geotype == 'zip')) {
    rnfail = max(which((vac_zip$geozone ==row$geozone) & (vac_zip['pass.or.fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 8, 
                 x = makeHyperlinkString(sheet = 'vac_zip', row = rnfail, col = 3,text = "fail"))
  }
  
}


writeData(wb, summary, x = "EDAM review", startCol = (ncol(allvars) + 1), startRow = 4)


# specify sheetname and tab colors
add_worksheets_to_excel(wb,"pop","yellow",8,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"hu","blue",12,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"hh","green",16,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"hhp","orange",20,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"hhs","orange",24,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"gq","yellow",28,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"vac","purple",32,fullname,acceptance_criteria)

# add comments to sheets with cutoff


#writing data to sheets- Alterative code since the function wasnt running 
writeData(wb, "pop_cpa", pop_cpa )
writeData(wb, "pop_jur", pop_jur )
writeData(wb, "pop_zip", pop_zip )
writeData(wb, "hh_cpa", hh_cpa )
writeData(wb, "hh_jur", hh_jur )
writeData(wb, "hh_zip", hh_zip )
writeData(wb, "hhp_cpa", hhp_cpa )
writeData(wb, "hhp_jur", hhp_jur )
writeData(wb, "hhp_zip", hhp_zip )
writeData(wb, "hhs_cpa", hhs_cpa )
writeData(wb, "hhs_jur", hhs_jur )
writeData(wb, "hhs_zip", hhs_zip )
writeData(wb, "hu_cpa", hu_cpa )
writeData(wb, "hu_jur", hu_jur )
writeData(wb, "hu_zip", hu_zip )
writeData(wb, "gq_cpa", gq_cpa )
writeData(wb, "gq_jur", gq_jur )
writeData(wb, "gq_zip", gq_zip )
writeData(wb, "vac_cpa", vac_cpa )
writeData(wb, "vac_jur", vac_jur )
writeData(wb, "vac_zip", vac_zip )

#Anne this is what I am having problem with the function below

##i <-3 # starting sheet number (sheet 1 is summar, sheet 2 is table of contents)
##for (demographic_var in c('units','households','hhp','gqpop','jobs')) {
  ##add_data_to_excel(wb,demographic_var,i)
  ##i <- i + 3 # 3 sheets for each variable: jur,cpa,region
##}




# formatting style

negStyle <- createStyle(fontColour = "#9C0006", bgFill = "#FFC7CE")
posStyle <- createStyle(fontColour = "#006100", bgFill = "#C6EFCE")
checkStyle <- createStyle(fontColour = "#9C5700", bgFill = "#FFEB9C")
lightgreyStyle <- createStyle(bgFill = "#dce6f1") #"#fcfcfa" #dce6f1 "#f5f5e6"
darkgreyStyle <- createStyle(bgFill = "#c5d9f1") # "#e3e3e1" #c5d9f1 #b8cce4
headerStyle <- createStyle(fontSize = 13, fontColour = "#FFFFFF", halign = "center",
                           fgFill = "#4F81BD", border="TopBottom", borderColour = "#4F81BD",
                           wrapText = TRUE)
invisibleStyle <- createStyle(fontColour = "#FFFFFF")
insideBorders <- openxlsx::createStyle(
  border = c("top", "bottom", "left", "right"),
  borderStyle = "dashed",borderColour="white")

rangeRows = 1:(nrow(hh_zip)+1)
rangeRowscpa = 2:(nrow(hh_cpa)+1)
rangeRowsjur = 2:(nrow(hh_jur)+1)
rangeRowszip = 2:(nrow(hh_zip)+1)
rangeCols = 1:(ncol(hh_jur))
pct = createStyle(numFmt="0%") # percent 
aligncenter = createStyle(halign = "center")


# format for summary sheet

conditionalFormatting(wb, summary, cols=c(1:(ncol(allvars)-1)), rows =1:(nrow(allvars)+4), rule="$J1==2", style = lightgreyStyle)
conditionalFormatting(wb, summary, cols=c(1:(ncol(allvars)-1)), rows=1:(nrow(allvars)+4), rule="$J1==1", style = darkgreyStyle)

addStyle(wb = wb,summary,style = insideBorders,rows = 4:(nrow(allvars)+3),cols = c(1:(ncol(allvars)-1),ncol(allvars)+1),gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, headerStyle, rows = 4, cols = c(1:ncol(allvars)+1), gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, style=invisibleStyle, cols=c(ncol(allvars)), rows=4:(nrow(allvars)+4), gridExpand=TRUE,stack = TRUE)
#conditionalFormatting(wb, summary, cols=1:(ncol(allvars)-1), rows=3:(nrow(allvars)+3), rule="$J1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(allvars)-1), rows=4:(nrow(allvars)+4), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(allvars)-1), rows=4:(nrow(allvars)+4), type="contains", rule="pass", style = posStyle)
setColWidths(wb, summary, cols = c(1,2,3,4,5,6,7,8,9,10,11), widths = c(16,22,15,30,18,18,18,18,18,2,40))
addStyle(wb, summary, style=aligncenter,cols=c(1:11), rows=4:(nrow(allvars)+4), gridExpand=TRUE,stack = TRUE)

#formating for other sheets

for (curr_sheet in names(wb)[3:length(names(wb))]) {
  #addStyle(wb = wb,sheet = curr_sheet,style = insideBorders,rows = rangeRowscpa,cols = rangeCols,gridExpand = TRUE,stack = TRUE)
  #addStyle(wb, curr_sheet, style=pct, cols=c(7), rows=rangeRowscpa, gridExpand=TRUE,stack = TRUE)
  #addStyle(wb, curr_sheet, style=aligncenter, cols=c(1:4,8), rows=rangeRows, gridExpand=TRUE,stack = TRUE)
  #addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(hhp_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(ncol(hh_jur)), rows=1:(nrow(hh_zip)), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8), widths = c(16,24,12,15,16,16,16,18))
  #conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$I1==2", style = lightgreyStyle)
  #conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$I1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="pass", style = posStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}








# out folder for excel

setwd(file.path(outfolder))

#saveWorkbook(wb, outfile,overwrite=TRUE)
saveWorkbook(wb, outfile,overwrite=TRUE)










#set 2010 number and pct change to NA - there is no previous year to calculate change
#est$hhp_pct[est$yr_id==2010] <- NA
#est$hhp_chg[est$yr_id==2010] <- NA
#est$hhs_pct[est$yr_id==2010] <- NA
#est$hhs_chg[est$yr_id==2010] <- NA
#est$hh_pct[est$yr_id==2010] <- NA
#est$hh_chg[est$yr_id==2010] <- NA 
#est$hu_pct[est$yr_id==2010] <- NA
#est$hu_chg[est$yr_id==2010] <- NA 
#est$gq_pct[est$yr_id==2010] <- NA
#est$gq_chg[est$yr_id==2010] <- NA 
#est$vac_chg[est$yr_id==2010] <- NA 

#head(est[est$geotype=="jurisdiction",],10)
#set Inf values to NA for later calculations
#est$hhp_pct[is.infinite(est$hhp_pct)] <-NA 
#est$hhs_pct[is.infinite(est$hhs_pct)] <-NA 
#est$hh_pct[is.infinite(est$hh_pct)] <-NA 
#est$hu_pct[is.infinite(est$hu_pct)] <-NA 
#est$gq_pct[is.infinite(est$gq_pct)] <- NA 
#est$vac_chg[is.infinite(est$vac_chg)]<- NA
#head(est[est$geotype=="jurisdiction",],10)







