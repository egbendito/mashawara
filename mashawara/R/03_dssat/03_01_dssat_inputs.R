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
        # # Process iSDA data
        solisda <- get.isda(X = x, Y = y)
        isda <- isda2dssat(isda = solisda) # from isda2DSSAT.R
        sol <- DSSAT::read_sol(paste0(root, "/data/inputs/dssat/soil.sol"), id_soil = "IB00720001")
        soilid <- dplyr::mutate(sol,
                                SOURCE="iSDA",
                                TEXTURE=as.integer(-99),
                                DEPTH=as.integer(50),
                                DESCRIPTION=as.integer(-99),
                                SITE=as.integer(-99),
                                COUNTRY=as.character(isda$ISO[1]),
                                LAT=round(as.numeric(isda$Y[1]),3),
                                LONG=round(as.numeric(isda$X[1]),3),
                                "SCS FAMILY"=as.integer(-99),
                                SCOM=as.integer(-99),
                                SALB=round(as.numeric(isda$SALB[1]),2),
                                SLB=as.integer(isda$depth),
                                # Review after downloading fertility layer:
                                # https://developers.google.com/earth-engine/datasets/catalog/ISDASOIL_Africa_v1_fcc#bands
                                # https://github.com/iSDA-Africa/isdasoil-tutorial/blob/main/iSDAsoil-tutorial.ipynb
                                # TRANSFORM/egb/isda/isda_fcc_download.sh
                                SLPF=round(as.numeric(isda$fcc[1]),2), # from isda2DSSAT.R
                                SLMH=rep(as.integer(-99), nrow(isda)),
                                SLLL=isda$LL15,
                                SSAT=isda$SAT,
                                # SHF=round(as.numeric(isda$SRGF), 2),
                                SDUL=isda$DUL,
                                SRGF=round(as.numeric(isda$SRGF), 2),
                                SSKS=as.integer(isda$SSS),
                                SBDM=round(as.numeric(isda$db_od), 2),
                                SLOC=round(as.numeric(isda$oc), 1),
                                SLCL=round(as.numeric(isda$clay), 0),
                                SLSI=round(as.numeric(isda$silt), 0),
                                SLCF=rep(as.integer(-99), nrow(isda)),
                                SLNI=round(as.numeric(isda$n_tot), 1),
                                SLHW=round(as.numeric(isda$ph_h2o), 1),
                                SLHB=rep(as.integer(-99), nrow(isda)),
                                SCEC=as.integer(isda$ecec))
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
    s <- dplyr::mutate(s, PEDON=paste0('ISDA', formatC(width = 6, (as.integer(pnt)-1), flag = "0")))
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
          # # CHIRTS only has data up to 2016...
          # if(all(as.integer(format(as.Date(wth$DATE, "%y%j"), format = "%Y")) <= 2016)){
          #   tmax <- chirts(startDate = sdate, endDate = edate, coordPoints = data.frame("X" = x, "Y" = y))
          #   wth$TMAX <- tmax$tmax
          # }
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