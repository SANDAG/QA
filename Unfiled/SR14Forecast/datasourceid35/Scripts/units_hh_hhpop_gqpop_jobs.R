
datasource_id_current <- 35


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)


# excel workbook output file name and folder with timestamp
now <- Sys.time()
outputfile <- paste("units_hh_hhpop_gqpop","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile2 <- paste("Units_HH_Pop_Jobs_Forecast","_ds",datasource_id_current,"_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))

outfolder<-paste("../Output/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- paste(maindir,"/",outfolder,outputfile,sep='')
outfile2 <- paste(maindir,"/",outfolder,outputfile2,sep='')
print(paste("output filepath: ",outfile))


source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')


# get hhpop data
hhvars <- readDB("../Queries/hh_hhp_hhs_ds_id.sql",datasource_id_current)
jobs <- readDB("../Queries/jobs.sql",datasource_id_current)
gq <- readDB("../Queries/group_quarter_w_description.sql",datasource_id_current)
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)
odbcClose(channel)

merge1 <- merge(x = hhvars, y = jobs,by = c("datasource_id","yr_id","geotype","geozone"), all = TRUE)
countvars <- merge(x = merge1, y = gq,by = c("datasource_id","yr_id","geotype","geozone"), all = TRUE)

##commenting out the code below as it is not needed for this source id
##countvars <- subset(countvars, yr_id==2012 | yr_id==2016 | yr_id==2018 | yr_id==2020 | yr_id==2025 | yr_id==2030 | yr_id==2035 | yr_id==2040 | yr_id==2045 | yr_id==2050)


# subset(countvars,geozone=='San Diego Region')
countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'

#merging countvars with geo_id on geozone
countvars <- merge(x = countvars, y =geo_id,by = "geozone", all.x = TRUE)

rm(merge1,hhvars,jobs,gq)


# clean up cpa names removing asterick and dashes etc.
countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% dplyr::rename('geo_id'= id)
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')

head(countvars)

# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$datasource_id,countvars$geotype,countvars$geozone,countvars$yr_id),]

# check number of rows of data
data_rows = nrow(countvars)
geo_id1 <- subset(geo_id,geozone != '*Not in a CPA*')
#write.csv(geo_id1,paste(maindir,"/",outfolder,"geo_id.csv",sep=''))
expected_rows = (nrow(geo_id1) + 1) * 9 # 9 increments and plus 1 for region

data_rows== expected_rows

## fixing geographies with less than 9 observations

## not needed for ds_id 34
geozone_to_fix = ''
if (data_rows != expected_rows) {
  print("ERROR: data rows not equal to expected rows")
  print(paste("data rows = ",data_rows))
  print(paste("expected rows = ",expected_rows))
  print(paste("data geographies = ",length(unique(countvars$geozone))))
  print(paste("expected geographies = ",((nrow(geo_id1) + 1))))
  t <- countvars %>% group_by(geozone) %>% tally()
  if (nrow(subset(t,n!=9))!=0) {       ## t is the n we are defining in the function which every geography should have
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) 
    geozone_to_fix = subset(t,n!=9)$geozone} }


## not needed for ds_id 34 
# add 'Marine Corps Recruit Depot' for yr 2016 if missing
if (geozone_to_fix == "Marine Corps Recruit Depot") {
  # add 'Marine Corps Recruit Depot' for yr 2016
  print("fixing ERROR")
  print("add Marine Corps Recruit Depot for yr 2016 since missing in datasource id 17")
  temp1<- subset(countvars,geozone == 'Marine Corps Recruit Depot' & yr_id ==2018)
  temp1['yr_id'] = 2016
  temp1[,5:11] = 0
  temp1$geo_id = 1492
  countvars = rbind(countvars,temp1)
}

# check number of rows of data
data_rows = nrow(countvars)
expected_rows = (nrow(geo_id1) + 1) * 9 # 9 increments and plus 1 for region
print(paste("data rows = ",data_rows))
print(paste("expected rows = ",expected_rows))

# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$datasource_id,countvars$geotype,countvars$geozone,countvars$yr_id),]




# calculate pass/fail
jobs <- calculate_pct_chg(countvars, jobs)
jobs <- calculate_pass_fail(jobs,5000,.20)
households <- calculate_pct_chg(countvars, households)
households <- calculate_pass_fail(households,2500,.20)
hhp <- calculate_pct_chg(countvars, hhp)
hhp <- calculate_pass_fail(hhp,7500,.20)
units <- calculate_pct_chg(countvars, units)
units <- calculate_pass_fail(units,2500,.20)
gqpop <- calculate_pct_chg(countvars, gqpop)
gqpop <- calculate_pass_fail(gqpop,500,.20)

# create dataframe of failed geos for summary tab
units_failed <- get_fails(units)
units_failed$units <- 'fail'
households_failed <- get_fails(households)
households_failed$hh <- 'fail'
hhp_failed <- get_fails(hhp)
hhp_failed$hhp <- 'fail'
gqpop_failed <- get_fails(gqpop)
gqpop_failed$gqpop <- 'fail' 
jobs_failed <- get_fails(jobs)
jobs_failed$jobs <- 'fail' 

# summary dataframe - merge all variables
allvars <- Reduce(function(x, y) merge(x, y, all=TRUE), 
                  list(units_failed,households_failed,hhp_failed,gqpop_failed,jobs_failed))
allvars <- allvars[order(allvars['units'],allvars['hhp'],allvars['geotype'],allvars['geozone']),]
ids <- rep(1:2, times=nrow(allvars)/2)    ##1:2 represents shade coding for excel, used later
if (length(ids) < nrow(allvars)) {ids<-c(ids,1)}
allvars$id <- ids
allvars[is.na(allvars)] <- 'pass'

# list of failed geographies for sorting dataframe by failures
failedgeosunitshhhhp <- subset(allvars,hhp=='fail')$geozone
failedgeosgqpop <- subset(allvars,gqpop=='fail')$geozone
failedgeosjobs <- subset(allvars,jobs=='fail')$geozone

# sort and rename dataframes
jobs <- sort_dataframe_geos(jobs,failedgeosjobs)
jobs <- rename_dataframe(jobs)
households <- sort_dataframe_geos(households,failedgeosunitshhhhp)
households <- rename_dataframe(households)
hhp <- sort_dataframe_geos(hhp,failedgeosunitshhhhp)
hhp <- rename_dataframe(hhp)
hhp <- hhp %>% dplyr::rename('hhp'= hhp)
units <- sort_dataframe_geos(units,failedgeosunitshhhhp)
units <- rename_dataframe(units)
gqpop <- sort_dataframe_geos(gqpop,failedgeosgqpop)
gqpop <- rename_dataframe(gqpop)

# create dataframe for cpa, jur, and region
jobs_cpa <- subset_by_geotype(jobs,c('cpa'))
jobs_jur <- subset_by_geotype(jobs,c('jurisdiction'))
jobs_region <- subset_by_geotype(jobs,c('region'))

households_cpa <- subset_by_geotype(households,c('cpa'))
households_jur <- subset_by_geotype(households,c('jurisdiction'))
households_region <- subset_by_geotype(households,c('region'))

hhp_cpa <- subset_by_geotype(hhp,c('cpa'))
hhp_jur <- subset_by_geotype(hhp,c('jurisdiction'))
hhp_region <- subset_by_geotype(hhp,c('region'))

units_cpa <- subset_by_geotype(units,c('cpa'))
units_jur <- subset_by_geotype(units,c('jurisdiction'))
units_region <- subset_by_geotype(units,c('region'))

gqpop_cpa <- subset_by_geotype(gqpop,c('cpa'))
gqpop_jur <- subset_by_geotype(gqpop,c('jurisdiction'))
gqpop_region <- subset_by_geotype(gqpop,c('region'))


########################################################### 
# create excel workbook

wb = createWorkbook()


#add summary worksheet
summary = addWorksheet(wb, "Summary of Findings", tabColour = "red")
# add table of contents
tableofcontents = addWorksheet(wb, "TableofContents")

headerStylecontents <- createStyle(fontSize = 14,textDecoration = "bold")
writeData(wb, tableofcontents, x = "Worksheet Name", startCol = 1, startRow = 1)
writeData(wb, tableofcontents, x = "Worksheet Description", startCol = 2, startRow = 1)
writeData(wb, tableofcontents, x = "Test Criteria", startCol = 3, startRow = 1)
setColWidths(wb, tableofcontents, cols = c(1,2), widths = c(45,45))
addStyle(wb, tableofcontents, style = headerStylecontents, rows = 1, cols = 1:3, gridExpand = TRUE)


writeFormula(wb, tableofcontents, startRow = 3, 
             x = makeHyperlinkString(sheet = "Emails", row = 1, col = 1,text = "Emails"))
writeData(wb, tableofcontents,x = "QA Emails with EDAM", startRow = 3, startCol = 2)

writeFormula(wb, tableofcontents, startRow = 5, 
             x = makeHyperlinkString(sheet = "Summary of Findings", row = 1, col = 1,text = "Summary of Findings"))
writeFormula(wb, tableofcontents, startRow = 6, 
             x = makeHyperlinkString(sheet = "TestPlan", row = 1, col = 1,text = "Test Plan"))
writeData(wb, tableofcontents,x = "Geographies that failed for any variable:units,households,household pop,group quarter pop,jobs", startRow = 5, startCol = 2)

## Insert email as images
imgfilepath<- "C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\supporting_documents\\dsid35_Email\\"
img1a <- paste(imgfilepath,"DTedrowEmail1_dsid35.png",sep='')
img2a <- paste(imgfilepath,"NOzanichEmail_dsid35.png",sep='')
##img3a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 3.png",sep='')
##img4a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 4.png",sep='')

# add sheet with email info
shtemail = addWorksheet(wb, "Emails")

insertImage(wb, shtemail, img1a, startRow = 3,  startCol = 2, width = 19.74, height = 4.77,units = "in") # divide by 96
insertImage(wb, shtemail, img2a, startRow = 26,  startCol = 2, width = 19.80, height = 6.93,units = "in")
#insertImage(wb, shtemail, img3a, startRow = 61,  startCol = 2, width = 19.76, height = 7.09,units = "in")
#insertImage(wb, shtemail, img4a, startRow = 98,  startCol = 2, width = 19.71, height = 8.97,units = "in")


########### test plan document ##########################
# add TestPlan as worksheet
#testingplan = addWorksheet(wb, "TestPlan")

# read Test Plan from share drive
#TestPlanDirectory <- "C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Forecast\\Test Plan\\"
#TestPlanFile <- paste(TestPlanDirectory,"Test_Plan_DS35.docx",sep='')
#testplan <- readtext(TestPlanFile)

# generate "dummy" plot with test plan as text box
# a hack to get word document as excel sheet
#png("testplan.png", width=1156, height=900, units="px", res=144)  #output to png device
#p <- ggplot(data = NULL, aes(x = 1:10, y = 1:10)) +
 # geom_text(aes(x = 1, y = 20), label = testplan$text) +
  #theme_minimal() +
  #theme(axis.text = element_blank(),
        #axis.title = element_blank(),
        #panel.grid = element_blank())
#print(p)
#dev.off()
#insertImage(wb, sheet=testingplan, "testplan.png")
#insertImage(wb, sheet=testingplan, "testplan.png", width=12.5, height=9.2, units="in")


### end test plan worksheet
#################################################################################



# add comments to sheets with cutoff
# create dictionary hash of comments
fullname <- hash()
fullname['Units'] <- "Housing units"
fullname['HH'] <- "Households"
fullname['HHPop'] <- "Household Population"
fullname['GQPop'] <- "Group Quarter Population"
fullname['Jobs'] <- "Jobs"

# add comments to sheets with cutoff
# create dictionary hash of comments
acceptance_criteria <- hash()
acceptance_criteria['Units'] <- "> 2,500 and > 20%"
acceptance_criteria['HH'] <- "> 2,500 and > 20%"
acceptance_criteria['HHPop'] <- "> 7,500 and > 20%"
acceptance_criteria['GQPop'] <- "> 500 and > 20%"
acceptance_criteria['Jobs'] <- "> 5,000 and > 20%"



writeData(wb, summary, x = "List of geographies that failed for any of the following variables: units, households, household pop, group quarter pop, jobs", 
          startCol = 1, startRow = 1)
headerStyleforsummary <- createStyle(fontSize = 14 ,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)

# add summary table of cutoffs
writeData(wb, summary, x = "Variable", startCol = 1, startRow = nrow(allvars)+6)
writeData(wb, summary, x = "Description", startCol = 2, startRow = nrow(allvars)+6)
writeData(wb, summary, x = "Test Criteria", startCol = 3, startRow = nrow(allvars)+6)
headerStyle1 <- createStyle(fontSize = 12, halign = "center" ,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(allvars)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)


tableStyle1 <- createStyle(fontSize = 10, halign = "center")
tableStyle2 <- createStyle(fontSize = 10, halign = "left")

writeData(wb, summary, x = "units", startCol = 1, startRow = nrow(allvars)+7)
writeData(wb, summary, x = "Number of housing units", startCol = 2, startRow = nrow(allvars)+7)
writeData(wb, summary, x = acceptance_criteria[['Units']], startCol = 3, startRow = nrow(allvars)+7)

writeData(wb, summary, x = "hh", startCol = 1, startRow = nrow(allvars)+8)
writeData(wb, summary, x = "Number of households", startCol = 2, startRow = nrow(allvars)+8)
writeData(wb, summary, x = acceptance_criteria[['HH']], startCol = 3, startRow = nrow(allvars)+8)

writeData(wb, summary, x = "hhp", startCol = 1, startRow = nrow(allvars)+9)
writeData(wb, summary, x = "Household Population", startCol = 2, startRow = nrow(allvars)+9)
writeData(wb, summary, x = acceptance_criteria[['HHPop']], startCol = 3, startRow = nrow(allvars)+9)

writeData(wb, summary, x = "gqpop", startCol = 1, startRow = nrow(allvars)+10)
writeData(wb, summary, x = "Group Quarter Population", startCol = 2, startRow = nrow(allvars)+10)
writeData(wb, summary, x = acceptance_criteria[['GQPop']], startCol = 3, startRow = nrow(allvars)+10)

writeData(wb, summary, x = "jobs", startCol = 1, startRow = nrow(allvars)+11)
writeData(wb, summary, x = "Number of Jobs", startCol = 2, startRow = nrow(allvars)+11)
writeData(wb, summary, x = acceptance_criteria[['Jobs']], startCol = 3, startRow = nrow(allvars)+11)

addStyle(wb, summary, tableStyle1, rows = (nrow(allvars)+7):(nrow(allvars)+11), cols = 1, gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, tableStyle2, rows = (nrow(allvars)+7):(nrow(allvars)+11), cols = 2:3, gridExpand = TRUE,stack = TRUE)



writeData(wb,summary,allvars,startCol = 1, startRow = 4)



for (index in 1:nrow(allvars)) { 
  row = allvars[index, ]
  if ((row$units == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((units_cpa$cpa ==row$geozone) & (units_cpa['pass/fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 5, 
                 x = makeHyperlinkString(sheet = 'UnitsByCpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hh == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((households_cpa$cpa ==row$geozone) & (households_cpa['pass/fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 6, 
                 x = makeHyperlinkString(sheet = 'HHByCpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$hhp == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((hhp_cpa$cpa ==row$geozone) & (hhp_cpa['pass/fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 7, 
                 x = makeHyperlinkString(sheet = 'HHPopByCpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$gqpop == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((gqpop_cpa$cpa ==row$geozone) & (gqpop_cpa['pass/fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 8, 
                 x = makeHyperlinkString(sheet = 'GQPopByCpa', row = rnfail, col = 3,text = "fail"))
  }
  if ((row$gqpop == 'fail') & (row$geotype == 'jurisdiction')) {
    rnfail = max(which((gqpop_jur$jurisdiction ==row$geozone) & (gqpop_jur['pass/fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 8, 
                 x = makeHyperlinkString(sheet = 'GQPopByJur', row = rnfail, col = 3,text = "fail"))
  }
  
  if ((row$jobs == 'fail') & (row$geotype == 'cpa')) {
    rnfail = max(which((jobs_cpa$cpa ==row$geozone) & (jobs_cpa['pass/fail'] =='fail'))) + 1
    writeFormula(wb, summary, startRow = index + 4,startCol = 9, 
                 x = makeHyperlinkString(sheet = 'JobsByCpa', row = rnfail, col = 3,text = "fail"))
  }
}




writeData(wb, summary, x = "EDAM review", startCol = (ncol(allvars) + 1), startRow = 4)
# specify sheetname and tab colors
add_worksheets_to_excel(wb,"Units","blue",8,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"HH","green",12,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"HHPop","orange",16,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"GQPop","yellow",20,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"Jobs","purple",24,fullname,acceptance_criteria)

# add comments to sheets with cutoff
# create dictionary hash of comments
comments_to_add <- hash()
comments_to_add['units'] <- "> 2,500 and > 20%"
comments_to_add['households'] <- "> 2,500 and > 20%"
comments_to_add['hhp'] <- "> 7,500 and > 20%"
comments_to_add['gqpop'] <- "> 500 and > 20%"
comments_to_add['jobs'] <- "> 5,000 and > 20%"


i <-4 # starting sheet number (sheet 1 is email message, sheet 2 is table of contents, sheet 3 is summary4 is test plan)
for (demographic_var in c('units','households','hhp','gqpop','jobs')) {
  add_data_to_excel(wb,demographic_var,i)
  i <- i + 3 # 3 sheets for each variable: jur,cpa,region
}


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

rangeRows = 1:(nrow(jobs_cpa)+1)
rangeRowscpa = 2:(nrow(jobs_cpa)+1)
rangeRowsjur = 2:(nrow(jobs_jur)+1)
rangeCols = 1:(ncol(jobs_jur)-1)
pct = createStyle(numFmt="0%") # percent 
aligncenter = createStyle(halign = "center")


for (curr_sheet in names(wb)[4:length(names(wb))]) {
  addStyle(wb = wb,sheet = curr_sheet,style = insideBorders,rows = rangeRowscpa,cols = rangeCols,gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(7), rows=rangeRowscpa, gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=c(1:4,8), rows=rangeRows, gridExpand=TRUE,stack = TRUE)
  #addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(hhp_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(ncol(jobs_jur)), rows=1:(nrow(hhp_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8), widths = c(16,12,33,12,15,16,18,18))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$I1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$I1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="check", style = checkStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}

# format for summary sheet
conditionalFormatting(wb, summary, cols=c(1:(ncol(allvars)-1)), rows =1:(nrow(allvars)+4), rule="$J1==2", style = lightgreyStyle)
conditionalFormatting(wb, summary, cols=c(1:(ncol(allvars)-1)), rows=1:(nrow(allvars)+4), rule="$J1==1", style = darkgreyStyle)

addStyle(wb = wb,summary,style = insideBorders,rows = 4:(nrow(allvars)+3),cols = c(1:(ncol(allvars)-1),ncol(allvars)+1),gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, headerStyle, rows = 4, cols = c(1:(ncol(allvars)-1),ncol(allvars)+1), gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, style=invisibleStyle, cols=c(ncol(allvars)), rows=4:(nrow(allvars)+4), gridExpand=TRUE,stack = TRUE)
#conditionalFormatting(wb, summary, cols=1:(ncol(allvars)-1), rows=3:(nrow(allvars)+3), rule="$J1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(allvars)-1), rows=4:(nrow(allvars)+4), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(allvars)-1), rows=4:(nrow(allvars)+4), type="contains", rule="check", style = checkStyle)
setColWidths(wb, summary, cols = c(1,2,3,4,5,6,7,8,9,10,11), widths = c(16,22,15,30,18,18,18,18,18,2,40))
addStyle(wb, summary, style=aligncenter,cols=c(1:11), rows=4:(nrow(allvars)+4), gridExpand=TRUE,stack = TRUE)

# out folder for excel

setwd(file.path(maindir,outfolder))

#commenting out the oufile which is duplicate of outfile2 with _QA nomenclature
#saveWorkbook(wb, outfile,overwrite=TRUE)
saveWorkbook(wb, outfile2,overwrite=TRUE)
