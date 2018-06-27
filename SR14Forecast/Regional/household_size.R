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

channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
hh_sql = getSQL("../Queries/hh_hhp_hhs.sql")
hh<-sqlQuery(channel,hh_sql)
odbcClose(channel)

head(hh)
hh<- hh[order(hh$geotype,hh$geozone,hh$yr_id),]

hh_jur = subset(hh,geotype=='jurisdiction')
colnames(hh_jur)[colnames(hh_jur)=="geozone"] <- "cityname"

hh_cpa = subset(hh,geotype=='cpa')
colnames(hh_cpa)[colnames(hh_cpa)=="geozone"] <- "cpaname"

hh_region = subset(hh,geotype=='region')
colnames(hh_region)[colnames(hh_region)=="geozone"] <- "SanDiegoRegion"

hh_jur$reg<-hh_region[match(hh_jur$yr_id, hh_region$yr_id),6]
hh_cpa$reg<-hh_region[match(hh_cpa$yr_id, hh_region$yr_id),6]


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results<-"plots\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

hh_jur$year<- "y"
hh_jur$yr <- as.factor(paste(hh_jur$year, hh_jur$yr, sep = ""))

jur_list = unique(hh_jur[["cityname"]])

for(i in jur_list) { 
  plotdat = subset(hh_jur, hh_jur$cityname==i)
  plot<-ggplot(plotdat, aes(yr)) + 
    geom_line(aes(y = reg, colour = "region",group=0),size=1.5) +
    geom_point(aes(y=reg)) +
    geom_line(aes(y = hhs, colour = cityname,group=0),size=1.5) + 
    geom_point(aes(y=hhs)) +
    scale_y_continuous(limits = c(2, 3.75)) +
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title=paste("Household Size\n ", i,' and Region',sep=''), 
         y="Household size", x="Year")
  ggsave(plot, file= paste(results, 'hhsize', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}



hh_cpa$year<- "y"
hh_cpa$yr <- as.factor(paste(hh_cpa$year, hh_cpa$yr, sep = ""))
hh_cpa$N <-  hh_cpa$households

cpa_list = unique(hh_cpa[["cpaname"]])

results<-"plots\\cpa\\hhsize\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)


for(i in cpa_list) { 
  plotdat = subset(hh_cpa, hh_cpa$cpaname==i)
  plot<-ggplot(plotdat, aes(yr)) + 
    geom_line(aes(y = reg, colour = "region",group=0),size=1.5) +
    geom_point(aes(y=reg)) +
    geom_line(aes(y = hhs, colour = cpaname,group=0),size=1.5) + 
    geom_point(aes(y=hhs)) +
    scale_y_continuous(limits = c(2, 3.75)) +
    theme(legend.position = "bottom",
          legend.title=element_blank()) +
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    labs(title=paste("Household Size\n ", i,' and Region',sep=''), 
         y="Household size", x="Year")
  i = gsub("\\*","",i)
  ggsave(plot, file= paste(results, 'hhsize', i, ".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}
