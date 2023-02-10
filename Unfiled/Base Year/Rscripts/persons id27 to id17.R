#base year persons 2016 EDAM to old 2016 ABM comparison


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

#read in mgra files for 2016 and 2012
persons_i27<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\abm_csv\\persons_2016_01.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")
persons_i17<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\abm_csv_2016 from xpef06 (id17)\\persons.csv',stringsAsFactors = FALSE ,fileEncoding="UTF-8-BOM")


#select and group by demographic variables from persons file
persons_i27 %<>% select(hhid, sex, miltary, pemploy, pstudent, ptype, educ, grade, weeks, hours, rac1p, hisp)
persons_i17 %<>% select(hhid, sex, miltary, pemploy, pstudent, ptype, educ, grade, weeks, hours, rac1p, hisp)

#melt persons(id27) file
persons_i27m<-melt(persons_i27, id.vars=c("hhid"))
persons_i17m<-melt(persons_i17, id.vars=c("hhid"))

#count records
persons_i27_tot  <- persons_i27m %>% group_by(variable,value) %>% tally()
persons_i17_tot  <- persons_i17m %>% group_by(variable,value) %>% tally()

#calculate age summary
summary(persons_i27$age)
summary(persons_i17$age)

#merge two files for comparison
persons_16s<-merge(persons_i27_tot, persons_i17_tot, by=c("variable", "value"))

#rename a variable
setnames(persons_16s, old="n.x",new="value_id27")
setnames(persons_16s, old="n.y",new="value_id17")

#calculate difference from new 2016 to 2012 for each variable
persons_16s$diff<-persons_16s$value_id27-persons_16s$value_id17

#calculate the difference summary
summary(persons_16s$diff)

#save output
write.csv(persons_16s, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\persons_16s.csv",row.names = FALSE )

#sum variables
persons_16s_sum <- persons_16s %>%  group_by(variable) %>%
summarise(sum_id27 = sum(value_id27), sum_id17 = sum(value_id17,na.rm=TRUE),diff = sum(diff,na.rm=TRUE))

#save output
write.csv(persons_16s_sum, "M:\\Technical Services\\QA Documents\\Projects\\Base Year_Popsyn\\4_Data Files\\ouput files\\persons_16s_sum.csv",row.names = FALSE )





# #extra code (unused)
# #aggregate three variables at once
# mgra_17_27<-aggregate(cbind(value_id27,value_id17,diff)~variable, data=mgra_16s, sum)
# #subset a file
# mgra_17_27 <- subset(mgra_17_27, mgra_17_27$diff!=0)
# #view top rows
# head(school_summary)