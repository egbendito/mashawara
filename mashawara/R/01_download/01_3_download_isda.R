dir.create(path = paste0("./data/inputs/main/soil/isda/"), recursive = TRUE, showWarnings = FALSE)
dep <- c("20"="0..20cm","50"="20..50cm")
tex <- c("clay_content"="clay_tot_psa","sand_content"="sand_tot_psa","silt_content"="silt_tot_psa", "texture_class"="texture.class")
phy <- c("bulk_density"="db_od","ph"="ph_h2o","nitrogen_total"="log.n_tot_ncs")
che <- c("carbon_total"="log.c_tot","carbon_organic"="log.oc",
         "phosphorous_extractable"="log.p_mehlich3","potassium_extractable"="log.k_mehlich3",
         # "zinc_extractable"="log.zn_mehlich3","magnesium_extractable"="log.mg_mehlich3",
         "calcium_extractable"="log.ca_mehlich3",
         # "aluminium_extractable"="log.al_mehlich3","iron_extractable"="log.fe_mehlich3","sulphur_extractable"="log.s_mehlich3",
         "cation_exchange_capacity"="log.ecec.f")
origin<- getwd()

cat('\n#############################################################################\n')
cat('\nstarted iSDA\n')

url <- "~/common_data/isda/raw/"

pol <- terra::vect("./data/inputs/main/administrative/roi.gpkg", layer = "roi")
aoi <- terra::ext(pol)
ref <- terra::rast("./data/inputs/main/weather/historical/Rainfall/2019.nc")
for (par in c(tex, phy, che)) {
  for (d in dep) {
    lab <- names(dep[dep == d])
    lyr <- paste("sol",par,"m_30m",d,"2001..2017_v0.13_wgs84.tif",sep = "_")
    tif.cog <- paste0(url,lyr)
    if(!file.exists(paste0("./data/inputs/main/soil/isda/", lyr))){
      sg.source <- terra::crop(terra::rast(tif.cog), aoi)
      if(par == "texture.class"){
        d <- terra::crop(terra::resample(terra::aggregate(sg.source,
                                                          fact = (terra::res(ref)[[1]]/terra::res(sg.source)[[1]]),
                                                          fun = "modal", cores = 2), ref[[1]], method = "near"), aoi)
        # d <- terra::crop(terra::resample(terra::aggregate(terra::crop(terra::rast(tif.cog), aoi), fact = 185, fun = "modal", cores = 2), ref[[1]], method = "near"), aoi)
      }
      else{
        d <- terra::crop(terra::resample(terra::aggregate(sg.source,
                                                          fact = (terra::res(ref)[[1]]/terra::res(sg.source)[[1]]),
                                                          fun = "mean", cores = 2), ref[[1]], method = "average"), aoi)
        # d <- terra::crop(terra::resample(terra::aggregate(terra::crop(terra::rast(tif.cog), aoi), fact = 185, fun = "mean", cores = 2), ref[[1]], method = "average"), aoi)
      }
      terra::writeRaster(d, paste0("./data/inputs/main/soil/isda/", lyr), gdal = c("COMPRESS=LZW"))
      rm(d)
      gc()
      cat(paste0("\nCompleted ", par, " ", lab))
    }
  }
}

# Add FCC table
if(!file.exists(paste0("./data/inputs/main/soil/isda/fcc_attributes.tab"))){
  lyr <- paste("sol_fcc_m_30m_0..200cm_2001..2017_v0.13_wgs84.tif",sep = "_")
  tif.cog <- paste0(url,lyr)
  d <- terra::crop(terra::resample(terra::crop(terra::rast(tif.cog), aoi), ref, method = "near", threads = TRUE), aoi)
  terra::writeRaster(d, paste0("./data/inputs/main/soil/isda/", lyr), gdal = c("COMPRESS=LZW"))
  system("cp ~/common_data/isda/raw/fcc_attributes.tab ./data/inputs/main/soil/isda/")
}

# Create VRT and NetCDF for parallel access
system(paste0("gdalbuildvrt -separate ./data/inputs/main/soil/isda/isda.vrt ", paste0("./data/inputs/main/soil/isda/", list.files("./data/inputs/main/soil/isda/", pattern = ".tif"), collapse = " ")))
system(paste0("gdal_translate -of netcdf ./data/inputs/main/soil/isda/isda.vrt ./data/inputs/main/soil/isda/isda.nc"))


setwd(origin)

cat('\n Succesfully completed iSDA download\n')
