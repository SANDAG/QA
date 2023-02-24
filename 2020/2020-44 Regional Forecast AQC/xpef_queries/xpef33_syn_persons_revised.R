
#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=isam; trusted_connection=true')



syn_persons_pre2030<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [isam].[xpef33].[abm_syn_persons].[yr]
                  ,[isam].[xpef33].[abm_syn_persons].[hhid]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
      ,count([perid]) as pop
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] <=9 then '0 to 9'
			when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then '10 to 19'
            when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then '20 to 29'
            when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then '30 to 39'
			when [isam].[xpef33].[abm_syn_persons].[age] between 40 and 49 then '40 to 49'
			when [isam].[xpef33].[abm_syn_persons].[age] between 50 and 59 then '50 to 59'
			when [isam].[xpef33].[abm_syn_persons].[age] between 60 and 69 then '60 to 69'
			when [isam].[xpef33].[abm_syn_persons].[age] between 70 and 79 then '70 to 79'
			when [isam].[xpef33].[abm_syn_persons].[age] >=80 then '80+'
            else NULL
            end as 'age_rc'
  FROM [isam].[xpef33].[abm_syn_persons]
  WHERE [yr]<2030
  group by [isam].[xpef33].[abm_syn_persons].[yr]
      ,[isam].[xpef33].[abm_syn_persons].[hhid]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] <=9 then '0 to 9'
			when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then '10 to 19'
            when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then '20 to 29'
            when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then '30 to 39'
			when [isam].[xpef33].[abm_syn_persons].[age] between 40 and 49 then '40 to 49'
			when [isam].[xpef33].[abm_syn_persons].[age] between 50 and 59 then '50 to 59'
			when [isam].[xpef33].[abm_syn_persons].[age] between 60 and 69 then '60 to 69'
			when [isam].[xpef33].[abm_syn_persons].[age] between 70 and 79 then '70 to 79'
			when [isam].[xpef33].[abm_syn_persons].[age] >=80 then '80+'
            else NULL
            end
  order by [isam].[xpef33].[abm_syn_persons].[yr]
	  ,[isam].[xpef33].[abm_syn_persons].[hhid]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] <=9 then '0 to 9'
			when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then '10 to 19'
            when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then '20 to 29'
            when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then '30 to 39'
			when [isam].[xpef33].[abm_syn_persons].[age] between 40 and 49 then '40 to 49'
			when [isam].[xpef33].[abm_syn_persons].[age] between 50 and 59 then '50 to 59'
			when [isam].[xpef33].[abm_syn_persons].[age] between 60 and 69 then '60 to 69'
			when [isam].[xpef33].[abm_syn_persons].[age] between 70 and 79 then '70 to 79'
			when [isam].[xpef33].[abm_syn_persons].[age] >=80 then '80+'
            else NULL
            end"),
               stringsAsFactors = FALSE))

hhid_mgra<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [yr],
                  [mgra],
                  [hhid]
                  FROM [isam].[xpef33].[abm_syn_households]
                  group by [yr],
                  [mgra],
                  [hhid]
                  order by [yr],
                  [mgra],
                  [hhid]"),
                  stringsAsFactors = FALSE))

syn_persons_pre2030<- merge(syn_persons_pre2030,
          hhid_mgra[,c("yr","mgra", "hhid")],
          by=c("yr","hhid"),
          all.x=TRUE)

library(data.table)
syn_persons_pre2030<- as.data.table(syn_persons_pre2030)
syn_persons_pre2030_agg<-  syn_persons_pre2030[, list(
  pop=sum(pop)),
  by=c("mgra", "yr", "rac1p","ptype","pstudent", "pemploy", "age_rc")]

rm(syn_persons_pre2030)


##Post-2030 (and including)
syn_persons_post2030<- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [isam].[xpef33].[abm_syn_persons].[yr]
                  ,[isam].[xpef33].[abm_syn_persons].[hhid]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
      ,count([perid]) as pop
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] <=9 then '0 to 9'
			when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then '10 to 19'
            when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then '20 to 29'
            when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then '30 to 39'
			when [isam].[xpef33].[abm_syn_persons].[age] between 40 and 49 then '40 to 49'
			when [isam].[xpef33].[abm_syn_persons].[age] between 50 and 59 then '50 to 59'
			when [isam].[xpef33].[abm_syn_persons].[age] between 60 and 69 then '60 to 69'
			when [isam].[xpef33].[abm_syn_persons].[age] between 70 and 79 then '70 to 79'
			when [isam].[xpef33].[abm_syn_persons].[age] >=80 then '80+'
            else NULL
            end as 'age_rc'
  FROM [isam].[xpef33].[abm_syn_persons]
  WHERE [yr]>=2030
  group by [isam].[xpef33].[abm_syn_persons].[yr]
      ,[isam].[xpef33].[abm_syn_persons].[hhid]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] <=9 then '0 to 9'
			when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then '10 to 19'
            when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then '20 to 29'
            when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then '30 to 39'
			when [isam].[xpef33].[abm_syn_persons].[age] between 40 and 49 then '40 to 49'
			when [isam].[xpef33].[abm_syn_persons].[age] between 50 and 59 then '50 to 59'
			when [isam].[xpef33].[abm_syn_persons].[age] between 60 and 69 then '60 to 69'
			when [isam].[xpef33].[abm_syn_persons].[age] between 70 and 79 then '70 to 79'
			when [isam].[xpef33].[abm_syn_persons].[age] >=80 then '80+'
            else NULL
            end
  order by [isam].[xpef33].[abm_syn_persons].[yr]
	  ,[isam].[xpef33].[abm_syn_persons].[hhid]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] <=9 then '0 to 9'
			when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then '10 to 19'
            when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then '20 to 29'
            when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then '30 to 39'
			when [isam].[xpef33].[abm_syn_persons].[age] between 40 and 49 then '40 to 49'
			when [isam].[xpef33].[abm_syn_persons].[age] between 50 and 59 then '50 to 59'
			when [isam].[xpef33].[abm_syn_persons].[age] between 60 and 69 then '60 to 69'
			when [isam].[xpef33].[abm_syn_persons].[age] between 70 and 79 then '70 to 79'
			when [isam].[xpef33].[abm_syn_persons].[age] >=80 then '80+'
            else NULL
            end"),
                  stringsAsFactors = FALSE))

syn_persons_post2030<- merge(syn_persons_post2030,
                            hhid_mgra[,c("yr","mgra", "hhid")],
                            by=c("yr","hhid"),
                            all.x=TRUE)

library(data.table)
syn_persons_post2030<- as.data.table(syn_persons_post2030)
syn_persons_post2030_agg<-  syn_persons_post2030[, list(
  pop=sum(pop)),
  by=c("mgra", "yr", "rac1p","ptype","pstudent", "pemploy", "age_rc")]

rm(syn_persons_post2030)
rm(hhid_mgra)

x_agg<-rbind(syn_persons_pre2030_agg,
         syn_persons_post2030_agg)

rm(syn_persons_pre2030_agg)
rm(syn_persons_post2030_agg)



#retreive tables using sql code
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[city]
                  FROM ws.dbo.mgra13_bg
                  GROUP BY [mgra]
                  ,[city]"),
                  stringsAsFactors = FALSE))

y<- merge(x_agg,
          d_mgra,
          by="mgra",
          allow.cartesian = TRUE,
          all.x=TRUE)

rm(x_agg)

final<- y[,list(
  pop=sum(pop)),
  by=c("city", "yr", "rac1p","ptype","pstudent", "pemploy","age_rc")]

#saveout merged table
write.csv(final, "C://Users//kte//San Diego Association of Governments//SANDAG QA QC - Documents//Projects//2020//2020-44 Regional Forecast AQC//Results//PowerBI//syn_persons_jur.csv")











#years with records missing mgra
p<- subset(y, is.na(mgra))
table(p$yr)

#to locate duplicate mgras
d<-subset(d_mgra, duplicated(d_mgra$mgra))
e<- d_mgra %>%
  filter(mgra %in% d$mgra)

f<- x %>%
  filter(mgra %in% d$mgra)


final<- y[, list(
  
)]
