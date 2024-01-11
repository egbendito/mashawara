# bbox
pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
bb <- terra::ext(pol)
bb <- data.frame("x" = c(bb[1][[1]],bb[2][[1]]), "y" = c(bb[3][[1]], bb[4][[1]]))
origin<- getwd()

# dir.create(path = paste0("./data/input/s5/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/weather/forecast/"), recursive = TRUE, showWarnings = FALSE)
# dir.create(path = paste0("./data/intermediate/forecast/"), recursive = TRUE, showWarnings = FALSE)

# Download ECMWF-S5 for specific year and transform
for(year in c(format(Sys.Date(), "%Y"))){
  setwd(origin)
  month <- format(Sys.Date(), "%m")
  system(paste('python', paste0(root, '/R/01_download/01_41_s5download.py'), year, month, bb[1,1], bb[2,1], bb[1,2], bb[2,2], sep = ' '))
  # Disaggregate forecast aggregations
  disagg <- c("rain", "srad")
  for (var in disagg) {
    x <- terra::rast(paste0("./data/inputs/main/weather/forecast/ecmwf_s5_", var, "_", year, ".nc"))
    o <- terra::rast()
    for (lyr in 1:terra::nlyr(x)) {
      if (lyr == 1){
        terra::add(o) <- x[[lyr]]
      }
      else {
        s0 <- x[[lyr-1]]
        s1 <- x[[lyr]]
        s <- s1 - s0
        terra::add(o) <- s
      }
    }
    terra::crs(o) <- "EPSG:4326"
    terra::writeCDF(o, paste0("./data/inputs/main/weather/forecast/ecmwf_s5_", var, "_", year, ".nc"), overwrite=TRUE,
                    unit="mm", compression = 5)  
  }
  file.remove(paste0("./data/inputs/main/weather/forecast/ecmwf_s5_uwind_", year, ".nc"))
  file.remove(paste0("./data/inputs/main/weather/forecast/ecmwf_s5_vwind_", year, ".nc"))
  file.remove(paste0("./data/inputs/main/weather/forecast/ecmwf_s5_dp_", year, ".nc"))
}

setwd(origin)
