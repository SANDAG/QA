#forcast QA ID 31

#calculate % change when lag value is 0

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)
getwd()

datasource_id_current <- 31

source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","zip","reshape2")

pkgTest(packages)

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get hhpop data
dem <- readDB("../Queries/age_ethn_gender.sql",datasource_id_current)
geography_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)

odbcClose(channel)

#select only years of interest for QA
dem <- subset(dem, yr_id %in% c(2016,2018,2020,2025,2030,2035,2040,2045,2050))

#since cpa Marine Corps Recruit Depot was not part of ID 17 2016 dataset records are added here with zero pop
marine <- subset(dem, geozone=="Marine Corps Recruit Depot" & yr_id=="2018")
marine_2016<- data.frame(marine)
marine_2016['yr_id'] = 2016
marine_2016[,"pop"] = 0

dem <- rbind(dem,marine_2016)

#merge in geography ids
dem <- merge(dem,geography_id, by.x="geozone",by.y="geozone", all = TRUE)
#recode id and geozone name for region records
dem$id[dem$geotype=='region'] <- 9999
dem$geozone[dem$geotype=='region'] <- 'San Diego Region'
rm(geography_id)
head(dem)

#rename variable id to geo_id
dem <- dem %>% rename(geo_id= id)
# clean up cpa names removing asterick and dashes etc.
dem <- rm_special_chr(dem)
dem <- subset(dem,geozone != 'Not in a CPA')
head(dem)

#recode ethnicity 
dem$ethn_group <- ifelse(dem$short_name=="Hispanic","Hispanic",
                         ifelse(dem$short_name=="White","White",
                                ifelse(dem$short_name=="Black","Black",
                                       ifelse(dem$short_name=="Asian","Asian","Other"))))

#aggregate pop by ethnic group, geography and year
dem_ethn<-aggregate(pop~ethn_group+geotype+geozone+geo_id+yr_id, data=dem, sum)

#create numeric id for ethnicity for sorting purposes
dem_ethn<- mutate(dem_ethn, ethn_id=
              ifelse(grepl("Hisp", ethn_group), 1,
                     ifelse(grepl("White", ethn_group),2,
                            ifelse(grepl("Black", ethn_group),3,
                                   ifelse(grepl("Asian", ethn_group),4,5)))))

#compare totals by ethn_group and ethn_id to confirm a match - therefore code is correct
dem_ethn  %>%  group_by(ethn_group) %>% tally(pop)
dem_ethn  %>%  group_by(ethn_id) %>% tally(pop)




####testing of marine and lindbergh field to make sure marine + lindbergh ~ lindbergh

marine <- subset(dem_ethn, geozone=="Marine Corps Recruit Depot" & (yr_id=="2018" | yr_id=="2016"))
head(marine)

lindbergh <- subset(dem_ethn, geozone=="Lindbergh Field" & (yr_id=="2018" | yr_id=="2016"))
head(lindbergh)

marine <- rename(marine, Marine_Corps_pop = pop)
lindbergh <- rename(lindbergh, Lindbergh_pop = pop)
marine <- select(marine, yr_id,ethn_group,ethn_id,Marine_Corps_pop)

marine$Lindbergh_pop <- lindbergh[match(paste(marine$yr_id,marine$ethn_group), paste(lindbergh$yr_id,lindbergh$ethn_group)),"Lindbergh_pop"]
marine

marine$tot_pop <- marine$Marine_Corps_pop+marine$Lindbergh_pop

marine2lindbergh <- dcast(marine,ethn_group+ethn_id~yr_id, value.var = "tot_pop")
marine2lindbergh <- rename(marine2lindbergh, lindbergh_2016="2016")
marine2lindbergh <- rename(marine2lindbergh, marine_plus_lindbergh_2018="2018")
marine2lindbergh

rm(marine,lindbergh,marine_2016)

#####end testing


#creates file with pop totals by geozone and year for proportion change calculation
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=dem_ethn, sum)

tail(geozone_pop)

#order dataframe for lag calcs
dem_ethn <- dem_ethn[order(dem_ethn$ethn_id,dem_ethn$geotype,dem_ethn$geozone,dem_ethn$yr_id),]

#lag for pop change based on proportion
ethn_proportion <- data.frame(dem_ethn)
ethn_proportion$change <- ethn_proportion$pop - lag(ethn_proportion$pop)
ethn_proportion$geozone_pop<-geozone_pop[match(paste(ethn_proportion$yr_id, ethn_proportion$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), "pop"]
ethn_proportion$proportion_of_pop<-(ethn_proportion$pop / ethn_proportion$geozone_pop)
ethn_proportion$proportion_of_pop<-round(ethn_proportion$proportion_of_pop,digits=2)
ethn_proportion$percent_change <- ethn_proportion$proportion_of_pop - lag(ethn_proportion$proportion_of_pop)
ethn_proportion$percent_change<-round(ethn_proportion$percent_change,digits=2)

head(ethn_proportion,15)

#recode values for 2016 change and NAN values
ethn_proportion$change[ethn_proportion$yr_id == "2016"] <- NA
ethn_proportion$percent_change[ethn_proportion$yr_id == "2016"] <- NA
#ethn_proportion$change[ethn_proportion$change == "NA"] <- 0
ethn_proportion$percent_change[ethn_proportion$percent_change == "NaN"] <- 0
#ethn_proportion$percent_change[ethn_proportion$percent_change == "Inf"] <- 0

#check flower hill as example of NAN
head(ethn_proportion[ethn_proportion$geozone=="Flower Hill",])
head(ethn_proportion[ethn_proportion$geozone=="Marine Corps Recruit Depot",])
head(ethn_proportion[ethn_proportion$geozone=="Lindbergh Field",])
head(ethn_proportion[ethn_proportion$geozone=="Via De La Valle",],20)
head(ethn_proportion[ethn_proportion$geozone=="Otay",],20)
head(ethn_proportion[ethn_proportion$geozone=="Fairbanks Country Club",],20)

max(ethn_proportion$percent_change[!is.na(ethn_proportion$percent_change)])
min(ethn_proportion$percent_change[!is.na(ethn_proportion$percent_change)])

#create absolute value to use in identifying fails
ethn_proportion$change_abs <- abs(ethn_proportion$change)
ethn_proportion$percent_change_abs <- abs(ethn_proportion$percent_change)

head(ethn_proportion,12)

#identify fails by EDAM parameters
ethn_proportion <- ethn_proportion %>%
  mutate(pass.or.fail = case_when(((ethn_id==1 & change_abs > 2500 & percent_change_abs > .20)| 
                                     (ethn_id==2 & change_abs > 2500 & percent_change_abs > .20)|
                                     (ethn_id==3 & change_abs > 250 & percent_change_abs > .20)|
                                     (ethn_id==4 & change_abs > 1000 & percent_change_abs > .20)|
                                     (ethn_id==5 & change_abs > 500 & percent_change_abs > .20)) ~ 1,
                                  TRUE ~ 0))

head(ethn_proportion)

ethn_proportion <- ethn_proportion %>%
  mutate(pass.or.fail.QA = case_when(((ethn_id==1 & change_abs > 500 & percent_change_abs > .05)| 
                                     (ethn_id==2 & change_abs > 500 & percent_change_abs > .05)|
                                     (ethn_id==3 & change_abs > 250 & percent_change_abs > .05)|
                                     (ethn_id==4 & change_abs > 500 & percent_change_abs > .05)|
                                     (ethn_id==5 & change_abs > 500 & percent_change_abs > .05)) ~ 1,
                                  TRUE ~ 0))


ethn_flag_QA <- aggregate(pass.or.fail~geozone+geotype+ethn_group+geo_id,data = ethn_proportion,max)
ethn_proportion$sort_flag <-  ethn_flag_QA[match(paste(ethn_proportion$geotype,ethn_proportion$geozone,ethn_proportion$ethn_group),paste(ethn_flag_QA$geotype,ethn_flag_QA$geozone,ethn_flag_QA$ethn_group)),5]

table(ethn_flag_QA$pass.or.fail)

#create variable for sorting
ethn_flag <- aggregate(pass.or.fail~geozone+geotype+ethn_group+geo_id,data = ethn_proportion,max)
ethn_proportion$sort_flag <-  ethn_flag[match(paste(ethn_proportion$geotype,ethn_proportion$geozone,ethn_proportion$ethn_group),paste(ethn_flag$geotype,ethn_flag$geozone,ethn_flag$ethn_group)),5]
#sort file
ethn_proportion <- arrange(ethn_proportion, desc(sort_flag,ethn_group,geotype,geozone,yr_id))

#select variables for final dataset
ethn_proportion <- ethn_proportion %>% select(geotype,geozone,yr_id,ethn_group,pop,geozone_pop,change,proportion_of_pop,percent_change,pass.or.fail,pass.or.fail.QA,sort_flag)

#create datasource id variable
ethn_proportion$datasource_id <- datasource_id_current

head(ethn_proportion)

#check that each geozone has record for 9 years
t <- ethn_proportion %>% group_by(geozone,ethn_group) %>% tally()
if (nrow(subset(t,n!=9))!=0) {
  print("ERROR: expecting 9 years per geography")
  print(subset(t,n!=9)) } 



####
####
####end proportion


#lag for pop change
dem_ethn$change <- dem_ethn$pop - lag(dem_ethn$pop)
dem_ethn$percent_change<-(dem_ethn$pop-lag(dem_ethn$pop)) / lag(dem_ethn$pop)
dem_ethn$percent_change<-round(dem_ethn$percent_change,digits=2)

#testing - review case
head(dem_ethn[dem_ethn$geozone=="Clairemont Mesa" & dem_ethn$ethn_group=="Hispanic",],9)

head(dem_ethn)

#recode values for 2016 change and NAN values
dem_ethn$change[dem_ethn$yr_id == "2016"] <- NA
dem_ethn$percent_change[dem_ethn$yr_id == "2016"] <- NA
#dem_ethn$change[dem_ethn$change == "NA"] <- 0
dem_ethn$percent_change[dem_ethn$percent_change == "NaN"] <- 0
#dem_ethn$percent_change[dem_ethn$percent_change == "Inf"] <- 0

#check some examples of NAN
head(dem_ethn[dem_ethn$geozone=="Flower Hill",])
head(dem_ethn[dem_ethn$geozone=="Marine Corps Recruit Depot",])
head(dem_ethn[dem_ethn$geozone=="East Elliott",],20)
infinite_test <- dem_ethn[is.infinite(dem_ethn$percent_change),]

#create absolute value to use in identifying fails
dem_ethn$change_abs <- abs(dem_ethn$change)
dem_ethn$percent_change_abs <- abs(dem_ethn$percent_change)

head(dem_ethn,12)

#identify fails by EDAM parameters
dem_ethn <- dem_ethn %>%
  mutate(pass.or.fail = case_when(((ethn_id==1 & change_abs > 2500 & percent_change_abs > .20)| 
                                     (ethn_id==2 & change_abs > 2500 & percent_change_abs > .20)|
                                     (ethn_id==3 & change_abs > 250 & percent_change_abs > .20)|
                                     (ethn_id==4 & change_abs > 1000 & percent_change_abs > .20)|
                                     (ethn_id==5 & change_abs > 500 & percent_change_abs > .20)) ~ 1,
                                  TRUE ~ 0))


#create variable for sorting
ethn_flag <- aggregate(pass.or.fail~geozone+geotype+ethn_group+geo_id,data = dem_ethn,max)
dem_ethn$sort_flag <-  ethn_flag[match(paste(dem_ethn$geotype,dem_ethn$geozone,dem_ethn$ethn_group),paste(ethn_flag$geotype,ethn_flag$geozone,ethn_flag$ethn_group)),5]
#sort file
dem_ethn <- arrange(dem_ethn, desc(sort_flag,ethn_group,geotype,geozone,yr_id))

head(dem_ethn,15)

#test <- subset(dem_ethn, dem_ethn$geotype=="cpa")
#test <- arrange(test, desc(sort_flag,geotype,geozone,yr_id,ethn_group))


#select variables for final dataset
dem_ethn <- dem_ethn %>% select(geotype,geozone,geo_id,yr_id,ethn_group,ethn_id,pop,change,percent_change,pass.or.fail)

#create datasource id variable
dem_ethn$datasource_id <- datasource_id_current

head(dem_ethn)
# dem_ethn <- add_id_for_excel_formatting(dem_ethn)
#check that each geozone has record for 9 years
t <- dem_ethn %>% group_by(geozone,ethn_group) %>% tally()
if (nrow(subset(t,n!=9))!=0) {
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) } 


#ids <- rep(1:2, times=nrow(t)/2, each=9)
#if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
#dem_ethn$id <- ids

colnames(dem_ethn)
colnames(ethn_proportion)

#merge raw number change and raw number percent change
ethn_proportion <- merge(dem_ethn, ethn_proportion, by.x = c("ethn_group","geozone","yr_id"), by.y = c("ethn_group","geozone","yr_id"), all = TRUE)
ethn_proportion <- select(ethn_proportion,datasource_id,yr_id,geozone,ethn_group,pop.x,change.x,percent_change.x,proportion_of_pop,percent_change.y,
                          pass.or.fail,sort_flag)

head(ethn_proportion)

#create summary sheet
ethn_summary <- aggregate(pass.or.fail~datasource_id+geotype+geozone+ethn_group, data=dem_ethn, max)
ethn_summary$pass.or.fail[ethn_summary$pass.or.fail==0] <- "pass"
ethn_summary$pass.or.fail[ethn_summary$pass.or.fail==1] <- "fail"
ethn_summary <- spread(ethn_summary,ethn_group,pass.or.fail)
ethn_summary <- subset(ethn_summary,(Asian=="fail"|Black=="fail"|Hispanic=="fail"|Other=="fail"|White=="fail"))
ethn_summary <- arrange(ethn_summary, Asian,Black,Hispanic,Other,White)

#assign number id for shading summary sheet in excel
ids1 <- rep(1:2, times=nrow(ethn_summary)/2, each=1)
if (nrow(ethn_summary)%%2!=0 ) {ids1 <- append(ids1, c(1))}
ethn_summary$id <- ids1

head(ethn_summary)

#rename values for pass/fail in file with all records
dem_ethn$pass.or.fail[dem_ethn$pass.or.fail==0] <- "pass"
dem_ethn$pass.or.fail[dem_ethn$pass.or.fail==1] <- "fail"

#rename variables for output file
dem_ethn <- dem_ethn %>% rename('year' = yr_id,'increment change'= change,'ethnicity' =ethn_group,'ethnicity id'=ethn_id,'Population by Ethnicity' = pop, 'Change in Population by Ethnicity' = change,
                                'Percent Change by Ethnicity' = percent_change,'pass/fail'= pass.or.fail)
ethn_proportion <- ethn_proportion %>% rename('Year' = yr_id,'Ethnicity' = ethn_group,'Population by Ethnicity' = pop, 'Change in Population by Ethnicity' = change.x,
                                              'Percent Change by Ethnicity' = percent_change.x,'Proportion of Population' = proportion_of_pop,
                                              'Proportion Change' = percent_change,'pass/fail'= pass.or.fail)


#move datasource_id to first column position
dem_ethn <- dem_ethn %>% select(datasource_id,everything())

#create files by geotype for output
dem_ethn_cpa <- subset(dem_ethn,dem_ethn$geotype=='cpa')
dem_ethn_jur <- subset(dem_ethn,dem_ethn$geotype=='jurisdiction')
dem_ethn_reg <- subset(dem_ethn,dem_ethn$geotype=='region')

#have sorted before assigning id
#cpa is sorted
#sort jur since no fails
table(dem_ethn_jur$`pass/fail`)
dem_ethn_jur <- arrange(dem_ethn_jur, geotype,geozone,ethnicity,year)
#sort reg since no fails
table(dem_ethn_reg$`pass/fail`)
dem_ethn_reg <- arrange(dem_ethn_reg, geotype,geozone,ethnicity,year)

#assign id for shading format
dem_ethn_reg <- dem_ethn_reg %>% 
  mutate(id=rep(1:2, each = 9, len = nrow(dem_ethn_reg))) 

dem_ethn_jur <- dem_ethn_jur %>% 
  mutate(id=rep(1:2, each = 9, len = nrow(dem_ethn_jur))) 

dem_ethn_cpa <- dem_ethn_cpa %>% 
  mutate(id=rep(1:2, each = 9, len = nrow(dem_ethn_cpa))) 

head(dem_ethn_cpa,12)
table(dem_ethn_cpa$id)

head(dem_ethn_jur,12)
table(dem_ethn_jur$id)

head(dem_ethn_reg,12)
table(dem_ethn_reg$id)

#rename geozone for cpa and jurisdiction and region
dem_ethn_cpa <- dem_ethn_cpa %>% rename('cpa'= geozone)
dem_ethn_jur <- dem_ethn_jur %>% rename('jurisdiction'= geozone)
dem_ethn_reg <- dem_ethn_reg %>% rename('region'= geozone)

#delete unneeded columns
dem_ethn_cpa$geotype <-NULL
dem_ethn_cpa$geo_id <-NULL

dem_ethn_jur$geotype <-NULL
dem_ethn_jur$geo_id <-NULL

dem_ethn_reg$geotype <-NULL
dem_ethn_reg$geo_id <-NULL

head(dem_ethn_reg)

#remove unneeded objects
rm(dem,dem_ethn,ethn_flag,t)

########################################################### 
###########################################################

# create excel workbook

wb = createWorkbook()

#add blank summary worksheet
summary = addWorksheet(wb, "Summary of Findings", tabColour = "red")

#no table of contents included

# read email message from Dave and attach to excel spreadsheet
## Insert email as images
imgfilepath<- "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\6_Notes\\"
img1a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 1.png",sep='')
img2a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 2.png",sep='')
img3a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 3.png",sep='')
img4a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 4.png",sep='')

# add sheet with email info
shtemail = addWorksheet(wb, "Email")

insertImage(wb, shtemail, img1a, startRow = 3,  startCol = 2, width = 19.74, height = 4.77,units = "in") # divide by 96
insertImage(wb, shtemail, img2a, startRow = 26,  startCol = 2, width = 19.80, height = 6.93,units = "in")
insertImage(wb, shtemail, img3a, startRow = 61,  startCol = 2, width = 19.76, height = 7.09,units = "in")
insertImage(wb, shtemail, img4a, startRow = 98,  startCol = 2, width = 19.71, height = 8.97,units = "in")


# add comments to sheets with cutoff
# create dictionary hash of comments
fullname <- hash()
fullname['As'] <- "Asian"
fullname['Bl'] <- "Black"
fullname['His'] <- "Hispanic"
fullname['Oth'] <- "Other"
fullname['Wh'] <- "White"

# add comments to sheets with cutoff
# create dictionary hash of comments
acceptance_criteria <- hash()
acceptance_criteria['His'] <- "> 2,500 and > 20%"
acceptance_criteria['Wh'] <- "> 2,500 and > 20%"
acceptance_criteria['Bl'] <- "> 250 and > 20%"
acceptance_criteria['As'] <- "> 1,000 and > 20%"
acceptance_criteria['Oth'] <- "> 500 and > 20%"

#add summary text to summary sheet
writeData(wb, summary, x = "List of geographies that failed QC for ethnicity/race based on test criteria:", 
          startCol = 1, startRow = 1)
headerStyleforsummary <- createStyle(fontSize = 14) #,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)

# add summary table of cutoffs
writeData(wb, summary, x = "Ethnicity", startCol = 1, startRow = nrow(ethn_summary)+6)
writeData(wb, summary, x = "Test Criteria", startCol = 2, startRow = nrow(ethn_summary)+6)
headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(ethn_summary)+6, cols = 1:2, gridExpand = TRUE,stack = TRUE)


tableStyle1 <- createStyle(fontSize = 10, halign = "center")
tableStyle2 <- createStyle(fontSize = 10, halign = "left")

#headerStyleforsummary <- createStyle(fontSize = 14) #,textDecoration = "bold")
#addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)

#write list of failed geographies into summary sheet
writeData(wb, summary, ethn_summary, startCol = 1, startRow = 4)

#write ethnic group and test parameters 
writeData(wb, summary, x = "Asian", startCol = 1, startRow = nrow(ethn_summary)+7)
writeData(wb, summary, x = acceptance_criteria[['As']], startCol = 2, startRow = nrow(ethn_summary)+7)

writeData(wb, summary, x = "Black", startCol = 1, startRow = nrow(ethn_summary)+8)
writeData(wb, summary, x = acceptance_criteria[['Bl']], startCol = 2, startRow = nrow(ethn_summary)+8)

writeData(wb, summary, x = "Hispanic", startCol = 1, startRow = nrow(ethn_summary)+9)
writeData(wb, summary, x = acceptance_criteria[['His']], startCol = 2, startRow = nrow(ethn_summary)+9)

writeData(wb, summary, x = "Other", startCol = 1, startRow = nrow(ethn_summary)+10)
writeData(wb, summary, x = acceptance_criteria[['Oth']], startCol = 2, startRow = nrow(ethn_summary)+10)

writeData(wb, summary, x = "White", startCol = 1, startRow = nrow(ethn_summary)+11)
writeData(wb, summary, x = acceptance_criteria[['Wh']], startCol = 2, startRow = nrow(ethn_summary)+11)

#format the summary table with test parameters 
addStyle(wb, summary, tableStyle1, rows = (nrow(ethn_summary)+7):(nrow(ethn_summary)+11), cols = 1, gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, tableStyle2, rows = (nrow(ethn_summary)+7):(nrow(ethn_summary)+11), cols = 2, gridExpand = TRUE,stack = TRUE)

#add and format area for EDAM comments
writeData(wb,summary,ethn_summary,startCol = 1, startRow = 4)
writeData(wb, summary, x = "EDAM review", startCol = (ncol(ethn_summary) + 1), startRow = 4)


# add sheets with data 
shtregethn = addWorksheet(wb, "EthnicityByRegion", tabColour = "blue")
shtjurethn = addWorksheet(wb, "EthnicityByJur", tabColour = "blue")
shtcpaethn = addWorksheet(wb, "EthnicityByCPA", tabColour = "blue")

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
  borderStyle = "dashed",borderColour="white"
)
rangeRows = 1:(nrow(dem_ethn_cpa)+1)
rangeRowscpa = 2:(nrow(dem_ethn_cpa)+1)
rangeRowsjur = 2:(nrow(dem_ethn_jur)+1)
rangeRowsreg = 2:(nrow(dem_ethn_reg)+1)
rangeCols = 1:(ncol(dem_ethn_cpa)-1)
pct = createStyle(numFmt="0%") # percent 
aligncenter=createStyle(halign="center")

for (curr_sheet in names(wb)[-1]) {
  addStyle(wb = wb, sheet = curr_sheet,style = insideBorders, rows = rangeRowscpa, cols = rangeCols, gridExpand = TRUE, stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=rangeRowscpa, gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=createStyle(halign = 'center'), cols=c(1:5,9), rows=rangeRowscpa, gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(ncol(dem_ethn_jur)), rows=1:(nrow(dem_ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10), widths = c(16,33,10,15,10,18,18,18,14))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$J1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$J1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="check", style = checkStyle)
}

########FIX SUMMARY

# format for summary sheet
conditionalFormatting(wb, summary, cols=c(1:(ncol(ethn_summary)-1)), rows =1:(nrow(ethn_summary)+4), rule="$I1==2", style = lightgreyStyle)
conditionalFormatting(wb, summary, cols=c(1:(ncol(ethn_summary)-1)), rows=1:(nrow(ethn_summary)+4), rule="$I1==1", style = darkgreyStyle)

addStyle(wb = wb,summary,style = insideBorders,rows = 4:(nrow(ethn_summary)+3),cols = c(1:(ncol(ethn_summary)-1),ncol(ethn_summary)+1),gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, headerStyle, rows = 4, cols = c(1:(ncol(ethn_summary)-1),ncol(ethn_summary)+1), gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, style=invisibleStyle, cols=c(ncol(ethn_summary)), rows=4:(nrow(ethn_summary)+4), gridExpand=TRUE,stack = TRUE)
conditionalFormatting(wb, summary, cols=1:(ncol(ethn_summary)-1), rows=3:(nrow(ethn_summary)+3), rule="$I1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(ethn_summary)-1), rows=4:(nrow(ethn_summary)+4), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(ethn_summary)-1), rows=4:(nrow(ethn_summary)+4), type="contains", rule="check", style = checkStyle)
setColWidths(wb, summary, cols = c(1,2,3,4,5,6,7,8,9,10), widths = c(16,22,30,18,18,18,18,18,2,40))
addStyle(wb, summary, style=aligncenter,cols=c(1:10), rows=4:(nrow(ethn_summary)+4), gridExpand=TRUE,stack = TRUE)

######END OF SUMMARY TO FIX


writeData(wb, shtcpaethn,dem_ethn_cpa)
writeData(wb, shtjurethn,dem_ethn_jur)
writeData(wb, shtregethn,dem_ethn_reg)

# add comment with cutoffs to each sheet
c1 <- createComment(comment = "Hispanic change > 2,500 and > 20%\nWhite change > 2,500 and > 20%\nBlack change > 250 and > 20%\nAsian change > 1,000 and > 20%\nOther change > 500 and > 20%")
writeComment(wb, shtregethn, col = "I", row = 1, comment = c1)
writeComment(wb, shtjurethn, col = "I", row = 1, comment = c1)
writeComment(wb, shtcpaethn, col = "I", row = 1, comment = c1)


# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))


saveWorkbook(wb, "Ethnicity_counts.xlsx",overwrite=TRUE)

write.csv(marine2lindbergh, "Ethnicity of Lindbergh Field and Marine Depot 2016 & 2018.csv", row.names = FALSE)


