# fix names of sr13 cpas to match sr14 cpas
rename_sr13_cpas <- function(df) {
  df$geozone[df$geozone == "City Heights"] <- "Mid-City:City Heights"
  df$geozone[df$geozone == "Normal Heights"] <- "Mid-City:Normal Heights"
  df$geozone[df$geozone == "Kensington-Talmadge"] <- "Mid-City:Kensington-Talmadge"
  df$geozone[df$geozone == "Ncfua Reserve"] <- "NCFUA Reserve"
  df$geozone[df$geozone == "Ncfua Subarea 2"] <- "NCFUA Subarea 2"
  df$geozone[df$geozone == "Nestor"] <- "Otay Mesa-Nestor"
  df$geozone[df$geozone == "Encanto"] <- "Southeastern:Encanto Neighborhoods"
  df$geozone[df$geozone == "Eastern Area"] <- "Mid-City:Eastern Area"
  df$geozone[df$geozone == "Southeastern San Diego"] <- "Southeastern:Southeastern San Diego"
  return(df)
}

# clean up cpa names removing asterick and dashes etc.
rm_special_chr <- function(df) {
  df$geozone <- gsub("\\*","",df$geozone)
  df$geozone <- gsub("\\-","_",df$geozone)
  df$geozone <- gsub("\\:","_",df$geozone)
  return(df)
}

# load packages
pkgTest <- function(pkg){
  new.pkg <- pkg[!(pkg %in% installed.packages()[, "Package"])]
  if (length(new.pkg))
    install.packages(new.pkg, dep = TRUE)
  sapply(pkg, require, character.only = TRUE)}

# get data from database
readDB <- function(sql_query,datasource_id_to_use){
  ds_sql = getSQL(sql_query)
  ds_sql <- gsub("ds_id",datasource_id_to_use,ds_sql)
  df<-sqlQuery(channel,ds_sql,stringsAsFactors = FALSE)
  return(df)
}
