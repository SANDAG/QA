

maindir = dirname(rstudioapi::getSourceEditorContext()$path)
setwd(maindir)

source("common_functions.R")
source("../Queries/readSQL.R")
source("config.R")

packages <- c("RODBC","rgdal")
pkgTest(packages)


# connect to database
channel <- odbcDriverConnect('driver={SQL Server}; server=sql2014a8; database=demographic_warehouse; trusted_connection=true')
# get parcels with adus
adu_df <- readDB("../Queries/adu.sql",datasource_id_current)
odbcClose(channel)


d <- data.frame(lon=adu_df$X, lat=adu_df$Y)
coordinates(d) <- 1:2
proj4string(d) <- CRS("+init=epsg:2875")
latlon <- spTransform(d, CRS("+init=epsg:4326"))
output <- adu_df
output$lat <- coordinates(latlon)[,2]
output$lon <- coordinates(latlon)[,1]


subset(output,du_2018 >1)

