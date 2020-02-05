#pull NWIS qw data 
library(dataRetrieval)
library(dplyr)
library(sf)
?readWQPdata
drb_poly <- sf::st_read('../delaware-basin-processing/DRB_Extent.shp')
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
  #ActivityTopDepthHeightMeasure.MeasureValue
  all_results <- bind_rows(all_results, state_results)
  all_locations <- bind_rows(all_locations, state_locations)
}

all_results <- 

#TODO: standardize units if needed