# Data Download Script

This Bash script automates the download of various datasets for a project using Rscript. The script logs the setup process in a file named `setup.log`.

## Usage

1. Make the script executable:

    ```bash
    chmod +x your_script_name.sh
    ```

2. Run the script:

    ```bash
    ./your_script_name.sh
    ```

## Downloaded Datasets

- **00_0_skeleton.R**: Checks and generates a project skeleton. Verify the Region of Interest (ROI) for proper generation.

- **01_0_download_gadm.R**: Downloads GADM data.

- **01_5_download_chirts.R**: Downloads CHIRTS data.

- **01_2_download_chirps.R**: Downloads CHIRPS data.

- **01_1_download_agera5.R**: Downloads AGERA5 data.

- **01_3_download_isda.R**: Downloads ISDA data.

## Log

The script appends all output and errors to `setup.log`. Check this file for details about the download process.

## Notes

- Ensure that R and required packages are installed before running the script.

- Review `setup.log` for any errors or issues during the setup process.

Feel free to customize the script or add additional instructions as needed for your specific project.
