
datasource_id_current <- 31

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)


# excel workbook output file name and folder with timestamp
now <- Sys.time()
outputfile <- paste("HouseholdIncome","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile2 <- paste("HouseholdIncome","_ds",datasource_id_current,"_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))

outfolder<-paste("../Output/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- paste(maindir,"/",outfolder,outputfile,sep='')
outfile2 <- paste(maindir,"/",outfolder,outputfile2,sep='')
print(paste("output filepath: ",outfile))

source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","janitor","readtext")
pkgTest(packages)

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get household income cateogry data
hhinc <- readDB("../Queries/household_income.sql",datasource_id_current)
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)
income_categories <- readDB("../Queries/income_group.sql",datasource_id_current)

odbcClose(channel)

countvars <- subset(hhinc, yr_id %in% c(2016,2018,2020,2025,2030,2035,2040,2045,2050))
rm(hhinc)

countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'

#subset(countvars,geozone=='San Diego Region')

# add jur and cpa id
countvars <- merge(x = countvars, y =geo_id,by = "geozone", all.x = TRUE)
# rm(geo_id)


# add dummy cpa id to region
countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% rename('geo_id'= id)

# clean up cpa names removing asterick and dashes etc.
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')
#head(countvars)

# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$income_group_id,countvars$datasource_id,countvars$geotype,countvars$geozone,
                             countvars$yr_id),]

income_categories <- income_categories[order(income_categories$income_group),]

# check number of rows of data
data_rows = nrow(countvars)
geo_id1 <- subset(geo_id,geozone != '*Not in a CPA*')
#write.csv(geo_id1,paste(maindir,"/",outfolder,"geo_id.csv",sep=''))
expected_rows = (nrow(geo_id1) + 1) * 9*10 # 9 increments, 10 income categories and plus 1 for region

geozone_to_fix = ''
if (data_rows != expected_rows) {
  print("ERROR: data rows not equal to expected rows")
  print(paste("data rows = ",data_rows))
  print(paste("expected rows = ",expected_rows))
  print(paste("data geographies = ",length(unique(countvars$geozone))))
  print(paste("expected geographies = ",((nrow(geo_id1) + 1))))
  t <- countvars %>% group_by(geozone) %>% tally()
  if (nrow( subset(t,n!=(90)) )!=0) {
    print("ERROR: expecting 9 years per geography * 10 income cat")
    print(subset(t,n!=(90)))
    geozone_to_fix = subset(t,n!=(90))$geozone} }

# add 'Marine Corps Recruit Depot' for yr 2016 if missing
if (geozone_to_fix == "Marine Corps Recruit Depot") {
  # add 'Marine Corps Recruit Depot' for yr 2016
  print("fixing ERROR")
  print("add Marine Corps Recruit Depot for yr 2016 since missing in datasource id 17")
  temp1<- subset(countvars,geozone == 'Marine Corps Recruit Depot' & yr_id ==2018)
  temp1['yr_id'] = 2016
  temp1$hh = 0
  countvars = rbind(countvars,temp1)
}

# check number of rows of data
data_rows = nrow(countvars)
expected_rows = (nrow(geo_id1) + 1) * 9 * 10 # 9 increments and plus 1 for region
print(paste("data rows = ",data_rows))
print(paste("expected rows = ",expected_rows))

#difference over increments
hhinc <- countvars %>% 
    group_by(geozone,geotype,income_group_id,name) %>% 
    mutate(change = hh - lag(hh))

#percent change over increments
hhinc <- hhinc %>% 
    group_by(geozone,geotype,income_group_id,name) %>%  
    # avoid divide by zero with ifelse
    mutate(percent_change = ifelse(lag(hh)==0, NA, (hh - lag(hh))/lag(hh)))

# round
hhinc$percent_change <- round(hhinc$percent_change, digits = 3)

hhinctotals <- hhinc %>% 
  group_by(geotype,geozone,yr_id) %>% 
  summarise(hhinctotal = sum(hh))

inc <- merge(x = hhinc, y = hhinctotals, by = c("geotype","geozone","yr_id"), all.x = TRUE)


inc$prop <- inc$hh/inc$hhinctotal

#proportion change over increments
inc <- inc %>% 
   group_by(geozone,geotype,income_group_id,name) %>%  
   # avoid divide by zero with ifelse
   mutate(prop_change = prop - lag(prop))



inc <- inc %>%
    mutate(pass.or.fail = case_when(abs(change) >= 250 & abs(percent_change) >= .20 ~ "fail",
                                    TRUE ~ "pass"))

inc$geozone_and_sector <-paste(inc$geozone,'_',inc$income_group_id)
df_fail <- unique(subset(inc,pass.or.fail=="fail")$geozone_and_sector)
df_check <- unique(subset(inc,pass.or.fail=="check")$geozone)
inc <- inc %>% 
    mutate(sort_order = case_when(geozone_and_sector %in% df_fail  ~ 1,
                                  geozone %in% df_check ~ 2,
                                  TRUE ~ 3))
inc <- inc[order(inc$geotype,inc$geo_id,inc$income_group_id,inc$yr_id),]
inc$sort_order <- NULL
inc$geozone_and_sector <- NULL


inc <- inc %>% rename('datasource id'= datasource_id,'geo id'=geo_id,
                      'increment'= yr_id,'change' = change,
                      #'percent change' = percent_change,
                      'pass/fail' = pass.or.fail,"income_category" = name)
 



get_fails <- function(df) {
  df1 <- df %>% select("datasource id","geotype","geo id","geozone","increment","income_group_id",
                       "income_category","pass/fail")
  df2 <- spread(df1,increment,'pass/fail')
  df3 <-df2 %>% filter_all(any_vars(. %in% c('fail')))
  drops <- c("2016","2018","2020","2025","2030","2035","2040","2045","2050")
  df4 <- df3[ , !(names(df3) %in% drops)]
  return(df4) 
}  

inc_failed <- get_fails(inc)
inc_failed$inc <- 'fail'
allvars <- inc_failed

inc_region <- subset(inc,geotype=='region')

region1 <- inc_region %>% select("datasource id","geotype","geo id","geozone","increment","income_group_id",
                                  "income_category","hh")
region2 <- spread(region1,increment,'hh')
region2['geo id'] <- NULL
region2['geotype'] <- NULL
 
region2['2050minus2016'] <- region2['2050'] - region2['2016']


region3 <- region2 %>% adorn_totals("row")


wide_DF <- allvars[ , c("datasource id","geotype","geo id","geozone", "income_category","inc")] %>%  spread(income_category, inc)

# all the sector names
all_income_cats <- unique(inc$income_category)
Missing <- setdiff(all_income_cats, names(wide_DF))
wide_DF[Missing] <- 'pass'

#head(wide_DF, 24)

ids <- rep(1:2, times=nrow(wide_DF)/2)
if (length(ids) < nrow(wide_DF)) {ids<-c(ids,1)}
wide_DF$id <- ids
wide_DF[is.na(wide_DF)] <- 'pass'

#wide_DF <- wide_DF[order(wide_DF['geotype'],wide_DF['geozone']),]
#allvars <- allvars[order(allvars['units'],allvars['hhp'],allvars['geotype'],allvars['geozone']),]
wide_DF <- wide_DF %>% arrange(desc(geotype))

#wide_DF <- wide_DF[,c("datasource id","geotype","geo id","geozone","Retail Trade","Leisure and Hospitality",
##                      "Professional and Business Services","Construction","Education and Healthcare",
#                      "Manufacturing","Military","Transporation, Warehousing, and Utilities","id")]

letters[which( colnames(wide_DF)=="id" )]

inc['geo id'] <- NULL


inc2 <- inc %>% select("datasource id","geotype","geozone","increment","income_group_id","income_category","hhinctotal","hh","change","percent_change","prop","prop_change","pass/fail")



add_id_for_excel_formatting_inc <- function(df) {
  t <- df %>% group_by(geozone,income_category) %>% tally()
  if (nrow(subset(t,n!=9))!=0) {
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) } 
  
  ids <- rep(1:2, times=nrow(t)/2, each=9)
  if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
  df$id <- ids
  return(df)
}



subset_by_geotype_inc <- function(df,the_geotype) {
  df1 <- subset(df,geotype %in% the_geotype)
  df2 <- add_id_for_excel_formatting_inc(df1)
  df2 <- df2 %>% rename(!!the_geotype[1] := geozone)
  #df %>% rename(!!variable := name_of_col_from_df)
  # df2$geotype <- NULL
  return(df2)
}


inc_cpa <- subset_by_geotype_inc(inc2,c('cpa'))
inc_jur <- subset_by_geotype_inc(inc2,c('jurisdiction'))
inc_region <- subset_by_geotype_inc(inc2,c('region'))

inc_jur <- inc_jur %>% rename('Total Households in Jurisdiction'= hhinctotal)
inc_jur <- inc_jur %>% rename('Households by Income Category'= hh)
inc_jur <- inc_jur %>% rename('Change in Households by Income Category'= change)
inc_jur <- inc_jur %>% rename('Percent Change in Households by Income Category'= percent_change)
inc_jur <- inc_jur %>% rename('Households by Income Category as a Share of Total Households in Jurisdiction'= prop)
inc_jur <- inc_jur %>% rename('Change in Income Category Share'= prop_change)


inc_cpa <- inc_cpa %>% rename('Total Households in CPA'= hhinctotal)
inc_cpa <- inc_cpa %>% rename('Households by Income Category'= hh)
inc_cpa <- inc_cpa %>% rename('Change in Households by Income Category'= change)
inc_cpa <- inc_cpa %>% rename('Percent Change in Households by Income Category'= percent_change)
inc_cpa <- inc_cpa %>% rename('Households by Income Category as a Share of Total Households in CPA'= prop)
inc_cpa <- inc_cpa %>% rename('Change in Income Category Share'= prop_change)

inc_region <- inc_region %>% rename('Total Households in region'= hhinctotal)
inc_region <- inc_region %>% rename('Households by Income Category'= hh)
inc_region <- inc_region %>% rename('Change in Households by Income Category'= change)
inc_region <- inc_region %>% rename('Percent Change in Households by Income Category'= percent_change)
inc_region <- inc_region %>% rename('Households by Income Category as a Share of Total Households in Region'= prop)
inc_region <- inc_region %>% rename('Change in Income Category Share'= prop_change)



# add comments to sheets with cutoff
# create dictionary hash of comments
acceptance_criteria <- hash()
acceptance_criteria['hhincomecat'] <- "> 250 and > 20%"


# sector_names <- merge(x=allvars,y=employment_name, by = 'income_group_id')

full_names <- unique(allvars$income_category)

inc_jur['income_group_id'] <-NULL
inc_jur['geotype'] <-NULL
inc_jur_sector_share <- inc_jur
inc_jur['Households by Income Category as a Share of Total Households in Jurisdiction'] <- NULL
inc_jur['Change in Income Category Share'] <- NULL
inc_cpa['income_group_id'] <-NULL
inc_cpa['geotype'] <-NULL
inc_cpa_sector_share <- inc_cpa
inc_cpa['Households by Income Category as a Share of Total Households in CPA'] <- NULL
inc_cpa['Change in Income Category Share'] <- NULL
inc_region['income_group_id'] <-NULL
inc_region['geotype'] <-NULL
inc_region_sector_share <- inc_region
inc_region['Households by Income Category as a Share of Total Households in Region'] <- NULL
inc_region['Change in Income Category Share'] <- NULL


########################################################### 
# create excel workbook


wb = createWorkbook()

#add summary worksheet
summary = addWorksheet(wb, "Summary of Findings", tabColour = "red")

writeData(wb, summary, x = "Cities & CPAs that QC failed based on the following criteria:", 
          startCol = 1, startRow = 1)
writeData(wb, summary, x = paste('      change by increment: ',acceptance_criteria[['hhincomecat']],sep=''), 
          startCol = 1, startRow = 2)

headerStyleforsummary <- createStyle(fontSize = 12 ,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)

sn <- colnames(wide_DF)[-(15)] # all but the last column (id)
sectors <- sn[-(1:4)] # from column 5 to the end
ini_cols <- colnames(wide_DF)[1:4]
id_col <- colnames(wide_DF)[15]
wide_DF <- wide_DF[,(c(ini_cols,income_categories$name,id_col))]


writeData(wb,summary,wide_DF,startCol = 1, startRow = 4)



# add summary table of cutoffs
writeData(wb, summary, x = "Variable", startCol = 1, startRow = nrow(wide_DF)+6)
writeData(wb, summary, x = "Description", startCol = 2, startRow = nrow(wide_DF)+6)
writeData(wb, summary, x = "Test Criteria", startCol = 3, startRow = nrow(wide_DF)+6)
headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(wide_DF)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)


tableStyle1 <- createStyle(fontSize = 10, halign = "center")
tableStyle2 <- createStyle(fontSize = 10, halign = "left")

writeData(wb, summary, x = "households by income category", startCol = 1, startRow = nrow(wide_DF)+7)
#writeData(wb, summary, x = "households by income category", startCol = 2, startRow = nrow(wide_DF)+7)
writeData(wb, summary, x = acceptance_criteria[['hhincomecat']], startCol = 3, startRow = nrow(wide_DF)+7)




for (index in 1:nrow(wide_DF)) { 
  row = wide_DF[index, ]
  for (sectorname in sectors){
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'cpa')) {
      rnfail = max(which((inc_cpa$cpa ==row$geozone) & (inc_cpa['pass/fail'] =='fail') & 
                           (inc_cpa['income_category'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                      x = makeHyperlinkString(sheet = 'IncomebyCPA', row = rnfail, col = 11,text = "fail"))
    }
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'jurisdiction')) {
      rnfail = max(which((inc_jur$jurisdiction ==row$geozone) & (inc_jur['pass/fail'] =='fail') & 
                           (inc_jur['income_category'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                   x = makeHyperlinkString(sheet = 'IncomebyJur', row = rnfail, col = 11,text = "fail"))
    }
  }
}


headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(wide_DF)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)
writeData(wb, summary, x = "EDAM review", startCol = (ncol(wide_DF) + 1), startRow = 4)



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


########### test plan document ##########################
# add TestPlan as worksheet
testingplan = addWorksheet(wb, "TestPlan")

# read Test Plan from share drive
TestPlanDirectory <- "M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\2_Testing Plan\\"
TestPlanFile <- paste(TestPlanDirectory,"Test_Plan_DS31.docx",sep='')
testplan <- readtext(TestPlanFile)

# generate "dummy" plot with test plan as text box
# a hack to get word document as excel sheet
png("testplan.png", width=1024, height=768, units="px", res=144)  #output to png device
p <- ggplot(data = NULL, aes(x = 1:10, y = 1:10)) +
  geom_text(aes(x = 1, y = 20), label = testplan$text) +
  theme_minimal() +
  theme(axis.text = element_blank(),
        axis.title = element_blank(),
        panel.grid = element_blank())
print(p)
dev.off()  
insertImage(wb, sheet=testingplan, "testplan.png", width=11.18, height=7.82, units="in")
#insertPlot(wb, sheet=testingplan,xy = c(2, 2), width = 8, height = 8)

### end test plan worksheet
#################################################################################

# add comments to sheets with cutoff
# create dictionary hash of comments
fullname <- hash()
fullname['HH'] <- "Households"


#j <-4 # starting sheet number for data
incomejur <- addWorksheet(wb, "IncomebyJur",tabColour="purple")
writeData(wb,incomejur,inc_jur)
writeComment(wb,incomejur,col = "I",row = 1,comment = createComment(comment = acceptance_criteria[['hhincomecat']]))

incomecpa <- addWorksheet(wb, "IncomebyCPA",tabColour="purple")
writeData(wb, incomecpa,inc_cpa)
writeComment(wb,incomecpa,col = "I",row = 1,comment = createComment(comment = acceptance_criteria[['hhincomecat']]))

incomeregion <- addWorksheet(wb, "IncomebyRegion",tabColour="purple")
writeData(wb, incomeregion,inc_region)
writeComment(wb,incomeregion,col = "I",row = 1,comment = createComment(comment = acceptance_criteria[['hhincomecat']]))
  
# sector share
incomebyjurshare <- addWorksheet(wb, "IncomeShareByJur",tabColour="yellow")
writeData(wb,incomebyjurshare,inc_jur_sector_share)
incomebycpashare <- addWorksheet(wb, "IncomeShareByCpa",tabColour="yellow")
writeData(wb, incomebycpashare,inc_cpa_sector_share)
incomebyregionshare <- addWorksheet(wb, "IncomeShareByRegion",tabColour="yellow")
writeData(wb, incomebyregionshare,inc_region_sector_share)
 


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
rangeRowscpa = 2:(nrow(inc_cpa)+1)
rangeRowsjur = 2:(nrow(inc_jur)+1)
rangeCols = 1:9
pct = createStyle(numFmt="0%") # percent 
aligncenter = createStyle(halign = "center")

# skip first 3 sheets
# note: sheet 1:summary, sheet 2:email, sheet 3:test plan
#for (curr_sheet in names(wb)[-1:-3]) {
for (curr_sheet in names(wb)[4:6]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowscpa,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(10), rows=1:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18), widths = c(16,30,15,38,16,18,18,18,22,20,25,20,20,20,20,20,6,25))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(inc_cpa)+1), rule="$J1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(inc_cpa)+1), rule="$J1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(inc_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(inc_cpa)+1), type="contains", rule="check", style = checkStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}

rangeCols = 1:11
for (curr_sheet in names(wb)[7:9]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowscpa,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(12), rows=1:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(inc_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18), widths = c(16,30,15,38,16,18,18,18,22,20,25,20,20,20,20,20,6,25))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(inc_cpa)+1), rule="$L1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(inc_cpa)+1), rule="$L1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(inc_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(inc_cpa)+1), type="contains", rule="check", style = checkStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}


# format for summary sheet
idcolumn <- letters[which( colnames(wide_DF)=="id" )]
iddarkgrey <- paste("$",idcolumn,"1")
idlightgrey <- paste("$",idcolumn,"2")

conditionalFormatting(wb, summary, cols=c(1:(ncol(wide_DF)-1)), rows=1:(nrow(wide_DF)+4), rule="$O1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=c(1:(ncol(wide_DF)-1)), rows =1:(nrow(wide_DF)+4), rule="$O1==2", style = lightgreyStyle)



addStyle(wb = wb,summary,style = insideBorders,rows = 4:(nrow(wide_DF)+3),cols = c(1:(ncol(wide_DF)-1),ncol(wide_DF)+1),gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, headerStyle, rows = 4, cols = c(1:(ncol(wide_DF)-1),ncol(wide_DF)+1), gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, style=invisibleStyle, cols=c(ncol(wide_DF)), rows=4:(nrow(wide_DF)+4), gridExpand=TRUE,stack = TRUE)
#conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=3:(nrow(wide_DF)+3), rule="$J1==1", style = darkgreyStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=4:(nrow(wide_DF)+4), type="contains", rule="fail", style = negStyle)
conditionalFormatting(wb, summary, cols=1:(ncol(wide_DF)-1), rows=4:(nrow(wide_DF)+4), type="contains", rule="check", style = checkStyle)
setColWidths(wb, summary, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21), widths = c(16,22,15,30,22,22,22,22,22,22,25,25,25,25,2,40))



addStyle(wb, summary, style=aligncenter,cols=c(1:12), rows=4:(nrow(wide_DF)+4), gridExpand=TRUE,stack = TRUE)

# writeData(wb,summary,employment_name,startCol = 2, startRow = nrow(wide_DF)+9)



# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))


saveWorkbook(wb, outfile,overwrite=TRUE)
saveWorkbook(wb, outfile2,overwrite=TRUE)
