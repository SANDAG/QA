
#set up
maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("readSQL.R")
source("common_functions.R")

packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=DDAMWSQL16.sandag.org; database=isam; trusted_connection=true')



syn_persons<- data.table::as.data.table(
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
                  [mgra]
	  ,[hhid]
  FROM [isam].[xpef33].[abm_syn_households]
  group by [yr],
  [mgra]
	  ,[hhid]
  order by [yr],
  [mgra]
	  ,[hhid]"),
                  stringsAsFactors = FALSE))

x<- merge(syn_persons,
          hhid_mgra[,c("yr","mgra", "hhid")],
          by=c("yr","hhid"),
          all.x=TRUE)

rm(syn_persons)
rm(hhid_mgra)


#retreive tables using sql code
d_mgra <- data.table::as.data.table(
  RODBC::sqlQuery(channel,
                  paste0("SELECT [mgra]
                  ,[city]
                  FROM ws.dbo.mgra13_bg
                  GROUP BY [mgra]
                  ,[city]"),
                  stringsAsFactors = FALSE))


library(data.table)
x<- as.data.table(x)
x_agg<-  x[, list(
  pop=sum(pop)),
  by=c("mgra", "yr", "rac1p","ptype","pstudent", "pemploy", "age_rc")]

#cleanup
rm(x)
rm(d_mgra)

y<- merge(x_agg,
          d_mgra,
          by="mgra",
          allow.cartesian = TRUE,
          all.x=TRUE)

rm(x_agg)
rm(dim_test)

final<- y[,list(
  pop=sum(pop)),
  by=c("City", "yr", "rac1p","ptype","pstudent", "pemploy","age_rc")]

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
