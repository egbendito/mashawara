dssat.extdata <- function(coords = NULL,
                          sdate, edate,
                          jobs = 1,
                          path.to.ex = NULL){
  require(doParallel)
  require(foreach)
  # Set number of parallel workers
  cls <- parallel::makePSOCKcluster(jobs)
  doParallel::registerDoParallel(cls)
  #Set working directory to experiment directory
  setwd(path.to.ex)
  # Process soil & weather
  foreach::foreach(pnt = seq_along(coords[,1]), .export = ls(globalenv()), .inorder = TRUE, .packages = c("tidyverse", "lubridate")) %dopar% {
    dir.create(file.path(paste(path.to.ex,paste0('EXTE', formatC(width = 4, (as.integer(pnt)-1), flag = "0")), sep = "/")))
    setwd(paste(path.to.ex,paste0('EXTE', formatC(width = 4, (as.integer(pnt)-1), flag = "0")), sep = "/"))
    # read coordinates of the point
    x = coords[pnt,1]
    y = coords[pnt,2]
    ############################################# EXTRACT DATA FROM DATA SOURCES ############################################
    # # Get soil iSDA data
    s <- tryCatch(
      expr = {
        # # Load inputs functions and isda (isda ++)
        source(paste0(root, "/R/02_etl/02_01_etl_isda.R"))
        source(paste0(root, "/R/02_etl/02_07_etl_isric.R"))
        # # Process soil data
        solisda <- isda2dssat(isda = get.isda(X = x, Y = y))
        solisric <- isric2dssat(isric = get.isric(X = x, Y = y))
        # Binding iSDA + ISRIC data
        solis <- rbind(solisda[,1:5], solisric[4:6, 1:5])
        solis$fertility <- solisda$fcc[1]
        solis$bd_od <- c(solisda$db_od, solisric$db_od[4:6])
        solis$clay <- c(solisda$clay, solisric$clay[4:6])
        solis$sand <- c(solisda$sand, solisric$sand[4:6])
        solis$silt <- c(solisda$silt, solisric$silt[4:6])
        solis$albedo <- rep(solisda$SALB[1], nrow(solis))
        solis$LL15 <- c(solisda$LL15, solisric$LL15[4:6])
        solis$SAT <- c(solisda$SAT, solisric$SAT[4:6])
        solis$DUL <- c(solisda$DUL, solisric$DUL[4:6])
        solis$SRGF <- c(solisda$SRGF, solisric$SRGF[4:6])
        solis$SSS <- c(solisda$SSS, solisric$SSS[4:6])
        solis$oc <- c(mean(solisric$oc[1:2], na.rm = TRUE), solisric$oc[3:6])
        solis$n_tot <- c(solisda$n_tot, solisric$n_tot[4:6])
        solis$ph_h2o <- c(solisda$ph_h2o, solisric$ph_h2o[4:6])
        solis$ecec <- c(solisda$ecec, solisric$ecec[4:6])
        solis$cf <- c(mean(solisric$coarse.fragments[1:2], na.rm = TRUE), solisric$coarse.fragments[3:6])
        # sol <- DSSAT::read_sol(paste0(root, "/data/inputs/dssat/SOILV47.SOL"), id_soil = "IB00720001") # iSDA only
        sol <- DSSAT::read_sol(paste0(root, "/data/inputs/dssat/SOILV48.SOL"), id_soil = "IB00830003") # iSDA + ISRIC
        soilid <- dplyr::mutate(sol,
                                SOURCE="iSDA+ISRIC",
                                TEXTURE=as.integer(-99),
                                DEPTH=as.integer(200),
                                DESCRIPTION=as.integer(-99),
                                SITE=as.integer(-99),
                                COUNTRY=as.character(solis$ISO[1]),
                                LAT=round(as.numeric(solis$Y[1]),3),
                                LONG=round(as.numeric(solis$X[1]),3),
                                "SCS FAMILY"=as.integer(-99),
                                SCOM=as.integer(-99),
                                SALB=round(as.numeric(solis$albedo[1]),2),
                                SLB=as.integer(solis$depth),
                                # Review after downloading fertility layer:
                                # https://developers.google.com/earth-engine/datasets/catalog/ISDASOIL_Africa_v1_fcc#bands
                                # https://github.com/iSDA-Africa/isdasoil-tutorial/blob/main/iSDAsoil-tutorial.ipynb
                                # TRANSFORM/egb/isda/isda_fcc_download.sh
                                SLPF=round(as.numeric(solis$fertility[1]),2), # from isda2DSSAT.R
                                SLMH=rep(as.integer(-99), nrow(solis)),
                                SLLL=round(solis$LL15, 2),
                                SSAT=round(solis$SAT, 2),
                                # SHF=round(as.numeric(solis$SRGF), 2),
                                SDUL=round(solis$DUL, 2),
                                SRGF=round(as.numeric(solis$SRGF), 2),
                                SSKS=round(solis$SSS, 2),
                                SBDM=round(as.numeric(solis$bd_od), 2),
                                SLOC=round(as.numeric(solis$oc), 2),
                                SLCL=round(as.numeric(solis$clay), 0),
                                SLSI=round(as.numeric(solis$silt), 0),
                                SLCF=round(as.numeric(solis$cf), 2),
                                SLNI=round(as.numeric(solis$n_tot), 2),
                                SLHW=round(as.numeric(solis$ph_h2o), 1),
                                # SLHB=rep(as.integer(-99), nrow(solis)),
                                SCEC=as.integer(solis$ecec))
        soilid
      },
      error = function(e){
        err <- DSSAT::read_sol(paste0(root, "/data/inputs/dssat/NP_ERR.SOL"))
        err <- dplyr::mutate(err,
                             SOURCE="ERROR", TEXTURE=as.integer(-99), DEPTH=as.integer(-99),
                             DESCRIPTION=as.integer(-99), SITE=as.integer(-99), COUNTRY=as.integer(-99), LAT=y, LONG=x, "SCS FAMILY"=as.integer(-99),
                             SCOM=as.integer(-99), SALB=as.integer(-99), SLU1=as.integer(-99), SLDR=as.integer(-99), SLRO=as.integer(-99),
                             SLNF=as.integer(-99), SLPF=as.integer(-99), SMHB=as.integer(-99), SMPX=as.integer(-99), SMKE=as.integer(-99),
                             SLB=as.integer(-99), SLMH=as.integer(-99), SLLL=as.integer(-99), SSAT=as.integer(-99), SDUL=as.integer(-99),
                             SRGF=as.integer(-99), SSKS=as.integer(-99), SBDM=as.integer(-99), SLOC=as.integer(-99), SLCL=as.integer(-99),
                             SLSI=as.integer(-99), SLCF=as.integer(-99),SLNI=as.integer(-99), SLHW=as.integer(-99), SLHB=as.integer(-99),
                             SCEC=as.integer(-99), SADC=as.integer(-99))
        return(err)
      }
    )
    s <- dplyr::mutate(s, PEDON=paste0('SO', formatC(width = 6, (as.integer(pnt)-1), flag = "0")))
    DSSAT::write_sol(s, 'SOIL.SOL', append = FALSE)
    ##########################################
    # # Get weather AgERA5 and CHIRPSv2 data
    w <- tryCatch(
      expr = {
        if (class == 'historical'){
          # Load ERA5 function
          source(paste0(root, "/R/02_etl/02_02_etl_agera5.R"))
          # Load CHIRPS function
          source(paste0(root, "/R/02_etl/02_03_etl_chirps.R"))
          # Load CHIRTS function
          source(paste0(root, "/R/02_etl/02_06_etl_chirts.R"))
          wth <- agera5(startDate = sdate, endDate = edate, coordPoints = data.frame("X" = x, "Y" = y))[c("dates",
                                                                                                          "WIND","TMIN","TMAX","RHUM","SRAD")]
          colnames(wth) <- c("DATE",
                             "WIND","TMIN","TMAX","RHUM","SRAD")
          wth$DATE <- format(as.Date(wth$DATE, "%Y-%m-%d"), format = "%y%j")
          prec <- chirps(startDate = sdate, endDate = edate, coordPoints = data.frame("X" = x, "Y" = y))
          wth$RAIN <- prec$rain
          # CHIRTS only has data up to 2016...
          if(all(as.integer(format(as.Date(wth$DATE, "%y%j"), format = "%Y")) <= 2016)){
            tmax <- chirts(startDate = sdate, endDate = edate, coordPoints = data.frame("X" = x, "Y" = y))
            wth$TMAX <- tmax$tmax
          }
          t <- data.frame("INSI" = "ERA5", "LAT" = y, "LONG" = x, "ELEV" = -99, "TAV" = -99, "AMP" = -99, "REFHT" = -99, "WNDHT" = -99)
          attr(wth, "GENERAL") <- t
          wth
        } else {
          # Load ERA5 function
          source(paste0(root, "/R/02_etl/02_05_etl_ecmwfs5.R"))
          wth <- ecmwf.s5(startDate = sdate, endDate = edate, coordPoints = data.frame("X" = x, "Y" = y))[c("dates",
                                                                                                            "WIND","TMIN","TMAX","RHUM","SRAD","RAIN")]
          colnames(wth) <- c("DATE",
                             "WIND","TMIN","TMAX","RHUM","SRAD","RAIN")
          wth$DATE <- format(as.Date(wth$DATE, "%Y-%m-%d"), format = "%y%j")
          t <- data.frame("INSI" = "ECS5", "LAT" = y, "LONG" = x, "ELEV" = -99, "TAV" = -99, "AMP" = -99, "REFHT" = -99, "WNDHT" = -99)
          attr(wth, "GENERAL") <- t
          wth
        }
      },
      error = function(e){
        dates <- seq(as.Date(sdate), as.Date(edate), by = "day")
        err <- read.table(paste0(root, "/data/inputs/dssat/NP_ERR.WTH"), skip = 15, header = TRUE)
        colnames(err) <- gsub("^.*\\.","",colnames(err))
        err <- err[1:length(dates), ]
        err[,names(err) == "DATE"] <- dates
        t <- data.frame("INSI" = "ERR", "LAT" = y, "LONG" = x, "ELEV" = -99, "TAV" = -99, "AMP" = -99, "REFHT" = -99, "WNDHT" = -99)
        attr(err, "GENERAL") <- t
        return(err)
      }
    )
    source(paste0(root, "/R/03_dssat/_write_wth_custom.R"))
    write_wth_custom(w, paste0("WHTE", formatC(width = 4, (as.integer(pnt)-1), flag = "0"), ".WTH"))
    setwd(path.to.ex)
    gc()
  }
  stopCluster(cls)
}