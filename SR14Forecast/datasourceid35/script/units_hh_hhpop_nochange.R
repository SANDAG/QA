
# check for NO change in:
#           units, households, household population, household size for 3 or more increments


# set directory 
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

# load packages
source("../Queries/readSQL.R")
source("common_functions.R")
packages <- c("RODBC","tidyverse","openxlsx")
pkgTest(packages)

# set datasource id
datasource_id_current <- 35

# no change for 3 or more increments
num_of_increments <- 3


# excel workbook output file name
outexcel <- paste("units_hh_pop_3_increments_no_change","_ds",datasource_id_current,"_QA",".xlsx",sep='')
outfolder<-paste("../Output/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
excelfile <- paste(maindir,"/",outfolder,outexcel,sep='')

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

# get units, hh, hhpop, hhsize data
# make sure household size is not rounded too much - different query
hhvars <- readDB("../Queries/hh_hhp_hhs_ds_id_round_hhs_4_digits.sql",datasource_id_current)
geo_id <- readDB("../Queries/get_cpa_and_jurisdiction_id.sql",datasource_id_current)
odbcClose(channel)

hhvars$geozone[hhvars$geotype=='region'] <- 'San Diego Region'

#merging countvars with geo_id on geozone
countvars <- merge(x = hhvars, y =geo_id,by = "geozone", all.x = TRUE)

rm(hhvars)

# clean up cpa names removing asterick and dashes etc.
countvars$id[countvars$geozone=="San Diego Region"] <- 9999
countvars <- countvars %>% rename('geo_id'= id)
countvars <- rm_special_chr(countvars)
countvars <- subset(countvars,geozone != 'Not in a CPA')


# order dataframe for doing lag calculation
countvars <- countvars[order(countvars$datasource_id,countvars$geotype,countvars$geozone,countvars$yr_id),]

# check number of rows of data
data_rows = nrow(countvars)
geo_id1 <- subset(geo_id,geozone != '*Not in a CPA*')
expected_rows = (nrow(geo_id1) + 1) * 9 # 9 increments and plus 1 for region
print(paste("data rows = ",data_rows))
print(paste("expected rows = ",expected_rows))

rm(geo_id,geo_id1)

# remove geographies with no units
countvars <- countvars[countvars$geozone %in% countvars$geozone[countvars$units!=0], ]

# count units that stay the same 
countvars$unit_counter <- sequence(rle(as.character(countvars$units))$lengths)

# count households that stay the same
countvars$household_counter <- sequence(rle(as.character(countvars$households))$lengths)

# count household population that stays the same
countvars$hhpop_counter <- sequence(rle(as.character(countvars$hhp))$lengths)

# count household size that stays the same
countvars$hhs_counter <- sequence(rle(as.character(countvars$hhs))$lengths)


# no change for 3 or more increments
# AND remove cases where units,hh,hhp or hhs equal zero
frozenunits <- unique(subset(countvars,((unit_counter >= num_of_increments) & (units > 0)))$geozone)
frozenhh <- unique(subset(countvars,((household_counter >= num_of_increments) & (households > 0)))$geozone)
frozenhhpop <- unique(subset(countvars,((hhpop_counter >= num_of_increments) & (hhp > 0)))$geozone)
frozenhhsize <- unique(subset(countvars,((hhpop_counter >= num_of_increments) & (hhs > 0)))$geozone)


allfrozen <- c(frozenunits, frozenhh,frozenhhpop,frozenhhsize)
allfrozen <- unique(allfrozen)


# get all the geographies with no change
nochange <- subset(countvars,countvars$geozone %in% allfrozen)

# order so jurisdictions first then city cpas and county cpas
nochange <- nochange[order(nochange$datasource_id,nochange$geo_id,nochange$yr_id),]

# rename columns
nochange <- nochange %>% rename(ds_id = datasource_id, id = geo_id,name = geozone,"household population"=hhp,"household size"=hhs)

total <- nochange

# initialize columns (needed in case none of the variables have repeated values)
total['unit_format_id'] <- 1
total['hh_format_id'] <- 1
total['hhpop_format_id'] <- 1
total['hhs_format_id'] <- 1


# get max number of repetitions for units
if(length(frozenunits) != 0){
  max_values_units <- nochange %>% group_by(name,units) %>%
    filter((unit_counter== max(unit_counter)) & (unit_counter >= num_of_increments))
  #max_values_units <- nochange %>% group_by(name) %>% filter(unit_counter >= num_of_increments)
  max_values_units<-max_values_units[!(max_values_units$units==0),] # need this to get rid of highlighting
  max_values_units <- max_values_units %>% rename(max_unit_counter = unit_counter)
  total <- merge(total,max_values_units[,c("ds_id","id", "name","units","max_unit_counter")],by=c("ds_id","id", "name","units"),all=TRUE) 
  total$unit_format_id <- ifelse(is.na(total$max_unit_counter), 1, 2)
}

# get max number of repetitions for households
if(length(frozenhh) != 0){
  max_values_households <- nochange %>% group_by(name) %>%
    filter((household_counter== max(household_counter)) & (household_counter >= num_of_increments))
  max_values_households<-max_values_households[!(max_values_households$households==0),] # need this to get rid of highlighting
  max_values_households <- max_values_households %>% rename(max_household_counter = household_counter)
  total <- merge(total,max_values_households[,c("ds_id","id", "name","households","max_household_counter")],by=c("ds_id","id", "name","households"),all=TRUE) 
  total$hh_format_id <- ifelse(is.na(total$max_household_counter), 1, 2)
}

# get max number of repetitions for household population
if(length(frozenhhpop) != 0){
  max_values_hhp <- nochange %>% group_by(name) %>%
    filter((hhpop_counter== max(hhpop_counter)) & (hhpop_counter >= num_of_increments)) #num_of_increments))
  max_values_hhp<-max_values_hhp[!(max_values_hhp['household population']==0),] # need this to get rid of highlighting
  max_values_hhp <- max_values_hhp %>% rename(max_hhp_counter = hhpop_counter)
  total <- merge(total,max_values_hhp[,c("ds_id","id", "name","household population","max_hhp_counter")],by=c("ds_id","id", "name","household population"),all=TRUE) 
  total$hhpop_format_id <- ifelse(is.na(total$max_hhp_counter), 1, 2)
}

# get max number of repetitions for householdsize
if(length(frozenhhsize) != 0){
  max_values_hhs <- nochange %>% group_by(name) %>% 
    filter((hhs_counter== max(hhs_counter)) & (hhs_counter >= num_of_increments)) #num_of_increments))
  max_values_hhs<-max_values_hhs[!(max_values_hhs['household size']==0),] # need this to get rid of highlighting
  max_values_hhs <- max_values_hhs %>% rename(max_hhs_counter = hhs_counter)
  total <- merge(total,max_values_hhs[,c("ds_id","id", "name","household size","max_hhs_counter")],by=c("ds_id","id", "name","household size"),all=TRUE) 
  total$hhs_format_id <- ifelse(is.na(total$max_hhs_counter), 1, 2)
}


# change order of columns

col_order <- c("name","ds_id","id", "yr_id","units","households","household population","household size",
               "unit_format_id","hh_format_id","hhpop_format_id","hhs_format_id")
total <- total[, col_order]

# order so jurisdictions first then city cpas and county cpas
total <- total[order(total$ds_id,total$id,total$yr_id),]

geoletter <- toupper(letters[grep("nameid", colnames(total))])

unitletter <- toupper(letters[grep("unit_format_id", colnames(total))])
unit_highlight <- paste0('$',unitletter,'1==2')
unit_column <- grep("units", colnames(total))

hhletter <- toupper(letters[grep("hh_format_id", colnames(total))])
hh_highlight <- paste0('$',hhletter,'1==2')
hh_column <- grep("households", colnames(total))

hhpletter <- toupper(letters[grep("hhpop_format_id", colnames(total))])
hhp_highlight <- paste0('$',hhpletter,'1==2')
hhp_column <- grep("household population", colnames(total))

hhsletter <- toupper(letters[grep("hhs_format_id", colnames(total))])
hhs_highlight <- paste0('$',hhsletter,'1==2')
hhs_column <- grep("household size", colnames(total))

invisible_unit_id <- grep("unit_format_id", colnames(total))
invisible_hh_id <-grep("hh_format_id", colnames(total))
invisible_hhpop_id <-grep("hhpop_format_id", colnames(total))
invisible_hhs_id <-grep("hhs_format_id", colnames(total))

                                      
t <- total %>% group_by(name) %>% tally()
if (nrow(subset(t,n!=9))!=0) {
  print("ERROR: expecting 9 years per geography")
  print(subset(t,n!=9)) } 

ids <- rep(1:2, times=nrow(t)/2, each=9)
if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
total$nameid <- ids

invisible_nameid <-grep("nameid", colnames(total))
geoletter <- toupper(letters[grep("nameid", colnames(total))])
geography_highlight1 <- paste0('$',geoletter,'1==1')
geography_highlight2 <- paste0('$',geoletter,'1==2')

# styles for excel
lightgreyStyle <- createStyle(bgFill = "#dce6f1")
darkgreyStyle <- createStyle(bgFill = "#c5d9f1") # "#e3e3e1" #c5d9f1 #b8cce4
unithighlightcolor <- createStyle(bgFill = "#e67300") # #ffff99
hhhighlightcolor <- createStyle(bgFill = "#e6ac00") # #ffff99
hhphighlightcolor <- createStyle(bgFill = "#e6e600") # #ffff99
hhshighlightcolor <- createStyle(bgFill = "#e6e600") # #ffff99
headerStyle <- createStyle(fontSize = 13, fontColour = "#FFFFFF", halign = "center",
                           fgFill = "#4F81BD", border="TopBottom", borderColour = "#4F81BD",
                           wrapText = TRUE)
aligncenter = createStyle(halign = "center")

invisibleStyle <- createStyle(fontColour = "#FFFFFF")
insideBorders <- openxlsx::createStyle(border = c("top", "bottom", "left", "right"),borderStyle = "dashed",borderColour="white")
outsideBorders <- openxlsx::createStyle(border = c("top", "bottom", "left", "right"),borderColour="black")

# rows and column range
rangeRows = 1:(nrow(total)+1)
rangeCols = 1:(ncol(total)-5)

# create excel workbook
wb = createWorkbook()
# add worksheet to workbook
units_hh_hhp = addWorksheet(wb, "units_hh_hhp", tabColour = "blue")
# write dataframe to worksheet
writeData(wb, units_hh_hhp,total)

# highlight every other geography
conditionalFormatting(wb, units_hh_hhp, cols=rangeCols, rows=rangeRows, rule=geography_highlight1, style = darkgreyStyle)
conditionalFormatting(wb, units_hh_hhp, cols=rangeCols, rows=rangeRows, rule=geography_highlight2, style = lightgreyStyle)
# highlight units,households,hhpop that stay the same
conditionalFormatting(wb, units_hh_hhp, cols=unit_column, rows=rangeRows, rule=unit_highlight, style = unithighlightcolor)
conditionalFormatting(wb, units_hh_hhp, cols=hh_column, rows=rangeRows, rule=hh_highlight, style = hhhighlightcolor)
conditionalFormatting(wb, units_hh_hhp, cols=hhp_column, rows=rangeRows, rule=hhp_highlight, style = hhphighlightcolor)
conditionalFormatting(wb, units_hh_hhp, cols=hhs_column, rows=rangeRows, rule=hhs_highlight, style = hhshighlightcolor)

addStyle(wb = wb,sheet = units_hh_hhp,style = insideBorders,rows=rangeRows,cols=rangeCols,gridExpand = TRUE,stack = TRUE)


total$rnum<-1:dim(total)[1]
total%>%group_by(name)%>%summarise(min=min(rnum)+1,max=max(rnum)+1)->box_lm
box_lm<-as.data.frame(box_lm)

for(i in seq_along(box_lm[,"name"])){
   box_lm%>%filter(name %in% box_lm[i,"name"]) %>%
   select(min,max)->minmax_lm
   rangeRows2<-minmax_lm$min:minmax_lm$max
      
   ## left units_hh_hhp
   openxlsx::addStyle(
     wb = wb,
     sheet = "units_hh_hhp",
     style = openxlsx::createStyle(
       border = c("left"),
       borderStyle = c("thick")
     ),
     rows = rangeRows2,
     cols = rangeCols[1],
     stack = TRUE,
     gridExpand = TRUE
   )
   
   ##right units_hh_hhp
   openxlsx::addStyle(
     wb = wb,
     sheet = "units_hh_hhp",
     style = openxlsx::createStyle(
       border = c("right"),
       borderStyle = c("thick")
     ),
     rows = rangeRows2,
     cols = tail(rangeCols, 1),
     stack = TRUE,
     gridExpand = TRUE
   )
   
   ## top units_hh_hhp
   openxlsx::addStyle(
     wb = wb,
     sheet = "units_hh_hhp",
     style = openxlsx::createStyle(
       border = c("top"),
       borderStyle = c("thick")
     ),
     rows = rangeRows2[1],
     cols = rangeCols,
     stack = TRUE,
     gridExpand = TRUE
   )
   
   ##bottom units_hh_hhp
   openxlsx::addStyle(
     wb = wb,
     sheet = "units_hh_hhp",
     style = openxlsx::createStyle(
       border = c("bottom"),
       borderStyle = c("thick")
     ),
     rows = tail(rangeRows2, 1),
     cols = rangeCols,
     stack = TRUE,
     gridExpand = TRUE
   )
}
   
# make format rows invisible - white text
addStyle(wb = wb,sheet = units_hh_hhp,style=invisibleStyle, rows=rangeRows,cols=invisible_unit_id,gridExpand = TRUE,stack = TRUE)
addStyle(wb = wb,sheet = units_hh_hhp,style=invisibleStyle, rows=rangeRows,cols=invisible_hh_id,gridExpand = TRUE,stack = TRUE)
addStyle(wb = wb,sheet = units_hh_hhp,style=invisibleStyle, rows=rangeRows,cols=invisible_hhpop_id,gridExpand = TRUE,stack = TRUE)
addStyle(wb = wb,sheet = units_hh_hhp,style=invisibleStyle, rows=rangeRows,cols=invisible_hhs_id,gridExpand = TRUE,stack = TRUE)

addStyle(wb = wb,sheet = units_hh_hhp,style=invisibleStyle, rows=rangeRows,cols=invisible_nameid,gridExpand = TRUE,stack = TRUE)
# add header style
addStyle(wb = wb,sheet = units_hh_hhp,style=headerStyle, rows = 1, cols = rangeCols, gridExpand = TRUE,stack = TRUE)

# align center
addStyle(wb = wb,sheet = units_hh_hhp,style=aligncenter,rows=rangeRows,cols=rangeCols, gridExpand=TRUE,stack = TRUE)
# set column widths
setColWidths(wb, units_hh_hhp, cols = c(1,2,3,4,5,6,7,8), widths = c(29,12,8,16,12,14,22,16))

# excel workbook with results
saveWorkbook(wb, excelfile,overwrite=TRUE)

# the jurisdictions and cpas that don't change over time as comma sep list
allfrozen <- sort(allfrozen)
cat(paste(shQuote(allfrozen, type="cmd"), collapse=", "))
