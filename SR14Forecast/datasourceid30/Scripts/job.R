
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","janitor")
pkgTest(packages)




# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get job data
jobs <- readDB("../Queries/jobs-2.sql",datasource_id_current)
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)
employment_name <- readDB("../Queries/employment_type.sql",datasource_id_current)


odbcClose(channel)

countvars <- subset(jobs, yr_id %in% c(2016,2018,2020,2025,2030,2035,2040,2045,2050))
rm(jobs)

countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'

#subset(countvars,geozone=='San Diego Region')

# add jur and cpa id
countvars <- merge(x = countvars, y =geo_id,by = "geozone", all.x = TRUE)
rm(geo_id)
countvars <- merge(x = countvars, y =employment_name,by = "employment_type_id", all.x = TRUE)

countvars$short_name <- NULL
countvars$civilian <- NULL



countvars <- countvars[,c("datasource_id","geotype","id","geozone","yr_id","employment_type_id","full_name","jobs")]



# add dummy cpa id to region
countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% rename('geo_id'= id)

# clean up cpa names removing asterick and dashes etc.
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')
#head(countvars)

# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$employment_type_id,countvars$datasource_id,countvars$geotype,countvars$geozone,
                             countvars$yr_id),]

#difference over increments
jobs <- countvars %>% 
    group_by(geozone,geotype,employment_type_id,full_name) %>% 
    mutate(change = jobs - lag(jobs))

#percent change over increments
jobs <- jobs %>% 
    group_by(geozone,geotype,employment_type_id,full_name) %>%  
    # avoid divide by zero with ifelse
    mutate(percent_change = ifelse(lag(jobs)==0, NA, (jobs - lag(jobs))/lag(jobs)))

# round
jobs$percent_change <- round(jobs$percent_change, digits = 3)


jobs <- jobs %>%
    mutate(pass.or.fail = case_when(abs(change) >= 500 & abs(percent_change) >= .20 ~ "fail",
                                    TRUE ~ "pass"))

jobs$geozone_and_sector <-paste(jobs$geozone,'_',jobs$employment_type_id)
df_fail <- unique(subset(jobs,pass.or.fail=="fail")$geozone_and_sector)
df_check <- unique(subset(jobs,pass.or.fail=="check")$geozone)
jobs <- jobs %>% 
    mutate(sort_order = case_when(geozone_and_sector %in% df_fail  ~ 1,
                                  geozone %in% df_check ~ 2,
                                  TRUE ~ 3))
jobs <- jobs[order(jobs$sort_order,jobs$geotype,jobs$geo_id,jobs$employment_type_id,jobs$yr_id),]
jobs$sort_order <- NULL
jobs$geozone_and_sector <- NULL


jobs <- jobs %>% rename('datasource id'= datasource_id,'geo id'=geo_id,
                      'increment'= yr_id,'change' = change,
                      'percent change' = percent_change,
                      'pass/fail' = pass.or.fail,"sector" = full_name)
 



get_fails <- function(df) {
  df1 <- df %>% select("datasource id","geotype","geo id","geozone","increment","employment_type_id",
                       "sector","pass/fail")
  df2 <- spread(df1,increment,'pass/fail')
  df3 <-df2 %>% filter_all(any_vars(. %in% c('fail')))
  drops <- c("2016","2018","2020","2025","2030","2035","2040","2045","2050")
  df4 <- df3[ , !(names(df3) %in% drops)]
  return(df4) 
}  

jobs_failed <- get_fails(jobs)
jobs_failed$jobs <- 'fail'
allvars <- jobs_failed

jobs_region <- subset(jobs,geotype=='region')

region1 <- jobs_region %>% select("datasource id","geotype","geo id","geozone","increment","employment_type_id",
                                  "sector","jobs")
region2 <- spread(region1,increment,'jobs')
region2['geo id'] <- NULL
region2['geotype'] <- NULL
 
region2['2050minus2016'] <- region2['2050'] - region2['2016']


region3 <- region2 %>% adorn_totals("row")


wide_DF <- allvars[ , c("datasource id","geotype","geo id","geozone", "sector","jobs")] %>%  spread(sector, jobs)
#head(wide_DF, 24)

ids <- rep(1:2, times=nrow(wide_DF)/2)
if (length(ids) < nrow(wide_DF)) {ids<-c(ids,1)}
wide_DF$id <- ids
wide_DF[is.na(wide_DF)] <- 'pass'

#wide_DF <- wide_DF[order(wide_DF['geotype'],wide_DF['geozone']),]
#allvars <- allvars[order(allvars['units'],allvars['hhp'],allvars['geotype'],allvars['geozone']),]
wide_DF <- wide_DF %>% arrange(desc(geotype))

wide_DF <- wide_DF[,c("datasource id","geotype","geo id","geozone","Retail Trade","Leisure and Hospitality",
                      "Professional and Business Services","Construction","Education and Healthcare",
                      "Manufacturing","Military","Transporation, Warehousing, and Utilities","id")]


jobs['geo id'] <- NULL
jobs$employment_type_id <- NULL

jobs_cpa <- subset_by_geotype_jobs(jobs,c('cpa'))
jobs_jur <- subset_by_geotype_jobs(jobs,c('jurisdiction'))
jobs_region <- subset_by_geotype_jobs(jobs,c('region'))

wide_DF <- allvars[ , c("datasource id","geotype","geo id","geozone", "sector","jobs")] %>%  spread(sector, jobs)

region_wide <- jobs_region[ , c("datasource id", "sector","jobs")] %>%  spread(sector, jobs)


# add comments to sheets with cutoff
# create dictionary hash of comments
acceptance_criteria <- hash()
acceptance_criteria['Jobs'] <- "> 500 and > 20%"


# sector_names <- merge(x=allvars,y=employment_name, by = 'employment_type_id')

full_names <- unique(allvars$sector)

########################################################### 
# create excel workbook

# add sheets with data 
add_worksheets_to_excel_jobs <- function(workbook,demographic_variable,colorfortab,rowtouse,namehash,ahash) {
  tabname <- paste(demographic_variable,"ByJur",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  ## Internal - Text to display
  tabname <- paste(demographic_variable,"ByCpa",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  tabname <- paste(demographic_variable,"ByRegion",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
}



wb = createWorkbook()

#add summary worksheet
summary = addWorksheet(wb, "Summary of Findings", tabColour = "red")

writeData(wb, summary, x = "Cities & CPAs that failed based on the following criteria:", 
          startCol = 1, startRow = 1)
writeData(wb, summary, x = paste('Test Criteria: ',acceptance_criteria[['Jobs']],sep=''), 
          startCol = 1, startRow = 2)

headerStyleforsummary <- createStyle(fontSize = 12 ,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)

writeData(wb,summary,wide_DF,startCol = 1, startRow = 4)

headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(wide_DF)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)


writeData(wb, summary, x = "EDAM review", startCol = (ncol(wide_DF) + 1), startRow = 4)
# specify sheetname and tab colors


#tableofcontents = addWorksheet(wb, "TableofContents")


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

#add_worksheets_to_excel(wb,"Units","blue",8,fullname,acceptance_criteria)

# add comments to sheets with cutoff
# create dictionary hash of comments
fullname <- hash()
fullname['Jobs'] <- "Jobs"



# specify sheetname and tab colors
add_worksheets_to_excel_jobs(wb,"Jobs","purple",8,fullname,acceptance_criteria)

# add comments to sheets with cutoff
# create dictionary hash of comments
comments_to_add <- hash()
comments_to_add['jobs'] <- "> 500 and > 20%"


i <-3 # starting sheet number (sheet 1 is email message)
for (demographic_var in c('jobs')) {
  add_data_to_excel_jobs(wb,demographic_var,i)
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
rangeRowscpa = 2:(nrow(jobs_cpa)+1)
rangeRowsjur = 2:(nrow(jobs_jur)+1)
rangeCols = 1:8
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
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(jobs_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(7), rows=2:(nrow(jobs_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(9), rows=1:(nrow(jobs_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(jobs_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9), widths = c(16,30,15,38,16,18,18,18,14))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(jobs_cpa)+1), rule="$I1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(jobs_cpa)+1), rule="$I1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(jobs_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(jobs_cpa)+1), type="contains", rule="check", style = checkStyle)
}

# format for summary sheet
conditionalFormatting(wb, summary, cols=c(1:(ncol(wide_DF)-1)), rows =1:(nrow(wide_DF)+4), rule="$M1==2", style = lightgreyStyle)
conditionalFormatting(wb, summary, cols=c(1:(ncol(wide_DF)-1)), rows=1:(nrow(wide_DF)+4), rule="$M1==1", style = darkgreyStyle)


addStyle(wb = wb,summary,style = insideBorders,rows = 4:(nrow(wide_DF)+3),cols = c(1:(ncol(wide_DF)-1),ncol(wide_DF)+1),gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, headerStyle, rows = 4, cols = c(1:(ncol(wide_DF)-1),ncol(wide_DF)+1), gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, style=invisibleStyle, cols=c(ncol(wide_DF)), rows=4:(nrow(wide_DF)+4), gridExpand=TRUE,stack = TRUE)
#conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=3:(nrow(wide_DF)+3), rule="$J1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=4:(nrow(wide_DF)+4), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=4:(nrow(wide_DF)+4), type="contains", rule="check", style = checkStyle)
setColWidths(wb, summary, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14), widths = c(15,21,14,28,21,21,21,21,21,21,21,21,2,40))
addStyle(wb, summary, style=aligncenter,cols=c(1:12), rows=4:(nrow(wide_DF)+4), gridExpand=TRUE,stack = TRUE)

# writeData(wb,summary,employment_name,startCol = 2, startRow = nrow(wide_DF)+9)



# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

saveWorkbook(wb, "JobsBySector.xlsx",overwrite=TRUE)

