vars <- c("RelativeHumidity", "SolarRadiation", "TemperatureMean", "TemperatureMax", "TemperatureMin", "WindSpeed")
names(vars) <- c("RelativeHumidity", "SolarRadiation", "TemperatureMean", "TemperatureMax", "TemperatureMin", "WindSpeed")
years <- seq(1990, as.integer(format(Sys.Date(), "%Y"))-1)
pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
bb <- terra::ext(pol)
origin<- getwd()

cat('\n#############################################################################')
cat('\nstarted AgERA5')

for (i in seq_along(vars)) {
  setwd(origin)
  vname <- names(vars[i])
  v <- vars[i][[1]]
  dir.create(path = paste0("./data/inputs/main/weather/historical/", vname), recursive = TRUE, showWarnings = FALSE)
  for (year in years){
    if(!file.exists(paste0("./data/inputs/main/weather/historical/", vname, "/", year, ".nc"))){
      R <- terra::rast(paste0("/home/jovyan/common_data/ecmwf_agera5/netcdf/", vname, "/AgEra/", year, ".nc"))
      R <- terra::crop(R, bb)
      terra::writeCDF(R, filename = paste0("./data/inputs/main/weather/historical/", vname, "/", year, ".nc"), prec = "float", compression = 5, overwrite = TRUE)
    }
  }
}

setwd(origin)

cat('\nSuccesfully completed AgERA5 download\n')
