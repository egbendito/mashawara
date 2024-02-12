get.isda <- function(X = NULL, Y = NULL, isda = NULL){
  vars <- c("fcc","clay","sand","silt","texture","db_od","ph_h2o","c_tot","oc","n_tot","p_mehlich3","k_mehlich3","ca_mehlich3","ecec")
  url <- paste0(root, "/data/inputs/main/soil/isda/")
  names(isda) <- gsub(".tif", "", basename(list.files(url, pattern = ".tif")))
  # Load info
  iso <- terra::vect(paste0(root, "/data/inputs/main/administrative/roi.gpkg"))
  iso3 <- terra::intersect(iso, terra::vect(data.frame("x" = X, "y" = Y), geom = c("x", "y"), crs = "+proj=longlat +datum=WGS84"))[[2]][[1]]
  soil <- as.data.frame(cbind("ISO" = iso3, "X" = X, "Y" = Y, "depth" = c(as.integer(20), as.integer(50)), "lyr_center" = c(as.integer(10), as.integer(20+15))))
  # Pre-process FCC
  fcc.atts <- read.table(paste0(root, "/data/inputs/main/soil/isda/fcc_attributes.tab"), sep = "\t", header = T)
  fcc.atts$Class <- lengths(regmatches(fcc.atts$Description, gregexpr(",", fcc.atts$Description))) + 1
  fcc.atts$Class <- ifelse(fcc.atts$Description == "No constraints", 0, fcc.atts$Class)
  fcc.atts$SLPF <- (fcc.atts$Class  - max(fcc.atts$Class))/(min(fcc.atts$Class) - max(fcc.atts$Class))
  isda[[which(grepl("fcc", names(isda), fixed = TRUE))]] <- isda[[grepl("fcc", names(isda), fixed = TRUE)]] %% 3000
  isda[[which(grepl("fcc", names(isda), fixed = TRUE))]] <- terra::classify(isda[[grepl("fcc", names(isda), fixed = TRUE)]], cbind(fcc.atts$Value, fcc.atts$SLPF))
  q <- terra::extract(isda, data.frame(x = X, y = Y), xy = TRUE)
  n <- 1
  for (v in vars) {
    out <- NULL
    if(v == "fcc"){
      vv <- as.data.frame(t(q[,colnames(q)[grepl(v, colnames(q), fixed = TRUE)]]))
      colnames(vv) <- v
      row.names(vv)<-c("0-50")
    } else {
      vv <- as.data.frame(t(q[,colnames(q)[grepl(v, colnames(q), fixed = TRUE)]]))
      colnames(vv) <- v
      row.names(vv)<-c("0-20", "20-50")
    }
    if (v %in% c("c_tot","log.oc","p_mehlich3","k_mehlich3","ca_mehlich3","ecec")){vv[[1]] <- expm1(vv[[1]] / 10)}
    else if (v == "db_od"){vv[[1]] <- vv[[1]] / 100}
    else if (v == "n_tot"){vv[[1]] <- expm1(vv[[1]] / 100)}
    else if (v == "ph_h2o"){vv[[1]] <- vv[[1]] / 10}
    else if (v == "texture"){vv[[1]] <- as.character(factor(vv[[1]], levels = c(1:12), labels = c("Clay", "Silty Clay", "Sandy Clay", "Clay Loam", "Silty Clay Loam", "Sandy Clay Loam", "Loam", "Silt Loam", "Sandy Loam", "Silt", "Loamy Sand", "Sand")))}
    soil <- as.data.frame(cbind(soil, vv[[1]]))
    colnames(soil)[length(soil)] <- v
  }
  return(soil)
}

isda2dssat <- function(isda = NULL){
  # Add pedo-transfer values
  # Drained upper limit (cm3 cm3)
  isda$DUL <- {
    clay <- as.numeric(isda$clay) * 1e-2
    sand <- as.numeric(isda$sand) * 1e-2
    om <- (as.numeric(isda$oc) * 1e-2) * 2
    ans0 <- -0.251 * sand + 0.195 * clay + 0.011 * om + 0.006 * (sand * om) - 0.027 * (clay * om) + 0.452 * (sand * clay) + 0.299
    ans <- ans0 + (1.283 * ans0^2 - 0.374 * ans0 - 0.015)
    ans
  }
  # Drained upper limit saturated (cm3 cm3)
  DUL_S <- {
    clay <- as.numeric(isda$clay) * 1e-2
    sand <- as.numeric(isda$sand) * 1e-2
    om <- (as.numeric(isda$oc) * 1e-2) * 2
    ans0 <- 0.278 * sand + clay * 0.034 + om * 0.022 + -0.018 * sand * om - 0.027 * clay * om + -0.584 * sand * clay + 0.078
    ans <- ans0 + (0.636 * ans0 - 0.107)
    ans
  }
  # Lower limit of plant extractable soil water (cm3 cm3)
  isda$LL15 <- {
    clay <- as.numeric(isda$clay) * 1e-2
    sand <- as.numeric(isda$sand) * 1e-2
    om <- (as.numeric(isda$oc) * 1e-2) * 2
    ans0 <- -0.024 * sand + 0.487 * clay + 0.006 * om + 0.005 * sand * om + 0.013 *clay * om + 0.068 *sand * clay +  0.031
    ans <- ans0 + (0.14 * ans0 - 0.02)
    ans
  }
  # Saturated upper limit (cm3 cm3)
  isda$SAT <- {
    sand <- sand * 1e-2
    ans <- isda$DUL + DUL_S - 0.097 * sand + 0.043
    ans
  }
  # Saturated hydraulic conductivity (cm h1)
  B <- (log(1500) - log(33))/(log(isda$DUL) - log(isda$LL15))
  Lambda <- 1/B
  isda$SKS <- (1930 * (isda$SAT - isda$DUL)^(3 - Lambda)) * 100
  isda$SSS <- round(as.numeric(isda$SKS), digits = 1)
  # Albedo (unitless)
  isda$SALB <- ifelse(isda$texture %in% c("Clay", "Silty Clay", "Silty Clay Loam", "Silt Loam"), 0.12,
                      ifelse(isda$texture %in% c("Sandy Clay", "Clay Loam", "Sandy Clay Loam", "Loam", "Sandy Loam", "Silt"), 0.13,
                             ifelse(isda$texture %in% c("Silty Loam"), 0.14,
                                    ifelse(isda$texture %in% c("Loamy Sand"), 0.16,
                                           ifelse(isda$texture %in% c("Sand"), 0.19, NA)))))
  isda$SRGF <- 1*exp(-0.02 * as.numeric(isda$lyr_center))
  return(isda)
}