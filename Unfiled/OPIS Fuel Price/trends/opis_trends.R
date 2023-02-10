#look up opis data online for data dictionary.


#function to load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)

}

#identify packages to be loaded
packages <- c("sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","tidyverse", "readxl", "frequency", "ggplot2", "lubridate")
#confirm packages are read in
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))
source("../Queries/readSQL.R")

options(stringsAsFactors=FALSE)

#open channel to database
channel <- odbcDriverConnect('driver={SQL Server}; server=socioeca8; database=dpoe_stage; trusted_connection=true')

#read in opis data
opis <- sqlQuery(channel, 
                    "SELECT * 
FROM [dpoe_stage].[fact].[opis_fuel_price] a
left join [dpoe_stage].[dim].[opis_date] b
on a.date_id=b.date_id"
)


#read in EIA data
#us - all areas all formulations

eia_reg_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 3", skip = 2)[,1:2]

eia_mid_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 6", skip = 2)[,1:2]

eia_prem_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 9", skip = 2)[,1:2]

eia_diesel_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\psw18vwall.xlsx", sheet = "Data 2", skip = 2)[,1:2]


#california - reformulated only
eia_reg_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 2", skip = 2)[,c(1,10)]
 
eia_mid_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 5", skip = 2)[,c(1,10)]
 
eia_prem_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 8", skip = 2)[,c(1,10)]
 
eia_diesel_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\psw18vwall.xlsx", sheet = "Data 2", skip = 2)[,c(1,11)]

head(eia_reg_us)
head(eia_mid_us)
head(eia_prem_us)
head(eia_diesel_us)
head(eia_reg_ca)
head(eia_mid_ca)
head(eia_prem_ca)
head(eia_diesel_ca)

#add column to indicate fuel grade
eia_reg_us$product <- "Unleaded Gas"
eia_mid_us$product <- "Midgrade Gas"
eia_prem_us$product <- "Premium Gas"
eia_diesel_us$product <- "Diesel"

eia_reg_ca$product <- "Unleaded Gas"
eia_mid_ca$product <- "Midgrade Gas"
eia_prem_ca$product <- "Premium Gas"
eia_diesel_ca$product <- "Diesel"

#add column to indicate data source
eia_reg_us$source <- "US_EIA"
eia_mid_us$source <- "US_EIA"
eia_prem_us$source <- "US_EIA"
eia_diesel_us$source <- "US_EIA"

eia_reg_ca$source <- "State of CA-EIA"
eia_mid_ca$source <- "State of CA-EIA"
eia_prem_ca$source <- "State of CA-EIA"
eia_diesel_ca$source <- "State of CA-EIA"

#rename eia columns with price
names(eia_reg_us)[2] <- "retail_avg"
names(eia_mid_us)[2] <- "retail_avg"
names(eia_prem_us)[2] <- "retail_avg"
names(eia_diesel_us)[2] <- "retail_avg"

names(eia_reg_ca)[2] <- "retail_avg"
names(eia_mid_ca)[2] <- "retail_avg"
names(eia_prem_ca)[2] <- "retail_avg"
names(eia_diesel_ca)[2] <- "retail_avg"

#recode EIA date
eia_reg_us$date <- as.Date(eia_reg_us$Date, format = "%Y-%m-%d")
eia_mid_us$date <- as.Date(eia_mid_us$Date, format = "%Y-%m-%d")
eia_prem_us$date <- as.Date(eia_prem_us$Date, format = "%Y-%m-%d")
eia_diesel_us$date <- as.Date(eia_diesel_us$Date, format = "%Y-%m-%d")

eia_reg_ca$date <- as.Date(eia_reg_ca$Date, format = "%Y-%m-%d")
eia_mid_ca$date <- as.Date(eia_mid_ca$Date, format = "%Y-%m-%d")
eia_prem_ca$date <- as.Date(eia_prem_ca$Date, format = "%Y-%m-%d")
eia_diesel_ca$date <- as.Date(eia_diesel_ca$Date, format = "%Y-%m-%d")

#exclude data before 2005 to make data comparable to opis 
eia_reg_us <- eia_reg_us[eia_reg_us$date>="2005-01-01",]
eia_mid_us <- eia_mid_us[eia_mid_us$date>="2005-01-01",]
eia_prem_us <- eia_prem_us[eia_prem_us$date>="2005-01-01",]
eia_diesel_us <- eia_diesel_us[eia_diesel_us$date>="2005-01-01",]

eia_reg_ca <- eia_reg_ca[eia_reg_ca$date>="2005-01-01",]
eia_mid_ca <- eia_mid_ca[eia_mid_ca$date>="2005-01-01",]
eia_prem_ca <- eia_prem_ca[eia_prem_ca$date>="2005-01-01",]
eia_diesel_ca <- eia_diesel_ca[eia_diesel_ca$date>="2005-01-01",]

#drop original date variable
eia_reg_us$Date <- NULL
eia_mid_us$Date <- NULL
eia_prem_us$Date <- NULL
eia_diesel_us$Date <- NULL
eia_reg_ca$Date <- NULL
eia_mid_ca$Date <- NULL
eia_prem_ca$Date <- NULL
eia_diesel_ca$Date <- NULL

head(eia_reg_us)
head(eia_mid_us)
head(eia_prem_us)
head(eia_diesel_us)
head(eia_reg_ca)
head(eia_mid_ca)
head(eia_prem_ca)
head(eia_diesel_ca)

eia_all <- rbind(eia_reg_us,eia_mid_us,eia_prem_us,eia_diesel_us,eia_reg_ca,eia_mid_ca,eia_prem_ca,eia_diesel_ca)

head(eia_all)
rm(eia_reg_us,eia_mid_us,eia_prem_us,eia_diesel_us,eia_reg_ca,eia_mid_ca,eia_prem_ca,eia_diesel_ca)

#run frequencies
#options(frequency_render = FALSE)
#options(frequency_open_output = TRUE)
colnames(opis)

freq(opis[, c('region','product','yr','season')])
opis$date <- as.Date(opis$date_code, format = "%Y-%m-%d")
opis$source <- "San Diego_OPIS"
opis <- opis %>% select(retail_avg,product,source,date)

head(opis)
head(eia_all)

table(opis$product)
table(eia_all$product)
opis_eia <- rbind(opis,eia_all)
opis_eia <- opis_eia[opis_eia$date<"2019-06-01",]

class(opis_eia$retail_avg)
class
opis_eia_reg <- opis_eia[(opis_eia$product=="Unleaded Gas"),]
opis_eia_mid <- opis_eia[(opis_eia$product=="Midgrade Gas"),]
opis_eia_prem <- opis_eia[(opis_eia$product=="Premium Gas"),]
opis_eia_diesel <- opis_eia[(opis_eia$product=="Diesel"),]


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results <- "plots\\opis_fuel\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

plot_reg <- ggplot() + geom_line(data=opis_eia_reg, aes(x=date, y = retail_avg, group=source, color=source)) + 
  scale_y_continuous(limits = c(2, 4.5)) +
  theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.text.x = element_text(hjust = 0.5)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9)) +
  labs(title="OPIS and EIA Regular Unleaded Gas Price Comparison:\n2005 through May 2019",
       y="Retail Average Price per Gallon", x="Year",
       caption="Sources: OPIS, EIA; Notes: US retail average is based on all areas and all formulations and CA is reformulated only;\nDue to differences in the availability of the data, OPIS data are shown by month whereas EIA data are available by week.")
  ggsave(plot_reg, file=paste(results,"Regular Unleaded OPIS to EIA Comparison.png", sep = ''),
  width=10, height=6, dpi=100)#, scale=2)
  
plot_reg
 
getwd() 
plot_mid <- ggplot() + geom_line(data=opis_eia_mid, aes(x=date, y = retail_avg, group=source, color=source)) + 
  scale_y_continuous(limits = c(2, 4.5)) +
  theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.text.x = element_text(hjust = 1)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9)) +
  labs(title="OPIS and EIA Midgrage Unleaded Gas Price Comparison:\n2005 May 2019",
       y="Retail Average Price per Gallon", x="Year",
       caption="Sources: OPIS, EIA; Notes: US retail average is based on all areas and all formulations and CA is reformulated only;\nDue to differences in the availability of the data, OPIS data are shown by month whereas EIA data are available by week.")
  ggsave(plot_reg, file= paste(results, "Midgrade Unleaded OPIS to EIA Comparison"),
         width=10, height=6, dpi=100)#, scale=2)

plot_mid

plot_prem <- ggplot() + geom_line(data=opis_eia_prem, aes(x=date, y = retail_avg, group=source, color=source)) + 
  scale_y_continuous(limits = c(2, 4.5)) +
  theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.text.x = element_text(hjust = 1)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9)) +
  labs(title="OPIS and EIA Premium Unleaded Gas Price Comparison:\n2005 through May 2019",
       y="Retail Average Price per Gallon", x="Year",
       caption="Sources: OPIS, EIA; Notes: US retail average is based on all areas and all formulations and CA is reformulated only;\nDue to differences in the availability of the data, OPIS data are shown by month whereas EIA data are available by week.")
ggsave(plot_reg, file= paste(results, "Premium Unleaded OPIS to EIA Comparison"),
       width=10, height=6, dpi=100)#, scale=2)

plot_prem  

plot_diesel <- ggplot() + geom_line(data=opis_eia_mid, aes(x=date, y = retail_avg, group=source, color=source)) + 
  scale_y_continuous(limits = c(2, 4.5)) +
  theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.text.x = element_text(hjust = 1)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9)) +
  labs(title="OPIS and EIA Midgrage Unleaded Gas Price Comparison:\n2005 through May 2019",
       y="Retail Average Price per Gallon", x="Year",
       caption="Sources: OPIS, EIA; Notes: US retail average is based on all areas and all Diesel types and CA is reformulated only;\nDue to differences in the availability of the data, OPIS data are shown by month whereas EIA data are available by week.")
ggsave(plot_reg, file= paste(results, "Diesel All Types OPIS to EIA Comparison"),
       width=10, height=6, dpi=100)#, scale=2)

plot_diesel



