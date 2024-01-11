# Data Download Script

This Bash script automates the download of various datasets for a project using Rscript. The script logs the setup process in a file named `setup.log`.

## Usage

1. Make the script executable:

```bash
chmod +x setup.sh
```

2. Run the script to prepare the data directory structure and the data:

    Before is necessary to edit the `R/01_0_download_gadm.R` which downloads GADM data and edit the first line with the ISO3 of the country of interest. Then you can run the `setup.sh` script as:

```bash
./setup.sh
```

    After this, the `data` directory should contain several sub-directories more and data in them. You can also check `setup.log` for errors or other messages.

## Execute DST

To execute the tool you only need to run:

```bash
Rscript R/0_saa.R v20240111.csv historical 2010 2012 02 05 01 01 2
```

The arguments of this command are:

- **Rscript**: Launch R routines from the terminal
- **R/0_saa.R**: The path to the "main" script that executes the entire routine
- **v20240111.csv**: Name of a file containing the locations to be simulated. This file needs to exist under `data/input/user`.
- **2010**: Start year of the simulation.
- **2012**: End year of the simulation.
- **02**: Start month of the simulation.
- **05**: End month of the simulation.
- **01**: Start day of the simulation.
- **01**: End day of the simulation.
- **2**: Number of parallel processes.

It is important to execute the tool from the `root` directory. We are working on making this a more flexible tool and put it into and R package.

## Notes

- Ensure that R and required packages are installed before running the script.

- Review `setup.log` for any errors or issues during the setup process.

Feel free to customize the script or add additional instructions as needed for your specific project.
