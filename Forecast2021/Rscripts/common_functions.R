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


rm_special_chr <- function(df) {
  # clean up cpa names removing asterick and dashes etc.
  df$geozone <- gsub("\\*","",df$geozone)
  df$geozone <- gsub("\\-","_",df$geozone)
  df$geozone <- gsub("\\:","_",df$geozone)
  return(df)
}