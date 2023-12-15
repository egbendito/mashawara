cat('\n#############################################################################')
cat('\nstarted GADM')

iso <- c("KEN")

origin<- getwd()

dir.create(path = paste0("../data/inputs/main/administrative/"), recursive = TRUE, showWarnings = FALSE)

if(!file.exists("../data/inputs/main/administrative/roi.gpkg")){
  # Download files
  for (i in iso) {
    url <- paste0("https://geodata.ucdavis.edu/gadm/gadm4.1/gpkg/gadm41_", i, ".gpkg")
    dir.create("../data/inputs/main/administrative/", showWarnings = FALSE)
    download.file(url, destfile = paste0("../data/inputs/main/administrative/gadm41_", i, ".gpkg"))
  }

  # Merge files
  # Check validity of geometries
  A <- sf::st_read(paste0("../data/inputs/main/administrative/gadm41_", iso[1], ".gpkg"), layer = "ADM_ADM_2", quiet = T)
  files <- list.files("../data/inputs/main/administrative/", pattern = ".gpkg")
  if (length(files) > 1){
    for (f in files[2:length(files)]) {
      iso <- substr(gsub(".gpkg","",f), 8,10)
      fname <- paste0("../data/inputs/main/administrative/", f)
      for (l in sf::st_layers(fname)[1]) {
        pol <- sf::st_read(fname, layer = l[length(l)], quiet = T)
        A <- sf::st_union(dplyr::bind_rows(list(A,pol)), by_feature = T)
      }
    }
  }
  sf::write_sf(obj = A, dsn = "../data/inputs/main/administrative/roi.gpkg", layer = "roi", append = FALSE)
}

setwd(origin)

cat('\nSuccesfully completed GADM download')
