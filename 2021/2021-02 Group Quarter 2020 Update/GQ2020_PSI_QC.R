### Project: 2021- 02 Group Quarter 2020 Update 
## Link to Test Plan: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={dbbbf7a2-5535-48d4-be08-b36c3f188109}&action=edit&wd=target%28Untitled%20Section.one%7Cc92109e3-f882-46aa-b8de-d792c848c78f%2FTest%20Plan%7C334fc90e-fa5e-4158-b204-8ff549abc103%2F%29
## Author: Purva Singh


### Part 1: Setting up the R environment, source files, and packages and output folder
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# Loading the packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}


packages <- c("data.table", "ggplot2", "scales", "sqldf", "rstudioapi", "RODBC", "dplyr", "reshape2", 
              "stringr","gridExtra","grid","lattice", "openxlsx", "rlang", "hash", "RCurl","readxl", "tidyverse")
pkgTest(packages)


### Part 2: Loading the data and preparing it for analysis

## Group Quarter 2020 data- NOTE- The csv file used for the analysis was exported from 
## the Group Quarter 2020 attribute table in the gdb folder shared by Blake Anderson (SME). 
## The CSV and gdb folder are on the QC SharePoint website 

gq<- read.csv("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2021\\2021-02 GQ LUDU 2020Update\\Data\\GQ2020.csv")


gq_19<- read.csv("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2021\\2021-02 GQ LUDU 2020Update\\Data\\gq2019.csv")


gq_desc<- read_excel("C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2021\\2021-02 GQ LUDU 2020Update\\Data\\GQ Facilities Definitions.xlsx")


## Test 1: Object IDs are unique

length(unique(gq$ï..OID_))== 919


## Test 2: Confirm effect year is 2020 for all entries
unique(gq$effectYear)

## Test 3: Confirm that:GQPOP= GQCIV+ GQMIL, AND, GQCIV= GQCIVCOL+ GQOther 
test3<- gq%>%
  mutate(gqpop= gqMil+ gqCiv, 
         gqciv= gqCivCol+ gqOther, 
         gqpopcheck= gqpop- gqPop, 
         gqcivcheck= gqciv- gqCiv)%>%
  filter(gqpopcheck!=0 | gqcivcheck!=0)


write.csv(test3, "C:\\Users\\psi\\San Diego Association of Governments\\SANDAG QA QC - Documents\\Projects\\2021\\2021-02 GQ LUDU 2020Update\\Results\\Test3.csv")

## Test 4: Confirm 4 new GQ records between Group Quarter 2019 and Group Quarter 2020

test4<- gq%>%
  filter(!facilityID %in% gq_19$facilityID)

## Test 5: Confirm that facility type and facility ID matches the GQ facility list definitions 


## test 5.1 filter out facility IDs which are 0 
test5.1<- gq%>%
  filter(facilityType!=0)

## test 5.2 testing whether non-zero facility IDs are in the GQ description table

test5.2<- gq%>%
  filter(facilityType %in% gq_desc$facilityID )

## test 5.3 testing whether all the non-zero facility IDs have a subfacility
test5.3<- test5.1%>%
  filter(facilityID== 0)%>%
  filter(gqPop!=0)    #### These 3 observations have population in the Other category

test5.4<- test5.1%>%
  filter(subFacility==0)

test5.5<- gq%>%
  filter(subFacility!=0)%>%
  filter(facilityID==0)

length(unique(test5.4$subFacility))

## Test 6: Confirm all the facilities are in San Diego region

## This test was conducted in ArcGIS Pro looking at the Attribute Table


