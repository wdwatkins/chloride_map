# Chloride map test
Prototyping a map of chloride hand samples in the Delaware Basin.  The script in `R` holds a quick and dirty workflow:

  - Pulls chloride data from the Water Quality Portal for states of DE, PA, NY, NJ for 2010-2020
  - intersects it with a polygon of the Delaware River Basin
  - does some cleaning and munging to create an `sf` data frame of all observations
  - creates some basic figures with samples exceeding 250 mg/L (EPA drinking water standard)
  
`create_gif.sh` contains an imagemagick command to create a gif from the map frames
  
![chloride sample histogram](https://github.com/wdwatkins/chloride_map/blob/master/plots/month_bars.png)

![chloride sample map](https://github.com/wdwatkins/chloride_map/blob/master/plots/map_months.gif)