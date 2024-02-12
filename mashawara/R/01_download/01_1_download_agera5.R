vars <- c("2m_relative_humidity", "solar_radiation_flux", "2m_temperature-24_hour_mean", "2m_temperature-24_hour_maximum", "2m_temperature-24_hour_minimum", "10m_wind_speed-24_hour_mean")
names(vars) <- c("RelativeHumidity", "SolarRadiation", "TemperatureMean", "TemperatureMax", "TemperatureMin", "WindSpeed")
years <- seq(1990, as.integer(format(Sys.Date(), "%Y"))-1)
months <- as.character(sprintf("%02d", 1:12))
pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
bb <- terra::ext(pol)
origin<- getwd()

cat('\n#############################################################################')
cat('\nstarted AgERA5')

for (i in seq_along(vars)) {
  setwd(origin)
  vname <- names(vars[i])
  v <- vars[i][[1]]
  for (year in years){
    if(!file.exists(paste0("./data/inputs/main/weather/historical/", vname, "/", year, ".nc"))){
      dir.create(path = paste0("./data/inputs/main/weather/historical/", vname, "/tmp"), recursive = TRUE, showWarnings = FALSE)
      for (month in months){
        suff <- ifelse(v %in% c("2m_relative_humidity", "solar_radiation_flux"), "-NA", "")
        unzip(paste0("/home/jovyan/common_data/ecmwf_agera5/", v, suff, "-", year, "-", month, ".zip"),
              exdir = paste0("./data/inputs/main/weather/historical/", vname, "/tmp/", v))
      }
      R <- terra::rast()
      for (file in list.files(paste0("./data/inputs/main/weather/historical/", vname, "/tmp/", v), full.names = TRUE)) {
        r <- terra::rast(file)
        terra::add(R) <- r
      }
      R <- terra::crop(R, bb)
      terra::writeCDF(R, filename = paste0("./data/inputs/main/weather/historical/", vname, "/", year, ".nc"), prec = "float", compression = 5, overwrite = TRUE)
      do.call(file.remove, list(list.files(paste0("./data/inputs/main/weather/historical/", vname, "/tmp/", v), full.names = TRUE)))
    }
    unlink(paste0("./data/inputs/main/weather/historical/", vname, "/tmp"), recursive = TRUE)
  }
}

setwd(origin)

cat('\nSuccesfully completed AgERA5 download')
