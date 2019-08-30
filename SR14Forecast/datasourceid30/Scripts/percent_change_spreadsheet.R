
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash")
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

countvars <- subset(countvars, yr_id==2012 | yr_id==2016 | yr_id==2018 | yr_id==2020 | yr_id==2025 | yr_id==2030 | yr_id==2035 | yr_id==2040 | yr_id==2045 | yr_id==2050)

countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'


rm(merge1,hhvars,jobs,gq)


subset(countvars,geozone=='San Diego Region')

countvars <- merge(x = countvars, y =geo_id,by = "geozone", all.x = TRUE)
# clean up cpa names removing asterick and dashes etc.
countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% rename('geo_id'= id)


# clean up cpa names removing asterick and dashes etc.
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')
#head(countvars)

# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$datasource_id,countvars$geotype,countvars$geozone,countvars$yr_id),]

jobs <- calculate_pct_chg(countvars, jobs)
jobs <- calculate_pass_fail(jobs,5000,.20)
jobs <- sort_dataframe(jobs)
jobs <- rename_dataframe(jobs)
jobs_cpa <- subset_by_geotype(jobs,c('cpa'))
jobs_jur <- subset_by_geotype(jobs,c('jurisdiction'))
jobs_region <- subset_by_geotype(jobs,c('region'))

households <- calculate_pct_chg(countvars, households)
households <- calculate_pass_fail(households,2500,.20)
households <- sort_dataframe(households)
households <- rename_dataframe(households)
households_cpa <- subset_by_geotype(households,c('cpa'))
households_jur <- subset_by_geotype(households,c('jurisdiction'))
households_region <- subset_by_geotype(households,c('region'))

hhp <- calculate_pct_chg(countvars, hhp)
hhp <- calculate_pass_fail(hhp,7500,.20)
hhp <- sort_dataframe(hhp)
hhp <- rename_dataframe(hhp)
hhp <- hhp %>% rename('hhpop'= hhp)
hhp_cpa <- subset_by_geotype(hhp,c('cpa'))
hhp_jur <- subset_by_geotype(hhp,c('jurisdiction'))
hhp_region <- subset_by_geotype(hhp,c('region'))

units <- calculate_pct_chg(countvars, units)
units <- calculate_pass_fail(units,2500,.20)
units <- sort_dataframe(units)
units <- rename_dataframe(units)
units_cpa <- subset_by_geotype(units,c('cpa'))
units_jur <- subset_by_geotype(units,c('jurisdiction'))
units_region <- subset_by_geotype(units,c('region'))


gqpop <- calculate_pct_chg(countvars, gqpop)
gqpop <- calculate_pass_fail(gqpop,500,.20)
gqpop <- sort_dataframe(gqpop)
gqpop <- rename_dataframe(gqpop)
gqpop_cpa <- subset_by_geotype(gqpop,c('cpa'))
gqpop_jur <- subset_by_geotype(gqpop,c('jurisdiction'))
gqpop_region <- subset_by_geotype(gqpop,c('region'))


########################################################### 
# create excel workbook

wb = createWorkbook()

tableofcontents = addWorksheet(wb, "TableofContents")

writeData(wb, tableofcontents, x = "Worksheet Name", startCol = 1, startRow = 1)
writeData(wb, tableofcontents, x = "Worksheet Description", startCol = 2, startRow = 1)
writeData(wb, tableofcontents, x = "Test Criteria", startCol = 3, startRow = 1)
setColWidths(wb, tableofcontents, cols = c(1,2), widths = c(45,45))


writeFormula(wb, tableofcontents, startRow = 3, 
             x = makeHyperlinkString(sheet = "Emails", row = 1, col = 1,text = "Emails"))
writeData(wb, tableofcontents,x = "QA Emails with EDAM", startRow = 3, startCol = 2)

# read email message from Dave and attach to excel spreadsheet
## Insert email as images
imgfilepath<- "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\6_Notes\\"
img1a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 1.png",sep='')
img2a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 2.png",sep='')
img3a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 3.png",sep='')
img4a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 4.png",sep='')

# add sheet with email info
shtemail = addWorksheet(wb, "Emails")




insertImage(wb, shtemail, img1a, startRow = 3,  startCol = 2, width = 19.74, height = 4.77,units = "in") # divide by 96
insertImage(wb, shtemail, img2a, startRow = 26,  startCol = 2, width = 19.80, height = 6.93,units = "in")
insertImage(wb, shtemail, img3a, startRow = 61,  startCol = 2, width = 19.76, height = 7.09,units = "in")
insertImage(wb, shtemail, img4a, startRow = 98,  startCol = 2, width = 19.71, height = 8.97,units = "in")


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


# specify sheetname and tab colors
add_worksheets_to_excel(wb,"Units","red",5,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"HH","green",9,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"HHPop","blue",13,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"GQPop","yellow",17,fullname,acceptance_criteria)
add_worksheets_to_excel(wb,"Jobs","purple",21,fullname,acceptance_criteria)



# add comments to sheets with cutoff
# create dictionary hash of comments
comments_to_add <- hash()
comments_to_add['units'] <- "> 2,500 and > 20%"
comments_to_add['households'] <- "> 2,500 and > 20%"
comments_to_add['hhp'] <- "> 7,500 and > 20%"
comments_to_add['gqpop'] <- "> 500 and > 20%"
comments_to_add['jobs'] <- "> 5,000 and > 20%"


i <-3 # starting sheet number (sheet 1 is email message, sheet 2 is table of contents)
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
  borderStyle = "dashed",borderColour="white"
)
rangeRows = 1:(nrow(jobs_cpa)+1)
rangeRowscpa = 2:(nrow(jobs_cpa)+1)
rangeRowsjur = 2:(nrow(jobs_jur)+1)
rangeCols = 1:(ncol(jobs_jur)-1)
pct = createStyle(numFmt="0%") # percent 
aligncenter = createStyle(halign = "center")

for (curr_sheet in names(wb)[3:length(names(wb))]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowscpa,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
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
}

# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

saveWorkbook(wb, "units_hh_hhpop_gqpop_jobs.xlsx",overwrite=TRUE)

