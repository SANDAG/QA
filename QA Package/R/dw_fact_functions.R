#begin build out of QA package

#Author: Kelsie Telson

#households 
f_households<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/households.sql",datasource_id)
  
  return(raw_dt)
  
}

########################################################
#jobs
f_jobs<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/jobs.sql",datasource_id)
  
  return(raw_dt)
  
}


########################################################
#median household income
f_mi_mgra<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/median_income_mgra.sql",datasource_id)
  
  return(raw_dt)
  
}

f_mi_jur<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/median_income_jur.sql",datasource_id)
  
  return(raw_dt)
  
}

########################################################
#demographic udf
#age
f_age<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/age.sql",datasource_id)
  
  return(raw_dt)
  
}

#population
f_pop<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/pop.sql",datasource_id)
  
  return(raw_dt)
  
}

#ethnicity
f_ethnicity<- function(datasource_id) {
  #set up
  maindir = dirname(rstudioapi::getSourceEditorContext()$path)
  setwd(maindir)
  
  source("readSQL.R")
  source("common_functions.R")
  
  packages <- c("RODBC","tidyverse","openxlsx","hash","readtext")
  pkgTest(packages)
  
  
  # connect to database
  channel <- connect_datawarehouse()

  #retrieve data from data warehouse
  raw_dt <- readDB("../queries/ethnicity.sql",datasource_id)
  
  return(raw_dt)
  
}
