
calculate_pct_chg <- function(df, edam_var) {
  edam_var <- enquo(edam_var)
  df1 <- df %>% select("datasource_id","yr_id","geotype","geozone",!!edam_var)
  #change over increments 
  df1 <- df1 %>% 
    group_by(geozone,geotype) %>% 
    mutate(change = !!edam_var - lag(!!edam_var))
  #percent change over increments
  df1 <- df1 %>%
    group_by(geozone,geotype) %>%  # avoid divide by zero with ifelse
    mutate(percent_change = ifelse(lag(!!edam_var)==0, NA, (!!edam_var - lag(!!edam_var))/lag(!!edam_var)))
  df1$percent_change <- round(df1$percent_change, digits = 2)
  #average annual change
  df1 <- df1 %>% 
    group_by(geozone,geotype) %>% 
    mutate(average_annual_change = (!!edam_var - lag(!!edam_var))/(yr_id - lag(yr_id)) )
  df1$average_annual_change  <- round(df1$average_annual_change, digits = 0)
  #average annual percent change
  df1 <- df1 %>%
    group_by(geozone,geotype) %>%  # avoid divide by zero with ifelse
    mutate(avg_ann_pct_chg = ifelse(lag(!!edam_var)==0, NA, 
                                    (!!edam_var - lag(!!edam_var))/lag(!!edam_var)/(yr_id - lag(yr_id))))
  df1$avg_ann_pct_chg <- round(df1$avg_ann_pct_chg, digits = 2)
  return(df1)
}

calculate_pass_fail <- function(df, cutoff1,cutoff2) {
  df <- df %>%
    mutate(pass.or.fail = case_when(change > cutoff1 & percent_change > cutoff2 ~ "fail",
                                    #average_annual_change >= cutoff1 & avg_ann_pct_chg >= cutoff2 ~ "fail",
                                    #change >= cutoff1 & percent_change  >= cutoff2 ~ "check",
                                    #change >= cutoff1 & percent_change < cutoff2 & geotype == 'cpa' ~ "check",
                                    #change < cutoff1 & percent_change >= cutoff2 ~ "check",
                                    TRUE ~ "pass"))
  return(df)
}


sort_dataframe <- function(df) {
  df_fail <- unique(subset(df,pass.or.fail=="fail")$geozone)
  df_check <- unique(subset(df,pass.or.fail=="check")$geozone)
  df <- df %>% 
    mutate(sort_order = case_when(geozone %in% df_fail ~ 1,
                                  geozone %in% df_check ~ 2,
                                  TRUE ~ 3))
  df <- df[order(df$sort_order,df$geotype,df$geozone,df$yr_id),]
  df$sort_order <- NULL
  return(df)
}

rename_dataframe <- function(df) {
  df <- df %>% rename('increment'= yr_id,'increment change' = change,
                      'average annual change' = average_annual_change,
                      'average annual percent change' = avg_ann_pct_chg,
                      'increment percent change' = percent_change,
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

subset_by_geotype <- function(df,the_geotype) {
  df1 <- subset(df,geotype %in% the_geotype)
  df2 <- add_id_for_excel_formatting(df1)
  df2 <- df2 %>% rename(!!the_geotype[1] := geozone)
  #df %>% rename(!!variable := name_of_col_from_df)
  df2$geotype <- NULL
  return(df2)
}

# add sheets with data 
add_worksheets_to_excel <- function(workbook,demographic_variable,colorfortab) {
  tabname <- paste(demographic_variable,"ByJur",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  tabname <- paste(demographic_variable,"ByCpa",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
  tabname <- paste(demographic_variable,"ByRegion",sep='')
  addWorksheet(wb, tabname, tabColour = colorfortab)
}

add_data_to_excel <- function(workbook,demographic_variable,j,m) {
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_jur',sep='')))
  writeData(wb,j,dataframe_name)
  writeComment(wb,j,col = "I",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_cpa',sep='')))
  writeData(wb, j+1,dataframe_name)
  writeComment(wb,j+1,col = "I",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
  dataframe_name <- eval(parse(text = paste(demographic_variable,'_region',sep='')))
  writeData(wb, j+2,dataframe_name)
  writeComment(wb,j+2,col = "I",row = 1,comment = createComment(comment = comments_to_add[[demographic_variable]]))
}  
