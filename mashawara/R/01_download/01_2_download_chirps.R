## For SAA Use Case...
vars <- c("prec")
names(vars) <- c("Rainfall")
years <- seq(1990, as.integer(format(Sys.Date(), "%Y"))-1)
pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
bb <- terra::ext(pol)
origin<- getwd()
print(origin)

cat('\n#############################################################################')
cat('\nstarted CHIRPS')

for (i in seq_along(vars)) {
  vname <- names(vars[i])
  v <- vars[i][[1]]
  dir.create(path = paste0("./data/inputs/main/weather/historical/", vname), recursive = TRUE, showWarnings = FALSE)
  for (year in years){
    if(!file.exists(paste0("./data/inputs/main/weather/historical/", vname, "/", year, ".nc"))){
      file <- list.files("/home/jovyan/common_data/chirps_af/chirps/netcdf", full.names = TRUE, pattern = paste0(year, collapse = '|'))
      R <- terra::rast(file)
      R <- terra::crop(R, bb)
      terra::writeCDF(R, filename = paste0("./data/inputs/main/weather/historical/", vname, "/", year, ".nc"), prec = "float", compression = 5, overwrite = TRUE)
    }
  }
}

setwd(origin)

cat('\nSuccesfully completed CHIRPS download')
