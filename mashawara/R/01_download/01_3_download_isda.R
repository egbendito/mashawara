dir.create(path = paste0("./data/inputs/main/soil/isda/"), recursive = TRUE, showWarnings = FALSE)
dep <- c("20"="0-20cm","50"="20-50cm")
tex <- c("clay_content"="clay","sand_content"="sand","silt_content"="silt", "texture_class"="texture.class")
phy <- c("bulk_density"="db","ph"="ph","nitrogen_total"="log.n")
che <- c("carbon_total"="log.c","carbon_organic"="log.oc",
         "phosphorous_extractable"="log.p","potassium_extractable"="log.k",
         # "zinc_extractable"="log.zn_mehlich3","magnesium_extractable"="log.mg_mehlich3",
         "calcium_extractable"="log.ca",
         # "aluminium_extractable"="log.al_mehlich3","iron_extractable"="log.fe_mehlich3","sulphur_extractable"="log.s_mehlich3",
         "cation_exchange_capacity"="log.ecec.f")
origin<- getwd()

cat('\n#############################################################################\n')
cat('\nstarted iSDA\n')

url <- "~/common_data/isda/intermediate/"

pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
aoi <- terra::ext(pol)
ref <- terra::rast("./data/inputs/main/weather/historical/Rainfall/2023.nc")
for (par in c(tex, phy, che)) {
  for (d in dep) {
    lab <- names(dep[dep == d])
    # lyr <- paste("sol",par,"m_30m",d,"2001..2017_v0.13_wgs84.tif",sep = "_")
    lyr <- paste0(par,"_", d, ".vrt")
    tif.cog <- paste0(url,lyr)
    if(!file.exists(paste0("./data/inputs/main/soil/isda/", lyr))){
      sg.source <- terra::crop(terra::rast(tif.cog), aoi)
      if(par == "texture.class"){
        t <- terra::crop(terra::resample(terra::aggregate(sg.source,
                                                          fact = (terra::res(ref)[[1]]/terra::res(sg.source)[[1]]),
                                                          fun = "modal", cores = 2), ref[[1]], method = "near"), aoi)
        # d <- terra::crop(terra::resample(terra::aggregate(terra::crop(terra::rast(tif.cog), aoi), fact = 185, fun = "modal", cores = 2), ref[[1]], method = "near"), aoi)
      }
      else{
        t <- terra::crop(terra::resample(terra::aggregate(sg.source,
                                                          fact = (terra::res(ref)[[1]]/terra::res(sg.source)[[1]]),
                                                          fun = "mean", cores = 2), ref[[1]], method = "average"), aoi)
        # d <- terra::crop(terra::resample(terra::aggregate(terra::crop(terra::rast(tif.cog), aoi), fact = 185, fun = "mean", cores = 2), ref[[1]], method = "average"), aoi)
      }
      terra::writeRaster(t, paste0("./data/inputs/main/soil/isda/", par, "_", d, ".tif"), gdal = c("COMPRESS=LZW"))
      rm(d)
      gc()
      cat(paste0("\nCompleted ", par, " ", lab))
    }
  }
}

# Add FCC table
if(!file.exists(paste0("./data/inputs/main/soil/isda/fcc_attributes.tab"))){
  lyr <- paste("fcc_0-200cm.vrt")
  tif.cog <- paste0(url,lyr)
  t <- terra::crop(terra::resample(terra::crop(terra::rast(tif.cog), aoi), ref, method = "near", threads = TRUE), aoi)
  terra::writeRaster(t, paste0("./data/inputs/main/soil/isda/fcc_0-200cm.tif"), gdal = c("COMPRESS=LZW"))
  system("cp ~/common_data/isda/raw/fcc_attributes.tab ./data/inputs/main/soil/isda/")
}

# Create VRT and NetCDF for parallel access
system(paste0("gdalbuildvrt -separate ./data/inputs/main/soil/isda/isda.vrt ", paste0("./data/inputs/main/soil/isda/", list.files("./data/inputs/main/soil/isda/", pattern = ".tif"), collapse = " ")))
system(paste0("gdal_translate -of netcdf ./data/inputs/main/soil/isda/isda.vrt ./data/inputs/main/soil/isda/isda.nc"))


setwd(origin)

cat('\n Succesfully completed iSDA download\n')
