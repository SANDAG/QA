#Load dimension tables for common SANDAG geographies in prep for PowerBI visualization

#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

#retreive tables using sql code
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra_id]
                  ,[mgra]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  GROUP BY [mgra_id]
                         ,[mgra]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

d_zip <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [zip]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  GROUP BY [zip]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

d_cpa <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [cpa]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  GROUP BY [cpa]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

d_jurisdiction <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [jurisdiction]
                  FROM [demographic_warehouse].[dim].[mgra_denormalize]
                  GROUP BY [jurisdiction]"),
                  stringsAsFactors = FALSE),
  stringsAsFactors = FALSE)

#save out tables
wb= createWorkbook()

mgra <- addWorksheet(wb, "mgra")
writeData(wb,mgra, d_mgra)
cpa <- addWorksheet(wb, "cpa")
writeData(wb,cpa, d_cpa)
zip <- addWorksheet(wb, "zip")
writeData(wb,zip, d_zip)
jur <- addWorksheet(wb, "jurisdiction")
writeData(wb,jur, d_jurisdiction)


outputfile <- paste("dimension",".xlsx",sep='')
outfolder<-paste("dimension/",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)

outfile <- "../output"
print(paste("output filepath: ",outfile))

saveWorkbook(wb, outfile,overwrite=TRUE)
