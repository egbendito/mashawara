get.isda <- function(X = NULL, Y = NULL){
  isda <- terra::rast(paste0(root, "/data/inputs/main/soil/isda/isda.nc"))
  vars <- c("fcc","clay","sand","silt","texture.class","db","ph","log.c","log.oc","log.n","log.p","log.k","log.ecec.f")
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
    
  # Rescaling to 0.8 - 0.2 SLPF
  fcc.atts$SLPF <- ((fcc.atts$SLPF - min(fcc.atts$SLPF))/(max(fcc.atts$SLPF) - min(fcc.atts$SLPF))*(0.8-0.2)+0.2)
  
  isda[[which(grepl("fcc", names(isda), fixed = TRUE))]] <- isda[[grepl("fcc", names(isda), fixed = TRUE)]] %% 3000
  isda[[which(grepl("fcc", names(isda), fixed = TRUE))]] <- terra::classify(isda[[grepl("fcc", names(isda), fixed = TRUE)]], cbind(fcc.atts$Class, fcc.atts$SLPF))
  q <- terra::extract(isda, data.frame(x = X, y = Y), xy = TRUE)
  q <- q[,colnames(q)[!grepl("ca", colnames(q), fixed = TRUE)]]
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
    if (v %in% c("c_tot","log.oc","log.p","log.k","log.ecec.f")){vv[[1]] <- expm1(vv[[1]] / 10)}
    else if (v == "db"){vv[[1]] <- vv[[1]] / 100}
    else if (v == "log.n"){vv[[1]] <- expm1(vv[[1]] / 100) / 10} # Convert to %
    else if (v %in% c("ph")){vv[[1]] <- vv[[1]] / 10}
    else if (v == "texture.class"){vv[[1]] <- as.character(factor(vv[[1]], levels = c(1:12), labels = c("Clay", "Silty Clay", "Sandy Clay", "Clay Loam", "Silty Clay Loam", "Sandy Clay Loam", "Loam", "Silt Loam", "Sandy Loam", "Silt", "Loamy Sand", "Sand")))}
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
    om <- (as.numeric(isda$log.oc) * 1e-2) * 2
    ans0 <- -0.251 * sand + 0.195 * clay + 0.011 * om + 0.006 * (sand * om) - 0.027 * (clay * om) + 0.452 * (sand * clay) + 0.299
    ans <- ans0 + (1.283 * ans0^2 - 0.374 * ans0 - 0.015)
    ans
  }
  # Drained upper limit saturated (cm3 cm3)
  DUL_S <- {
    clay <- as.numeric(isda$clay) * 1e-2
    sand <- as.numeric(isda$sand) * 1e-2
    om <- (as.numeric(isda$log.oc) * 1e-2) * 2
    ans0 <- 0.278 * sand + clay * 0.034 + om * 0.022 + -0.018 * sand * om - 0.027 * clay * om + -0.584 * sand * clay + 0.078
    ans <- ans0 + (0.636 * ans0 - 0.107)
    ans
  }
  # Lower limit of plant extractable soil water (cm3 cm3)
  isda$LL15 <- {
    clay <- as.numeric(isda$clay) * 1e-2
    sand <- as.numeric(isda$sand) * 1e-2
    om <- (as.numeric(isda$log.oc) * 1e-2) * 2
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
  isda$SKS <- (193 * (isda$SAT - isda$DUL)^(3 - Lambda))
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
