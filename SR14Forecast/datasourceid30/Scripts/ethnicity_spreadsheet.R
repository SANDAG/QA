
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("config.R")
source("../Queries/readSQL.R")
source("common_functions.R")
source("functions_for_percent_change.R")

#install.packages("conflicted")
#library(conflicted)
#conflict_prefer("rename","dplyr")
#conflict_prefer("mutate","dplyr")
# conflict_scout()
# library()
#remove.packages("conflicted")

packages <- c("RODBC","tidyverse","openxlsx")
pkgTest(packages)

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get hhpop data
dem <- readDB("../Queries/age_ethn_gender.sql",datasource_id_current)
geography_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)
odbcClose(channel)

dem <- subset(dem, yr_id==2012 | yr_id==2016 | yr_id==2018 | yr_id==2020 | yr_id==2025 | yr_id==2030 | yr_id==2035 | yr_id==2040 | yr_id==2045 | yr_id==2050)

table(dem$geotype)

dem <- merge(dem,geography_id, by.x="geozone",by.y="geozone", all = TRUE)

dem$id[dem$geotype=='region'] <- 9999
dem$geozone[dem$geotype=='region'] <- 'San Diego Region'

head(dem)

dem <- dem %>% rename(geo_id= id)
# clean up cpa names removing asterick and dashes etc.
dem <- rm_special_chr(dem)
dem <- subset(dem,geozone != 'Not in a CPA')
head(dem)

dem$ethn_group <- ifelse(dem$short_name=="Hispanic","Hispanic",
                         ifelse(dem$short_name=="White","White",
                                ifelse(dem$short_name=="Black","Black",
                                       ifelse(dem$short_name=="Asian","Asian","Other"))))

dem_ethn<-aggregate(pop~ethn_group+geotype+geozone+geo_id+yr_id, data=dem, sum)

dem_ethn<- mutate(dem_ethn, ethn_id=
              ifelse(grepl("Hisp", ethn_group), 1,
                     ifelse(grepl("White", ethn_group),2,
                            ifelse(grepl("Black", ethn_group),3,
                                   ifelse(grepl("Asian", ethn_group),4,5)))))


dem_ethn  %>%  group_by(ethn_group) %>% tally(pop)

dem_ethn  %>%  group_by(ethn_id) %>% tally(pop)

head(dem_ethn)

#creates file with pop totals by geozone and year
#geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=dem_ethn, sum)

#tail(geozone_pop)

# #lag for pop change
# dem_ethn$change <- dem_ethn$pop - lag(dem_ethn$pop)
# dem_ethn$geozone_pop<-geozone_pop[match(paste(dem_ethn$yr_id, dem_ethn$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), "pop"]
# dem_ethn$proportion_of_pop<-(dem_ethn$pop / dem_ethn$geozone_pop)
# dem_ethn$proportion_of_pop<-round(dem_ethn$proportion_of_pop,digits=2)
# dem_ethn$percent_change <- dem_ethn$proportion_of_pop - lag(dem_ethn$proportion_of_pop)
# dem_ethn$percent_change<-round(dem_ethn$percent_change,digits=2)

head(dem_ethn,15)
#order dataframe for lag calc
dem_ethn <- dem_ethn[order(dem_ethn$ethn_id,dem_ethn$geotype,dem_ethn$geozone,dem_ethn$yr_id),]

#lag for pop change
dem_ethn$change <- dem_ethn$pop - lag(dem_ethn$pop)
dem_ethn$percent_change<-(dem_ethn$pop-lag(dem_ethn$pop)) / lag(dem_ethn$pop)
dem_ethn$percent_change<-round(dem_ethn$percent_change,digits=2)

head(dem_ethn[dem_ethn$geozone=="Flower Hill",])

dem_ethn$change[dem_ethn$yr_id == "2016"] <- NA
dem_ethn$percent_change[dem_ethn$yr_id == "2016"] <- NA
#dem_ethn$change[dem_ethn$change == "NA"] <- 0
dem_ethn$percent_change[dem_ethn$percent_change == "NaN"] <- 0

dem_ethn$change_abs <- abs(dem_ethn$change)
dem_ethn$percent_change_abs <- abs(dem_ethn$percent_change)

head(dem_ethn,12)

dem_ethn <- dem_ethn %>%
  mutate(pass.or.fail = case_when(((ethn_id==1 & change_abs > 2500 & percent_change_abs > .20)| 
                                     (ethn_id==2 & change_abs > 2500 & percent_change_abs > .20)|
                                     (ethn_id==3 & change_abs > 250 & percent_change_abs > .20)|
                                     (ethn_id==4 & change_abs > 1000 & percent_change_abs > .20)|
                                     (ethn_id==5 & change_abs > 500 & percent_change_abs > .20)) ~ 1,
                                  TRUE ~ 0))

sort_dataframe <- function(df) {
  df_fail <- unique(subset(df,pass.or.fail=="fail")$geozone)
  #df_check <- unique(subset(df,pass.or.fail=="check")$geozone)
  df <- df %>% 
    mutate(sort_order = case_when(geozone %in% df_fail ~ 1,
                                  #geozone %in% df_check ~ 2,
                                  TRUE ~ 3))
  df <- df[order(df$sort_order,df$geotype,df$geozone,df$ethn_id,df$yr_id),]
  df$sort_order <- NULL
  return(df)
}

dem_ethn <- sort_dataframe(dem_ethn)

dem_ethn <- dem_ethn %>% select(geotype,geozone,geo_id,yr_id,ethn_group,ethn_id,pop,change,percent_change,pass.or.fail)

dem_ethn$datasource_id <- datasource_id_current

head(dem_ethn)
# dem_ethn <- add_id_for_excel_formatting(dem_ethn)
t <- dem_ethn %>% group_by(geozone,ethn_group) %>% tally()
if (nrow(subset(t,n!=9))!=0) {
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) } 


ids <- rep(1:2, times=nrow(t)/2, each=9)
if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
dem_ethn$id <- ids

#create summary sheet
ethn_summary <- aggregate(pass.or.fail~ethn_group+geozone, data=dem_ethn, max)
ethn_summary$pass.or.fail[ethn_summary$pass.or.fail==0] <- "pass"
ethn_summary$pass.or.fail[ethn_summary$pass.or.fail==1] <- "fail"
ethn_summary <- spread(ethn_summary,ethn_group,pass.or.fail)
ethn_summary <- subset(ethn_summary,(Asian=="fail"|Black=="fail"|Hispanic=="fail"|Other=="fail"|White=="fail"))


#rename variables for output file
dem_ethn <- dem_ethn %>% rename('year' = yr_id,'increment change'= change,'ethnicity' =ethn_group,'ethnicity id'=ethn_id,'Population by Ethnicity' = pop, 'Change in Population by Ethnicity' = change,
                               'Percent Change by Ethnicity' = percent_change,'pass/fail'= pass.or.fail)

#move datasource_id to first column position
dem_ethn <- dem_ethn %>% select(datasource_id,everything())

#create files by geotype for output
dem_ethn_cpa <- subset(dem_ethn,dem_ethn$geotype=='cpa')
dem_ethn_jur <- subset(dem_ethn,dem_ethn$geotype=='jurisdiction')
dem_ethn_reg <- subset(dem_ethn,dem_ethn$geotype=='region')

#rename geozone for cpa and jurisdiction
dem_ethn_cpa <- dem_ethn_cpa %>% rename('cpa'= geozone)
dem_ethn_jur <- dem_ethn_jur %>% rename('jurisdiction'= geozone)
dem_ethn_reg <- dem_ethn_reg %>% rename('region'= geozone)

dem_ethn_cpa$geotype <-NULL
dem_ethn_cpa$geo_id <-NULL

dem_ethn_jur$geotype <-NULL
dem_ethn_jur$geo_id <-NULL

dem_ethn_reg$geotype <-NULL
dem_ethn_reg$geo_id <-NULL

head(dem_ethn_reg)


rm(dem,dem_ethn)
########################################################### 
# create excel workbook

wb = createWorkbook()

#add summary worksheet
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
  addStyle(wb, curr_sheet, style=pct, cols=c(7,8), rows=rangeRowscpa, gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=createStyle(halign = 'center'), cols=c(1:5,10), rows=rangeRowscpa, gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(ncol(dem_ethn_jur)), rows=1:(nrow(dem_ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10), widths = c(16,33,10,15,10,18,18,18,14))
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$K1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRows, rule="$K1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=rangeCols, rows=rangeRowscpa, type="contains", rule="check", style = checkStyle)
}

#add summary text to summary sheet
writeData(wb, summary, x = "Cities and CPAs that failed QC for ethnicity/race based on following criteria:", 
          startCol = 1, startRow = 1)
headerStyleforsummary <- createStyle(fontSize = 14) #,textDecoration = "bold")
addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)

# add summary table of cutoffs
writeData(wb, summary, x = "Variable", startCol = 1, startRow = nrow(allvars)+6)
writeData(wb, summary, x = "Description", startCol = 2, startRow = nrow(allvars)+6)
writeData(wb, summary, x = "Test Criteria", startCol = 3, startRow = nrow(allvars)+6)
headerStyle1 <- createStyle(fontSize = 12, halign = "center") #,textDecoration = "bold")
addStyle(wb, summary, headerStyle1, rows = nrow(allvars)+6, cols = 1:3, gridExpand = TRUE,stack = TRUE)


tableStyle1 <- createStyle(fontSize = 10, halign = "center")
tableStyle2 <- createStyle(fontSize = 10, halign = "left")

#headerStyleforsummary <- createStyle(fontSize = 14) #,textDecoration = "bold")
#addStyle(wb, summary, style = headerStyleforsummary, rows = c(1,2), cols = 1, gridExpand = TRUE)


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




writeData(wb, shtcpaethn,dem_ethn_cpa)
writeData(wb, shtjurethn,dem_ethn_jur)
writeData(wb, shtregethn,dem_ethn_reg)


# add comment with cutoffs to each sheet
c1 <- createComment(comment = "Hispanic change > 2,500 and > 20%\nWhite change > 2,500 and > 20%\nBlack change > 250 and > 20%\nAsian change > 1,000 and > 20%\nOther change > 500 and > 20%")
writeComment(wb, shtregethn, col = "J", row = 1, comment = c1)
writeComment(wb, shtjurethn, col = "J", row = 1, comment = c1)
writeComment(wb, shtcpaethn, col = "J", row = 1, comment = c1)




# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

saveWorkbook(wb, "Ethnicity_counts.xlsx",overwrite=TRUE)




