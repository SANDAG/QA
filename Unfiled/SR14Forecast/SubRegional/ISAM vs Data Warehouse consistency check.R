pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
  }

packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)
channel <- odbcConnect("r_connection")


isam_HH <-sqlQuery(channel,"SELECT yr
                   ,COUNT(sex) as sex_count_hh
                   ,COUNT(CASE WHEN sex = 'F' THEN sex  END) as female_hh
                   ,COUNT(CASE WHEN sex = 'M' THEN sex  END) as male_HH
                   ,COUNT(sex) - (COUNT(CASE WHEN sex = 'F' THEN sex  END) + COUNT(CASE WHEN sex = 'M' THEN sex  END)) as diff
                   FROM isam.xpef03.household_population
                   GROUP BY yr 
                   ORDER BY yr DESC, sex_count_hh DESC")


isam_GQ <-sqlQuery(channel,"SELECT yr
                   ,COUNT(sex) as sex_count_gq
                   ,COUNT(CASE WHEN sex = 'F' THEN sex  END) as female_gq
                   ,COUNT(CASE WHEN sex = 'M' THEN sex  END) as male_gq
                   ,COUNT(sex) - (COUNT(CASE WHEN sex = 'F' THEN sex  END) + COUNT(CASE WHEN sex = 'M' THEN sex  END)) as diff_gq
                   FROM isam.xpef03.gq_population
                   GROUP BY yr 
                   ORDER BY yr DESC, sex_count_gq DESC")

isam_tot_gender <- merge(isam_HH, isam_GQ, by.a="yr", by.b="yr", all=TRUE)

isam_tot_gender$isam_tot_pop<-isam_tot_gender$sex_count_hh+isam_tot_gender$sex_count_gq

colnames(isam_tot_gender)
isam_tot_gender$female_tot<- isam_tot_gender$female_hh + isam_tot_gender$female_gq
isam_tot_gender$male_tot<- isam_tot_gender$male_HH + isam_tot_gender$male_gq

summary(isam_HH$sex_count_hh)
summary(isam_GQ$sex_count_gq)
summary(isam_tot_gender$isam_tot_pop)


#####
#make race
isam_HH_race <-sqlQuery(channel,"SELECT [yr]     
                        ,CASE 
                        WHEN [hisp] = 'H' THEN [hisp]
                        ELSE [r]
                        END AS [r]
                        ,COUNT([yr]) as race_hh
                        FROM isam.xpef02.household_population
                        GROUP BY [yr], 
                        CASE 
                        WHEN [hisp] = 'H' THEN [hisp]
                        ELSE [r]
                        END
                        ORDER BY [yr] desc, [r]") 

#make race
isam_GQ_race <-sqlQuery(channel,"SELECT [yr]     
                        ,CASE 
                        WHEN [hisp] = 'H' THEN [hisp]
                        ELSE [r]
                        END AS [r]
                        ,COUNT([yr]) as race_gq
                        FROM [isam].[xpef02].[gq_population]
                        GROUP BY [yr], 
                        CASE 
                        WHEN [hisp] = 'H' THEN [hisp]
                        ELSE [r]
                        END
                        ORDER BY [yr] desc, [r]") 


isam_tot_race <- merge(isam_HH_race, isam_GQ_race, by.a="yr", by.b="yr", all=TRUE)


isam_tot_race$isam_tot_pop <- isam_tot_race$race_hh + isam_tot_race$race_gq

table(isam_tot_race$r)

isam_tot_race$r <- factor(isam_tot_race$r, levels=c('R10','R02','R03','R04','R05','R07','H', 'R06'),
                          labels = c('White', 'Black', 'Amer Ind/Alaska Nat', 
                                     'Asian', 'Pac Isl','Multi Race', 'Hispanic', 'Other'))




#make age

isam_age_hh<- sqlQuery(channel, "SELECT yr
                       ,COUNT(age) as age_count_hh
                       ,COUNT(CASE WHEN age = 0 THEN age END) as age_0
                       ,COUNT(CASE WHEN age>=1 AND age<=4 THEN age END) as age_1
                       ,COUNT(CASE WHEN age>=5 AND age<=9 THEN age END) as age_2
                       ,COUNT(CASE WHEN age>=10 AND age<=14 THEN age END) as age_3
                       ,COUNT(CASE WHEN age>=15 AND age<=19 THEN age END) as age_4
                       ,COUNT(CASE WHEN age>=20 AND age<=24 THEN age END) as age_5
                       ,COUNT(CASE WHEN age>=25 AND age<=29 THEN age END) as age_6
                       ,COUNT(CASE WHEN age>=30 AND age<=34 THEN age END) as age_7
                       ,COUNT(CASE WHEN age>=35 AND age<=39 THEN age END) as age_8
                       ,COUNT(CASE WHEN age>=40 AND age<=44 THEN age END) as age_9
                       ,COUNT(CASE WHEN age>=45 AND age<=49 THEN age END) as age_10
                       ,COUNT(CASE WHEN age>=50 AND age<=54 THEN age END) as age_11
                       ,COUNT(CASE WHEN age>=55 AND age<=59 THEN age END) as age_12
                       ,COUNT(CASE WHEN age>=60 AND age<=64 THEN age END) as age_13
                       ,COUNT(CASE WHEN age>=65 AND age<=69 THEN age END) as age_14
                       ,COUNT(CASE WHEN age>=70 AND age<=74 THEN age END) as age_15
                       ,COUNT(CASE WHEN age>=75 AND age<=79 THEN age END) as age_16
                       ,COUNT(CASE WHEN age>=80 AND age<=84 THEN age END) as age_17
                       ,COUNT(CASE WHEN age>=85 AND age<=89 THEN age END) as age_18
                       ,COUNT(CASE WHEN age>=90 AND age<=94 THEN age END) as age_19
                       ,COUNT(CASE WHEN age>=95 AND age<=99 THEN age END) as age_20
                       ,COUNT(CASE WHEN age>=100 THEN age END) as age_21
                       FROM isam.xpef02.household_population
                       GROUP BY yr 
                       ORDER BY yr DESC, age_count_hh DESC")

isam_age_hh<-melt(isam_age_hh, id.vars=c("yr"))

TYPE_DELETE_hh<-c("age_count_hh")
isam_age_hh<-isam_age_hh[!(isam_age_hh$variable %in% TYPE_DELETE_hh),]

colnames(isam_age_hh)[colnames(isam_age_hh)=="value"] <- "isam_hh_age_pop"

isam_age_hh$variable<- substr(isam_age_hh$variable, start=5, stop=6)

isam_age_hh$Age.Group<- as.factor(isam_age_hh$variable)

isam_age_hh$Age.Group<-factor(isam_age_hh$Age.Group, levels= c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21),
                              labels = c("0","1-4","5-9","10-14","15-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59",
                                         "60-64","65-69","70-74","75-79","80-84","85-89","90-94","95-99","100+"))

isam_age_gq<- sqlQuery(channel, "SELECT yr
                       ,COUNT(age) as age_count_gq
                       ,COUNT(CASE WHEN age = 0 THEN age END) as age_0
                       ,COUNT(CASE WHEN age>=1 AND age<=4 THEN age END) as age_1
                       ,COUNT(CASE WHEN age>=5 AND age<=9 THEN age END) as age_2
                       ,COUNT(CASE WHEN age>=10 AND age<=14 THEN age END) as age_3
                       ,COUNT(CASE WHEN age>=15 AND age<=19 THEN age END) as age_4
                       ,COUNT(CASE WHEN age>=20 AND age<=24 THEN age END) as age_5
                       ,COUNT(CASE WHEN age>=25 AND age<=29 THEN age END) as age_6
                       ,COUNT(CASE WHEN age>=30 AND age<=34 THEN age END) as age_7
                       ,COUNT(CASE WHEN age>=35 AND age<=39 THEN age END) as age_8
                       ,COUNT(CASE WHEN age>=40 AND age<=44 THEN age END) as age_9
                       ,COUNT(CASE WHEN age>=45 AND age<=49 THEN age END) as age_10
                       ,COUNT(CASE WHEN age>=50 AND age<=54 THEN age END) as age_11
                       ,COUNT(CASE WHEN age>=55 AND age<=59 THEN age END) as age_12
                       ,COUNT(CASE WHEN age>=60 AND age<=64 THEN age END) as age_13
                       ,COUNT(CASE WHEN age>=65 AND age<=69 THEN age END) as age_14
                       ,COUNT(CASE WHEN age>=70 AND age<=74 THEN age END) as age_15
                       ,COUNT(CASE WHEN age>=75 AND age<=79 THEN age END) as age_16
                       ,COUNT(CASE WHEN age>=80 AND age<=84 THEN age END) as age_17
                       ,COUNT(CASE WHEN age>=85 AND age<=89 THEN age END) as age_18
                       ,COUNT(CASE WHEN age>=90 AND age<=94 THEN age END) as age_19
                       ,COUNT(CASE WHEN age>=95 AND age<=99 THEN age END) as age_20
                       ,COUNT(CASE WHEN age>=100 THEN age END) as age_21
                       FROM isam.xpef02.gq_population
                       GROUP BY yr 
                       ORDER BY yr DESC, age_count_gq DESC")

isam_age_gq<-melt(isam_age_gq, id.vars=c("yr"))

TYPE_DELETE_gq<-c("age_count_gq")
isam_age_gq<-isam_age_gq[!(isam_age_gq$variable %in% TYPE_DELETE_gq),]

isam_age_gq$variable<- substr(isam_age_gq$variable, start=5, stop=6)

isam_age_gq$Age.Group<- as.factor(isam_age_gq$variable)

isam_age_gq$Age.Group<-factor(isam_age_gq$Age.Group, levels= c(0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21),
                              labels = c("0","1-4","5-9","10-14","15-19","20-24","25-29","30-34","35-39","40-44","45-49","50-54","55-59",
                                         "60-64","65-69","70-74","75-79","80-84","85-89","90-94","95-99","100+"))

colnames(isam_age_gq)[colnames(isam_age_gq)=="value"] <- "isam_gq_age_pop"

isam_tot_age<-merge(isam_age_gq, isam_age_hh, by.a=c("yr", "Age.Group"), by.b=c("yr", "Age.Group"), all=TRUE)
isam_tot_age$isam_age_tot<-isam_tot_age$isam_hh_age_pop+isam_tot_age$isam_gq_age_pop


head(isam_tot_age)
isam_age_gq$Age.Group_rc <- ifelse(isam_age_gq$Age.Group=='0'|
                                     isam_age_gq$Age.Group=='1-4'|
                                     isam_age_gq$Age.Group=='5-9'|
                                     isam_age_gq$Age.Group=='10-14'|
                                     isam_age_gq$Age.Group=='15-19','1',        
                                   ifelse(isam_age_gq$Age.Group=='20-24'|
                                            isam_age_gq$Age.Group=='25-29'|
                                            isam_age_gq$Age.Group=='30-34'|
                                            isam_age_gq$Age.Group=='35-39', '2',
                                          ifelse(isam_age_gq$Age.Group=='40-44'|
                                                   isam_age_gq$Age.Group=='45-49'|
                                                   isam_age_gq$Age.Group=='50-54'|
                                                   isam_age_gq$Age.Group=='55-59', '3',
                                                 ifelse(isam_age_gq$Age.Group=='60-64'|
                                                          isam_age_gq$Age.Group=='65-69'|
                                                          isam_age_gq$Age.Group=='70-74'|
                                                          isam_age_gq$Age.Group=='75-79', '4',
                                                        ifelse(isam_age_gq$Age.Group=='80-84'|
                                                                 isam_age_gq$Age.Group=='85-89'|
                                                                 isam_age_gq$Age.Group=='90-94'|
                                                                 isam_age_gq$Age.Group=='95-99'|
                                                                 isam_age_gq$Age.Group=='100+','5', NA)))))

table(isam_age_gq$Age.Group_rc)

age_0_19_gq <- subset(isam_age_gq, Age.Group_rc ==1)
age_20_39_gq <- subset(isam_age_gq, Age.Group_rc ==2)
age_40_59_gq <- subset(isam_age_gq, Age.Group_rc ==3)
age_60_79_gq <- subset(isam_age_gq, Age.Group_rc ==4)
age_80_100_gq <- subset(isam_age_gq, Age.Group_rc ==5)



isam_age_hh$Age.Group_rc <- ifelse(isam_age_hh$Age.Group=='0'|
                                     isam_age_hh$Age.Group=='1-4'|
                                     isam_age_hh$Age.Group=='5-9'|
                                     isam_age_hh$Age.Group=='10-14'|
                                     isam_age_hh$Age.Group=='15-19','1',        
                                   ifelse(isam_age_hh$Age.Group=='20-24'|
                                            isam_age_hh$Age.Group=='25-29'|
                                            isam_age_hh$Age.Group=='30-34'|
                                            isam_age_hh$Age.Group=='35-39', '2',
                                          ifelse(isam_age_hh$Age.Group=='40-44'|
                                                   isam_age_hh$Age.Group=='45-49'|
                                                   isam_age_hh$Age.Group=='50-54'|
                                                   isam_age_hh$Age.Group=='55-59', '3',
                                                 ifelse(isam_age_hh$Age.Group=='60-64'|
                                                          isam_age_hh$Age.Group=='65-69'|
                                                          isam_age_hh$Age.Group=='70-74'|
                                                          isam_age_hh$Age.Group=='75-79', '4',
                                                        ifelse(isam_age_hh$Age.Group=='80-84'|
                                                                 isam_age_hh$Age.Group=='85-89'|
                                                                 isam_age_hh$Age.Group=='90-94'|
                                                                 isam_age_hh$Age.Group=='95-99'|
                                                                 isam_age_hh$Age.Group=='100+','5', NA)))))



#descriptives of total population
summary(isam_tot_gender$isam_tot_pop)

#descriptives by age
tapply(isam_tot_age$isam_age_tot, isam_tot_age$Age.Group, summary)

#descriptives by gq age
tapply(isam_tot_age$isam_gq_age_pop, isam_tot_age$Age.Group, summary)

#descriptives by hh age
tapply(isam_tot_age$isam_age_tot, isam_tot_age$Age.Group, summary)



# descriptives by race
tapply(isam_tot_race$isam_tot_pop, isam_tot_race$r, summary)

# descriptives by race
tapply(isam_tot_race$race_gq, isam_tot_race$r, summary)

# descriptives by race
tapply(isam_tot_race$race_hh, isam_tot_race$r, summary)

head(isam_tot_gender)

# descriptives by gender
summary(isam_tot_gender$female_tot)
summary(isam_tot_gender$male_tot)

# descriptives by househole gender
summary(isam_tot_gender$female_hh)
summary(isam_tot_gender$male_HH)

# descriptives by gq gender
summary(isam_tot_gender$female_gq)
summary(isam_tot_gender$male_gq)

##############################################

DW_Demographics<-read.csv('M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\dem_sql_20180710_092055.csv')

head(DW_Demographics)
