#base year persons 2016 id28 to id27


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}

packages <- c("sqldf", "rstudioapi", "RODBC", "tidyverse", "magrittr", "reshape", "data.table")
pkgTest(packages)


setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

options(stringsAsFactors=FALSE)
options(scipen=999)

#read in persons files for 2016 id27 and id28
persons_i28<-read.csv('T:\\socioec\\Current_Projects\\XPEF11\\abm_csv\\persons_2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")
persons_i27<-read.csv('T:\\socioec\\Current_Projects\\XPEF10\\abm_csv\\persons_2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")

#calculate age summary
summary(persons_i27$age)
summary(persons_i28$age)


#select and group by demographic variables from persons file
persons_i27 %<>% select(hhid, sex, miltary, pemploy, pstudent, ptype, educ, grade, weeks, hours, rac1p, hisp)
persons_i28 %<>% select(hhid, sex, miltary, pemploy, pstudent, ptype, educ, grade, weeks, hours, rac1p, hisp)

#melt persons(id27) file
persons_i27m<-melt(persons_i27, id.vars=c("hhid"))
persons_i28m<-melt(persons_i28, id.vars=c("hhid"))

#count records
persons_i27_tot  <- persons_i27m %>% group_by(variable,value) %>% tally()
persons_i28_tot  <- persons_i28m %>% group_by(variable,value) %>% tally()


#merge two files for comparison
persons_16s<-merge(persons_i28_tot, persons_i27_tot, by=c("variable", "value"))

#rename a variable
setnames(persons_16s, old="n.x",new="value_id28")
setnames(persons_16s, old="n.y",new="value_id27")

#calculate difference from id28 to id27 for each variable
persons_16s$diff<-persons_16s$value_id28-persons_16s$value_id27

#calculate the difference summary
summary(persons_16s$diff)

#save output
write.csv(persons_16s, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\persons_28_27 v2.csv",row.names = FALSE )

#sum variables
persons_16s_sum <- persons_16s %>%  group_by(variable) %>%
summarise(sum_id28 = sum(value_id28), sum_id27 = sum(value_id27,na.rm=TRUE),diff = sum(diff,na.rm=TRUE))

#save output
write.csv(persons_16s_sum, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\persons_28_27_sum v2.csv",row.names = FALSE )

