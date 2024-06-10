dir.create(path = paste0("./data/inputs/main/soil/isric/"), recursive = TRUE, showWarnings = FALSE)
dep <- c("5" = "0-5", "15" = "5-15", "30" = "15-30", "60" = "30-60", "100" = "60-100", "200" = "100-200")
par <- c("bulk-density" = "bdod", "cation-exchange-capacity" = "cec", "coarse-fragments" = "cfvo", "clay" = "clay", "nitrogen" = "nitrogen", "carbon-density" = "ocd", "ph" = "phh2o", "sand" = "sand", "silt" = "silt", "organic-carbon" = "soc")
origin<- getwd()

cat('\n#############################################################################')
cat('\nstarted SoilGrids (ISRIC')

url <- "~/common_data/soilgrids/raw"

pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
aoi <- terra::ext(pol)
ref <- terra::rast(list.files("./data/inputs/main/weather/historical/Rainfall/", pattern = ".nc", full.names = TRUE)[1])
for (p in par) {
  for (d in dep) {
    parameter <- names(par[par == p])
    sg.source <- terra::crop(terra::rast(paste0(url, "/", p, "/", d, "/", p, "_", d, ".vrt")), aoi)
    x <- terra::crop(terra::resample(terra::aggregate(sg.source,
                                                      fact = (terra::res(ref)[[1]]/terra::res(sg.source)[[1]]),
                                                      fun = "mean", cores = 2), ref[[1]], method = "near"), aoi)
    terra::writeRaster(x, paste0("./data/inputs/main/soil/isric/isric_", parameter, "_", d, "cm.tif"), gdal = c("COMPRESS=LZW"), overwrite = TRUE)
    rm(x)
    gc()
    cat(paste0("\nCompleted ", parameter, " ", d, "\n"))
  }
}

# Create VRT and NetCDF for parallel access
system(paste0("gdalbuildvrt -separate ./data/inputs/main/soil/isric/isric.vrt ", paste0("./data/inputs/main/soil/isric/", list.files("./data/inputs/main/soil/isric/", pattern = ".tif"), collapse = " ")))
system(paste0("gdal_translate -of netcdf ./data/inputs/main/soil/isric/isric.vrt ./data/inputs/main/soil/isric/isric.nc"))


setwd(origin)

cat('\n Succesfully completed SoilGrids (ISRIC) download')
