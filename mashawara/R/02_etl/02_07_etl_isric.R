get.isric <- function(X = NULL, Y = NULL){
  isric <- terra::rast(paste0(root, "/data/inputs/main/soil/isric/isric.nc"))
  # vars <- c("bdod", "cec", "clay", "nitrogen", "ocd", "phh2o", "sand", "silt", "soc")
  vars <- c("bulk-density", "cation-exchange-capacity", "coarse-fragments", "clay", "nitrogen", "carbon-density", "ph", "sand", "silt", "organic-carbon")
  url <- paste0(root, "/data/inputs/main/soil/isric/")
  names(isric) <- gsub(".tif", "", basename(list.files(url, pattern = ".tif")))
  # Load info
  iso <- terra::vect(paste0(root, "/data/inputs/main/administrative/roi.gpkg"))
  iso3 <- terra::intersect(iso, terra::vect(data.frame("x" = X, "y" = Y), geom = c("x", "y"), crs = "+proj=longlat +datum=WGS84"))[[2]][[1]]
  soil <- as.data.frame(cbind("ISO" = iso3, "X" = X, "Y" = Y, "depth" = c(as.integer(5), as.integer(15), as.integer(30), as.integer(60), as.integer(100), as.integer(200)), "lyr_center" = c(as.integer(3), as.integer(10), as.integer(23), as.integer(45), as.integer(80), as.integer(150))))
  # Extract data
  q <- terra::extract(isric, data.frame(x = X, y = Y), xy = TRUE)
  n <- 1
  for (v in vars) {
    if (v == "bulk-density"){nv <- "db_od"}
    else if (v == "cation-exchange-capacity"){nv <- "ecec"}
    else if (v == "coarse-fragments"){nv <- "coarse.fragments"}
    else if (v == "carbon-density"){nv <- "c_tot"}
    else if (v == "organic-carbon"){nv <- "oc"}
    else if (v == "nitrogen"){nv <- "n_tot"}
    else if (v == "ph"){nv <- "ph_h2o"}
    else {nv <- v}
    out <- NULL
    vv <- as.data.frame(t(q[,colnames(q)[grepl(v, colnames(q), fixed = TRUE)]]))
    colnames(vv) <- v
    row.names(vv) <- gsub("cm", "", gsub(".*-", "", gsub(paste0("isric_", v, "_"), "", row.names(vv))))
    vv <- vv[ order(as.numeric(row.names(vv))), ]
    if (v %in% c("nitrogen", "coarse-fragments")){vv <- vv / 1000}
    else if (v %in% c("organic-carbon", "bulk-density")){vv <- vv / 100}
    else if (v %in% c("ph", "clay", "sand", "silt", "cation-exchange-capacity")){vv <- vv / 10}
    soil <- as.data.frame(cbind(soil, vv))
    colnames(soil)[length(soil)] <- nv
  }
  return(soil)
}

isric2dssat <- function(isric = NULL){
  # Add pedo-transfer values
  # Drained upper limit (cm3 cm3)
  isric$DUL <- {
    clay <- as.numeric(isric$clay) * 1e-2
    sand <- as.numeric(isric$sand) * 1e-2
    om <- (as.numeric(isric$oc) * 1e-2) * 2
    ans0 <- -0.251 * sand + 0.195 * clay + 0.011 * om + 0.006 * (sand * om) - 0.027 * (clay * om) + 0.452 * (sand * clay) + 0.299
    ans <- ans0 + (1.283 * ans0^2 - 0.374 * ans0 - 0.015)
    ans
  }
  # Drained upper limit saturated (cm3 cm3)
  DUL_S <- {
    clay <- as.numeric(isric$clay) * 1e-2
    sand <- as.numeric(isric$sand) * 1e-2
    om <- (as.numeric(isric$oc) * 1e-2) * 2
    ans0 <- 0.278 * sand + clay * 0.034 + om * 0.022 + -0.018 * sand * om - 0.027 * clay * om + -0.584 * sand * clay + 0.078
    ans <- ans0 + (0.636 * ans0 - 0.107)
    ans
  }
  # Lower limit of plant extractable soil water (cm3 cm3)
  isric$LL15 <- {
    clay <- as.numeric(isric$clay) * 1e-2
    sand <- as.numeric(isric$sand) * 1e-2
    om <- (as.numeric(isric$oc) * 1e-2) * 2
    ans0 <- -0.024 * sand + 0.487 * clay + 0.006 * om + 0.005 * sand * om + 0.013 *clay * om + 0.068 *sand * clay +  0.031
    ans <- ans0 + (0.14 * ans0 - 0.02)
    ans
  }
  # Saturated upper limit (cm3 cm3)
  isric$SAT <- {
    sand <- sand * 1e-2
    ans <- isric$DUL + DUL_S - 0.097 * sand + 0.043
    ans
  }
  # Saturated hydraulic conductivity (cm h1)
  B <- (log(1500) - log(33))/(log(isric$DUL) - log(isric$LL15))
  Lambda <- 1/B
  isric$SKS <- (193 * (isric$SAT - isric$DUL)^(3 - Lambda))
  # isric$SKS <- (1930 * (isric$SAT - isric$DUL)^(3 - Lambda)) * 100
  isric$SSS <- round(as.numeric(isric$SKS), digits = 2)
  # # Albedo (unitless)
  # isric$SALB <- ifelse(isric$texture %in% c("Clay", "Silty Clay", "Silty Clay Loam", "Silt Loam"), 0.12,
  #                     ifelse(isric$texture %in% c("Sandy Clay", "Clay Loam", "Sandy Clay Loam", "Loam", "Sandy Loam", "Silt"), 0.13,
  #                            ifelse(isric$texture %in% c("Silty Loam"), 0.14,
  #                                   ifelse(isric$texture %in% c("Loamy Sand"), 0.16,
  #                                          ifelse(isric$texture %in% c("Sand"), 0.19, NA)))))
  isric$SRGF <- 1*exp(-0.02 * as.numeric(isric$lyr_center))
  return(isric)
}
