
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx")
pkgTest(packages)




# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get hhpop data
hhvars <- readDB("../Queries/hh_hhp_hhs_ds_id.sql",datasource_id_current)
jobs <- readDB("../Queries/jobs.sql",datasource_id_current)
gq <- readDB("../Queries/group_quarter_w_description.sql",datasource_id_current)

odbcClose(channel)

merge1 <- merge(x = hhvars, y = jobs,by = c("datasource_id","yr_id","geotype","geozone"), all = TRUE)
countvars <- merge(x = merge1, y = gq,by = c("datasource_id","yr_id","geotype","geozone"), all = TRUE)

countvars <- subset(countvars, yr_id==2012 | yr_id==2016 | yr_id==2018 | yr_id==2020 | yr_id==2025 | yr_id==2030 | yr_id==2035 | yr_id==2040 | yr_id==2045 | yr_id==2050)

countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'


rm(merge1,hhvars,jobs,gq)


subset(countvars,geozone=='San Diego Region')


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
jobs_cpa <- subset_by_geotype(jobs,'cpa')
jobs_jur <- subset_by_geotype(jobs,'jurisdiction')

households <- calculate_pct_chg(countvars, households)
households <- calculate_pass_fail(households,2500,.20)
households <- sort_dataframe(households)
households <- rename_dataframe(households)
households_cpa <- subset_by_geotype(households,'cpa')
households_jur <- subset_by_geotype(households,'jurisdiction')

hhp <- calculate_pct_chg(countvars, hhp)
hhp <- calculate_pass_fail(hhp,7500,.20)
hhp <- sort_dataframe(hhp)
hhp <- rename_dataframe(hhp)
hhp <- hhp %>% rename('hhpop'= hhp)
hhp_cpa <- subset_by_geotype(hhp,'cpa')
hhp_jur <- subset_by_geotype(hhp,'jurisdiction')

units <- calculate_pct_chg(countvars, units)
units <- calculate_pass_fail(units,2500,.20)
units <- sort_dataframe(units)
units <- rename_dataframe(units)
units_cpa <- subset_by_geotype(units,'cpa')
units_jur <- subset_by_geotype(units,'jurisdiction')

gqpop <- calculate_pct_chg(countvars, gqpop)
gqpop <- calculate_pass_fail(gqpop,500,.20)
gqpop <- sort_dataframe(gqpop)
gqpop <- rename_dataframe(gqpop)
gqpop_cpa <- subset_by_geotype(gqpop,'cpa')
gqpop_jur <- subset_by_geotype(gqpop,'jurisdiction')

########################################################### 
# create excel workbook

# read email message from Dave and attach to excel spreadsheet
## Insert email as images
imgfilepath<- "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\6_Notes\\"
img1a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 1.png",sep='')
img2a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 2.png",sep='')
img3a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 3.png",sep='')
img4a <- paste(imgfilepath,"DaveTedrowEmail_ds30\\DaveTedrowEmail_2019-08-26 4.png",sep='')



wb = createWorkbook()

# add sheet with email info
shtemail = addWorksheet(wb, "Email")

insertImage(wb, shtemail, img1a, startRow = 3,  startCol = 2, width = 19.74, height = 4.77,units = "in") # divide by 96
insertImage(wb, shtemail, img2a, startRow = 26,  startCol = 2, width = 19.80, height = 6.93,units = "in")
insertImage(wb, shtemail, img3a, startRow = 61,  startCol = 2, width = 19.76, height = 7.09,units = "in")
insertImage(wb, shtemail, img4a, startRow = 98,  startCol = 2, width = 19.71, height = 8.97,units = "in")


# add sheets with data 
shtjurunits = addWorksheet(wb, "UnitsByJur", tabColour = "red")
shtcpaunits = addWorksheet(wb, "UnitsByCPA", tabColour = "red")
shtjurhh = addWorksheet(wb, "HHByJur", tabColour = "green")
shtcpahh = addWorksheet(wb, "HHByCPA", tabColour = "green")
shtjurhhp = addWorksheet(wb, "HHPopByJur", tabColour = "blue")
shtcpahhp = addWorksheet(wb, "HHPopByCPA", tabColour = "blue")
shtjurjobs = addWorksheet(wb, "JobsByJur", tabColour = "yellow")
shtcpajobs = addWorksheet(wb, "JobsByCPA", tabColour = "yellow")
shtjurgqpop = addWorksheet(wb, "GQPopByJur", tabColour = "purple")
shtcpagqpop = addWorksheet(wb, "GQPopByCPA", tabColour = "purple")

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
rangeRowscpa = 2:(nrow(jobs_cpa)+1)
rangeRowsjur = 2:(nrow(jobs_jur)+1)
rangeCols = 1:9
pct = createStyle(numFmt="0%") # percent 

for (curr_sheet in names(wb)[-1]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowscpa,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(hhp_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(hhp_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(10), rows=1:(nrow(hhp_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9), widths = c(16,14,33,15,16,18,18,18,14))
  conditionalFormatting(wb, curr_sheet, cols=1:9, rows=1:(nrow(hhp_cpa)+1), rule="$J1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=1:9, rows=1:(nrow(hhp_cpa)+1), rule="$J1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=1:9, rows=2:(nrow(hhp_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=1:9, rows=2:(nrow(hhp_cpa)+1), type="contains", rule="check", style = checkStyle)
}

writeData(wb, shtjurunits,units_jur)
writeData(wb, shtcpaunits,units_cpa)
writeData(wb, shtjurhh,households_jur )
writeData(wb, shtcpahh,households_cpa )
writeData(wb, shtjurhhp,hhp_jur)
writeData(wb, shtcpahhp,hhp_cpa)
writeData(wb, shtjurjobs,jobs_jur)
writeData(wb, shtcpajobs,jobs_cpa)
writeData(wb, shtjurgqpop,gqpop_jur)
writeData(wb, shtcpagqpop,gqpop_cpa)

# add comment with cutoffs to each sheet
c1 <- createComment(comment = "> 2,500 and > 20%")
writeComment(wb, shtjurunits, col = "I", row = 1, comment = c1)
writeComment(wb, shtcpaunits, col = "I", row = 1, comment = c1)
writeComment(wb, shtjurhh, col = "I", row = 1, comment = c1)
writeComment(wb, shtcpahh, col = "I", row = 1, comment = c1)
c2 <- createComment(comment = "> 7,500 and > 20%")
writeComment(wb, shtjurhhp, col = "I", row = 1, comment = c2)
writeComment(wb, shtcpahhp, col = "I", row = 1, comment = c2)
c3 <- createComment(comment = "> 5,000 and > 20%")
writeComment(wb, shtjurjobs, col = "I", row = 1, comment = c3)
writeComment(wb, shtcpajobs, col = "I", row = 1, comment = c3)
c4 <- createComment(comment = "> 500 and > 20%")
writeComment(wb, shtjurgqpop, col = "I", row = 1, comment = c4)
writeComment(wb, shtcpagqpop, col = "I", row = 1, comment = c4)

# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

saveWorkbook(wb, "EDAM_Forecast_var_counts.xlsx",overwrite=TRUE)











