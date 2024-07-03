#!/bin/bash

# Rscript R/01_download/00_0_skeleton.R > setup.log # Need to check because the ROI is not properly generated... MOZ is missing
# Rscript R/01_download/01_0_download_gadm.R >> setup.log 2>&1
# Rscript R/01_download/01_5_download_chirts.R >> setup.log 2>&1
Rscript R/01_download/01_2_download_chirps.R >> setup.log 2>&1
# Rscript R/01_download/01_1_download_agera5.R >> setup.log 2>&1
Rscript R/01_download/01_3_download_isda.R >> setup.log 2>&1
Rscript R/01_download/01_31_download_isric.R >> setup.log 2>&1

# Add python requirements
conda install -y -c conda-forge cdsapi
conda install -y -c conda-forge xarray
conda install -y -c conda-forge netcdf4

exit
