#Fix - Datasource id current isn't not reading in


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
dem <- readDB("../Queries/age_ethn_gender.sql",datasource_id_current)

odbcClose(channel)

dem <- subset(dem, yr_id==2012 | yr_id==2016 | yr_id==2018 | yr_id==2020 | yr_id==2025 | yr_id==2030 | yr_id==2035 | yr_id==2040 | yr_id==2045 | yr_id==2050)

dem$geozone[dem$geotype=='region'] <- 'San Diego Region'

subset(dem,geozone=='San Diego Region')

dem$ethn_group <- ifelse(dem$short_name=="Hispanic","Hispanic",
                         ifelse(dem$short_name=="White","White",
                                ifelse(dem$short_name=="Black","Black",
                                       ifelse(dem$short_name=="Asian","Asian","Other"))))



dem_ethn<-aggregate(pop~ethn_group+geotype+geozone+yr_id, data=dem, sum)

dem_ethn<- mutate(dem_ethn, ethn_id=
              ifelse(grepl("Hisp", ethn_group), 1,
                     ifelse(grepl("White", ethn_group),2,
                            ifelse(grepl("Black", ethn_group),3,
                                   ifelse(grepl("Asian", ethn_group),4,5)))))


dem_ethn  %>%  group_by(ethn_group) %>% tally(pop)

dem_ethn  %>%  group_by(ethn_id) %>% tally(pop)

head(dem_ethn)

# clean up cpa names removing asterisk and dashes etc.
dem_ethn<- rm_special_chr(dem_ethn)
dem_ethn<- subset(dem_ethn,geozone != 'Not in a CPA')

#creates file with pop totals by geozone and year
geozone_pop<-aggregate(pop~geotype+geozone+yr_id, data=dem_ethn, sum)

tail(geozone_pop)

head(dem_ethn,15)
#order dataframe for lag calc
dem_ethn <- dem_ethn[order(dem_ethn$ethn_id,dem_ethn$geotype,dem_ethn$geozone,dem_ethn$yr_id),]
#lag for pop change
##SHOULD THIS BE A FUNCTION FROM FUNCTIONS SCRIPTS
dem_ethn$change <- dem_ethn$pop - lag(dem_ethn$pop)
dem_ethn$geozone_pop<-geozone_pop[match(paste(dem_ethn$yr_id, dem_ethn$geozone), paste(geozone_pop$yr_id, geozone_pop$geozone)), "pop"]
dem_ethn$proportion_of_pop<-(dem_ethn$pop / dem_ethn$geozone_pop)
dem_ethn$proportion_of_pop<-round(dem_ethn$proportion_of_pop,digits=2)
dem_ethn$percent_change <- dem_ethn$proportion_of_pop - lag(dem_ethn$proportion_of_pop)
dem_ethn$percent_change<-round(dem_ethn$percent_change,digits=2)

dem_ethn$change[dem_ethn$yr_id == "2016"] <- 0
dem_ethn$percent_change[dem_ethn$yr_id == "2016"] <- 0
dem_ethn$change[dem_ethn$change == "NA"] <- 0
dem_ethn$proportion_of_pop[dem_ethn$proportion_of_pop == "NaN"] <- 0
dem_ethn$percent_change[dem_ethn$percent_change == "NaN"] <- 0

dem_ethn$change_abs <- abs(dem_ethn$change)
dem_ethn$percent_change_abs <- abs(dem_ethn$percent_change)

head(dem_ethn,12)

dem_ethn <- dem_ethn %>%
  mutate(pass.or.fail = case_when(((ethn_id==1 & change_abs > 2500 & percent_change_abs > 20)| 
                                     (ethn_id==2 & change_abs > 2500 & percent_change_abs > 20)|
                                     (ethn_id==3 & change_abs > 250 & percent_change_abs > 20)|
                                     (ethn_id==4 & change_abs > 1000 & percent_change_abs > 20)|
                                     (ethn_id==5 & change_abs > 500 & percent_change_abs > 20)) ~ "fail",
                                  TRUE ~ "pass"))


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

#need to add datasource id to file
dem_ethn <- dem_ethn %>% select(geotype,geozone,yr_id,ethn_group,ethn_id,pop,change,proportion_of_pop,percent_change,pass.or.fail)

dem_ethn <- dem_ethn %>% rename('increment'= yr_id,'increment change' = change,'ethnicity'=ethn_group,'ethnicity id'=ethn_id,
                                'proportion of pop'= proportion_of_pop,'increment percent change' = percent_change,
                                'pass/fail' = pass.or.fail)


dem_ethn_cpa <- subset(dem_ethn,dem_ethn$geotype=='cpa')
dem_ethn_jur <- subset(dem_ethn,dem_ethn$geotype=='jurisdiction')
dem_ethn_reg <- subset(dem_ethn,dem_ethn$geotype=='region')

rm(dem,dem_ethn,geozone_pop)
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
rangeRowscpa = 2:(nrow(dem_ethn_cpa)+1)
rangeRowsjur = 2:(nrow(dem_ethn_jur)+1)
rangeRowsjur = 2:(nrow(dem_ethn_reg)+1)
rangeCols = 1:11
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
  addStyle(wb, curr_sheet, style=pct, cols=c(9), rows=2:(nrow(dem_ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=pct, cols=c(10), rows=2:(nrow(dem_ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)
  addStyle(wb, curr_sheet, style=invisibleStyle, cols=c(11), rows=1:(nrow(dem_ethn_cpa)+1), gridExpand=TRUE,stack = TRUE)
  setColWidths(wb, curr_sheet, cols = c(1,2,3,4,5,6,7,8,9,10,11), widths = c(16,14,33,15,16,18,18,18,14))
  conditionalFormatting(wb, curr_sheet, cols=1:11, rows=1:(nrow(dem_ethn_cpa)+1), rule="$K1==2", style = lightgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=1:11, rows=1:(nrow(dem_ethn_cpa)+1), rule="$K1==1", style = darkgreyStyle)
  conditionalFormatting(wb, curr_sheet, cols=1:11, rows=2:(nrow(dem_ethn_cpa)+1), type="contains", rule="fail", style = negStyle)
  conditionalFormatting(wb, curr_sheet, cols=1:11, rows=2:(nrow(dem_ethn_cpa)+1), type="contains", rule="check", style = checkStyle)
}


writeData(wb, shtcpaethn,dem_ethn_cpa)
writeData(wb, shtjurethn,dem_ethn_jur)
writeData(wb, shtregethn,dem_ethn_reg)

#LH TO REVISE
# add comment with cutoffs to each sheet
c1 <- createComment(comment = "Hispanic change > 2,500 and > 20%\nWhite change > 2,500 and > 20%\nBlack + 
                    change > 250 and > 20%\nAsian change > 1,000 and > 20%\nOther change > 500 and > 20%")
writeComment(wb, shtjurethn, col = "J", row = 1, comment = c1)
writeComment(wb, shtcpaethn, col = "J", row = 1, comment = c1)

# out folder for excel
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

saveWorkbook(wb, "EDAM_Forecast_ethnicity_counts.xlsx",overwrite=TRUE)


