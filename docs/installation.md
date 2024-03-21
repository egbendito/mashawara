---
layout: default
title: Installation
nav_order: 2
---

# Installation

## 1. How to install?

The tool is designed to be deployed in a [CG Labs](https://labs.scio.systems/) like environment under its current deployment in the
CGIAR system. Independent users might choose to deploy on their own systems. This can be done through [tenedor](https://github.com/egbendito/tenedor)
or following a more customize build (which will be included in a future release). The basic procedure to install the tool is by cloning the repository.
This can be done by running `git clone https://github.com/egbendito/mashawara` from a terminal or by downloading the local directory.

[Download Mashawara](https://github.com/egbendito/mashawara/archive/refs/heads/prod.zip){: .btn}

## 2. Configuration

Once cloned, the tool needs to be configured to the desired region of interest. This is done by indicating the ISO3 codes of 1 or more countries as arguments.
For example to deploy an instance focusing on Kenya, Ethiopia and Tanzania:

```
setup.sh KEN ETH TZA
```

Alternatively, the user can store a copy of the region of interest (ROI) in [GeoPackage format](https://www.geopackage.org/) (GPKG) and a single layer called "roi".

## 3. Requirements

Tool dependencies are listed below. When installing the tool directly from the [tenedor](https://github.com/egbendito/tenedor) docker image, all software requirements
are installed by default. This is the preferred way. For a customized deployment users can clone the repository [GitHub repository](https://github.com/egbendito/mashawarar), which provide the required R packages and Python modules.

```
# List of R packages required and versions
devtools==2.4.5
utils==4.2.2
tools==4.2.2
terra==1.7.46
sf==1.0.14
DSSAT==0.0.6
parallel==4.2.2
doParallel==1.0.17
foreach==1.5.2
tidyverse==2.0.0
lubridate==1.9.2
jsonlite==1.8.7
```

```
# List of Python modules required and versions
xarray==2024.2.0
cdsapi==0.6.1
numpy==1.26.4
```

It is necessary to execute the tool inside a Linux Debian-based distro, preferably using Ubuntu 22.04. Additionally, the user needs to provide a [CDS key](https://google.com).

## 4. How to upgrade

In future releases and updates of the tool the user will need to re-start from scratch... But better not do it like that...
