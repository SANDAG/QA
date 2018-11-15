
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","cowplot","gtable")
       
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

maindir = dirname(rstudioapi::getSourceEditorContext()$path)

source("../Queries/readSQL.R")

datasource_ids = c(13,14,17,19)

hh <- data.frame()

for(ds_id in datasource_ids) {
  channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
  hh_sql = getSQL("../Queries/hh_hhp_hhs_ds_id.sql")
  hh_sql <- gsub("ds_id", ds_id,hh_sql)
  hhquery<-sqlQuery(channel,hh_sql,stringsAsFactors = FALSE)
  hhquery$datasource_id = ds_id
  hh <- rbind(hh,hhquery)
  odbcClose(channel)
}


hh$geozone[hh$geotype =="region"]<- "~Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)

colnames(hh)[colnames(hh)=="yr_id"] <- "Year"
hh$datasource_id = factor( hh$datasource_id) 


# jursidiction plots

hh_jur<-subset(hh, geotype=="jurisdiction")

jur_list = unique(hh_jur[["geozone"]])

results<-"plots\\hh_variable_comparison\\PopvsHH\\"

ifelse(!dir.exists(file.path(maindir,results)), 
       dir.create(file.path(maindir,results), 
                  showWarnings = TRUE, recursive=TRUE),0)

for(i in jur_list) {
  plotdat <- subset(hh,geozone==i & datasource_id %in% c(14,19))
  gg <- ggplot(data=plotdat, aes(x=Num_Households, y=Household_Pop)) + 
    geom_point(aes(col=datasource_id,size=Persons_per_Household)) + geom_line(aes(col=datasource_id)) +
    labs(subtitle="Household Population vs Number of Households", 
         y="Household Population", 
         x="Number of Households", 
         title=i, 
         caption = paste("Source: Demographic Warehouse Datsource id=", 
                         toString(unique(plotdat$datasource_id),sep=''))) 
  ggsave(gg, file=paste(results,i,"_hhpop",
                        gsub(", ","_",toString(unique(plotdat$datasource_id))),".png",sep=""),
         width=12,height=8,dpi=100)
  output_table = plotdat[,c("Year","Num_Households","Household_Pop","Persons_per_Household","datasource_id")]
  output_table13 = subset(output_table,datasource_id==13)
  output_table13$datasource_id <- NULL
  output_table19 = subset(output_table,datasource_id==19)
  output_table19$datasource_id <- NULL
  outtbl = merge(output_table13,output_table19,by='Year',all=TRUE,suffixes = c("(13)","(19)"))
  outtbl <- outtbl[c(1, 2, 5, 3,  6, 4, 7)] # reorder columns
  t1 = gridExtra::tableGrob(outtbl)
  title <- textGrob(i,gp=gpar(fontsize=50))
  padding <- unit(5,"mm")
  table <- gtable_add_rows(
    t1, 
    heights = grobHeight(title) + padding,
    pos = 0)
  table <- gtable_add_grob(
    table, 
    title, 
    1, 1, 1, ncol(table))
  h = grid::convertHeight(sum(table$heights), "in", TRUE)
  w = grid::convertWidth(sum(table$widths), "in", TRUE)
  
  ggplot2::ggsave(file= paste(results, i, 'data', ".png", sep=''), table, width=w, height=h)
  
}
  
 