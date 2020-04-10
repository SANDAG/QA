#QA checks for ethnicity by region, jurisdiction, and cpa per EDAM defined test criteria.
#output into Excel workbooks.


datasource_id_current <- 35

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)


# excel workbook output file name and folder with timestamp
now <- Sys.time()
#outputfile2 <- paste("Ethnicity","_ds",datasource_id_current,"_",format(now, "%Y%m%d"),".xlsx",sep='')
outputfile <- paste("Ethnicity","_ds",datasource_id_current,"_QA",".xlsx",sep='')
print(paste("output filename: ",outputfile))

outfolder<-paste("../Output/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- paste(maindir,"/",outfolder,outputfile,sep='')
#outfile2 <- paste(maindir,"/",outfolder,outputfile2,sep='')
print(paste("output filepath: ",outfile))

source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","janitor","readtext", "data.table")
pkgTest(packages)

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get ethinicity data
ethn <- readDB("../Queries/age_ethn_gender.sql",datasource_id_current)
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)

odbcClose(channel)

countvars <- subset(ethn, yr_id %in% c(2016,2018,2020,2025,2030,2035,2040,2045,2050))
#rm(ethn)

#renaming region to San Diego Region
countvars$geozone[countvars$geotype=='region'] <- 'San Diego Region'

#subset(countvars,geozone=='San Diego Region')

# merging countvars and geo_id
countvars <- merge(x = countvars, y =geo_id,by = "geozone", all.x = TRUE)


# add dummy cpa id to region and rename id to geo_id
countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% rename('geo_id'= id)

# clean up cpa names removing asterick and dashes etc.
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')
#head(countvars)

#collapse ethnicity categories 
countvars$ethn_group <- ifelse(countvars$short_name=="Hispanic","Hispanic",
                         ifelse(countvars$short_name=="White","White",
                                ifelse(countvars$short_name=="Black","Black",
                                       ifelse(countvars$short_name=="Asian","Asian","Other"))))

#aggregate pop by ethnic group, geography and year
countvars<-aggregate(pop~ethn_group+geotype+geozone+geo_id+yr_id+datasource_id, data=countvars, sum)

#create numeric id for ethnicity for sorting purposes
countvars<- mutate(countvars, ethn_id=
                    ifelse(grepl("Hisp", ethn_group), 1,
                           ifelse(grepl("White", ethn_group),2,
                                  ifelse(grepl("Black", ethn_group),3,
                                         ifelse(grepl("Asian", ethn_group),4,5)))))

#compare totals by ethn_group and ethn_id to confirm a match - therefore code is correct
countvars  %>%  group_by(ethn_group) %>% tally(pop)
countvars  %>%  group_by(ethn_id) %>% tally(pop)

head(countvars)


# check number of rows of data
data_rows = nrow(countvars)
geo_id1 <- subset(geo_id,geozone != '*Not in a CPA*')

rm(geo_id)


#write.csv(geo_id1,paste(maindir,"/",outfolder,"geo_id.csv",sep=''))
expected_rows = (nrow(geo_id1) + 1) * 9*5 # 9 increments, 5 ethnicity categories and plus 1 for region

#fixing geozone with missing observations for 9 years 
geozone_to_fix = ''
if (data_rows != expected_rows) {
  print("ERROR: data rows not equal to expected rows")
  print(paste("data rows = ",data_rows))
  print(paste("expected rows = ",expected_rows))
  print(paste("data geographies = ",length(unique(countvars$geozone))))
  print(paste("expected geographies = ",((nrow(geo_id1) + 1))))
  t <- countvars %>% group_by(geozone) %>% tally()
  if (nrow( subset(t,n!=(45)) )!=0) {
    print("ERROR: expecting 9 years per geography * 5 ethnic cat")
    print(subset(t,n!=(45)))
    geozone_to_fix = subset(t,n!=(45))$geozone} }

# add 'Marine Corps Recruit Depot' for yr 2016 if missing
if (geozone_to_fix == "Marine Corps Recruit Depot") {
  # add 'Marine Corps Recruit Depot' for yr 2016
  print("fixing ERROR")
  print("add Marine Corps Recruit Depot for yr 2016 since missing in datasource id 17")
  temp1<- subset(countvars,geozone == 'Marine Corps Recruit Depot' & yr_id ==2018)
  temp1['yr_id'] = 2016
  temp1$pop = 0
  countvars = rbind(countvars,temp1)
}

# check number of rows of data
data_rows = nrow(countvars)
expected_rows = (nrow(geo_id1) + 1) * 9 * 5 # 5 categories 9 increments and plus 1 for region
print(paste("data rows = ",data_rows, "and ", "expected rows= ",expected_rows))
head(countvars)

# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$ethn_id,countvars$datasource_id,countvars$geotype,countvars$geozone,
                             countvars$yr_id),]

head(countvars,20)


#number difference over increments
ethnicity <- countvars %>% 
  group_by(geozone,geotype,ethn_id,ethn_group) %>% 
  mutate(change = pop - lag(pop))

#tracing error
options(show.error.locations=TRUE)
path.expand("~")
traceback()

#percent change over increments and address divide by zero.
ethnicity <- ethnicity %>%
  group_by(geozone,geotype,ethn_id,ethn_group) %>% 
  mutate(percent_change = case_when(lag(pop)==0 & (pop==0)  ~ 0,
                                    lag(pop)==0   ~ 1 ,
                                    TRUE ~ (pop - lag(pop))/lag(pop))) 


# round
ethnicity$percent_change <- round(ethnicity$percent_change, digits = 2)

head(ethnicity)

#removing countvars
rm(countvars)

#create file with pop totals by geozone and year 
ethnicity_totals <- ethnicity %>% 
  group_by(geotype,geozone,yr_id) %>% 
  summarise(ethntotal = sum(pop))

#create file that includes proportion change and number change for output- merge in pop totals for proportion calculations
ethn <- merge(x = ethnicity, y = ethnicity_totals, by = c("geotype","geozone","yr_id"), all.x = TRUE)
#calculate proportion of pop for each ethnic group by year
ethn$prop <- ifelse(!ethn$pop, 0, ethn$pop/ethn$ethntotal)
head(ethn)

#proportion change over increments and address divide by zero.
ethn <- ethn %>%
  group_by(geozone,geotype,ethn_id,ethn_group) %>% 
  mutate(prop_change = case_when(lag(prop)==0 & (prop==0)  ~ 0,
                                    lag(prop)==0   ~ 1 ,
                                    TRUE ~ (prop - lag(prop))/lag(prop)))
#round
ethn$prop_change <- round(ethn$prop_change, digits = 3)


#identify fails by EDAM parameters
ethn <- ethn %>%
  mutate(pass.or.fail = case_when(((ethn_id==1 & abs(change) > 2500 & abs(percent_change) > .20)| 
                                     (ethn_id==2 & abs(change) > 2500 & abs(percent_change) > .20)|
                                     (ethn_id==3 & abs(change) > 250 & abs(percent_change) > .20)|
                                     (ethn_id==4 & abs(change) > 1000 & abs(percent_change) > .20)|
                                     (ethn_id==4 & abs(change) > 1000 & abs(percent_change) > .20)|
                                     (geotype == 'region' & pop == 0)|
                                     (geotype == 'jurisdiction' & pop== 0)) ~ "fail",
                                  TRUE ~ "pass"))

ethn$geozone_ethnid <-paste(ethn$geozone,'_',ethn$ethn_id)
df_fail <- unique(subset(ethn,pass.or.fail=="fail")$geozone_ethnid)
df_check <- unique(subset(ethn,pass.or.fail=="check")$geozone)
ethn <- ethn %>% 
  mutate(sort_order = case_when(geozone_ethnid %in% df_fail  ~ 1,
                                geozone %in% df_check ~ 2,
                                TRUE ~ 3))
ethn <- ethn[order(ethn$geotype,ethn$geo_id,ethn$ethn_group,ethn$yr_id),]
ethn$sort_order <- NULL
ethn$geozone_ethnidr <- NULL


ethn <- ethn %>% rename('datasource id'= datasource_id,'geo id'=geo_id,
                      'increment'= yr_id,'change' = change,
                   #'percent change' = percent_change,
                    'pass/fail' = pass.or.fail,"ethnicity_category" = ethn_group)

get_fails <- function(df) {
  df1 <- df %>% select("datasource id","geotype","geo id","geozone","increment","ethn_id",
                       "ethnicity_category","pass/fail")
  df2 <- spread(df1,increment,'pass/fail')
  df3 <-df2 %>% filter_all(any_vars(. %in% c('fail')))
  drops <- c("2016","2018","2020","2025","2030","2035","2040","2045","2050")
  df4 <- df3[ , !(names(df3) %in% drops)]
  return(df4) 
}  


ethn_failed <- get_fails(ethn)
ethn_failed$"test result" <- 'fail'
allvars <- ethn_failed

ethn_region <- subset(ethn,geotype=='region')

region1 <- ethn_region %>% select("datasource id","geotype","geo id","geozone","increment","ethn_id",
                                 "ethnicity_category","pop")
region2 <- spread(region1,increment,'pop')
region2['geo id'] <- NULL
region2['geotype'] <- NULL

region2['2050minus2016'] <- region2['2050'] - region2['2016']


region3 <- region2 %>% adorn_totals("row")

wide_DF <- allvars[ , c("datasource id","geotype","geo id","geozone", "ethnicity_category","test result")] %>%  spread(ethnicity_category, 'test result')

# include all the ethnicity categories whether they pass or fail
all_ethn_cats <- unique(ethn$ethnicity_category)
Missing <- setdiff(all_ethn_cats, names(wide_DF))
wide_DF[Missing] <- 'pass'

head(wide_DF, 24)



#add id for shading
ids <- rep(1:2, times=nrow(wide_DF)/2)
if (length(ids) < nrow(wide_DF)) {ids<-c(ids,1)}
wide_DF$id <- ids
wide_DF[is.na(wide_DF)] <- 'pass'

wide_DF

#sort summary data by geotype
wide_DF <- wide_DF %>% arrange(desc(geotype))

#identifies excel column id for shading will be in
letters[which( colnames(wide_DF)=="id" )]

#delete geo id column
ethn['geo id'] <- NULL

#create new df with columns in order for output
ethn2 <- ethn %>% select("datasource id","geotype","geozone","increment","ethn_id","ethnicity_category","ethntotal","pop","change","percent_change","prop","prop_change","pass/fail")

ethn2
#checking for 9 increments for each geozone
add_id_for_excel_formatting_ethn <- function(df) {
  t <- df %>% group_by(geozone,ethnicity_category) %>% tally()
  if (nrow(subset(t,n!=9))!=0) {
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) } 
  
  ids <- rep(1:2, times=nrow(t)/2, each=9)
  if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
  df$id <- ids
  return(df)
}

#function to subset files by geotype
subset_by_geotype_ethn <- function(df,the_geotype) {
  df1 <- subset(df,geotype %in% the_geotype)
  df2 <- add_id_for_excel_formatting_ethn(df1)
  df2 <- df2 %>% rename(!!the_geotype[1] := geozone)
  #df %>% rename(!!variable := name_of_col_from_df)
  # df2$geotype <- NULL
  return(df2)
}

ethn_cpa <- subset_by_geotype_ethn(ethn2,c('cpa'))
ethn_jur <- subset_by_geotype_ethn(ethn2,c('jurisdiction'))
ethn_region <- subset_by_geotype_ethn(ethn2,c('region'))

ethn_jur <- ethn_jur %>% rename('Total Population in Jurisdiction'= ethntotal)
ethn_jur <- ethn_jur %>% rename('Population by Ethnic Category'= pop)
ethn_jur <- ethn_jur %>% rename('Change in Population by Ethnic Category'= change)
ethn_jur <- ethn_jur %>% rename('Percent Change in Population by Ethnic Category'= percent_change)
ethn_jur <- ethn_jur %>% rename('Population by Ethnic Category as a Share of Total Population in Jurisdiction'= prop)
ethn_jur <- ethn_jur %>% rename('Change in Ethnic Category Share'= prop_change)

ethn_cpa <- ethn_cpa %>% rename('Total Population in CPA'= ethntotal)
ethn_cpa <- ethn_cpa %>% rename('Population by Ethnic Category'= pop)
ethn_cpa <- ethn_cpa %>% rename('Change in Population by Ethnic Category'= change)
ethn_cpa <- ethn_cpa %>% rename('Percent Change in Population by Ethnic Category'= percent_change)
ethn_cpa <- ethn_cpa %>% rename('Population by Ethnic Category as a Share of Total Population in CPA'= prop)
ethn_cpa <- ethn_cpa %>% rename('Change in Ethnic Category Share'= prop_change)

ethn_region <- ethn_region %>% rename('Total Population in Region'= ethntotal)
ethn_region <- ethn_region %>% rename('Population by Ethnic Category'= pop)
ethn_region <- ethn_region %>% rename('Change in Population by Ethnic Category'= change)
ethn_region <- ethn_region %>% rename('Percent Change in Population by Ethnic Category'= percent_change)
ethn_region <- ethn_region %>% rename('Population by Ethnic Category as a Share of Total Population in Region'= prop)
ethn_region <- ethn_region %>% rename('Change in Ethnic Category Share'= prop_change)

# add comments to sheets with cutoff
# create dictionary hash of comments
acceptance_criteria <- hash()
acceptance_criteria['His'] <- "> 2,500 and > 20%"
acceptance_criteria['Wh'] <- "> 2,500 and > 20%"
acceptance_criteria['Bl'] <- "> 250 and > 20%"
acceptance_criteria['As'] <- "> 1,000 and > 20%"
acceptance_criteria['Oth'] <- "> 500 and > 20%"

# sector_names <- merge(x=allvars,y=employment_name, by = 'income_group_id')
full_names <- unique(allvars$ethnicity_category)
colnames(ethn_jur)
ethn_jur['ethn_id'] <-NULL
ethn_jur['geotype'] <-NULL
ethn_jur_sector_share <- ethn_jur
ethn_jur['Population by Ethnic Category as a Share of Total Population in Jurisdiction'] <- NULL
ethn_jur['Change in Ethnic Category Share'] <- NULL

ethn_cpa['ethn_id'] <-NULL
ethn_cpa['geotype'] <-NULL
ethn_cpa_sector_share <- ethn_cpa
ethn_cpa['Population by Ethnic Category as a Share of Total Population in CPA'] <- NULL
ethn_cpa['Change in Ethnic Category Share'] <- NULL

ethn_region['ethn_id'] <-NULL
ethn_region['geotype'] <-NULL
ethn_region_sector_share <- ethn_region
ethn_region['Population by Ethnic Category as a Share of Total Population in Region'] <- NULL
ethn_region['Change in Ethnic Category Share'] <- NULL
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
sectors <- sn[-(1:4)] # from column 5 to the end
ini_cols <- colnames(wide_DF)[1:4]
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

writeData(wb, summary, x = "population by ethnic category", startCol = 1, startRow = nrow(wide_DF)+7)

#write ethnic group and test parameters 
writeData(wb, summary, x = "Asian", startCol = 1, startRow = nrow(wide_DF)+7)
writeData(wb, summary, x = acceptance_criteria[['As']], startCol = 2, startRow = nrow(wide_DF)+7)

writeData(wb, summary, x = "Black", startCol = 1, startRow = nrow(wide_DF)+8)
writeData(wb, summary, x = acceptance_criteria[['Bl']], startCol = 2, startRow = nrow(wide_DF)+8)

writeData(wb, summary, x = "Hispanic", startCol = 1, startRow = nrow(wide_DF)+9)
writeData(wb, summary, x = acceptance_criteria[['His']], startCol = 2, startRow = nrow(wide_DF)+9)

writeData(wb, summary, x = "Other", startCol = 1, startRow = nrow(wide_DF)+10)
writeData(wb, summary, x = acceptance_criteria[['Oth']], startCol = 2, startRow = nrow(wide_DF)+10)

writeData(wb, summary, x = "White", startCol = 1, startRow = nrow(wide_DF)+11)
writeData(wb, summary, x = acceptance_criteria[['Wh']], startCol = 2, startRow = nrow(wide_DF)+11)

#format the summary table with test parameters 
addStyle(wb, summary, tableStyle1, rows = (nrow(wide_DF)+7):(nrow(wide_DF)+11), cols = 1, gridExpand = TRUE,stack = TRUE)
addStyle(wb, summary, tableStyle2, rows = (nrow(wide_DF)+7):(nrow(wide_DF)+11), cols = 2, gridExpand = TRUE,stack = TRUE)


for (index in 1:nrow(wide_DF)) { 
  row = wide_DF[index, ]
  for (sectorname in sectors){
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'cpa')) {
      rnfail = max(which((ethn_cpa$cpa ==row$geozone) & (ethn_cpa['pass/fail'] =='fail') & 
                           (ethn_cpa['ethnicity_category'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                   x = makeHyperlinkString(sheet = 'EthnicitybyCPA', row = rnfail, col = 11,text = "fail"))
    }
    if ((row[[sectorname]] == 'fail') & (row$geotype == 'jurisdiction')) {
      rnfail = max(which((ethn_jur$jurisdiction ==row$geozone) & (ethn_jur['pass/fail'] =='fail') & 
                           (ethn_jur['ethnicity_category'] == sectorname))) + 1
      writeFormula(wb, summary, startRow = index + 4,startCol = grep((gsub("\\$", "", sectorname)), gsub("\\$", "", colnames(wide_DF))), 
                   x = makeHyperlinkString(sheet = 'EthnicitybyJur', row = rnfail, col = 11,text = "fail"))
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


#j <-2 # starting sheet number for data
ethnjur <- addWorksheet(wb, "EthnicitybyJur",tabColour="purple")
writeData(wb,ethnjur,ethn_jur)

ethncpa <- addWorksheet(wb, "EthnicitybyCPA",tabColour="purple")
writeData(wb, ethncpa,ethn_cpa)

ethnregion <- addWorksheet(wb, "EthnicitybyRegion",tabColour="purple")
writeData(wb, ethnregion,ethn_region)

# sector share
ethnbyjurshare <- addWorksheet(wb, "EthnicityShareByJur",tabColour="yellow")
writeData(wb,ethnbyjurshare,ethn_jur_sector_share)
ethnbycpashare <- addWorksheet(wb, "EthnicityShareByCpa",tabColour="yellow")
writeData(wb, ethnbycpashare,ethn_cpa_sector_share)
ethnbyregionshare <- addWorksheet(wb, "EthnicityShareByRegion",tabColour="yellow")
writeData(wb, ethnbyregionshare,ethn_region_sector_share)

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
rangeRowscpa = 2:(nrow(ethn_cpa)+1)
rangeRowsjur = 2:(nrow(ethn_jur)+1)
rangeCols = 1:9
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
    rows = rangeRowscpa,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(10), rows=1:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18), widths = c(16,30,15,38,16,18,18,18,22,20,25,20,20,20,20,20,6,25))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(ethn_cpa)+1), rule="$J1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(ethn_cpa)+1), rule="$J1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(ethn_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(ethn_cpa)+1), type="contains", rule="check", style = checkStyle)
  freezePane(wb, curr_sheet, firstRow = TRUE)
}

rangeCols = 1:11
for (curr_sheet in names(wb)[5:7]) {
  addStyle(
    wb = wb,
    sheet = curr_sheet,
    style = insideBorders,
    rows = rangeRowscpa,
    cols = rangeCols,
    gridExpand = TRUE,
    stack = TRUE
  )
  #addStyle(wb, curr_sheet, style=pct, cols=c(6), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(8), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(12), rows=1:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=aligncenter, cols=rangeCols, rows=1:(nrow(ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18), widths = c(16,30,15,38,16,18,18,18,22,20,25,20,20,20,20,20,6,25))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(ethn_cpa)+1), rule="$L1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=1:(nrow(ethn_cpa)+1), rule="$L1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(ethn_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=2:(nrow(ethn_cpa)+1), type="contains", rule="check", style = checkStyle)
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

saveWorkbook(wb, outfile,overwrite=TRUE)
#saveWorkbook(wb, outfile2,overwrite=TRUE)

#####
#examine total pop differences from 2016-2050
#no output prepared

pop <- subset(ethnicity_totals, yr_id==2016 | yr_id==2050)
head(pop)


pop_wide <- reshape2::dcast(pop,geotype+geozone~yr_id, value.var="ethntotal")
head(pop_wide)
pop_wide$num_chg <- pop_wide$`2050`-pop_wide$`2016`
pop_wide$pct_chg <- ((pop_wide$`2050`-pop_wide$`2016`)/pop_wide$`2016`)*100
pop_wide$pct_chg <- round(pop_wide$pct_chg, digits = 0)
pop_wide$pct_chg[pop_wide$`2016`==0 & pop_wide$`2050`>0] <- 100


head(pop_wide[pop_wide$geozone=='Flower Hill',])
head(pop_wide[pop_wide$geozone=='East Elliott',])

max(pop_wide$pct_chg)
min(pop_wide$pct_chg)
summary(pop_wide$pct_chg[pop_wide$num_chg>500])    
summary(pop_wide$pct_chg[pop_wide$num_chg>100])

