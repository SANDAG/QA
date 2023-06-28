# install.packages('ipumsr')
# install.packages("stargazer")
# install.packages("plm")
# install.packages("mlogit")
# install.packages("reshape")
# install.packages("survey")
# library('ipumsr')
# install.packages("fitdistrplus")
# install.packages("ForestFit")
library(dplyr)
library(tidyverse)
library(stargazer)
library(magrittr)
library(plm)
library(haven)
library(ggplot2)
library(readxl)
library(writexl)
library(mlogit)
library(plyr)
library(reshape)
library(lattice)
library(survey)
library(fitdistrplus)
library(ForestFit)

# Read in PUMS re-coded data (from E&F and Beth)
# Variable names in PUMS_Data_Dictionary_2016-2020.pdf
setwd("C:/Users/fhe/Weekly tasks/IPUMS/HH_Income")
data <- read.table(file = "PUMSsubset_SanDiego-2017-2021.txt",sep="\t",
                   header=TRUE)

# Only work with housing units (TYPEHUGQ ==1)
# We are excluding group quarters (TYPEHUGQ == 2 and TYPEHUGQ 3)
data <- data %>% filter (TYPEHUGQ == 1 & data$Year == 2019)
data <- subset(data, select = c(Year, WGTP, PWGTP, SERIALNO, ADJINC,
                                RELSHIPP, ESR, PINCP, HHT, HINCP,
                                Age, RaceCode, RaceName, Gender))

### Household data: size, child present, senior present, and income cat ###

# Number of HH members, HHSize
# Every person in the same household, ie. sharing the same SERIALNO
HHSize <- data
HHSize <- subset(HHSize, select = c(SERIALNO, RELSHIPP))
HHSize$Person <- 1
Size <- ddply(HHSize, .(SERIALNO), summarise,
              HHSize = sum(Person))

data <- data %>% right_join(Size, by=c("SERIALNO"))
rm(HHSize, Size)

# Presence of children, ChildPresent
# Census def of children: All persons under 18, excluding people
# who maintain households, families, or subfamilies as
# a reference person or spouse

# For us, there is a child present (ChildPresent ==1) if
# there is at least one person under 18 who is not a reference person or spouse
# If no one meets these characteristics,
# then there is no child present (ChildPresent ==0)
HHChild <- data
HHChild <- subset(HHChild, select = c(SERIALNO, RELSHIPP, Age))
HHChild$IsChild <- NA
# Next line suggested by DLE from QC
HHChild$IsChild <- ifelse(!(HHChild$RELSHIPP %in% c(20, 21, 23)) & HHChild$Age < 18, 1, 0)
ChildPresent <- ddply(HHChild, .(SERIALNO), summarise,
                      ChildPresent= sum(IsChild))
ChildPresent$ChildPresent <- ifelse(ChildPresent$ChildPresent >= 1, 1, 0)
data <- data %>% right_join(ChildPresent, by=c("SERIALNO"))
rm(HHChild, ChildPresent)

# Presence of 65+ (inclusive), SeniorPresent
# 0 no, 1 yes
HHSenior <- data
HHSenior <- subset(HHSenior, select = c(SERIALNO, Age))
HHSenior$IsSenior <- NA
HHSenior$IsSenior <- ifelse(HHSenior$Age >= 65, 1, 0)
Senior <- ddply(HHSenior, .(SERIALNO), summarise,
                SeniorPresent= sum(IsSenior))
Senior$SeniorPresent <- ifelse(Senior$SeniorPresent >= 1, 1, 0)
data <- data %>% right_join(Senior, by=c("SERIALNO"))
rm(HHSenior, Senior)

# Use adjusting inflation factors 'factor(YEAR)' to get 2022 dollars
# Adjusting factors are annual CPI-U all items for San Diego-Carlsbad
factor2019 <- 344.416/299.433

data$AdjIncome <- 0
data$AdjIncome <- data$HINCP * factor2019

###############
## Very important assumption: we are only keeping non-negative income houses
# So, positive and 0 values only
data <- data %>% filter(AdjIncome >= 0)

# Define 16 income categories, IncomeCat (14 main ones (1 -14),
# and the defaults: NA (0) and everything else (15))
# We break over 200k into 4 more categories to better account for the 
# right-hand side tail
data$IncomeCat <- 0
data$IncomeCat <- ifelse(data$AdjIncome == 9999999, 0,
                  ifelse(data$AdjIncome < 15000, 1,
                  ifelse(data$AdjIncome >= 15000 & data$AdjIncome < 30000, 2,
                  ifelse(data$AdjIncome >= 30000 & data$AdjIncome < 45000, 3,
                  ifelse(data$AdjIncome >= 45000 & data$AdjIncome < 60000, 4,
                  ifelse(data$AdjIncome >= 60000 & data$AdjIncome < 75000, 5,       
                  ifelse(data$AdjIncome >= 75000 & data$AdjIncome < 100000, 6, 
                  ifelse(data$AdjIncome >= 100000 & data$AdjIncome < 125000, 7,
                  ifelse(data$AdjIncome >= 125000 & data$AdjIncome < 150000, 8,
                  ifelse(data$AdjIncome >= 150000 & data$AdjIncome < 200000, 9,
                  ifelse(data$AdjIncome >= 200000 & data$AdjIncome < 300000, 10,
                  ifelse(data$AdjIncome >= 300000 & data$AdjIncome < 500000, 11,
                  ifelse(data$AdjIncome >= 500000 & data$AdjIncome < 700000, 12,       
                  ifelse(data$AdjIncome >= 700000 & data$AdjIncome < 900000, 13,
                  ifelse(data$AdjIncome >= 900000 & data$AdjIncome < 1500000, 14, 15)
                  ))))))))))))))

### Householder data: In labor force, Sex ###

# Labor force (LF)
# 0 no, 1 yes
# Assume in LF if age between 16 and 70 and in labor force,
# which for our purposes is not 'not in labor force' Employment status
# This gives LF of all members, but when we collapse by unique household number
# we are left with the first reference person, which for our purposes is the householder
data$LF <- NA
data$LF <- ifelse(data$Age >= 16 & data$Age <=70 & data$ESR != 6, 1, 0)

# Sex
# 0 female, 1 male
data$Sex <- NA
data$Sex <- ifelse(data$Gender == "M", 1, 0)

### Compress into unique Households, HH ###

# Collapse into households, this keeps the first row of each SERIALNO
HH <- data %>% distinct(SERIALNO, .keep_all = TRUE)

############
# Using the annual (compound) growth rate to grow income
# We are using 2060 as an example, but it can be replicated using any other of
# the conformity years
growth_2026 <- 1.70
growth_2029 <- 1.86
growth_2032 <- 1.99
growth_2035 <- 2.01
growth_2040 <- 2.02
growth_2050 <- 1.99
growth_2060 <- 1.96

### Importantly, we are only growing the income of households whose householder is
# in the labor force
# 2060 income
HH$Inc2060 <- NA
HH$Inc2060 <- ifelse(HH$LF == 1, HH$AdjIncome * (1 + growth_2060/100),
                     HH$AdjIncome)

# Income cat 2060
HH$Cat2060 <- 0
HH$Cat2060 <- ifelse(HH$Inc2060 < 15000, 1,
               ifelse(HH$Inc2060 >= 15000 & HH$Inc2060 < 30000, 2,
               ifelse(HH$Inc2060 >= 30000 & HH$Inc2060 < 45000, 3,
               ifelse(HH$Inc2060 >= 45000 & HH$Inc2060 < 60000, 4,
               ifelse(HH$Inc2060 >= 60000 & HH$Inc2060 < 75000, 5,       
               ifelse(HH$Inc2060 >= 75000 & HH$Inc2060 < 100000, 6, 
               ifelse(HH$Inc2060 >= 100000 & HH$Inc2060 < 125000, 7,
               ifelse(HH$Inc2060 >= 125000 & HH$Inc2060 < 150000, 8,
               ifelse(HH$Inc2060 >= 150000 & HH$Inc2060 < 200000, 9,
               ifelse(HH$Inc2060 >= 200000 & HH$Inc2060 < 300000, 10,
               ifelse(HH$Inc2060 >= 300000 & HH$Inc2060 < 500000, 11,
               ifelse(HH$Inc2060 >= 500000 & HH$Inc2060 < 700000, 12,       
               ifelse(HH$Inc2060 >= 700000 & HH$Inc2060 < 900000, 13,
               ifelse(HH$Inc2060 >= 900000 & HH$Inc2060 < 1500000, 14, 15)
               )))))))))))))

### Logit regressions ###

# Add an indicator variable for each income category
# 1 if IncomeCat is in it and 0 if it is not
HH$Inc1 <-ifelse(HH$Cat2060 == 1, 1, 0)
HH$Inc2 <-ifelse(HH$Cat2060 == 2, 1, 0)
HH$Inc3 <-ifelse(HH$Cat2060 == 3, 1, 0)
HH$Inc4 <-ifelse(HH$Cat2060 == 4, 1, 0)
HH$Inc5 <-ifelse(HH$Cat2060 == 5, 1, 0)
HH$Inc6 <-ifelse(HH$Cat2060 == 6, 1, 0)
HH$Inc7 <-ifelse(HH$Cat2060 == 7, 1, 0)
HH$Inc8 <-ifelse(HH$Cat2060 == 8, 1, 0)
HH$Inc9 <-ifelse(HH$Cat2060 == 9, 1, 0)
HH$Inc10 <-ifelse(HH$Cat2060 == 10, 1, 0)
HH$Inc11 <-ifelse(HH$Cat2060 == 11, 1, 0)
HH$Inc12 <-ifelse(HH$Cat2060 == 12, 1, 0)
HH$Inc13 <-ifelse(HH$Cat2060 == 13, 1, 0)
HH$Inc14 <-ifelse(HH$Cat2060 == 14, 1, 0)

# Using survey weights
Weighted <- svydesign(ids = ~0,
                      weights = ~ WGTP,
                      nest = FALSE,
                      data = HH)

# This is just to define the design, because of the characteristics of householders,
# we don't lose any observations, as min age is 16, and max is 94
# summary(HH$Age)
Design <- subset(Weighted, Age > 15 & Age < 100)

# Logit models
# To avoid getting a warning (non-integer #successes in a binomial glm!), we use
# family = quasibinomial instead of family = binomial
# The warning is most likely derived from the weights.
# The estimated coefficients are the same, there could be variability in the S.E.
# However, this is not the case
logit1qb <- svyglm(Inc1 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit2qb <- svyglm(Inc2 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit3qb <- svyglm(Inc3 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit4qb <- svyglm(Inc4 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
### Category 5 has a different regression specification, namely ChildPresent and Age
# this is by design, since the original specification gives no significant coefficients
# apart from the intercept
# The 2 variables included were the most significant in the original regression,
# that is, those whose significance level was closest to 0.10
logit5qb <- svyglm(Inc5 ~ChildPresent  +
                     Age ,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit6qb <- svyglm(Inc6 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit7qb <- svyglm(Inc7 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit8qb <- svyglm(Inc8 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit9qb <- svyglm(Inc9 ~ HHSize + ChildPresent + SeniorPresent +
                     Age + LF + Sex,
                   family = quasibinomial (link = "logit"),
                   data = Weighted,
                   design = Design)
logit10qb <- svyglm(Inc10 ~ HHSize + ChildPresent + SeniorPresent +
                      Age + LF + Sex,
                    family = quasibinomial (link = "logit"),
                    data = Weighted,
                    design = Design)
logit11qb <- svyglm(Inc11 ~ HHSize + ChildPresent + SeniorPresent +
                      Age + LF + Sex,
                    family = quasibinomial (link = "logit"),
                    data = Weighted,
                    design = Design)
logit12qb <- svyglm(Inc12 ~ HHSize + ChildPresent + SeniorPresent +
                      Age + LF + Sex,
                    family = quasibinomial (link = "logit"),
                    data = Weighted,
                    design = Design)
logit13qb <- svyglm(Inc13 ~ HHSize + ChildPresent + SeniorPresent +
                      Age + LF + Sex,
                    family = quasibinomial (link = "logit"),
                    data = Weighted,
                    design = Design)
logit14qb <- svyglm(Inc14 ~ HHSize + ChildPresent + SeniorPresent +
                      Age + LF + Sex,
                    family = quasibinomial (link = "logit"),
                    data = Weighted,
                    design = Design)

# Summary of results
# Including family = binomial for comparison of coefficients and SE (1st logit)
logit1 <- svyglm(Inc1 ~ HHSize + ChildPresent + SeniorPresent +
                   Age + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
# Summarize to see which coefficients are significant
summary(logit1)
summary(logit1qb)
summary(logit2qb)
summary(logit3qb)
summary(logit4qb)
summary(logit5qb)
summary(logit6qb)
summary(logit7qb)
summary(logit8qb)
summary(logit9qb)
summary(logit10qb)
summary(logit11qb)
summary(logit12qb)
summary(logit13qb)
summary(logit14qb)

# Since the coefficients have to be copy-pasted, and there are potentially 658 = 94 * 7 of them,
# 94 for each year, and 7 years total
# (13 x 7 = 91 for logits 1 through 14, except 5; and 3 coefficients for logit 5),
# we build a table that can be exported to excel
# from there, the coefficients can be rearranged

# Retrieve the coefficients of each logit
sum1 <- as.data.frame(logit1qb$coefficients)
sum2 <- as.data.frame(logit2qb$coefficients)
sum3 <- as.data.frame(logit3qb$coefficients)
sum4 <- as.data.frame(logit4qb$coefficients)
sum5 <- as.data.frame(logit5qb$coefficients)
sum6 <- as.data.frame(logit6qb$coefficients)
sum7 <- as.data.frame(logit7qb$coefficients)
sum8 <- as.data.frame(logit8qb$coefficients)
sum9 <- as.data.frame(logit9qb$coefficients)
sum10 <- as.data.frame(logit10qb$coefficients)
sum11 <- as.data.frame(logit11qb$coefficients)
sum12 <- as.data.frame(logit12qb$coefficients)
sum13 <- as.data.frame(logit13qb$coefficients)
sum14 <- as.data.frame(logit14qb$coefficients)

# Name the columns
sum1 <- sum1 %>% rownames_to_column(var = "ID")
sum2 <- sum2 %>% rownames_to_column(var = "ID")
sum3 <- sum3 %>% rownames_to_column(var = "ID")
sum4 <- sum4 %>% rownames_to_column(var = "ID")
sum5 <- sum5 %>% rownames_to_column(var = "ID")
sum6 <- sum6 %>% rownames_to_column(var = "ID")
sum7 <- sum7 %>% rownames_to_column(var = "ID")
sum8 <- sum8 %>% rownames_to_column(var = "ID")
sum9 <- sum9 %>% rownames_to_column(var = "ID")
sum10 <- sum10 %>% rownames_to_column(var = "ID")
sum11 <- sum11 %>% rownames_to_column(var = "ID")
sum12 <- sum12 %>% rownames_to_column(var = "ID")
sum13 <- sum13 %>% rownames_to_column(var = "ID")
sum14 <- sum14 %>% rownames_to_column(var = "ID")

# Do a big coefficient table for regressions 1 through 14, except 5
# Copy the coefficients of logit 5 manually
coeffs <- merge(sum1, sum2, by = "ID")
coeffs <- merge(coeffs, sum3, by = "ID")
coeffs <- merge(coeffs, sum4, by = "ID")
coeffs <- merge(coeffs, sum6, by = "ID")
coeffs <- merge(coeffs, sum7, by = "ID")
coeffs <- merge(coeffs, sum8, by = "ID")
coeffs <- merge(coeffs, sum9, by = "ID")
coeffs <- merge(coeffs, sum10, by = "ID")
coeffs <- merge(coeffs, sum11, by = "ID")
coeffs <- merge(coeffs, sum12, by = "ID")
coeffs <- merge(coeffs, sum13, by = "ID")
coeffs <- merge(coeffs, sum14, by = "ID")

write_xlsx(coeffs, "C:/Users/fhe/Weekly tasks/IPUMS/HH_Income/Coeffs2026.xlsx")
# Copy the significant coefficients at the 0.05 level or higher
rm(logit1qb, logit2qb, logit3qb, logit4qb, logit5qb, logit6qb, logit7qb, logit8qb, logit9qb,
   logit10qb, logit11qb, logit12qb, logit13qb, logit14qb)

# Fitting a gamma distribution using the logit results (original or calibrated)

# For using the fitmixturegrouped function, we have to specify a few variables.
# K is the number of components, meaning the number of distributions where the data 
# comes from. We set it equal to 1 because we are not using a "mix" of distributions
# so, we assume our data comes from only one distribution and not a combination of many.
# r is the range of our intervals, that is, of our income categories,
# the first interval is [0,15000), the second [15,000,30000), and so on
# f is the frequency from the logit estimation in the excel file,
# sheet 'PUMS 2019 model' cells H48:U48 (original logits), H22:U22 (calibrated logits),
# or 2022 estimates, sheet '2022 estimates' G21:T21
# The current frequency corresponds to 2022 calibrated logits
K <- 1 
f <- c(574, 799, 767, 1237, 876, 991, 1339, 860, 990, 983, 435, 69, 70, 168)
r <- c(0, 15000, 30000, 45000, 60000, 75000,
       100000, 125000, 150000, 200000, 300000,
       500000, 700000, 900000, 1500000)

# Fit the distribution and paste the respective parameters in the excel file
# Sheet 'PUMS 2019 model', cells Y24:Y25, OR '2022 estimates' cells B37:B38.
fitmixturegrouped("gamma",r,f,K,initial=FALSE)