

calculate_pct_chg <- function(df, edam_var) {
  edam_var <- enquo(edam_var)
  df1 <- df %>% select("datasource_id","geotype","geo_id","geozone","yr_id",!!edam_var)
  #change over increments 
  df1 <- df1 %>% 
    group_by(geozone,geotype) %>% 
    dplyr::mutate(change = !!edam_var - lag(!!edam_var))
  #percent change over increments
  df1 <- df1 %>%
    group_by(geozone,geotype) %>% 
    dplyr::mutate(percent_change = case_when(lag(!!edam_var)==0 & (!!edam_var==0)  ~ 0,
                                      lag(!!edam_var)==0   ~ 1 ,
                                      TRUE ~ (!!edam_var - lag(!!edam_var))/lag(!!edam_var))) 
 
 # df1 <- df1 %>%
  #  group_by(geozone,geotype) %>%  # avoid divide by zero with ifelse
    #mutate(percent_change = ifelse(lag(!!edam_var)==0, NA, (!!edam_var - lag(!!edam_var))/lag(!!edam_var)))
  
  df1$percent_change <- round(df1$percent_change, digits = 2)
  # #average annual change
  # df1 <- df1 %>% 
  #   group_by(geozone,geotype) %>% 
  #   mutate(average_annual_change = (!!edam_var - lag(!!edam_var))/(yr_id - lag(yr_id)) )
  # df1$average_annual_change  <- round(df1$average_annual_change, digits = 0)
  # #average annual percent change
  # df1 <- df1 %>%
  #   group_by(geozone,geotype) %>%  # avoid divide by zero with ifelse
  #   mutate(avg_ann_pct_chg = ifelse(lag(!!edam_var)==0, NA, 
  #                                   (!!edam_var - lag(!!edam_var))/lag(!!edam_var)/(yr_id - lag(yr_id))))
  # df1$avg_ann_pct_chg <- round(df1$avg_ann_pct_chg, digits = 2)
  return(df1)
}




calculate_pass_fail <- function(df, cutoff1,cutoff2) {
  df <- df %>%
    mutate(pass.or.fail = case_when(abs(change) > cutoff1 & abs(percent_change) > cutoff2 ~ "fail",
                                    #average_annual_change >= cutoff1 & avg_ann_pct_chg >= cutoff2 ~ "fail",
                                    #change >= cutoff1 & percent_change  >= cutoff2 ~ "check",
                                    #change >= cutoff1 & percent_change < cutoff2 & geotype == 'cpa' ~ "check",
                                    #change < cutoff1 & percent_change >= cutoff2 ~ "check",
                                    TRUE ~ "pass"))
  return(df)
}

# df <- units
# df <- units
sort_dataframe <- function(df) {
  df_fail <- unique(subset(df,pass.or.fail=="fail")$geozone)
  df_check <- unique(subset(df,pass.or.fail=="check")$geozone)
  df <- df %>% 
    dplyr::mutate(sort_order = case_when(geozone %in% df_fail ~ 1,
                                  geozone %in% df_check ~ 2,
                                  TRUE ~ 3))
  df <- df[order(df$sort_order,df$geotype,df$geozone,df$yr_id),]
  df$sort_order <- NULL
  return(df)
}
# df <- jobs
# failures <- failedgeos
sort_dataframe_geos <- function(df,failures) {
  #df_fail <- unique(subset(df,pass.or.fail=="fail")$geozone)
  #df_check <- unique(subset(df,pass.or.fail=="check")$geozone)
  df <- df %>% 
    mutate(sort_order = case_when(geozone %in% failures ~ 1,
                                  TRUE ~ 3))
  df <- df[order(df$sort_order,df$geotype,df$geozone,df$yr_id),]
  df$sort_order <- NULL
  return(df)
}


rename_dataframe <- function(df) {
  df <- df %>% dplyr::rename('datasource id'= datasource_id,'geo id'=geo_id,
                      'increment' = yr_id,'change per increment' = change,
                      #'average annual change' = average_annual_change,
                      #'average annual percent change' = avg_ann_pct_chg,
                      'percent change per increment' = percent_change,
                      'pass/fail' = pass.or.fail)
  return(df)
}



add_id_for_excel_formatting <- function(df) {
  t <- df %>% group_by(geozone) %>% tally()
  if (nrow(subset(t,n!=9))!=0) {
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) } 
  
  ids <- rep(1:2, times=nrow(t)/2, each=9)
  if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
  df$id <- ids
  return(df)
}

add_id_for_excel_formatting_jobs <- function(df) {
  t <- df %>% group_by(geozone,sector) %>% tally()
  if (nrow(subset(t,n!=9))!=0) {
    print("ERROR: expecting 9 years per geography")
    print(subset(t,n!=9)) } 
  
  ids <- rep(1:2, times=nrow(t)/2, each=9)
  if (nrow(t)%%2!=0 ) {ids <- append(ids, c(1,1,1,1,1,1,1,1,1))}
  df$id <- ids
  return(df)
}

#df <- units
#the_geotype <- 'cpa'
subset_by_geotype <- function(df,the_geotype) {
  df1 <- subset(df,geotype %in% the_geotype)
  df2 <- add_id_for_excel_formatting(df1)
  df2 <- df2 %>% dplyr::rename(!!the_geotype[1] := geozone)
  # df %>% rename(!!variable := name_of_col_from_df)
  df2$geotype <- NULL
  return(df2)
}

subset_by_geotype_jobs <- function(df,the_geotype) {
  df1 <- subset(df,geotype %in% the_geotype)
  df2 <- add_id_for_excel_formatting_jobs(df1)
  df2 <- df2 %>% rename(!!the_geotype[1] := geozone)
  #df %>% rename(!!variable := name_of_col_from_df)
  df2$geotype <- NULL
  return(df2)
}

# add sheets with data 
add_worksheets_to_excel <- function(workbook,demographic_variable,colorfortab,rowtouse,namehash,ahash) {
  tabname <- paste(demographic_variable,"ByJur",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  ## Internal - Text to display
  writeFormula(wb, tableofcontents, startRow = rowtouse, 
               x = makeHyperlinkString(sheet = tabname, row = 1, col = 1,text = tabname))
  writeData(wb, tableofcontents, x = paste(namehash[[demographic_variable]]," by Jurisdiction",sep=''), startCol = 2, startRow = rowtouse)
  writeData(wb, tableofcontents, x = ahash[[demographic_variable]], startCol = 3, startRow = rowtouse) 
  tabname <- paste(demographic_variable,"ByCpa",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  writeFormula(wb, tableofcontents, startRow = rowtouse + 1, 
               x = makeHyperlinkString(sheet = tabname, row = 1, col = 1,text = tabname))
  writeData(wb, tableofcontents, x = paste(namehash[[demographic_variable]]," by CPA",sep=''), 
            startCol = 2, startRow = rowtouse+1)
  
  writeData(wb, tableofcontents, x = ahash[[demographic_variable]], startCol = 3, startRow = rowtouse+1)
  tabname <- paste(demographic_variable,"ByRegion",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  writeFormula(wb, tableofcontents, startRow = rowtouse + 2, 
               x = makeHyperlinkString(sheet = tabname, row = 1, col = 1,text = tabname))
  writeData(wb, tableofcontents, x = paste(namehash[[demographic_variable]]," by Region",sep=''), 
            startCol = 2, startRow = rowtouse +2)
  writeData(wb, tableofcontents, x = ahash[[demographic_variable]], startCol = 3, startRow = rowtouse+2)
  freezePane(wb, tabname, firstRow = TRUE)
}

add_data_to_excel <- function(workbook,demographic_variable,j,m) {
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_jur',sep='')))
  writeData(wb,j,dataframe_name)
  writeComment(wb,j,col = "H",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_cpa',sep='')))
  writeData(wb, j+1,dataframe_name)
  writeComment(wb,j+1,col = "H",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_region',sep='')))
  writeData(wb, j+2,dataframe_name)
  writeComment(wb,j+2,col = "H",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
}  
add_data_to_excel_jobs <- function(workbook,demographic_variable,j,m) {
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_jur',sep='')))
  writeData(wb,j,dataframe_name)
  writeComment(wb,j,col = "H",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_cpa',sep='')))
  writeData(wb, j+1,dataframe_name)
  writeComment(wb,j+1,col = "H",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_region',sep='')))
  writeData(wb, j+2,dataframe_name)
  writeComment(wb,j+2,col = "H",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
}  

# create dataframe with summary of results
# include only geographies that fail in summary
df <- units

get_fails <- function(df) {
  df <- df %>% select("datasource_id","geotype","geo_id","geozone","yr_id","pass.or.fail")
  df <- spread(df,yr_id,'pass.or.fail')
  df <-df %>% filter_all(any_vars(. %in% c('fail')))
  drops <- c("2016","2018","2020","2025","2030","2035","2040","2045","2050")
  df <- df[ , !(names(df) %in% drops)]
  return(df) 
}  
