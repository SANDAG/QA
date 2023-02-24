#Compare GQ totals across datasource_id versions


pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}
packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "plyr", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "gtable")
pkgTest(packages)

#set v= most updated datasource_id 
#set o= other comparison datasource_id 
#set p= most current phase number
#set op= other comparison phase number
v="19"
o="17"
p="6"
op="4"

gq_cpav<-read.csv(paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase ",p,"\\GQ\\gq_cpa",v,".csv",sep=""))
gq_jurv<-read.csv(paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase ",p,"\\GQ\\gq_jur",v,".csv",sep=""))
gq_regionv<-read.csv(paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase ",p,"\\GQ\\gq_region",v,".csv",sep=""))
gq_cpao<-read.csv(paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase ",op,"\\GQ\\gq_cpa.csv",sep=""))
gq_juro<-read.csv(paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase ",op,"\\GQ\\gq_jur.csv",sep=""))
gq_regiono<-read.csv(paste("M:\\Technical Services\\QA Documents\\Projects\\Sub Regional Forecast\\4_Data Files\\Phase ",op,"\\GQ\\gq_region.csv",sep=""))

gq_v<-rbind(gq_cpav,gq_jurv,gq_regionv)
gq_o<-rbind(gq_cpao, gq_juro, gq_regiono)

setnames(gq_v, old=("pop"),new=("pop_new"))
setnames(gq_o, old=("pop"),new=("pop_old"))

levels(gq_v$geozone) <- c(levels(gq_v$geozone), "San Diego Region")
gq_v$geozone[gq_v$geotype=='region'] <- 'San Diego Region'
gq_v$geozone <- gsub("\\*","",gq_v$geozone)
gq_v$geozone <- gsub("\\-","_",gq_v$geozone)
gq_v$geozone <- gsub("\\:","_",gq_v$geozone)

levels(gq_o$geozone) <- c(levels(gq_o$geozone), "San Diego Region")
gq_o$geozone[gq_o$geotype=='region'] <- 'San Diego Region'
gq_o$geozone <- gsub("\\*","",gq_o$geozone)
gq_o$geozone <- gsub("\\-","_",gq_o$geozone)
gq_o$geozone <- gsub("\\:","_",gq_o$geozone)


gq_comparison<-merge(gq_v, gq_o, by.a=c(yr_id,geotype,geozone,shortname),by.b=c(yr_id,geotype,geozone,shortname), all=TRUE)

table(gq_cpao$short_name)

gq_comparison$num_diff<-gq_comparison$pop_new-gq_comparison$pop_old

gq_comparison$pct_diff<-((gq_comparison$pop_new-gq_comparison$pop_old)/gq_comparison$pop_old)*100
gq_comparison$pct_diff<-round(gq_comparison$pct_diff,digits=2)

summary(gq_comparison$pct_diff)
above_5<-subset(gq_comparison, pct_diff>=(abs(5)))

head(above_5,25)

gq_sum <-aggregate(cbind(pop_new, pop_old) ~geozone + geotype + short_name, data= gq_comparison, sum,na.rm = TRUE)
gq_sum<-subset(gq_sum, short_name=="gq_mil")

head(gq_sum)
gq_sum$num_diff<-gq_sum$pop_new-gq_sum$pop_old

issue<-subset(gq_sum, num_diff!=0)

setnames(issue, old=c("pop_new"),new=(paste("pop_",v,"",sep="")))
setnames(issue, old=c("pop_old"),new=(paste("pop_",o,"",sep="")))
                                                                  

head(issue,45)

summary(issue,45)
