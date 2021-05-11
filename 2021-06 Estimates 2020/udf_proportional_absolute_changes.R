#udf to return flagged records from a given dataset (proportional changes and absolute changes)
#Parameters: dataset, geographyid (ex. region, jurisdiction, zip), and categoryid (ex. age_group_id)
#Author: Kelsie Telson

age_est_test_prop <- function(dataset, geographyid) { 
  
  require("dplyr")
  
  
  #initialize variables to assess proportional changes over time
  working<- dataset%>%
    group_by_(geographyid)%>%
    mutate("prop_10"=round((`2010`/sum(`2010`))*100,2),
           "prop_11"=round((`2011`/sum(`2011`))*100,2),
           "prop_12"=round((`2012`/sum(`2012`))*100,2),
           "prop_13"=round((`2013`/sum(`2013`))*100,2),
           "prop_14"=round((`2014`/sum(`2014`))*100,2),
           "prop_15"=round((`2015`/sum(`2015`))*100,2),
           "prop_16"=round((`2016`/sum(`2016`))*100,2),
           "prop_17"=round((`2017`/sum(`2017`))*100,2),
           "prop_18"=round((`2018`/sum(`2018`))*100,2),
           "prop_19"=round((`2019`/sum(`2019`))*100,2),
           "prop_20"=round((`2020`/sum(`2020`))*100,2))
  
  working$tProp11 <-working$prop_11-working$prop_10
  working$tProp12 <-working$prop_12-working$prop_11
  working$tProp13 <-working$prop_13-working$prop_12
  working$tProp14 <-working$prop_14-working$prop_13
  working$tProp15 <-working$prop_15-working$prop_14
  working$tProp16 <-working$prop_16-working$prop_15
  working$tProp17 <-working$prop_17-working$prop_16
  working$tProp18 <-working$prop_18-working$prop_17
  working$tProp19 <-working$prop_19-working$prop_18
  working$tProp20 <-working$prop_20-working$prop_19
  
  test<- subset(working, 
                tProp11 >= 5 |
                  tProp12 >= 5 |  
                  tProp13 >= 5 |
                  tProp14 >= 5 |
                  tProp15 >= 5 |
                  tProp16 >= 5 |
                  tProp17 >= 5 |
                  tProp18 >= 5 |
                  tProp19 >= 5 |
                  tProp20 >= 5 |
                  tProp11 <= -5|
                  tProp12 <= -5|
                  tProp13 <= -5|
                  tProp14 <= -5|
                  tProp15 <= -5|
                  tProp16 <= -5|
                  tProp17 <= -5|
                  tProp18 <= -5|
                  tProp19 <= -5|
                  tProp20 <= -5)
  
  return(test)
  
}

age_est_test_abso <- function(dataset, geographyid, categoryid) { 
  
  require("dplyr")
  
  
  #initialize variables to assess proportional changes over time
  working<- dataset%>%
    group_by_(geographyid,categoryid)%>%
    mutate("10_11%chg"=round(((`2011`-`2010`)/`2010`)*100,2),
           "11_12%chg"=round(((`2012`-`2011`)/`2011`)*100,2),
           "12_13%chg"=round(((`2013`-`2012`)/`2012`)*100,2),
           "13_14%chg"=round(((`2014`-`2013`)/`2013`)*100,2),
           "14_15%chg"=round(((`2015`-`2014`)/`2014`)*100,2),
           "15_16%chg"=round(((`2016`-`2015`)/`2015`)*100,2),
           "16_17%chg"=round(((`2017`-`2016`)/`2016`)*100,2),
           "17_18%chg"=round(((`2018`-`2017`)/`2017`)*100,2),
           "18_19%chg"=round(((`2019`-`2018`)/`2018`)*100,2),
           "19_20%chg"=round(((`2020`-`2019`)/`2019`)*100,2))
  
  test<- subset(working, 
                `10_11%chg` >= 5 |
                  `11_12%chg` >= 5 |  
                  `12_13%chg` >= 5 |
                  `13_14%chg` >= 5 |
                  `14_15%chg` >= 5 |
                  `15_16%chg` >= 5 |
                  `16_17%chg` >= 5 |
                  `17_18%chg` >= 5 |
                  `18_19%chg` >= 5 |
                  `19_20%chg` >= 5 |
                  `10_11%chg` <= -5 |
                  `11_12%chg` <= -5 |  
                  `12_13%chg` <= -5 |
                  `13_14%chg` <= -5 |
                  `14_15%chg` <= -5 |
                  `15_16%chg` <= -5 |
                  `16_17%chg` <= -5 |
                  `17_18%chg` <= -5 |
                  `18_19%chg` <= -5 |
                  `19_20%chg` <= -5 )
  
  return(test)
  
}