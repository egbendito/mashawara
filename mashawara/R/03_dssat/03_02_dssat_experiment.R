dssat.Xdata <- function(coords = NULL,
                        sdate, edate,
                        jobs = 1,
                        path.to.ex = NULL){
  require(doParallel)
  require(foreach)
  # Set number of parallel workers
  cls <- parallel::makePSOCKcluster(jobs)
  doParallel::registerDoParallel(cls)
  #Set working directory to experment directory
  setwd(path.to.ex)
  # Process soil & weather
  foreach::foreach(pnt=seq_along(coords[,1]), .export = ls(globalenv()), .inorder = TRUE, .packages = c("tidyverse", "lubridate")) %dopar% {
    ############################################## MODIFICATION OF EXPERIMENTAL FILES ############################################
    setwd(paste(path.to.ex,paste0('EXTE', formatC(width = 4, (as.integer(pnt)-1), flag = "0")), sep = "/"))
    x = coords[pnt,1]
    y = coords[pnt,2]
    # Write the .MZX file for the location
    # v <- as.data.frame(DSSAT::read_cul(paste0(root, "/data/inputs/dssat/SBGRO048.CUL")))
    # v <- as.data.frame(DSSAT::read_cul(paste0(root, "/data/inputs/dssat/culfiles/v", as.character(version), ".CUL")))
    v <- as.data.frame(DSSAT::read_cul(list.files(paste0(root, "/data/inputs/dssat/culfiles"), pattern = as.character(version), full.names = TRUE)))
    v <- data.frame("C" = 1:length(v[[1]]),
                    # "CR" = "MZ",
                    "CR" = substr(tools::file_ext(list.files(paste0(root, "/data/inputs/dssat/xfiles"), pattern = as.character(version), full.names = TRUE)), start = 1, stop = 2),
                    "INGENO" = v[[1]],
                    "CNAME" = v[[2]])
    #Read in template FileX
    # filex <- DSSAT::read_filex(paste0(root, "/data/inputs/dssat/xfiles/v", as.character(version), ".MZX"))
    filex <- DSSAT::read_filex(list.files(paste0(root, "/data/inputs/dssat/xfiles"), pattern = as.character(version), full.names = TRUE))
    # Define Authorship
    filex$GENERAL$PEOPLE <- "Eduardo Garcia Bendito"
    filex$GENERAL$ADDRESS <- "Excellence in Agronomy Initiative - CGIAR"
    # Define location
    filex$GENERAL$SITE <- paste(paste0("X=", x), paste0("Y=", y), sep = ", ")
    # Define Simulation Controls
    filex$`SIMULATION CONTROLS`$SDATE <- format(as.Date(sdate, "%Y-%m-%d"), "%y%j")
    cc <- substr(tools::file_ext(list.files(paste0(root, "/data/inputs/dssat/xfiles"), pattern = as.character(version), full.names = TRUE)), start = 1, stop = 2)
    filex$`SIMULATION CONTROLS`$RSEED <- ifelse(cc == "SB", as.integer(runif(1, 500, 1000)), as.integer(runif(1, 1500, 2500)))
    filex$`SIMULATION CONTROLS`$IRRIG <- "N"
    filex$`SIMULATION CONTROLS`$FERTI <- "N"
    filex$`SIMULATION CONTROLS`$RESID <- "N"
    # # Define planting date
    pdates <- data.frame(seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1),
                         format(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week"), "%y%j"),
                         -99,5.3,5.3,"S","R",75,-99,3,-99,-99,-99,-99,-99,
                         paste0("PD", seq(1, length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")))))
    colnames(pdates) <- colnames(filex$`PLANTING DETAILS`)
    filex$`PLANTING DETAILS` <- pdates
    # Define irrigation
    filex$`IRRIGATION AND WATER MANAGEMENT`$IDEP <- 0
    filex$`IRRIGATION AND WATER MANAGEMENT`$ITHR <- 0
    filex$`IRRIGATION AND WATER MANAGEMENT`$IEPT <- 0
    filex$`IRRIGATION AND WATER MANAGEMENT`$IAMT <- 0
    filex$`IRRIGATION AND WATER MANAGEMENT`$IDATE <- format(as.Date(sdate, "%Y-%m-%d"), "%y%j")
    # # Define fertilizer amounts
    # fert <- data.frame(1, format(as.Date(sdate, "%Y-%m-%d"), "%y%j"), "FE013", "AP004", 5, 60, 26, 50, "NA", "NA", "NA", "NA")
    # colnames(fert) <- colnames(filex$`FERTILIZERS (INORGANIC)`)
    # filex$`FERTILIZERS (INORGANIC)` <- fert
    # # Define fertilizer amounts
    fert <- rbind(c(1, 0, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F1"),
                  c(1, 47, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F2"),
                  c(2, 0, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F1"),
                  c(2, 47, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F2"),
                  c(3, 0, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F1"),
                  c(3, 47, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F2"),
                  c(4, 0, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F1"),
                  c(4, 47, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F2"),
                  c(5, 0, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F1"),
                  c(5, 47, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F2"),
                  c(6, 0, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F1"),
                  c(6, 47, "FE005", "AP004", 5, 60, 0, 0, NA, NA, NA, "F2"))
    fert <- data.frame(fert)
    colnames(fert) <- colnames(filex$`FERTILIZERS (INORGANIC)`)
    filex$`FERTILIZERS (INORGANIC)` <- fert
    # Define Automatic management options
    filex$`SIMULATION CONTROLS`$PFRST <- format(as.Date(sdate, "%Y-%m-%d"), "%y%j")
    # filex$`SIMULATION CONTROLS`$PLAST <- format(as.Date(edate, "%Y-%m-%d"), "%y%j")
    filex$`SIMULATION CONTROLS`$PLAST <- format(as.Date(paste0(format(as.Date(edate, "%Y-%m-%d"), "%Y"), "-12-31"), "%Y-%m-%d"), "%y%j")
    filex$`SIMULATION CONTROLS`$PH2OL <- 0
    filex$`SIMULATION CONTROLS`$PH2OU <- 100
    filex$`SIMULATION CONTROLS`$PH2OD <- 0
    filex$`SIMULATION CONTROLS`$PSTMX <- 50
    filex$`SIMULATION CONTROLS`$PSTMN <- 0
    filex$`SIMULATION CONTROLS`$IMDEP <- 0
    filex$`SIMULATION CONTROLS`$ITHRL <- 0
    filex$`SIMULATION CONTROLS`$ITHRU <- 100
    filex$`SIMULATION CONTROLS`$IRAMT <- 0
    filex$`SIMULATION CONTROLS`$IREFF <- 1
    filex$`SIMULATION CONTROLS`$NMDEP <- 0
    filex$`SIMULATION CONTROLS`$NMTHR <- 0
    filex$`SIMULATION CONTROLS`$NAMNT <- 0
    filex$`SIMULATION CONTROLS`$RIPCN <- 0
    filex$`SIMULATION CONTROLS`$RTIME <- 1
    filex$`SIMULATION CONTROLS`$RIDEP <- 0
    filex$`SIMULATION CONTROLS`$HFRST <- format(as.Date(sdate, "%Y-%m-%d"), "%y%j")
    filex$`SIMULATION CONTROLS`$HLAST <- format(as.Date(paste0(format(as.Date(edate, "%Y-%m-%d"), "%Y"), "-12-31"), "%Y-%m-%d"), "%y%j")
    # filex$`SIMULATION CONTROLS`$HARVS <- "A"
    # Add SIMULATION CONTROL switches (for WLY and Nutrient)
    filex$`SIMULATION CONTROLS`$WATER <- "Y"
    filex$`SIMULATION CONTROLS`$NITRO <- "N"
    filex$`SIMULATION CONTROLS`$SYMBI <- "N"
    filex$`SIMULATION CONTROLS`$PHOSP <- "N"
    filex$`SIMULATION CONTROLS`$POTAS <- "N"
    filex$`SIMULATION CONTROLS`$DISES <- "N"
    filex$`SIMULATION CONTROLS`$CHEM <- "N"
    filex$`SIMULATION CONTROLS`$TILL <- "N"
    filex$`SIMULATION CONTROLS`$CO2 <- "M"
    filex$`SIMULATION CONTROLS`$FERTI <- "D"
    # Add SOIL and WTH references to FileX
    filex$FIELDS$WSTA<-paste0("WHTE", formatC(width = 4, as.integer((pnt-1)), flag = "0"))
    filex$FIELDS$ID_SOIL<-paste0('SO', formatC(width = 6, as.integer((pnt-1)), flag = "0"))
    # # Define the initial conditions
    # filex$`INITIAL CONDITIONS`$ICDAT<-format(as.Date(sdate, "%Y-%m-%d"), "%y%j")
    
    # icd <- data.frame(seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1),
    #                   "MZ",
    #                   format(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week"), "%y%j"),
    #                   # NA, NA, 1, 1, NA, NA, NA, NA, NA, NA,
    #                   0, 0, 1, 1, 200, 0, 0, 0, 0, 0,
    #                   # paste0("IC", seq(1, length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week"))))
    #                   NA)
    # colnames(icd) <- colnames(filex$`INITIAL CONDITIONS`[,1:14])
    # icd <- tibble::as_tibble(icd)
    # icd$C <- 1:6
    # icd$ICBL <- list(filex$`INITIAL CONDITIONS`$ICBL[[1]])
    # icd$SH2O <- list(c(0.13, 0.15, 0.14, 0.13, 0.12),
    #                  c(0.13, 0.16, 0.14, 0.13, 0.13),
    #                  c(0.14, 0.16, 0.14, 0.13, 0.12),
    #                  c(0.14, 0.16, 0.14, 0.13, 0.13),
    #                  c(0.13, 0.16, 0.14, 0.13, 0.12),
    #                  c(0.13, 0.15, 0.14, 0.13, 0.12))
    # icd$SNH4 <- list(filex$`INITIAL CONDITIONS`$SNH4[[1]])
    # icd$SNO3 <- list(filex$`INITIAL CONDITIONS`$SNO3[[1]])

    filex$`INITIAL CONDITIONS` <- filex$`INITIAL CONDITIONS` %>% 
      add_row() %>% 
      add_row() %>% 
      add_row() %>% 
      add_row() %>% 
      add_row()
    filex$`INITIAL CONDITIONS`$C <- 1:6
    filex$`INITIAL CONDITIONS`$PCR <- "MZ"
    filex$`INITIAL CONDITIONS`$ICDAT <- format(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week"), "%y%j")
    filex$`INITIAL CONDITIONS`$ICRT <- NA
    filex$`INITIAL CONDITIONS`$ICND <- NA
    filex$`INITIAL CONDITIONS`$ICRN <- NA
    filex$`INITIAL CONDITIONS`$ICRE <- NA
    filex$`INITIAL CONDITIONS`$ICWD <- NA
    filex$`INITIAL CONDITIONS`$ICRES <- NA
    filex$`INITIAL CONDITIONS`$ICREN <- NA
    filex$`INITIAL CONDITIONS`$ICREP <- NA
    filex$`INITIAL CONDITIONS`$ICRIP <- NA
    filex$`INITIAL CONDITIONS`$ICRID <- NA
    filex$`INITIAL CONDITIONS`$ICBL <- list(filex$`INITIAL CONDITIONS`$ICBL[[1]])
    filex$`INITIAL CONDITIONS`$SH2O <- list(c(0.13, 0.15, 0.14, 0.13, 0.12),
                                            c(0.13, 0.16, 0.14, 0.13, 0.13),
                                            c(0.14, 0.16, 0.14, 0.13, 0.12),
                                            c(0.14, 0.16, 0.14, 0.13, 0.13),
                                            c(0.13, 0.16, 0.14, 0.13, 0.12),
                                            c(0.13, 0.15, 0.14, 0.13, 0.12))
    filex$`INITIAL CONDITIONS`$SNH4 <- list(filex$`INITIAL CONDITIONS`$SNH4[[1]])
    filex$`INITIAL CONDITIONS`$SNO3 <- list(filex$`INITIAL CONDITIONS`$SNO3[[1]])
    
    # Prepare the treatment levels of FileX
    for (var in v$C) {
      # Define cultivars
      filex$CULTIVARS <- v[var,]
      filex$CULTIVARS$C <- 1
      # Define Treatments
      treat <- data.frame( # seq_along(seq(1,length(seq(as.Date(sdate, "%Y-%m-%d") + 1, as.Date(edate, "%Y-%m-%d") - 1, by = "1 week")), by = 1)),
                          seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1),
                          1, 1, 0,
                          # Treatment name
                          paste0(rep(v$INGENO[var], each = length(seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1))),
                                 "_PD_", seq(1:length(seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1)))),
                          # Cultivar selection
                          # rep(v$C, each=length(seq(as.Date(sdate, "%Y-%m-%d") + 1, as.Date(edate, "%Y-%m-%d") - 1, by = "1 week"))),
                          1, 1, 0,
                          seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1),
                          # 1,
                          # seq(1,length(seq(as.Date(sdate, "%Y-%m-%d") + 1, as.Date(edate, "%Y-%m-%d") - 1, by = "1 week")), by = 1),
                          seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1),
                          0,0,
                          # seq(1,length(seq(as.Date(sdate, "%Y-%m-%d"), length.out = 6, by = "1 week")), by = 1),
                          0, 0, 0, 0, 0, 1)
      colnames(treat) <- colnames(filex$`TREATMENTS                        -------------FACTOR LEVELS------------`)
      filex$`TREATMENTS                        -------------FACTOR LEVELS------------` <- treat
      # # DSSAT::write_filex(filex, paste0("EX",v$INGENO[var],'.MZX'))
      DSSAT::write_filex(filex, paste0("EX", v$INGENO[var], ".", tools::file_ext(list.files(paste0(root, "/data/inputs/dssat/xfiles"), pattern = as.character(version), full.names = TRUE))))
    }
    setwd(path.to.ex)
    gc()
  }
  stopCluster(cls)
}
