#pull NWIS qw data 
library(dataRetrieval)
library(dplyr)
library(sf)
drb_poly <- sf::st_read('../delaware-basin-processing/DRB_Extent.shp') %>% 
  st_transform(4326)
drb_bbox <- sf::st_bbox(drb_poly)

wqp_summary <- readWQPdata(statecode="DE",
                           characteristicName="Chloride",
                           startDateLo = '2010-01-01',
                           startDateHi = '2020-01-01',
                           querySummary = TRUE)

drb_states <- c("PA", "DE", "NJ", "NY")
all_results <- tibble()
all_locations <- tibble()
for(state in drb_states) {
  state_results <- readWQPdata(statecode=state,
                    characteristicName="Chloride",
                    startDateLo = '2010-01-01',
                    startDateHi = '2020-01-01') %>% 
    mutate_at(.vars = vars(ResultDepthHeightMeasure.MeasureValue,
                           ActivityTopDepthHeightMeasure.MeasureValue,
                           ActivityBottomDepthHeightMeasure.MeasureValue),
              .funs = as.character) %>%
    select(-contains("HorizontalAccuracyMeasure")) 
  
  unique_monitoring_locs <- unique(state_results$MonitoringLocationIdentifier)
  state_locations <- whatWQPsites(siteid = unique_monitoring_locs) %>% 
    select(-contains("HorizontalAccuracyMeasure"),
           -contains("VerticalAccuracyMeasure")) 
  all_results <- bind_rows(all_results, state_results)
  all_locations <- bind_rows(all_locations, state_locations)
}

#intersect with DRB polygon, filter down results
locations_spatial <- st_as_sf(all_locations, coords = c("LongitudeMeasure", "LatitudeMeasure"),
                              crs = 4326)

intersection <- st_intersects(locations_spatial, drb_poly$geometry)
locations_drb <- locations_spatial %>% filter(apply(intersection, 1, any))
results_drb <- all_results %>% filter(MonitoringLocationIdentifier %in% locations_drb$MonitoringLocationIdentifier &
                                      ResultMeasure.MeasureUnitCode == "mg/l" &
                                      ResultStatusIdentifier != "Preliminary")

#chloride thresholds
#250 drinking water
results_gt250 <- results_drb %>% filter(ResultMeasureValue > 250) %>%
  left_join(locations_drb, by = "MonitoringLocationIdentifier") %>%
  mutate(month = lubridate::month(ActivityStartDate, label=TRUE, abbr=FALSE)) %>% 
  st_as_sf() %>% st_crop( y = st_bbox(c(ymin = 39.74, ymax=40.9, xmax=-90, xmin=0))) %>%
  mutate(rescale_cex = scales::rescale(ResultMeasureValue, to = c(0.1, 5)))

city_df <- tibble(city = c("Wilmington", "Philadelphia"),
                  lat = c(39.74, 39.95),
                  lon = c(-75.55, -75.16))
st_bbox(results_gt250)
ggplot(results_gt250, aes(x = month)) + geom_bar() +
  labs(x="Month", y = "Chloride samples > 250 mg/L", 
       title = "Chloride samples exceeding EPA drinking water threshold",
       subtitle = "Delaware Basin above Wilmington, DE, 2010-2020")

#TODO: plot each month separately
#TODO: animation and bar chart by month
plot(drb_poly$geometry, ylim = c(39.5, 40.3))
plot(drb_flow$geometry, add=TRUE, col = "blue")
points(city_df$lon, city_df$lat, pch = 15, cex=2)
plot(results_gt250$geometry, col="red", cex = results_gt250$rescale_cex, add=TRUE,
     pch=16)
i <- 1
for(this_month in month.name[c(10:12, 1:9)]) {
  month_df <- filter(results_gt250, month == this_month)
  print(nrow(month_df))
  png(filename = sprintf("%02d_%s.png", i, this_month))
  plot(drb_poly$geometry, ylim = c(39.5, 40.3))
  plot(drb_flow$geometry, add=TRUE, col = "blue")
  plot(month_df$geometry, col="red", cex = month_df$rescale_cex, add=TRUE,
       pch=16)
  points(city_df$lon, city_df$lat, pch = 15, cex=2)
  title(main = "Chloride samples exceeding EPA drinking water threshold",
        sub = paste(this_month, "2010-2020"))
  dev.off()
  i <- i+1
}
