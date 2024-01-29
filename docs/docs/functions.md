---
layout: default
title: Functions
nav_order: 4
---

# Functions

## 1 Download data

Necessary data for the execution of the DST has to be pre-populated into the system.
This process is carried by the tools stored in `./functions/01_download`.
These set of functions do not run with the rest of the DST, since these are heavy processes which take time.
Instead, the data manager will need to make sure the data is updated and execute the functions as per the update schedules,
or in worst case after data losses. The data sources rely on CG Labs internal data vault to access and repopulate the data inputs for environmental data.
Each download process is specific for the different data sources in `./data/input/main` and needs to be executed separately from the CG Labs terminal.
For example, to download the data for chirps data, the user would need to execute the following command:

```
jovyan@user:~$ cd /home/jovyan/saa-use-case/functions/01_download
jovyan@user:~/saa-use-case/functions/01_download$ Rscript 01_2_download_chirps.R 
```

Where `2022` is the year that needs to be updated. It is important that the user executes the script from the local script directory
(`./functions/01_download`), as shown in the example above. The outputs will be automatically stored in the relevant folder in ./data/input/main

## 2 Extract, Transform and Load

The functions stored in ./functions/02_etl serve to interact with the relevant data inputs in **./data/input/main**. They are a typical set of ETL (Extract, Transform and Load)
procedures that allow to provide data for the DST, and particularly for the DSSAT software. These are stand-alone procedures integrated into the DSSAT routines,
so the user does not need to execute them, unless a new variable from the dataset is implemented, or a new dataset is being added, in which case an ETL will need to be developed.
At the moment there are 4 ETL processes providing inputs in the DST: **02_01_isda.R** for soil variables; **02_02_agera5.R** for climatic variables (except rainfall);
**02_03_chirps.R** for rainfall; and **02_04_gps.R** to provide GPS coordinates in the target area if the user does not provide specific ones.
These are stand-alone procedures integrated into the DSSAT routines, so the user does not need to execute them, but below are examples of how they work:

```
get.isda(X = 9.578, Y = 10.564)
```

Which would return something like:

```
iso     X      Y depth lyr_center clay sand silt bulk_density  ph
1  NG 9.578 10.564    20         10   21   55   23         1.36 6.1
2  NG 9.578 10.564    50         35   27   52   23         1.35 6.2
```

For extracting the data from CHIRPS, for example:

```
chirps(startDate = "2020-07-01", endDate = "2020-07-13", coordPoints = data.frame(X = 9.578, Y = 10.564))
```

Returning:

```
       X      Y      dates year month day      rain
1  9.578 10.564 2020-07-01 2020    07  01  0.000000
2  9.578 10.564 2020-07-02 2020    07  02  0.000000
3  9.578 10.564 2020-07-03 2020    07  03 20.258272
4  9.578 10.564 2020-07-04 2020    07  04 20.258272
5  9.578 10.564 2020-07-05 2020    07  05 20.258272
6  9.578 10.564 2020-07-06 2020    07  06  5.997376
7  9.578 10.564 2020-07-07 2020    07  07 11.994753
8  9.578 10.564 2020-07-08 2020    07  08  5.997376
9  9.578 10.564 2020-07-09 2020    07  09  5.997376
10 9.578 10.564 2020-07-10 2020    07  10 11.994753
11 9.578 10.564 2020-07-11 2020    07  11  0.000000
12 9.578 10.564 2020-07-12 2020    07  12 33.512047
13 9.578 10.564 2020-07-13 2020    07  13  6.702409
```

## 3 DSSAT

As mentioned, this is the engine of the DST. These functions are the processes that form component B shown in figure 1, and are stored in **./functions/03_dssat**.
Just as the other download and ETL processes, the user does not need to interact with these scripts in order to execute the DST.
They automatically generate and run the necessary steps to run and execute DSSAT, and depend on *02_etl* (see 6.2 Extract, Transform and Load)
to prepare the necessary soil and weather data requirements.

The functions provide the possibility to be executed in parallel for computationally intensive runs of the DST, such as multiple years, over large number of locations (e.g.; 100).
They require certain inputs to be provided by the user, such as the target area or locations to be simulated and the range of dates to cover.
The functions automatically read and construct the necessary folder structure to store the intermediate DSSAT results under *./data/intermediate/dssat*.
The processes are sequential and need to be executed in order, but this is handled by the DST. Below are examples of these functions.

The function **03_01_dssat_inputs.R** is responsible for preparing the necessary environmental data (soil and weather) in the required DSSAT formats.
It uses the set of locations and range of times to extract the relevant information as per below:

```
dssat.extdata(coords = data.frame("longitude" = c(9.578), "latitude" = c(10.564)),
	      sdate = "2023-01-01", edate = "2023-12-31",
	      jobs = 1,
	      path.to.ex = “data/intermediate/dssat/v20231231”)
```
The code above will extract and write DSSAT .WTH and .SOL files to a folder *./data/intermediate/dssat/v20231231/EXTE0000/* for the range of dates indicated and the coordinates provided.
The DST is designed to simulate the entire year (1st Jan to 31st Dec), so the .WTH files will contain daily weather observations for each entire year in the date range.

DSSAT requires an Xfile or experimental file which defines the scenario to be simulated. This file is generated using the **03_02_dssat_experiment.R** script and requires the same arguments to be defined:

```
dssat.Xdata(coords = data.frame("longitude" = c(9.578), "latitude" = c(10.564)),
	    sdate = "2023-01-01", edate = "2023-12-31",
	    jobs = 1,
	    path.to.ex = “data/intermediate/dssat/v20231231”)
```

This produces the .MZX file using the template *vYYYYMMDD.MZX* (see [Inputs](architecture.html/#1-inputs)) provided by the user in *./data/inputs/dssat/xfiles*. These files look something like:

```
*EXP.DETAILS: 

*GENERAL
@PEOPLE
@ADDRESS
@SITE
X=7.82500000069449, Y=12.2749999676097

*TREATMENTS                        -------------FACTOR LEVELS------------
@N R O C TNAME.................... CU FL SA IC MP MI MF MR MC MT ME MH SM
 1 1 1 0 IF0012_PD_1                1  1  0  1  1  0  1  0  0  0  0  0  1
 2 1 1 0 IF0012_PD_2                1  1  0  1  2  0  1  0  0  0  0  0  1

*CULTIVARS
@C CR INGENO CNAME
 1 MZ IF0012 DT STR W

*FIELDS
@L ID_FIELD WSTA....  FLSA  FLOB  FLDT  FLDD  FLDS  FLST SLTX  SLDP  ID_SOIL    
 1 00000001 WHTE0081   -99   -99   -99   -99   -99   -99  SIL   237  ISDA000081
```

Once the required files (.SOL, .WTH and .MZX) are generated, it is possible to execute DSSAT. The function in 03_03_dssat_execute.R uses the same inputs as the other two dssat functions shown above,
and launches a batch execution. The DSSAT output files are stored in ./data/intermediate/dssat/v20231231/EXTE0000/, but only the .OUT files are kept. Below is an example of how DSSAT is executed in the DST:

```
dssat.execute(coords = data.frame("longitude" = c(9.578), "latitude" = c(10.564)),
	      sdate = "2023-01-01", edate = "2023-12-31",
	      jobs = 1,
	      path.to.ex = “data/intermediate/dssat/v20231231”)
```

## 4 Aggregation

The final outputs from the DST are generated through the functions in **./functions/04_aggregation**. There are two processes in this component (C in figure 1): *04_01_aggregation_dssat.R*
which aggregates DSSAT outputs; and *04_02_aggregation_rank.R* which ranks the aggregated outputs and produces the final look-up table for the DST ([Outputs](architecture.html/#3-outputs)).
Both processes are again automated and part of the processing chain, so the user does not need to explicitly run the scripts. The function 04_01_aggregation_dssat.R reads the DSSAT .OUT files
for all locations, varieties and planting dates in the DST run, and puts everything into a single temporary table. It is executed as follows:

```
dssat.aggregate(years = c(2020:2023),
		jobs = 1,
		path.to.ex = “data/intermediate/dssat/v20231231”)
```

The final ranked outputs from the DST are generated through the script 04_02_aggregation_rank.R, which produces several metrics of the yield (upper limit, mean, lower limit and coefficient of variation)
to determine the most appropriate combination of variety and planting windows in each simulated location. The function in this script can be executed as follows:		

```
rank.aggregate(years = c(2020:2023),
	       jobs = 1,
	       path.to.ex = “data/intermediate/dssat/v20231231”)
```

Which stores the final DST output in a CSV tabular format in *./data/outputs/* (see [Outputs](architecture.html/#3-outputs)).

## 5 Executing the DST

To execute the DST, the user can run a command from the terminal.

```
jovyan@user:~$ cd /path/to/mashawara/functions
jovyan@user:/path/to/mashawara/functions$ Rscript 0_saa.R Kano 2022-01-01 2022-12-31 6
```

It is recommended to execute the DST from the functions directory, as shown in the first line of the block above. In the example, the **Rscript** command is used to execute R scripts from the terminal,
in this case, we are executing the **0_saa.R** script, a ‘mother’ script containing all other scripts and putting the different processes together. After this the user needs to provide a set of 4 arguments.
The first argument is the set of GPS coordinates corresponding to each point simulation (in the example above **Kano**). Optionally, the user can provide a table in CSV format with the file name convention
(as indicated in [User](#13-user)) and storing it under the relevant user folder. The 2 next arguments are the start and end dates (**2022-01-01** and **2022-12-31** in the example),
composing the date ranges that the DST will be executed for. This can span over multiple years, and at least, the DST will execute an entire calendar year,
even if the year is the same both at the start and end dates. Finally, the user needs to provide the number of parallel processes to be executed (**6** in the example).
This process also checks that the input requirements are met, including the .MZX file with the appropriate name, and will write the intermediate and final outputs in the relevant folders.

