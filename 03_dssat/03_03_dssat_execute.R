dssat.execute <- function(coords = NULL,
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
  # Execution (loop simulations)
  foreach::foreach(pnt=seq_along(coords[,1]), .export = ls(globalenv()), .inorder = TRUE, .packages = c("tidyverse", "lubridate")) %dopar% {
    # read coordinates of the point
    x = coords[pnt,1]
    y = coords[pnt,2]
    ######################################################### MODEL EXECUTION ######################################################
    # Set the experimental directory
    setwd(paste(path.to.ex,paste0('EXTE', formatC(width = 4, (as.integer(pnt)-1), flag = "0")), sep = "/"))
    # v <- as.data.frame(DSSAT::read_cul(paste0(root, "/data/inputs/dssat/SBGRO048.CUL")))
    # v <- as.data.frame(DSSAT::read_cul(paste0(root, "/data/inputs/dssat/culfiles/v", as.character(version), ".CUL")))
    v <- as.data.frame(DSSAT::read_cul(list.files(paste0(root, "/data/inputs/dssat/culfiles"), pattern = as.character(version), full.names = TRUE)))
    v <- data.frame("C" = 1:length(v[[1]]),
                    "CR" = substr(tools::file_ext(list.files(paste0(root, "/data/inputs/dssat/xfiles"), pattern = as.character(version), full.names = TRUE)), start = 1, stop = 2),
                    "INGENO" = v[[1]],
                    "CNAME" = v[[2]])
    for (var in v$C) {
      # filex <- DSSAT::read_filex(paste0("EX",v$INGENO[var],'.MZX'))
      filex <- DSSAT::read_filex(list.files("./", pattern = as.character(v$INGENO[var])))
      # Create Batch file
      # tibble(FILEX = paste0("EX", v$INGENO[var], '.MZX'),
      tibble(FILEX = list.files("./", pattern = as.character(v$INGENO[var])),
             TRTNO=filex$`TREATMENTS                        -------------FACTOR LEVELS------------`$N,
             RP=1, SQ=0, OP=0, CO=0) %>%
        DSSAT::write_dssbatch(file_name = paste0("EX", v$INGENO[var], '.V48'))
        # DSSAT::write_dssbatch(file_name = paste0("EX", v$INGENO[var], '.V47'))
      # Run DSSAT-CSM
      # !!!!!!!!!!!!!!!!!  REMEMBER TO CORRECT THE VARIETY FILES AND ADD NEW VARIETIES /opt/DSSAT/Genotype/*.CUL !!!!!!!!!!!!!!!!!!!!
      # This has been automated through WORKFLOW.R with Cultivars.xlsx
      system(paste0("/opt/DSSAT/v4.8.1.40/dscsm048 B ", paste0("EX", v$INGENO[var], '.V48')))
      # system(paste0("/opt/DSSAT/v4.7.5.30/dscsm047 B ", paste0("EX", v$INGENO[var], '.V47')))
      if (file.exists("Summary.OUT")){
        file.rename(list.files(pattern = "Summary.OUT"), paste0("EX", v$INGENO[var], ".OUT"))
      }
    }
    file.remove(setdiff(list.files(), list.files(pattern = paste0(paste0("EX", v$INGENO, collapse = "|"), "|.WTH|.SOL"))))
    # ######################################################### End of Function ######################################################
    setwd(path.to.ex)
    gc()
  }
  stopCluster(cls)
}