rank.aggregate.forecast <- function(years = NULL,
                                    jobs = 1,
                                    path.to.ex = NULL){
  for (year in years) {
    t <- data.table::fread(paste0(path.to.ex, "/", year, "/dssat_aggregate_", year, ".csv"))
    if(tail(t$pweek, n = 1) != 52){
      t$pweek <- t$pweek + 1
    }
    colnames(t) <- c(paste0("pdate_", year), "pyear", "pmon", "pweek", "pdoy", "var", paste0("yield_", year), "x", "y")
    t <- t[,c(8,9,1,4,6,7)]
    if(year == years[1]){
      out <- t
    }
    else {
      out <- merge(out, t, by = c("x", "y", "pweek", "var"), all = TRUE)
    }
  }
  out$pdate_forecast <- gsub("19", "20", out$pdate_forecast)
  
  ##  Rank (top 3) optimal variety and date by yield
  # initialize output table
  nn <- data.frame("X" = NA, "Y" = NA, "var" = NA, "pdate" = NA, "rank" = NA)
  # Find top 3 combinations
  for (rank in 1:3) {
    res <- by(out, list(out$x, out$y), function(x)
      c(
        X = x$x[rank],
        Y = x$y[rank],
        var = x$var[rev(order(x$yield_forecast))][rank],
        pdate = x$pdate_forecast[rev(order(x$yield_forecast))][rank],
        rank = rank
      )
    )
    n <- as.data.frame(do.call(rbind, res))
    nn <- rbind(nn, n)
  }
  nn <- nn[2:nrow(nn),] # remove NA initialization
  # Sort output by location
  nn <- nn[with(nn, order(X, Y)), ]
  nn$E <- ifelse(nn$X > 0, "E", "W")
  nn$N <- ifelse(nn$Y > 0, "N", "S")
  nn$lookup_key <- paste0(nn$E,nn$X,nn$N,nn$Y)
  nn$spdate <- paste0(format(as.Date(nn$pdate, "%Y%m%d")-3, format = "%d %B"))
  nn$epdate <- paste0(format(as.Date(nn$pdate, "%Y%m%d")+3, format = "%d %B"))
  nn$pdate <- NULL
  # Write output (CSV)
  write.table(nn, paste0(root, "/data/outputs/", "v", version, ".csv"), sep = ",", row.names = FALSE)
  # Format to (JSON)
  json <- lapply(unique(nn$lookup_key), function(id) {
    recs <- nn[nn$lookup_key == id, c("rank", "pdate", "var", "X", "Y")]
    list(rank = recs)
  })
  # Naming the list elements with IDs
  names(json) <- unique(nn$lookup_key)
  # Write output in JSON
  jsonlite::write_json(json, paste0(root, "/data/outputs/", "v", version, ".json"))
}
