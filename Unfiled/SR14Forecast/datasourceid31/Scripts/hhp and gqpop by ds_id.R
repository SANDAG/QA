


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)
getwd()


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}

packages <- c("RODBC","tidyverse","openxlsx","hash","zip","reshape2","sqldf")

pkgTest(packages)

# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')

gqpop <- sqlQuery(channel, "SELECT 
[yr_id]
,datasource_id
,sum(population) as pop
FROM [demographic_warehouse].[fact].[population]
where housing_type_id<>1 and (datasource_id IN (17,18,19,29,30,31))
group by yr_id,datasource_id
order by yr_id, datasource_id"
)


hhpop <- sqlQuery(channel,'SELECT 
[yr_id]
,datasource_id
,sum(population) as pop
FROM [demographic_warehouse].[fact].[population]
where housing_type_id=1 and (datasource_id IN (17,18,19,29,30,31))
group by yr_id,datasource_id
order by yr_id, datasource_id'
)


estimates <- sqlQuery(channel,'SELECT 
[yr_id]
,datasource_id
,sum(population) as pop
FROM [demographic_warehouse].[fact].[population]
where housing_type_id=1 and (datasource_id IN (25,27))
group by yr_id,datasource_id
order by yr_id, datasource_id'
)

head(estimates_wide[estimates_wide$yr_id==2017,])
head(hhpop_wide[hhpop_wide$yr_id==2016,])

gqpop_wide <- dcast(gqpop, yr_id~datasource_id, value.var = "pop") 
gqpop_wide

hhpop_wide <- dcast(hhpop, yr_id~datasource_id, value.var = "pop") 
hhpop_wide

head(estimates)
estimates_wide <- dcast(estimates, yr_id~datasource_id, value.var = "pop") 
estimates_wide

colnames(estimates_wide)[2] <- paste("Estimates_2017_ds_id_25", colnames(estimates_wide[,c(2)]), sep = "")
colnames(estimates_wide)[3] <- paste("Estimates_2018_ds_id_27", colnames(estimates_wide[,c(3)]), sep = "")

# out folder
outfolder<-paste("..\\Output\\",sep='')
ifelse(!dir.exists(file.path(maindir,outfolder)), dir.create(file.path(maindir,outfolder), showWarnings = TRUE, recursive=TRUE),0)
setwd(file.path(maindir,outfolder))

write.csv(gqpop_wide, "Group Quarter Pop by ds_id.csv", row.names = FALSE)
write.csv(hhpop_wide, "Household Pop by ds_id.csv", row.names = FALSE)
write.csv(estimates_wide, "Estimates HH Pop by ds_id.csv", row.names = FALSE)


