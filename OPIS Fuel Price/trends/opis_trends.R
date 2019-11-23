#look up opis data online for data dictionary.
##NEED TO CHANGE DATE FORMAT FOR EIA DATA? SEE ROW 93
#need to add california sheets or column - waiting for Cherry

#function to load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)

}

#identify packages to be loaded
packages <- c("sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","tidyverse", "readxl", "frequency", "ggplot", "lubridate")
#confirm packages are read in
pkgTest(packages)

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
#need to add california sheets or column - waiting for Cherry

eia_reg_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 3", skip = 2)[,1:2]

eia_mid_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 6", skip = 2)[,1:2]

eia_prem_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 9", skip = 2)[,1:2]

eia_diesel_us <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\psw18vwall.xlsx", sheet = "Data 2", skip = 2)[,1:2]


#set the columns to select
# eia_reg_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 3", skip = 2)[,1:2]
# 
# eia_mid_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 6", skip = 2)[,1:2]
# 
# eia_prem_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\pswrgvwall (1).xlsx", sheet = "Data 9", skip = 2)[,1:2]
# 
# eia_diesel_ca <- read_excel("M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\EIA gas price data\\psw18vwall.xlsx", sheet = "Data 2", skip = 2)[,1:2]



head(eia_reg_us)
head(eia_mid_us)
head(eia_prem_us)
head(eia_diesel_us)


#rename eia data columns
names(eia_reg_us)[2] <- "eia_reg_ret_avg"
names(eia_mid_us)[2] <- "eia_mid_ret_avg"
names(eia_prem_us)[2] <- "eia_prem_ret_avg"
names(eia_diesel_us)[2] <- "eia_diesel_ret_avg"

#run frequencies
#options(frequency_render = FALSE)
freq(opis[, c('region','product','yr','season')])

#options(frequency_open_output = TRUE)

opis$date_code_rc <- as.Date(opis$date_code, format = "%Y-%m-%d")

#opis$date_code_rc <- as.Date(opis$date_code_rc1, format = '%b-%y')

#confirm opis$data_code_rc is date format
IsDate <- function(mydate) {
  tryCatch(!is.na(as.Date(opis$date_code_rc, "",tryFormats = c("%Y-%m-%d", "%Y/%m/%d","%d-%m-%Y","%m-%d-%Y"))),  
           error = function(err) {FALSE})  
}

IsDate(opis$date_code_rc)
IsDate(eia_reg_us$Date)

#recode EIA date
eia_reg_us$date <- as.Date(eia_reg_us$Date, format = "%Y-%m-%d")
eia_reg_us <- eia_reg_us[eia_reg_us$date>="2005-01-01",]

head(eia_reg_us$date)



opis_reg_us <- opis[(opis$product=="Unleaded Gas" | opis$product=="Regular Gas"),]
#calculate average price across gas types
#opis_agg <- opis  %>%  group_by(date_code_rc) %>% tally(retail_avg)
#opis_agg$retail_avg_rc <- opis_agg$n/4


maindir = dirname(rstudioapi::getSourceEditorContext()$path)
results <- "plots\\opis_fuel\\"
ifelse(!dir.exists(file.path(maindir,results)), dir.create(file.path(maindir,results), showWarnings = TRUE, recursive=TRUE),0)

head(opis)
head(eia_reg_us)

p <- ggplot() + geom_line(data=opis_reg, aes(x=date_code_rc, y = retail_avg), color= "red") + 
#  geom_line(data=eia_reg_ca, aes(x=date,y=eia_reg_ret_avg), color = "green")
  geom_line(data=eia_reg_us, aes(x=date,y=eia_reg_ret_avg), color = "blue")
  scale_y_continuous(limits = c(2, 3.5)) +
  theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(legend.position = "bottom",
        legend.title=element_blank(),
        plot.caption = element_text(size = 9)) +
  labs(title="OPIS and EIA Gas Price Comparison:\n2005 through September 2019",
       y="Retail Average Price per Gallon", x="Year",
       caption="Sources: OPIS, EIA; Notes: US retail average is based on [TBD- add info about formulation]; Due to differences in the availability of the data, OPIS data are shown by month whereas EIA data are available by week.")
results<-"plots\\opis\\"
ggsave(output, file= paste(results, 'opis_reg.png'))
       #width=6, height=8, dpi=100)#, scale=2)


p



############################
############################

#for(i in jur_list) {
 # plotdat = subset(hh_jur, hh_jur$cityname==i)
  plot<-ggplot(opis_agg, aes(date_code_rc)) + 
    geom_line(aes(y = us_price, colour = "1_Region",group=0),size=1.5) +
    geom_point(size=3,aes(y=reg_hhs,color="1_Region")) +
    geom_line(aes(y = hhs, colour = cityname,group=0),size=1.5) + 
    geom_point(size=3,aes(y=hhs,colour=cityname)) +
    scale_y_continuous(limits = c(2, 3.5)) +
    theme_bw(base_size = 14) +  theme(plot.title = element_text(hjust = 0.5)) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    theme(legend.position = "bottom",
          legend.title=element_blank(),
          plot.caption = element_text(size = 9)) +
    labs(title=paste("Household Size:", i,' and Region\n datasource_id ',ds_id,sep=''), 
         y="Household size", x="Year",
         caption=paste("Sources: demographic_warehouse",ds_id,"; Notes: Refer to table below for out of range hh size values",sep=''))
  results<-"plots\\hhsize\\jur\\"
  output_table<-plotdat[,c("yr_id","hhp","households","hhs","reg_hhp","reg_hh","reg_hhs")]
  colnames(output_table)[colnames(output_table)=="households"] <- "hh"
  tt <- ttheme_default(base_size=12,colhead=list(fg_params = list(parse=TRUE)))
  tbl <- tableGrob(output_table, rows=NULL, theme=tt)
  lay <- rbind(c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(1,1,1,1,1),
               c(2,2,2,2,2),
               c(2,2,2,2,2))
  output<-grid.arrange(plot,tbl,ncol=1,as.table=TRUE,layout_matrix=lay)
  ggsave(output, file= paste(results, 'hhsize', i, ds_id,".png", sep=''),
         width=6, height=8, dpi=100)#, scale=2)
}








