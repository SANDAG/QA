#hhinc by category plots

datasource_id=35

pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice")
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

#change all factors to character for ease of coding
options(stringsAsFactors=FALSE)


channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/Household Income (HHINC).sql")
hh_sql <- gsub("ds_id", datasource_id, hh_sql)
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

#strip extra characters from cpa names
hh$geozone[hh$geotype =="region"]<- "Region"
hh$geozone <- gsub("\\*","",hh$geozone)
hh$geozone <- gsub("\\-","_",hh$geozone)
hh$geozone <- gsub("\\:","_",hh$geozone)


# 
# # rename San Diego region to 'San Diego Region' and then aggregate
# levels(hh$geozone) <- c(levels(hh$geozone), "San Diego Region")
# hh$geozone[hh$geotype=='region'] <- 'San Diego Region'
# sd = subset(hh,geozone=='San Diego')
# sd2 = subset(hh,geozone=='San Diego Region')
# #write.csv(sd,'cityofsandiego.csv')
# #write.csv(sd2,'regionofsandiego.csv')

Geo_totals<-aggregate(hh~yr_id+geozone, data=hh, sum)
hh$tot_pop<-Geo_totals[match(paste(hh$yr_id, hh$geozone),paste(Geo_totals$yr_id, Geo_totals$geozone)),3]
hh$tot_pop[hh$tot_pop==0] <- NA
hh$percent_income = hh$hh/hh$tot_pop * 100
#write.csv(Geo_totals,'geototals.csv')

# specify order of levels for plotting
hh$name <- factor(hh$name, levels = c("Less than $15,000", 
                                      "$15,000 to $29,999", 
                                      "$30,000 to $44,999",
                                      "$45,000 to $59,999",
                                      "$60,000 to $74,999",
                                      "$75,000 to $99,999",
                                      "$100,000 to $124,999",
                                      "$125,000 to $149,999",
                                      "$150,000 to $199,999",
                                      "$200,000 or more"))

hh$income_id2 <-ifelse(hh$income_group_id>=11 &hh$income_group_id<=12, '1',
                       ifelse(hh$income_group_id>=13 &hh$income_group_id<=14, '2',
                              ifelse(hh$income_group_id>=15 &hh$income_group_id<=16, '3',
                                     ifelse(hh$income_group_id>=17 &hh$income_group_id<=18, '4',
                                            ifelse(hh$income_group_id>=19 &hh$income_group_id<=20, '5', NA)))))


hh$name2[hh$income_id2=="1"]<- "Less than $30,000"
hh$name2[hh$income_id2=="2"]<- "$30,000 to $59,999"
hh$name2[hh$income_id2=="3"]<- "$60,000 to $99,999"
hh$name2[hh$income_id2=="4"]<- "$100,000 to $149,999"
hh$name2[hh$income_id2=="5"]<- "$150,000 or more"

hh$name2<- as.factor(hh$name2)

hh$name2<- factor(hh$name2, levels = c("Less than $30,000",
                                       "$30,000 to $59,999","$60,000 to $99,999", "$100,000 to $149,999", "$150,000 or more"))


Cat_agg<-aggregate(hh~yr_id+geozone+name2+geotype+income_id2, data=hh, sum)
Cat_agg$tot_pop<-Geo_totals[match(paste(Cat_agg$yr_id, Cat_agg$geozone),paste(Geo_totals$yr_id, Geo_totals$geozone)),3]
Cat_agg$tot_pop[Cat_agg$tot_pop==0] <- NA
Cat_agg$percent_income = Cat_agg$hh/Cat_agg$tot_pop * 100
Cat_agg$percent_income = round(Cat_agg$percent_income, digits = 1)
                               

Cat_agg$year<- "y"
Cat_agg$yr <- as.factor(paste(Cat_agg$year, Cat_agg$yr, sep = ""))


hh_jur = subset(Cat_agg,geotype=='jurisdiction')

hh_cpa = subset(Cat_agg,geotype=='cpa')

hh_region = subset(Cat_agg,geotype=='region')


colours = c('#ffeda0','#fd8d3c','#bd0026','#800026','#561B07')

#Region plot and table
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hhinc\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

plotdat = hh_region
plot<-ggplot(hh_region,aes(x=yr_id, y=percent_income, colour=name2)) +
  geom_line(size=1)+ geom_point(size=3, aes(colour=name2))  +
  scale_y_continuous(label=comma,limits=c(0.0,41.0))+ 
  labs(title=paste("Household Income: Proportion of Households by Category ds_id= ", datasource_id, '\n Region',sep=''), 
       y="Proportion of Households", x="Year",
       caption="Sources: demographic warehouse: fact.household_income
         \nNote:Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
  scale_colour_manual(values=colours) +
  #sp+scale_colour_manual(values=cbp1) +
  theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
  #theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9))
#ggsave(plot, file= paste(results, '2_hhinc',datasource_id,".png", sep=''))#, scale=2)
output_table<-data.frame(plotdat$yr_id,plotdat$tot_pop,plotdat$name2,plotdat$percent_income)
output_table <- dcast(output_table,plotdat.yr_id+plotdat.tot_pop~plotdat.name2,value.var = "plotdat.percent_income")
setnames(output_table, old=c("plotdat.yr_id","plotdat.tot_pop"),new=c("Increment","Tot HH"))
tt <- ttheme_default(base_size=9)
tbl <- tableGrob(output_table, rows=NULL, theme=tt)
lay <- rbind(c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(2,2,2,2,2),
             c(2,2,2,2,2))
output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
ggsave(output, file= paste(results, 'hhinc region',datasource_id, ".png", sep=''))#, scale=2)


##jurisdiction plots

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hhinc\\jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

jur_list<- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)
jur_list2<- c("Carlsbad","Chula Vista","Coronado","Del Mar","El Cajon","Encinitas","Escondido","Imperial Beach","La Mesa","Lemon Grove",
              "National City","Oceanside","Poway","San Diego","San Marcos","Santee","Solana Beach","Vista","Unincorporated")


citynames <- data.frame(jur_list, jur_list2)
hh_jur$jurisdiction_id<-citynames[match(hh_jur$geozone, citynames$jur_list2),1]

head(hh_jur)

for(i in 1:length(jur_list)){
  plotdat = subset(hh_jur, hh_jur$jurisdiction_id==jur_list[i])
  plot<-ggplot(plotdat,aes(x=yr_id, y=percent_income, colour=name2)) +
  geom_line(size=1) +
  geom_point(size=3, aes(colour=name2))  +
  scale_y_continuous(label=comma,limits=c(0.0,41.0))+ 
  labs(title=paste(jur_list2[i],"\nHousehold Income: Proportion of Households by Category\n datasource_id ",datasource_id,sep=''), 
       y="Proportion of Households", x="Year",
       caption="Sources: demographic warehouse: fact.household_income
         \nNote: Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
  scale_colour_manual(values=colours) +
  #sp+scale_colour_manual(values=cbp1) +
  theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
  #theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9))
  #ggsave(plot, file= paste(results, '2_hhinc',datasource_id,".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$name2,plotdat$tot_pop,plotdat$percent_income)
  output_table <- dcast(output_table,plotdat.yr_id+plotdat.tot_pop~plotdat.name2,value.var = "plotdat.percent_income")
  setnames(output_table, old=c("plotdat.yr_id","plotdat.tot_pop"),new=c("Increment","Tot HH"))
  tt <- ttheme_default(base_size=9)
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(1,1,1,1,1),
             c(2,2,2,2,2),
             c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'hhinc_', jur_list2[i],datasource_id, ".png", sep=''))#, scale=2)
}



##cpa plots

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\hhinc\\cpa\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

cpa_list = unique(hh_cpa[["geozone"]])
head(hh_cpa)

for(i in 1:length(cpa_list)){
  plotdat = subset(hh_cpa, hh_cpa$geozone==cpa_list[i])
  plot<-ggplot(plotdat,aes(x=yr_id, y=percent_income, colour=name2)) +
    geom_line(size=1) +
    geom_point(size=3, aes(colour=name2))  +
    scale_y_continuous(label=comma,limits=c(0.0,41.0))+ 
    labs(title=paste(cpa_list[i],"\nHousehold Income: Proportion of Households by Category\n datasource id ", datasource_id,sep=''), 
         y="Proportion of Households", x="Year",
         caption="Sources: demographic warehouse: fact.household_income
         \nNote: Out of range data may not appear on the plot. Refer to the table below for those related data results.") +
    scale_colour_manual(values=colours) +
    #sp+scale_colour_manual(values=cbp1) +
    theme_bw(base_size = 12) +  theme(plot.title = element_text(hjust = 0.5)) +
    #theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 9))
  #ggsave(plot, file= paste(results, '2_hhinc',datasource_id,".png", sep=''))#, scale=2)
  output_table<-data.frame(plotdat$yr_id,plotdat$name2,plotdat$tot_pop,plotdat$percent_income)
  output_table <- dcast(output_table,plotdat.yr_id+plotdat.tot_pop~plotdat.name2,value.var = "plotdat.percent_income")
  setnames(output_table, old=c("plotdat.yr_id","plotdat.tot_pop"),new=c("Increment","Tot HH"))
  tt <- ttheme_default(base_size=9)
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'hhinc_', cpa_list[i],datasource_id, ".png", sep=''))#, scale=2)
}



