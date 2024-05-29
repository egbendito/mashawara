# Example
# Rscript 0_saa.R v20231215.csv historical 2010 2012 01 06 01 30 4
# 1. Read inputs and check validity
  # 1.1 Catch arguments from bash
args <- commandArgs()
if(length(args) < 6){
  stop("Add the relevant arguments!")
}
aoi <- as.character(args[6])
class <- as.character(args[7])
# Check for valid "class" argument
if(!(class %in% c("historical", "forecast"))){
  stop("Please, choose between historical of forecast assessment")
}
if(class  == "historical"){
  start.year <- as.character(args[8])
  end.year <- as.character(args[9])
  start.month <- as.character(args[10])
  end.month <- as.character(args[11])
  start.day <- as.character(args[12])
  end.day <- as.character(args[13])
  workers <- as.integer(args[14])
} else {
  workers <- as.integer(args[8])
}


# Formatting of date
if(class  == "historical"){
  start.Date <- format(as.Date(paste0(start.year, start.month, start.day), "%Y%m%d"), "%Y%m%d")
  end.Date <- format(as.Date(paste0(end.year, end.month, end.day), "%Y%m%d"), "%Y%m%d")
} else {
  start.Date <- paste0(format(Sys.Date(), "%Y%m"), "02")
  end.Date <- format(as.Date(start.Date, "%Y%m%d")+214, "%Y%m%d")
}

# Define version name
version <- format(Sys.Date(), "%Y%m%d")

# Note root directory
root <- getwd()
  # 1.2 Check validity of inputs and necessary files
    # Check the spatial inputs (either file or a valid state in Nigeria)
if(grepl(paste0("v", version, ".csv"), aoi)){
  if(!file.exists(paste0(root, "/data/inputs/user/", "v", version, ".csv"))){
    stop("Please, ensure that a valid file with coordinates (Longitude and latitude columns, in .csv) is located in the user folder.")
  }
} else {
  if(!(aoi %in% c("Kano", "Kaduna"))){
    stop("Please, use an accepted location for the DST")
  }
}
    # Check if dates are correct and valid
if(class  == "historical"){
  if(as.Date(start.Date, "%Y%m%d") < as.Date("1990-01-01") | as.Date(start.Date, "%Y%m%d") > as.Date(paste0(as.integer(format(Sys.Date(), "%Y"))-1, "-12-31"))){
    stop("Start date is not accepted. Please, make sure is after or on 1st Jan 1990 and not grater than Dec 31st of last year. Also ensure is the correct date format (YYYY-MM-DD)")
  }
  if(as.Date(end.Date, "%Y%m%d") < as.Date("1990-01-01") | as.Date(end.Date, "%Y%m%d") > as.Date(paste0(as.integer(format(Sys.Date(), "%Y"))-1, "-12-31")) | as.Date(end.Date, "%Y%m%d") < as.Date(start.Date, "%Y%m%d")){
    stop("End date is not accepted. Please, make sure is after or on 1st Jan 1990, not grater than Dec 31st of last year and after the *Start Date*. Also ensure is the correct date format (YYYY-MM-DD)")
  }
}

     # Check that the number of jobs is appropriate
if(workers > 30){stop("Number of parallel workers not accepted. Please use a number lower than 10")}
    # Check that the necessary .MZX template file is there
if(!file.exists(list.files(paste0(root, "/data/inputs/dssat/xfiles"), pattern = as.character(version), full.names = TRUE))) stop("Please, add an X file template")
# Check that the necessary .CUL file with the varieties is there
if(!file.exists(paste0(root, "/data/inputs/dssat/culfiles/v", as.character(version), ".CUL"))) stop("Please, add an .CUL template")
# # 2. Install requirements
packs <- data.frame("package" = c("DSSAT"),
                    "version" = c("0.0.6"))
ipacks <- as.data.frame(installed.packages())
for (p in 1:nrow(packs)){
  pack <- packs[p,1]
  ver <- packs[p,2]
  if(!(pack %in% ipacks[,"Package"])){
    cat(paste0("\nInstalling: ", pack, " (ver ", ver, ")\n"))
    devtools::install_version(pack, ver, repos = "https://cloud.r-project.org/")
  }
  else{
    cat(paste0("\nUninstalling and re-installing: ", pack, " (ver ", ver, ")\n"))
    utils::remove.packages(pack, lib = ipacks[ipacks$Package == pack, "LibPath"])
    devtools::install_version(pack, ver, repos = "https://cloud.r-project.org/", force = TRUE, upgrade = "never", quiet = TRUE)
  }
}
# 3. Source Functions
funcs <- list.files(paste0(root, "/R/"),
                    recursive = TRUE, full.names = TRUE, include.dirs = FALSE,
                    pattern = paste0(c("02", "03", "04"), collapse = '|'))
for (func in funcs) {
  source(func)
}
# 4. Start DST
  # 4.1 Define the AOI depending on the input by the user
if(grepl(paste0("v", version, ".csv"), aoi)){
  gps <- read.csv(paste0(root, "/data/inputs/user/", "v", version, ".csv"))
} else {
  gps <- define.regions(iso = "NGA", level = 1, resolution = 0.05)
  gps <- gps[gps$NAME_1 == aoi,]
}
  # 4.2 Define the list of years to simulate
if(class  == "historical"){
  years <- unique(format(seq(as.Date(as.character(format(as.Date(start.Date, "%Y%m%d"), "%Y-%m-%d"))), as.Date(as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d"))), by = "day"), "%Y"))
  # 4.3 Create the intermediate directory for DSSAT files
  dssat.paths <- paste0(root, "/data/intermediate/dssat/v", as.character(version), "/", years)
  for (dssat.path in dssat.paths) {
    dir.create(dssat.path, recursive = TRUE)
  }
} else {
  # 4.3 Create the intermediate directory for DSSAT files
  dssat.paths <- paste0(root, "/data/intermediate/dssat/v", as.character(version), "/forecast")
  for (dssat.path in dssat.paths) {
    dir.create(dssat.path, recursive = TRUE)
  }
}

  # 4.4 DSSAT
  # 4.4.0 Remove all pre-existing varieties. Replace with ours
CUL <- DSSAT::read_cul(paste0(root, "/data/inputs/dssat/culfiles/v", as.character(version), ".CUL"))
cr <-  substr(tools::file_ext(list.files(paste0(root, "/data/inputs/dssat/xfiles"),
                                         pattern = as.character(version),
                                         full.names = TRUE)),
              start = 1, stop = 2)
DSSAT::write_cul(CUL, file_name = paste0("/opt/DSSAT/v4.8.1.40/Genotype/", ifelse(cr == "SB", "SBGRO", "MZCER"), "048.CUL"))
# # DSSAT::write_cul(CUL, file_name = "/opt/DSSAT/v4.8.1.40/Genotype/SBGRO048.CUL")
# # DSSAT::write_cul(CUL, file_name = "/opt/DSSAT/v4.7.5.30/Genotype/MZCER047.CUL")
# Start simulations
if(class  == "historical"){
  for (year in years) {
    # Format years
    start.year <- as.integer(year)
    end.year <- as.integer(year)
    if(end.month < start.month){
      start.year <- as.integer(year)
      end.year <- as.integer(year) + 1
    }
    start.Date = paste0(start.year, start.month, start.day)
    end.Date = paste0(end.year, end.month, end.day)
    # Record directory
    dssat.intermediate <- paste0(root, "/data/intermediate/dssat/v", as.character(version), "/", year)
    # 4.4.1 Execute DSSAT + ETL
    dssat.extdata(coords = gps,
                  sdate = as.character(format(as.Date(start.Date, "%Y%m%d") - 21, "%Y-%m-%d")),
                  edate = as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d")),
                  jobs = workers,
                  path.to.ex = dssat.intermediate)
    # 4.4.2 Define experiment file
    dssat.Xdata(coords = gps,
                sdate = as.character(format(as.Date(start.Date, "%Y%m%d"), "%Y-%m-%d")),
                edate = as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d")),
                jobs = workers,
                path.to.ex = dssat.intermediate)
    # 4.4.3 Execute DSSAT
    dssat.execute(coords = gps,
                  sdate = as.character(format(as.Date(start.Date, "%Y%m%d"), "%Y-%m-%d")),
                  edate = as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d")),
                  jobs = workers,
                  path.to.ex = dssat.intermediate)
  }
} else {
  # Download ECMWF data
  source(paste0(root, "/R/01_download/", "01_4_s5wrapper.R"))
  # Record directory
  dssat.intermediate <- paste0(root, "/data/intermediate/dssat/v", as.character(version), "/forecast")
  # 4.4.1 Execute DSSAT + ETL
  dssat.extdata(coords = gps,
                sdate = as.character(format(as.Date(start.Date, "%Y%m%d") - 21, "%Y-%m-%d")),
                edate = as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d")),
                jobs = workers,
                path.to.ex = dssat.intermediate)
  # 4.4.2 Define experiment file
  dssat.Xdata(coords = gps,
              sdate = as.character(format(as.Date(start.Date, "%Y%m%d"), "%Y-%m-%d")),
              edate = as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d")),
              jobs = workers,
              path.to.ex = dssat.intermediate)
  # 4.4.3 Execute DSSAT
  dssat.execute(coords = gps,
                sdate = as.character(format(as.Date(start.Date, "%Y%m%d"), "%Y-%m-%d")),
                edate = as.character(format(as.Date(end.Date, "%Y%m%d"), "%Y-%m-%d")),
                jobs = workers,
                path.to.ex = dssat.intermediate)
}

  # 4.5 Aggregation
dir.create(paste0(root, "/data/outputs/"), recursive = TRUE)
if(class  == "historical"){
#     # 4.5.1 Aggregate DSSAT outputs by year
  dssat.aggregate(years = years,
                  jobs = workers,
                  path.to.ex = paste0(root, "/data/intermediate/dssat/v", as.character(version)))
#     # 4.5.2 Ranking the final results
  rank.aggregate(years = years,
                 jobs = workers,
                 path.to.ex = paste0(root, "/data/intermediate/dssat/v", as.character(version)))
} else {
#     # 4.5.1 Aggregate DSSAT outputs by year
  dssat.aggregate(years = "forecast",
                  jobs = workers,
                  path.to.ex = paste0(root, "/data/intermediate/dssat/v", as.character(version)))
#     # 4.5.2 Ranking the final results
  rank.aggregate.forecast(years = "forecast",
                          jobs = workers,
                          path.to.ex = paste0(root, "/data/intermediate/dssat/v", as.character(version)))
}

