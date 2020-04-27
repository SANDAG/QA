#estimates
#file sizes are large so id33 data is transformed first and then id 24 data
#exclusion/recode of N_pct from inf to 0 loses info about most remarkably the Marine Corps Recruit Depot - need to fix or note
#ID24 pops by geozone merge in incorrectly

datasource_id_current <- 33

maindir= (dirname(rstudioapi::getActiveDocumentContext()$path))

setwd(maindir)


# excel workbook output file name and folder with timestamp
now <- Sys.time()
#outputfile <- paste("Ethnicity","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile <- paste("Gender","_ds",datasource_id_current,"_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))

outfolder<-paste("../Output/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- paste(maindir,"/",outfolder,outputfile,sep='')
#outfile2 <- paste(maindir,"/",outfolder,outputfile2,sep='')
print(paste("output filepath: ",outfile))


# sourcing the functions
source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "reshape2", 
              "stringr","tidyverse", "hash", "openxlsx")
pkgTest(packages)




#getting the data
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

countvars <- readDB("../Queries/age_ethn_gender.sql",datasource_id_current)
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)

odbcClose(channel)

#renaming countvars as countvars
countvars<- countvars

#renaming region as San Diego region

countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'


countvars <- merge(x = countvars, y =geo_id,by = "geozone", all.x = TRUE)

countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% rename('geo_id'= id)

# clean up cpa names removing asterick and dashes etc.
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')


#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)

#order file for merge
countvars<- countvars[order(countvars$geotype,countvars$geozone,countvars$yr_id),]



#aggregate total counts by year for age, gender and ethnicity
countvars_gender<-aggregate(pop~sex+geotype+geozone+yr_id, data=countvars, sum)


countvars  %>%  group_by(sex) %>% tally(pop)
countvars  %>%  group_by(sex_id) %>% tally(pop)

# #recode ethn into 3 categories per EDAM - White, Hispanic, Other
# #copy ethnicity column for reference
# countvars_ethn$short_name_orig=countvars_ethn$short_name
# #collapse ethnic categories
# countvars_ethn$short_name_rc <- 3
# countvars_ethn$short_name_rc[countvars_ethn$short_name=="Hispanic"] <- 1
# countvars_ethn$short_name_rc[countvars_ethn$short_name=="White"] <- 2
# 
# #name recoded ethnic categories
# countvars_ethn$short_name<- ifelse(countvars_ethn$short_name_rc==1,"Hispanic",
#                                    ifelse(countvars_ethn$short_name_rc==2,"White",
#                                           ifelse(countvars_ethn$short_name_rc==3,"Other",NA)))
#                                                  
#setnames(countvars_age, old = "pop", new = "pop_age_33")
#setnames(countvars_ethn, old = "pop", new = "pop_ethn_33")
#setnames(countvars_gender, old = "pop", new = "pop_gender_33")



table(countvars_gender$geotype)

#creates file with pop totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=countvars, sum)

tail(geozone_pop)


#calculate year to year changes and proportion of total pop by group per year within ID33.
countvars_gender <- countvars_gender[order(countvars_gender$sex,countvars_gender$geotype,countvars_gender$geozone,countvars_gender$yr_id),]

#Calculating lags and % change 


#gender
countvars_gender <- countvars_gender %>% 
  group_by(geozone,geotype,sex) %>% 
  mutate(change = pop - lag(pop))


countvars_gender <- countvars_gender %>%
  group_by(geozone,geotype,sex) %>% 
  mutate(percent_change = case_when(lag(pop)==0 & (pop==0)  ~ 0,
                                    lag(pop)==0   ~ 1 ,
                                    TRUE ~ (pop - lag(pop))/lag(pop))) 

#traceback
#options(show.error.locations=TRUE)
#path.expand("~")
#traceback()



# rounding percent change
#countvars_age$percent_change <- round(countvars_age$percent_change, digits = 3)
countvars_gender$percent_change <- round(countvars_gender$percent_change, digits = 3)

head(countvars_gender)



#create file with pop totals by geozone and year 
gender_totals <- countvars_gender %>% 
  group_by(geotype,geozone,yr_id) %>% 
  summarise(gendertotal = sum(pop))

#create file that includes proportion change and number change for output- merge in pop totals for proportion calculations
gender <- merge(x = countvars_gender, y = gender_totals, by = c("geotype","geozone","yr_id"), all.x = TRUE)


#calculate proportion of pop for each age and gender group by year
gender$prop <- ifelse(!gender$pop, 0, gender$pop/gender$gendertotal)

head(gender)

#proportion change over increments and address divide by zero.
gender <- gender %>%
  group_by(geozone,geotype,sex) %>% 
  mutate(prop_change = case_when(lag(prop)==0 & (prop==0)  ~ 0,
                                 lag(prop)==0   ~ 1 ,
                                 TRUE ~ (prop - lag(prop))/lag(prop)))


#round
gender$prop_change <- round(gender$prop_change, digits = 3)



#identify fails by EDAM parameters
#two criteria
#ethn <- ethn %>%
# mutate(pass.or.fail = case_when(((ethn_id==1 & abs(change) > 500 & abs(percent_change) > .05)| 
#                                   (ethn_id==2 & abs(change) > 500 & abs(percent_change) > .05)|
#                                  (ethn_id==3 & abs(change) > 50 & abs(percent_change) > .05)|
#                                 (ethn_id==4 & abs(change) > 250 & abs(percent_change) > .05)|
#                                (ethn_id==5 & abs(change) > 100 & abs(percent_change) > .05)) ~ "fail",
#                          TRUE ~ "pass"))

#Single test criteria
#5% 

gender <- gender %>%
  mutate(pass.or.fail = case_when(((sex=='M' & abs(percent_change) > .05)| 
                                   (sex=='F' & abs(percent_change) > .05)) ~ "fail",
                                  TRUE ~ "pass"))



gender$geozone_and_sector <-paste(gender$geozone,'_',gender$sex)



#categorizing fails

df_fail <- unique(subset(gender,pass.or.fail=="fail")$geozone_and_sector)
df_check <- unique(subset(gender,pass.or.fail=="check")$geozone)
gender <- gender %>% 
  mutate(sort_order = case_when(geozone_and_sector %in% df_fail  ~ 1,
                                geozone %in% df_check ~ 2,
                                TRUE ~ 3))
gender<- gender[order(gender$geotype,gender$sex,gender$yr_id),]
gender$sort_order <- NULL
gender$geozone_and_sector <- NULL

gender$datasource_id<- datasource_id_current

gender <- gender %>% rename('datasource id'= datasource_id,#'geo id'=geo_id,
                      'increment'= yr_id,'change' = change,
                      #'percent change' = percent_change,
                      'pass/fail' = pass.or.fail)



# get fails 

get_fails <- function(df) {
  df1 <- df %>% select("datasource id","geotype","geozone","increment",
                       "sex","pass/fail")
  df2 <- spread(df1,increment,'pass/fail')
  df3 <-df2 %>% filter_all(any_vars(. %in% c('fail')))
  drops <- c("2010","2011","2012","2013","2014","2015","2016","2017","2018", "2019")
  df4 <- df3[ , !(names(df3) %in% drops)]
  return(df4) 
}  

gender_failed <- get_fails(gender)
gender_failed$gender <- 'fail'
allvars <- gender_failed

gender_region <- subset(gender,geotype=='region')

region1 <- gender_region %>% select("datasource id","geotype","geozone","increment","sex",
                                 "pop")
region2 <- spread(region1,increment,'pop')
region2['geo id'] <- NULL
region2['geotype'] <- NULL

region2['2019minus2010'] <- region2['2019'] - region2['2010']


#region3 <- region2 %>% adorn_totals("row")

wide_DF <- allvars[ , c("datasource id","geotype","geozone", "sex", "gender")] %>%  spread(sex, gender)

# include all the ethnicity categories whether they pass or fail
all_gender_cats <- unique(gender$sex)
Missing <- setdiff(all_gender_cats, names(wide_DF))
wide_DF[Missing] <- 'pass'

head(wide_DF, 24)

#add id for shading
ids <- rep(1:2, times=nrow(wide_DF)/2)
if (length(ids) < nrow(wide_DF)) {ids<-c(ids,1)}
wide_DF$id <- ids
wide_DF[is.na(wide_DF)] <- 'pass'

#sort summary data by geotype
wide_DF <- wide_DF %>% arrange(desc(geotype))

#identifies excel column id for shading will be in
letters[which( colnames(wide_DF)=="id" )]

#delete geo id column
#ethn['geo id'] <- NULL

#create new df with columns in order for output
gender2 <- gender %>% select("datasource id","geotype","geozone","increment","sex","gendertotal","pop","change","percent_change","prop","prop_change","pass/fail")

add_id_for_excel_formatting_gender <- function(df) {
  t <- df %>% group_by(geozone,gender_group) %>% tally()
  if (nrow(subset(t,n!=10))!=0) {
    print("ERROR: expecting 10 years per geography")
    print(subset(t,n!=10)) } 
  
  ids <- rep(1:2, times=nrow(t)/2, each=10)
  if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
  df$id <- ids
  return(df)
}

#function to subset files by geotype
subset_by_geotype_gender <- function(df,the_geotype) {
  df1 <- subset(df,geotype %in% the_geotype)
  df2 <- add_id_for_excel_formatting_gender(df1)
  df2 <- df2 %>% rename(!!the_geotype[1] := geozone)
  #df %>% rename(!!variable := name_of_col_from_df)
  # df2$geotype <- NULL
  return(df2)
}


#Subsetting gender2 for zip, cpa and jur

gender_cpa<- subset(gender2, geotype== 'cpa')
gender_jur<- subset(gender2, geotype== 'jurisdiction')
gender_zip <- subset(gender2, geotype== 'zip')
#age_region<- subset(age2, geotype== 'region')

gender_jur <- gender_jur %>% rename('Total Population in Jurisdiction'= gendertotal)
gender_jur <- gender_jur %>% rename('Population by gender'= pop)
gender_jur <- gender_jur %>% rename('Change in Population by gender'= change)
gender_jur <- gender_jur %>% rename('Percent Change in Population by gender'= percent_change)
gender_jur <- gender_jur %>% rename('Population by gender as a Share of Total Population in Jurisdiction'= prop)
gender_jur <- gender_jur %>% rename('Change in gender Share'= prop_change)

gender_cpa <- gender_cpa %>% rename('Total Population in CPA'= gendertotal)
gender_cpa <- gender_cpa %>% rename('Population by gender'= pop)
gender_cpa <- gender_cpa %>% rename('Change in Population by gender'= change)
gender_cpa <- gender_cpa %>% rename('Percent Change in Population by gender'= percent_change)
gender_cpa <- gender_cpa %>% rename('Population by gender as a Share of Total Population in CPA'= prop)
gender_cpa <- gender_cpa %>% rename('Change in gender Share'= prop_change)

gender_zip <- gender_zip %>% rename('Total Population in Region'= gendertotal)
gender_zip <- gender_zip %>% rename('Population by gender'= pop)
gender_zip <- gender_zip %>% rename('Change in Population by gender'= change)
gender_zip <- gender_zip %>% rename('Percent Change in Population by gender'= percent_change)
gender_zip <- gender_zip %>% rename('Population by gender as a Share of Total Population in Region'= prop)
gender_zip <- gender_zip %>% rename('Change in gender Share'= prop_change)

# add comments to sheets with cutoff
# create dictionary hash of comments

acceptance_criteria <- hash()
acceptance_criteria['M'] <- "> 5%"
acceptance_criteria['F'] <- "> 5%"



# sector_names <- merge(x=allvars,y=employment_name, by = 'income_group_id')
full_names <- unique(allvars$gender_group)
colnames(gender_jur)
#age_jur['ethn_id'] <-NULL
gender_jur['geotype'] <-NULL
gender_jur_sector_share <- gender_jur
gender_jur['Population by gender as a Share of Total Population in Jurisdiction'] <- NULL
gender_jur['Change in gender Share'] <- NULL

gender_cpa['geotype'] <-NULL
gender_cpa_sector_share <- gender_cpa
gender_cpa['Population by gender as a Share of Total Population in Jurisdiction'] <- NULL
gender_cpa['Change in Gender Share'] <- NULL

gender_zip['geotype'] <-NULL
gender_zip_sector_share <- gender_zip
gender_zip['Population by gender as a Share of Total Population in Jurisdiction'] <- NULL
gender_zip['Change in gender Share'] <- NULL


########################################################### 
# create excel workbook


wb = createWorkbook()

#add summary worksheet
summary = addWorksheet(wb, "Summary of Findings", tabColour = "red")

writeData(wb, summary, x = "Cities & CPAs that QC failed based on the following criteria:", 
          startCol = 1, startRow = 1)
writeData(wb, summary, x = "Notes: For the purpose of these QA checks, percent change is shown as 100% where population increases from 0 to >0 from one increment to the next.", 
          startCol = 1, startRow = 2)
writeData(wb, summary, x = "          Percent change is shown as 0% where population is zero for both increments. Test criteria are listed on this worksheet below table of results.", 
          startCol = 1, startRow = 3)


headerStyleforsummary <- createStyle(fontSize = 12 ,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1), cols = 1, gridExpand = TRUE)

sn <- colnames(wide_DF)[-(15)] # all but the last column (id)
sectors <- sn[-(1:3)] # from column 4 to the end
ini_cols <- colnames(wide_DF)[1:3]
id_col <- colnames(wide_DF)[15]
#wide_DF <- wide_DF[,(c(ini_cols,income_categories$name,id_col))]


writeData(wb,summary,wide_DF,startCol = 1, startRow = 4)

# add summary table of cutoffs
writeData(wb, summary, x = "Variable", startCol = 1, startRow = nrow(wide_DF)+6)
writeData(wb, summary, x = "Test Criteria", startCol = 2, startRow = nrow(wide_DF)+6)
headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(wide_DF)+6, cols = 1:2, gridExpand = TRUE,stack = TRUE)

tableStyle1 <- createStyle(fontSize = 10, halign = "center")
tableStyle2 <- createStyle(fontSize = 10, halign = "left")

writeData(wb, summary, x = "population by Gender", startCol = 1, startRow = nrow(wide_DF)+7)

#write ethnic group and test parameters 
writeData(wb, summary, x = "Male", startCol = 1, startRow = nrow(wide_DF)+7)
writeData(wb, summary, x = acceptance_criteria[['M']], startCol = 2, startRow = nrow(wide_DF)+7)

writeData(wb, summary, x = "Female", startCol = 1, startRow = nrow(wide_DF)+8)
writeData(wb, summary, x = acceptance_criteria[['F']], startCol = 2, startRow = nrow(wide_DF)+8)

#writeData(wb, summary, x = "45-64", startCol = 1, startRow = nrow(wide_DF)+9)
#writeData(wb, summary, x = acceptance_criteria[['45-64']], startCol = 2, startRow = nrow(wide_DF)+9)

#writeData(wb, summary, x = "65+", startCol = 1, startRow = nrow(wide_DF)+10)
#writeData(wb, summary, x = acceptance_criteria[['65+']], startCol = 2, startRow = nrow(wide_DF)+10)

#writeData(wb, summary, x = "White", startCol = 1, startRow = nrow(wide_DF)+11)
#writeData(wb, summary, x = acceptance_criteria[['Wh']], startCol = 2, startRow = nrow(wide_DF)+11)

#format the summary table with test parameters 
addStyle(wb, summary, tableStyle1, rows = (nrow(wide_DF)+7):(nrow(wide_DF)+11), cols = 1, gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, tableStyle2, rows = (nrow(wide_DF)+7):(nrow(wide_DF)+11), cols = 2, gridExpand = TRUE,stack = TRUE)


for (index in 1:nrow(wide_DF)) { 
  row = wide_DF[index, ]
  for (sectorname in sectors){
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'cpa')) {
      rnfail = max(which((gender_cpa$geozone ==row$geozone) & (gender_cpa['pass/fail'] =='fail') & 
                           (gender_cpa['sex'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                   x = makeHyperlinkString(sheet = 'GenderbyCPA', row = rnfail, col = 11,text = "fail"))
    }
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'jurisdiction')) {
      rnfail = max(which((gender_jur$geozone ==row$geozone) & (gender_jur['pass/fail'] =='fail') & 
                           (gender_jur['sex'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                   x = makeHyperlinkString(sheet = 'GenderbyJur', row = rnfail, col = 11,text = "fail"))
    }
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'zip')) {
      rnfail = max(which((gender_zip$geozone ==row$geozone) & (gender_zip['pass/fail'] =='fail') & 
                           (gender_zip['sex'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                   x = makeHyperlinkString(sheet = 'GenderbyZIP', row = rnfail, col = 11,text = "fail"))
    }
  }
}


headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(wide_DF)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)
writeData(wb, summary, x = "EDAM review", startCol = (ncol(wide_DF) + 1), startRow = 4)



# read email message from Dave and attach to excel spreadsheet
## Insert email as images
#imgfilepath<- "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\6_Notes\\"
#img1a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 1.png",sep='')
#img2a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 2.png",sep='')
#img3a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 3.png",sep='')
#img4a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 4.png",sep='')

# add sheet with email info
#shtemail = addWorksheet(wb, "Email")

#insertImage(wb, shtemail, img1a, startRow = 3,  startCol = 2, width = 19.74, height = 4.77,units = "in") # divide by 96
#insertImage(wb, shtemail, img2a, startRow = 26,  startCol = 2, width = 19.80, height = 6.93,units = "in")
#insertImage(wb, shtemail, img3a, startRow = 61,  startCol = 2, width = 19.76, height = 7.09,units = "in")
#insertImage(wb, shtemail, img4a, startRow = 98,  startCol = 2, width = 19.71, height = 8.97,units = "in")


########### test plan document ##########################
# add TestPlan as worksheet
#testingplan = addWorksheet(wb, "TestPlan")

# read Test Plan from share drive
#TestPlanDirectory <- "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\2_Testing Plan\\"
#TestPlanFile <- paste(TestPlanDirectory,"Test_Plan_DS31.docx",sep='')
#testplan <- readtext(TestPlanFile)

# generate "dummy" plot with test plan as text box
# a hack to get word document as excel sheet
#png("testplan.png", width=1024, height=768, units="px", res=144)  #output to png device
#p <- ggplot(data = NULL, aes(x = 1:10, y = 1:10)) +
# geom_text(aes(x = 1, y = 20), label = testplan$text) +
#theme_minimal() +
#theme(axis.text = element_blank(),
#     axis.title = element_blank(),
#    panel.grid = element_blank())
#print(p)
#dev.off()  
#insertImage(wb, sheet=testingplan, "testplan.png", width=11.18, height=7.82, units="in")
#insertPlot(wb, sheet=testingplan,xy = c(2, 2), width = 8, height = 8)

### end test plan worksheet
#################################################################################

# add comments to sheets with cutoff
# create dictionary hash of comments
fullname <- hash()


#j <-4 # starting sheet number for data
agejur <- addWorksheet(wb, "GenderbyJur",tabColour="purple")
writeData(wb,agejur, age_jur)

agecpa <- addWorksheet(wb, "GenderbyCPA",tabColour="purple")
writeData(wb, agecpa,age_cpa)

agezip <- addWorksheet(wb, "GenderbyZIP",tabColour="purple")
writeData(wb, agezip,age_zip)

# sector share
agebyjurshare <- addWorksheet(wb, "AgeShareByJur",tabColour="yellow")
writeData(wb,agebyjurshare,age_jur_sector_share)

agebycpashare <- addWorksheet(wb, "AgeShareByCpa",tabColour="yellow")
writeData(wb, agebycpashare,age_cpa_sector_share)

agebyzipshare <- addWorksheet(wb, "AgeShareByZIP",tabColour="yellow")
writeData(wb, agebyzipshare,age_zip_sector_share)

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
rangeRowscpa = 2:(nrow(age_cpa)+1)
rangeRowsjur = 2:(nrow(age_jur)+1)
rangeRowszip = 2:(nrow(age_zip)+1)
rangeCols = 1:10
pct = createStyle(numFmt="0%") # percent 
aligncenter = createStyle(halign = "center")

# skip first 3 sheets
# note: sheet 1:summary, sheet 2:email, sheet 3:test plan
#for (curr_sheet in names(wb)[-1:-3]) {
for (curr_sheet in names(wb)[2:4]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowszip,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet,style = insideBorders,rows = 1, cols= rangeCols, gridExpand= TRUE, stack= TRUE) 
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(10), rows=1:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18), widths = c(16,30,15,38,16,18,18,18,22,20,25,20,20,20,20,20,6,25))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(age_zip)+1), rule="$J1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(age_zip)+1), rule="$J1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(age_zip)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(age_zip)+1), type="contains", rule="check", style = checkStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}

rangeCols = 1:11
for (curr_sheet in names(wb)[5:7]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowszip,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(12), rows=1:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(age_zip)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18), widths = c(16,30,15,38,16,18,18,18,22,20,25,20,20,20,20,20,6,25))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(age_zip)+1), rule="$L1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(age_zip)+1), rule="$L1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(age_zip)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(age_zip)+1), type="contains", rule="check", style = checkStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}


# format for summary sheet
idcolumn <- letters[which( colnames(wide_DF)=="id" )]
iddarkgrey <- paste("$",idcolumn,"1")
idlightgrey <- paste("$",idcolumn,"2")

conditionalFormatting(wb, summary, cols=c(1:(ncol(wide_DF)-1)), rows=1:(nrow(wide_DF)+4), rule="$J1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=c(1:(ncol(wide_DF)-1)), rows =1:(nrow(wide_DF)+4), rule="$J1==2", style = lightgreyStyle)

addStyle(wb = wb,summary,style = insideBorders,rows = 4:(nrow(wide_DF)+3),cols = c(1:(ncol(wide_DF)-1),ncol(wide_DF)+1),gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, headerStyle, rows = 4, cols = c(1:(ncol(wide_DF)-1),ncol(wide_DF)+1), gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, style=invisibleStyle, cols=c(ncol(wide_DF)), rows=4:(nrow(wide_DF)+4), gridExpand=TRUE,stack = TRUE)
#conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=3:(nrow(wide_DF)+3), rule="$J1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=4:(nrow(wide_DF)+4), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=4:(nrow(wide_DF)+4), type="contains", rule="check", style = checkStyle)
setColWidths(wb, summary, cols = c(1,2,3,4,5,6,7,8,9,10,11), widths = c(16,22,15,30,22,22,22,22,22,2,40))

addStyle(wb, summary, style=aligncenter,cols=c(1:9), rows=4:(nrow(wide_DF)+4), gridExpand=TRUE,stack = TRUE)

#remove worksheet with email-not necessary after all
#removeWorksheet(wb, "Email")

# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

getwd()
saveWorkbook(wb, outfile,overwrite=TRUE)









