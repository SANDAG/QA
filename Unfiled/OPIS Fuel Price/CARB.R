#CARB fleet data plots

##function to load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)
  
}

#identify packages to be loaded
packages <- c("sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","tidyverse", "readxl", "frequency", "ggplot2", "lubridate","gmodels")
#confirm packages are read in
pkgTest(packages)

setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

options(stringsAsFactors=FALSE)

#open channel to database
channel <- odbcDriverConnect('driver={SQL Server}; server=socioeca8; database=dpoe_stage; trusted_connection=true')

#read in opis data
carb_fleet <- sqlQuery(channel, 
                       "SELECT * 
FROM [dpoe_stage].[fact].[fleet_data] a
left join [dpoe_stage].[dim].[fuel_tech] b on a.fuel_tech_id=b.fuel_tech_id
left join [dpoe_stage].[dim].[vehicle_category] c on a.vehicle_category_id=c.vehicle_category_id
left join [dpoe_stage].[dim].[fuel_type] d on a.fuel_type_id=d.fuel_type_id
left join [dpoe_stage].[dim].[fleet_data_geo] e on a.geo_id=e.fleet_data_geo_id
left join [dpoe_stage].[dim].[model_yr] f on a.model_yr_id=f.model_yr_id"
)

head(carb_fleet)
sapply(carb_fleet, class)

table(carb_fleet$vintage_yr, carb_fleet$vintage_yr)
table(carb_fleet$vintage_yr, carb_fleet$fuel_tech_desc)
table(carb_fleet$vintage_yr, carb_fleet$vehicle_category_desc)
table(carb_fleet$vintage_yr, carb_fleet$fuel_type_code)
table(carb_fleet$vintage_yr, carb_fleet$model_yr_code)
table(carb_fleet$vintage_yr, carb_fleet$fleet_data_subarea)
table(carb_fleet$vintage_yr, carb_fleet$fleet_data_zip)
summary(carb_fleet$fleet_data_blk_grp)

#look at cases coded as scrubbed
scrubbed <- subset(carb_fleet, fleet_data_geo_id==2424)
table(scrubbed$vintage_yr,scrubbed$fleet_data_subarea)
table(scrubbed$vintage_yr, scrubbed$fuel_tech_desc)
table(scrubbed$vintage_yr, scrubbed$vehicle_category_desc)
table(scrubbed$vintage_yr, scrubbed$fuel_type_code)
table(scrubbed$vintage_yr, scrubbed$model_yr_code)
table(scrubbed$vintage_yr, scrubbed$fleet_data_subarea)
table(scrubbed$vintage_yr, scrubbed$fleet_data_zip)

colnames(carb_fleet)

# carb_fleet$fleet_data_id <- NULL
# carb_fleet$vehicle_category_id <- NULL
# carb_fleet$vehicle_category_code <- NULL
# carb_fleet$fuel_type_id <- NULL
# carb_fleet$model_yr_id <- NULL
# carb_fleet$fuel_tech_id <- NULL
# carb_fleet$electric_mile_range_id <- NULL



county <- aggregate(vehicle_pop~vintage_yr+fleet_data_county,data = carb_fleet,sum)

mpo <- aggregate(vehicle_pop~vintage_yr+fleet_data_mpo,data = carb_fleet,sum)


model_yr <- aggregate(vehicle_pop~vintage_yr+model_yr_code,data = carb_fleet,sum)
model_yr$yr_tot <- county[match(model_yr$vintage_yr,county$vintage_yr),3]
model_yr$proportion <- (model_yr$vehicle_pop/model_yr$yr_tot) *100
model_yr$proportion <- round(model_yr$proportion,digits=4)

model_yr_test <- dcast(model_yr,model_yr_code~vintage_yr, value.var = "vehicle_pop")
model_yr_test2 <- dcast(model_yr,model_yr_code~vintage_yr, value.var = "proportion")
model_yr_test2$variance <- colVars(model_yr_test2,suma)

list2 <-  c("vehicle_category_code","fuel_type_code")

write.csv(model_yr_test,"M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Results\\model_yr_num.csv")
write.csv(model_yr_test2,"M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Results\\model_yr_proportion.csv")

test_lh <- lapply(list2,function(x){
  carb_fleet %>%
    group_by('vintage_yr',.dots=x) %>%
    summarise(vehicle_pop=sum(vehicle_pop))
})


df <- test_lh[[1]]




[df] <- lapply(list2,function(x){
  carb_fleet %>%
    group_by('vintage_yr',.dots=x) %>%
    summarise(vehicle_pop=sum(vehicle_pop))
})


df <- test_lh[[1]]



vehicle_category <- aggregate(vehicle_pop~vintage_yr+vehicle_category_code+vehicle_category_desc,data = carb_fleet,sum)

fuel_type <- aggregate(vehicle_pop~vintage_yr+fuel_type_code,data = carb_fleet,sum)

fuel_tech <- aggregate(vehicle_pop~vintage_yr+fuel_tech_code,data = carb_fleet,sum)

zip <- aggregate(vehicle_pop~vintage_yr+fleet_data_zip,data = carb_fleet,sum)

blk_grp <- aggregate(vehicle_pop~vintage_yr+fleet_data_blk_grp,data = carb_fleet,sum)

scrubbed_agg <- aggregate(vehicle_pop~vintage_yr,data = scrubbed,sum)




write.csv(carb_fleet, "M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\CARB fleet\\CARB fleet.csv")

write.csv(carb_fleet_test, "M:\\Technical Services\\QA Documents\\Projects\\OPIS and CARB Fleet\\Data Files\\CARB fleet\\CARB fleet test.csv")



test_table<- carb_fleet  %>%  group_by(carb_fleet$vintage_yr) %>% tally(carb_fleet$fuel_tech_desc)



CrossTable(carb_fleet$fuel_tech_id,carb_fleet$vintage_yr,prop.r=FALSE,prop.c = TRUE,prop.t = FALSE,prop.chisq = FALSE,
           missing.include=TRUE,format = "SPSS")
hel