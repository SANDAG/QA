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
# So, we are excluding group quarters (TYPEHUGQ == 2 and TYPEHUGQ 3)
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

# For us, there is a children present (ChildPresent ==1) if
# there is at least one person under 18 who is not a reference person or spouse
# If no one meets these characteristics,
# then there is no child present (ChildPresent ==0)
HHChild <- data
HHChild <- subset(HHChild, select = c(SERIALNO, RELSHIPP, Age))
HHChild$IsChild <- NA
HHChild$IsChild <- ifelse((HHChild$RELSHIPP != 20 | HHChild$RELSHIPP != 21 |
                             HHChild$RELSHIPP != 23) & HHChild$Age < 18, 1, 0)
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
# Keep only positive-income households
factor2019 <- 344.416/299.433
factor2020 <- 344.416/303.932
factor2021 <- 344.416/319.761

data$AdjIncome <- 0
data$AdjIncome <- data$HINCP * factor2019
data <- data %>% filter(AdjIncome > 0)

# Define 14 income categories, IncomeCat
# We break over 200k into 4 more categories to better account for the tail
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
                  ifelse(data$AdjIncome >= 700000 & data$AdjIncome < 900000, 13, 14)
                  )))))))))))))


### Householder data: In labor force, Sex, Age category ###

# Labor force (LF)
# 0 no, 1 yes
# Assume in LF if age between 16 and 70 and in labor force,
# which for our purposes is not 'not in labor force' Employment status
data$LF <- NA
data$LF <- ifelse(data$Age >= 16 & data$Age <=70 & data$ESR != 6, 1, 0)

# Sex
# 0 female, 1 male
data$Sex <- NA
data$Sex <- ifelse(data$Gender == "M", 1, 0)

# Age categories
# Category 1: less than 15, Category 2: 15 (inclusive) to 25,
# Category 3: 25 (inclusive) to 70, Category 4: 70 and older
data$AgeCode <- 0
data$AgeCode <- ifelse(data$Age < 15, 1,
                 ifelse(data$Age >= 15 & data$Age < 25, 2,
                 ifelse(data$Age >= 25 & data$Age < 70, 3,
                 ifelse(data$Age >= 70, 4, 0))))

### Compress into unique Households, HH ###

# Collapse into households, this keeps the first row of each SERIALNO
HH <- data %>% distinct(SERIALNO, .keep_all = TRUE)

### Select the most relevant variables for the regressions ###

# Use principal component analysis (PCA) to find the main
# components (a component is a sort of "combination" of variables)
# The main components are those whose eigenvalues are greater than 1

# Deal with a smaller set of variables
PC <- subset(HH, select = c(WGTP, AdjIncome, IncomeCat, HHSize,
                            ChildPresent, SeniorPresent,
                            AgeCode, Sex, RaceCode, LF))
attach(PC)

# These are the variables to choose from
X <- cbind(HHSize, ChildPresent, SeniorPresent,
           AgeCode, Sex, RaceCode, LF)

# Principal component analysis
pca1 <- princomp(X, scores = TRUE, cor = TRUE)

# This is the plot with the eigenvalues
# Keep components with values above 1
screeplot(pca1, type="line", main="Scree Plot")
abline(h=1, col = "blue")

# To check which variables are relevant, select those whose
# loadings are below -0/3 or above 0.3
loadings(pca1)

# To determine whether Race(code) should be included look at correlation matrix
# Since it has the lowest correlation with IncomeCat we will not include it
Y <- cbind(IncomeCat, HHSize, ChildPresent, SeniorPresent,
           AgeCode, Sex, RaceCode, LF)
cor(Y)
rm(PC, X, Y, pca1)

### Logit regressions ###

# Add an indicator variable for each income category
# 1 if IncomeCat is in it and 0 if it is not
HH$Inc1 <-ifelse(HH$IncomeCat == 1, 1, 0)
HH$Inc2 <-ifelse(HH$IncomeCat == 2, 1, 0)
HH$Inc3 <-ifelse(HH$IncomeCat == 3, 1, 0)
HH$Inc4 <-ifelse(HH$IncomeCat == 4, 1, 0)
HH$Inc5 <-ifelse(HH$IncomeCat == 5, 1, 0)
HH$Inc6 <-ifelse(HH$IncomeCat == 6, 1, 0)
HH$Inc7 <-ifelse(HH$IncomeCat == 7, 1, 0)
HH$Inc8 <-ifelse(HH$IncomeCat == 8, 1, 0)
HH$Inc9 <-ifelse(HH$IncomeCat == 9, 1, 0)
HH$Inc10 <-ifelse(HH$IncomeCat == 10, 1, 0)
HH$Inc11 <-ifelse(HH$IncomeCat == 11, 1, 0)
HH$Inc12 <-ifelse(HH$IncomeCat == 12, 1, 0)
HH$Inc13 <-ifelse(HH$IncomeCat == 13, 1, 0)
HH$Inc14 <-ifelse(HH$IncomeCat == 14, 1, 0)

# Using survey weights
Weighted <- svydesign(ids = ~0,
                      weights = ~ WGTP,
                      nest = FALSE,
                      data = HH)

Design <- subset(Weighted, Age > 15 & Age < 95)

# Logit models
logit1 <- svyglm(Inc1 ~ HHSize + ChildPresent + SeniorPresent +
                        AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit2 <- svyglm(Inc2 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit3 <- svyglm(Inc3 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit4 <- svyglm(Inc4 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit5 <- svyglm(Inc5 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit6 <- svyglm(Inc6 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit7 <- svyglm(Inc7 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit8 <- svyglm(Inc8 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit9 <- svyglm(Inc9 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit10 <- svyglm(Inc10 ~ HHSize + ChildPresent + SeniorPresent +
                   AgeCode + LF + Sex,
                 family = binomial (link = "logit"),
                 data = Weighted,
                 design = Design)
logit11 <- svyglm(Inc11 ~ HHSize + ChildPresent + SeniorPresent +
                    AgeCode + LF + Sex,
                  family = binomial (link = "logit"),
                  data = Weighted,
                  design = Design)
logit12 <- svyglm(Inc12 ~ HHSize + ChildPresent + SeniorPresent +
                    AgeCode + LF + Sex,
                  family = binomial (link = "logit"),
                  data = Weighted,
                  design = Design)
logit13 <- svyglm(Inc13 ~ HHSize + ChildPresent + SeniorPresent +
                    AgeCode + LF + Sex,
                  family = binomial (link = "logit"),
                  data = Weighted,
                  design = Design)
logit14 <- svyglm(Inc14 ~ HHSize + ChildPresent + SeniorPresent +
                    AgeCode + LF + Sex,
                  family = binomial (link = "logit"),
                  data = Weighted,
                  design = Design)

# Summarize to see which coefficients are significant
# Copy those that are significant at the 0.05 level 
# into the Excel file, sheet 'Logits (2019 Model)' cells L5:Y11
summary(logit1)
summary(logit2)
summary(logit3)
summary(logit4)
summary(logit5)
summary(logit6)
summary(logit7)
summary(logit8)
summary(logit9)
summary(logit10)
summary(logit11)
summary(logit12)
summary(logit13)
summary(logit14)

# Get sample means to plug into the logit equations in the excel file
# sheet 'Logits (2019 Model)' cells Z6:Z11
avgHHSize <- svymean(~HHSize, Weighted, na.rm = TRUE)
avgChild <- svymean(~ChildPresent, Weighted, na.rm = TRUE)
avgSenior <- svymean(~SeniorPresent, Weighted, na.rm = TRUE)
avgAge <- svymean(~AgeCode, Weighted, na.rm = TRUE)
avgLF <- svymean(~LF, Weighted, na.rm = TRUE)
avgSex <- svymean(~Sex, Weighted, na.rm = TRUE)

avgHHSize
avgChild
avgSenior
avgAge
avgLF
avgSex

# We will be using the empirical frequencies of 2019 for comparison
# Paste these values into the excel file as well,
# sheet 'Logits (2019 Model)' L20:Y20. Note we are using not just normal
# averages, but we are using the household weights from the survey, WGTP

# HHs (in thousands) in each income category - Weighted
detach(package:plyr)
TotalWG <- sum(HH$WGTP)
TotalUW <- nrow(HH)
Distribution <- HH %>%
  group_by(IncomeCat) %>%
  summarize(Weighted = sum(WGTP)/TotalWG,
            Unweighted = n()/TotalUW)
Distribution
rm(TotalWG, TotalUW)

# Fitting a gamma and log-normal distribution
# Using the frequencies obtained in Excel (using the adjusted coefficients)

# For using the fitmixturegrouped function, we have to specify a few variables.
# K is the number of components, meaning the number of distributions where the data 
# comes from. We set it equal to 1 because we are not using a "mix" of distributions
# so, we assume our data comes from only one distribution and not a combination of many
# r is the range of our intervals, that is, of our income categories
# we start with 35 instead of 0 because logarithms are not defined at 0,
# and because 35 is the nearest integer of the minimum household income
# So, the first interval is [30,15000), the second [15,000,30000) and so on
# f is the frequency from the adjusted logit estimation in the excel file,
# sheet 'Logits (2019 Model)'cells L49:Y49 
l <- round(min(HH$AdjIncome),0)
l
m <- round(max(HH$AdjIncome),0)
m
K <- 1 
f <- c(4, 4, 24, 13, 9, 13, 17, 4, 7, 8, 10, 1, 1, 0)
r <- c(35, 15000, 30000, 45000, 60000, 75000,
       100000, 125000, 150000, 200000, 300000,
       500000, 700000, 900000, 1500000)

# Fit the distributions and paste the respective parameters in the excel file
# Sheet '2019 Model', cells B53:D54
fitmixturegrouped("gamma",r,f,K,initial=FALSE)
fitmixturegrouped("log-normal",r,f,K,initial=FALSE)
fitmixturegrouped("weibull",r,f,K,initial=FALSE)

##### End of the main part of the program #####









# The rest is for producing plots for presentations and code snippets no longer
# useful#

# Plotting histogram and fitted curves
h <- hist(HH$AdjIncome, breaks = 50)
plot(h, freq =FALSE, main = "Empirical frequencies and fitted distributions",
     xlab = "Income in thousands (2022 dollars)", ylab="Frequency",
     xlim = c(0,500000), ylim = c(0,0.00001),
     xaxt = "n")
axis(1,
     at = c(0, 30000, 60000, 90000, 120000, 150000, 200000,
            300000, 500000, 800000, 1000000),
     labels = c(0, 30, 60, 90, 120, 150, 200, 300, 500, 800, 1000))
curve(dlnorm(x, meanlog=11.42365, sdlog=0.8734723), add =TRUE,
      from = 0, to = 500000, col = 'blue', lwd =2)
curve(dgamma(x, shape =1.449759, scale = 91439.87), add =TRUE,
      from = 0, to = 700000, col = 'red', lwd =2)
curve(dweibull(x, shape = 1.198797, scale = 164057.9), add =TRUE,
      from = 0, to = 500000, col = 'magenta', lwd =2)
legend(x = "topright",          # Position
       legend = c("Gamma", "Log-normal", "Weibull"),  # Legend texts
       col = c("red", "blue", "magenta"),           # Line colors
       lwd = 2)


## Code snippets ##
# DO NOT RUN #

# Different run specification for logit
Y1 <- cbind(Inc1)
X <- cbind(HHSize, ChildPresent, SeniorPresent, 
           AgeCode, LF, Sex)
logit1 <- glm(Y1 ~ X, family =binomial (link = "logit"))

# Logit model average marginal effects
LogitScalar1 <- mean(dlogis(predict(logit1, type = "link")))
LogitScalar1*coef(logit1)

# Logit model predicted probabilities
plogit1 <- predict(logit1, type = "response")
summary(plogit1)
table(Y1)/sum(table(Y1))

# Percent correctly predicted values
L1 <- table(true = Y1, pred = round(fitted(logit1)))
table(true = Y1, pred = round(fitted(logit1)))

mn <- svymean(~AdjIncome, Weighted, na.rm = TRUE)

# Empirical cumulative distribution function plot
plot(ecdf(HH$AdjIncome), main ="Empirical cumulative distribution function")

# Quantiles and other measures
deciles <- quantile(HH$AdjIncome, probs=seq(0.1, 1, by=0.1))
quartiles <- quantile(HH$AdjIncome, probs = seq(0.25,1, by=0.25))

# Ventiles using weights
ventiles <- svyquantile(~AdjIncome, Weighted, quantile=c(0.05,0.1,0.15,0.2,
                                                         0.25,0.3,0.35,0.4,
                                                         0.45,0.5,0.55,0.6,
                                                         0.65,0.7,0.75,0.8,
                                                         0.85,0.9,0.95), ci =FALSE)
ventiles[["AdjIncome"]]

# Testing for accuracy
plogit1 <- predict(logit1, type = "response", newdata = HH)
T1 <- data.frame(plogit1)
T1['Observed'] <- NA
T1$Observed <- HH$Inc1
T1['Round'] <- NA
T1$Round <- round(T1$response)
T1['Cutoff'] <- NA
T1$Cutoff <- ifelse(T1$response >= 0.5, 1, 0)
T1['Validation'] <- NA
T1$Validation <- ifelse(T1$Observed == T1$Cutoff, 1, 0)
summary(T1)

