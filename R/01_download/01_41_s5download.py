import numpy as np
import time
import os
import sys
import xarray as xr # Need to install
import cdsapi # Need to install


year = int(sys.argv[1])
month = int(sys.argv[2])
xmin = float(sys.argv[3])
xmax = float(sys.argv[4])
ymin = float(sys.argv[5])
ymax = float(sys.argv[6])
area = [ymax, xmin, ymin, xmax,]

c = cdsapi.Client()

variables = ['total_precipitation', 'surface_net_solar_radiation', '10m_u_component_of_wind', '10m_v_component_of_wind',
             'maximum_2m_temperature_in_the_last_24_hours', 'minimum_2m_temperature_in_the_last_24_hours', '2m_temperature', '2m_dewpoint_temperature']
# variables = ['total_precipitation', 'surface_net_solar_radiation', '10m_u_component_of_wind', '10m_v_component_of_wind']

for var in variables:
    if var == 'total_precipitation':
      times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_rain_' + str(year) + '.nc'
    if var == 'surface_net_solar_radiation':
      times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_srad_' + str(year) + '.nc'
    if var == '2m_dewpoint_temperature':
      times = ["{:01d}".format(n) for n in range(6, 5166, 6)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_dp_' + str(year) + '.nc'
    if var == '10m_u_component_of_wind':
      times = ["{:01d}".format(n) for n in range(6, 5166, 6)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_uwind_' + str(year) + '.nc'
    if var == '10m_v_component_of_wind':
      times = ["{:01d}".format(n) for n in range(6, 5166, 6)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_vwind_' + str(year) + '.nc'
    if var == 'maximum_2m_temperature_in_the_last_24_hours':
      times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_tmax_' + str(year) + '.nc'
    if var == 'minimum_2m_temperature_in_the_last_24_hours':
      times = ["{:01d}".format(n) for n in range(24, 5166, 24)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_tmin_' + str(year) + '.nc'
    if var == '2m_temperature':
      times = ["{:01d}".format(n) for n in range(6, 5166, 6)]
      out = '../data/inputs/main/weather/forecast/ecmwf_s5_temp_' + str(year) + '.nc'
    c.retrieve(
        'seasonal-original-single-levels',
        {
            'format': 'netcdf',
            'variable': var,
            'originating_centre': 'ecmwf',
            'system': '51',
            'year': year,
            'month': month,
            'day': '01',
            'leadtime_hour': times,
            'area': area,
        },
        out
    )
    time.sleep(1)
    if var == 'total_precipitation':
      rain = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_rain_' + str(year) + '.nc')
      rain = rain * 1000
      rain = rain.mean(dim = 'number')
      rain.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_rain_' + str(year) + '.nc')
    if var == 'surface_net_solar_radiation':
      srad = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_srad_' + str(year) + '.nc')
      srad = srad
      srad = srad.mean(dim = 'number')
      srad.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_srad_' + str(year) + '.nc')
    if var == '10m_v_component_of_wind':
      wu = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_uwind_' + str(year) + '.nc')
      wv = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_vwind_' + str(year) + '.nc')
      w = np.sqrt((wu.u10 ** 2) + (wv.v10 ** 2))
      w = w.resample(time='1D').mean().mean(dim = 'number')
      w.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_wind_' + str(year) + '.nc')
    if var == '2m_dewpoint_temperature':
      temp = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_temp_' + str(year) + '.nc')
      t = temp - 273.15
      tmax = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_tmax_' + str(year) + '.nc')
      tmin = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_tmin_' + str(year) + '.nc')
      dp = xr.open_dataset('../data/inputs/main/weather/forecast/ecmwf_s5_dp_' + str(year) + '.nc')
      dp = dp - 273.15
      rh = 100 * ((np.exp((17.625 * dp.d2m)/(243.04 + dp.d2m)))/(np.exp((17.625 * t.t2m)/(243.04 + t.t2m))))
      rh = rh.resample(time='1D').mean().mean(dim = 'number')
      rh.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_rhum_' + str(year) + '.nc', mode = 'w', format = 'NETCDF4')
      temp = temp.resample(time='1D').mean().mean(dim = 'number')
      temp.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_temp_' + str(year) + '.nc')
      tmax = tmax.mean(dim = 'number')
      tmax.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_tmax_' + str(year) + '.nc')
      tmin = tmin.mean(dim = 'number')
      tmin.to_netcdf('../data/inputs/main/weather/forecast/ecmwf_s5_tmin_' + str(year) + '.nc')
        
