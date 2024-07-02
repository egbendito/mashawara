# Create Data seleton

origin<- getwd()

dir.create(path = paste0("./data/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/administrative/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/soil/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/soil/isda/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/weather/historical/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/main/weather/forecast/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/dssat/culfiles/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/dssat/xfiles/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/inputs/user/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/intermediate/dssat/"), recursive = TRUE, showWarnings = FALSE)
dir.create(path = paste0("./data/outputs/"), recursive = TRUE, showWarnings = FALSE)

setwd(origin)

cat('\nData structure created\n')

