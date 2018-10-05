pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice","tidyr")
pkgTest(packages)

# install.packages("tidyr")
# library(tidyr)
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))


#SOURCE ID 14 files


Income14_2016<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_0\\input\\2016\\households.csv", stringsAsFactors = FALSE)
Income14_2020<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_0\\input\\2020\\households.csv", stringsAsFactors = FALSE)
Income14_2025<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_0\\input\\2025\\households.csv", stringsAsFactors = FALSE)
Income14_2035<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_0\\input\\2035\\households.csv", stringsAsFactors = FALSE)
Income14_2050<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_0\\input\\2050\\households.csv", stringsAsFactors = FALSE)

geography<-read.csv("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\GEO for DCO.csv", stringsAsFactors = FALSE)
# setnames(geography, old=c("?..mgra"),new=c("mgra"))

setnames(geography, old=c("ï..mgra"),new=c("mgra"))


Income14_2016$yr = 2016
Income14_2020$yr = 2020
Income14_2025$yr = 2025
Income14_2035$yr = 2035
Income14_2050$yr = 2050


Income14<-rbind(Income14_2016,Income14_2020,Income14_2025,Income14_2035,Income14_2050)

Income14$POP_14<- 1

head(Income14)
head(geography)

income14_agg<-aggregate(POP_14~yr+MGRA+hinccat1+unittype, data=Income14, sum)


#SOURCE ID 17 files

Income17_2016<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2016\\households.csv", stringsAsFactors = FALSE)
Income17_2020<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2020\\households.csv", stringsAsFactors = FALSE)
Income17_2025<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2025\\households.csv", stringsAsFactors = FALSE)
Income17_2035<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2035\\households.csv", stringsAsFactors = FALSE)
Income17_2050<-read.csv("T:\\ABM\\release\\ABM\\version_14_0_1\\input\\2050\\households.csv", stringsAsFactors = FALSE)

Income17_2016$yr = 2016
Income17_2020$yr = 2020
Income17_2025$yr = 2025
Income17_2035$yr = 2035
Income17_2050$yr = 2050

Income17<-rbind(Income17_2016,Income17_2020,Income17_2025,Income17_2035,Income17_2050)

head(Income17)
Income17$POP_17<- 1

income17_agg<-aggregate(POP_17~yr+MGRA+hinccat1 + unittype, data=Income17, sum)

head(income17_agg)

INCOME <- merge(income14_agg, income17_agg, by.a=c("MGRA","yr","hinccat1"), by.b=c("MGRA","yr","hinccat1"), all=TRUE)


rm(Income17_2016, Income17_2020, Income17_2025, Income17_2035 ,Income17_2050,Income14_2016, Income14_2020, Income14_2025, Income14_2035 ,Income14_2050)


#Merge in geography

income_Geo <- merge(INCOME, geography, by.x="MGRA",by.y="mgra", all=TRUE)

rm(INCOME, Income17, Income14, income17_agg ,income14_agg)


###Here is where I save the files by geography for graphing. I don't know how to incorporate the loop for the ggplots

Income_CPA<- aggregate(cbind(POP_17, POP_14)~yr+cpa_id+hinccat1+cpa + unittype , data=income_Geo, sum)
Income_Jur<- aggregate(cbind(POP_17, POP_14)~yr+jurisdiction_id+hinccat1+jurisdiction + unittype , data=income_Geo, sum)

Income_CPA$inc_cat[Income_CPA$hinccat1=="1"]<- "Less than $30,000"
Income_CPA$inc_cat[Income_CPA$hinccat1=="2"]<- "$30,000 to $59,999"
Income_CPA$inc_cat[Income_CPA$hinccat1=="3"]<- "$60,000 to $99,999"
Income_CPA$inc_cat[Income_CPA$hinccat1=="4"]<- "$100,000 to $149,999"
Income_CPA$inc_cat[Income_CPA$hinccat1=="5"]<- "$150,000 or more"

Income_Jur$inc_cat[Income_Jur$hinccat1=="1"]<- "Less than $30,000"
Income_Jur$inc_cat[Income_Jur$hinccat1=="2"]<- "$30,000 to $59,999"
Income_Jur$inc_cat[Income_Jur$hinccat1=="3"]<- "$60,000 to $99,999"
Income_Jur$inc_cat[Income_Jur$hinccat1=="4"]<- "$100,000 to $149,999"
Income_Jur$inc_cat[Income_Jur$hinccat1=="5"]<- "$150,000 or more"

# write.csv(Income_Jur,'income_jur_datasource_14_and_17.csv')

jur_list = unique(Income_Jur[["jurisdiction"]])
maindir = dirname(rstudioapi::getSourceEditorContext()$path)

results<-"plots\\Household Income Comparison\\Jur\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in jur_list) {
  plotdat = subset(Income_Jur,Income_Jur$jurisdiction==i)
  plotd <- plotdat %>% gather(datasource, POP, POP_17:POP_14)
  plot <- ggplot(plotd, aes(x=yr, y=POP,group=datasource)) + geom_point(aes(color=datasource)) +
    facet_grid(hinccat1 ~ unittype,scales="free_y") + geom_line(aes(color=datasource),size=1) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste(i,": Pop by 5 Income Categories\n (unit type 0 and 1)",sep=''))
  #plot
  ggsave(plot, file= paste(results,i, '_datasource_14_17_income', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
}

cpa_list = unique(Income_CPA[["cpa"]])
results<-"plots\\Household Income Comparison\\CPA\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

for(i in cpa_list) {
  plotdat = subset(Income_CPA,Income_CPA$cpa==i)
  plotd <- plotdat %>% gather(datasource, POP, POP_17:POP_14)
  plot <- ggplot(plotd, aes(x=yr, y=POP,group=datasource)) + geom_point(aes(color=datasource)) +
    facet_grid(hinccat1 ~ unittype,scales="free_y") + geom_line(aes(color=datasource),size=1) + 
    theme(plot.title = element_text(hjust = 0.5,size=16)) + 
    labs(title=paste(i,": Pop by 5 Income Categories\n (unit type 0 and 1)",sep=''))
  #plot
  i = gsub("\\*","",i)
  i = gsub("\\-","_",i)
  i = gsub("\\:","_",i)
  ggsave(plot, file= paste(results,i, '_datasource_14_17_income', ".png", sep=''),
         width=10, height=6, dpi=100)#, scale=2)
}



