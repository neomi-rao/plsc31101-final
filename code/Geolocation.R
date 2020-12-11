library(ggmap)
library(purrr)

# set API key for Google Maps
register_google(key = "AIzaSyDcJaf423dDqPBcG_WEo7Ad35eSM-cpjMw")

# load the raw data from webscraping
blm_df_distinct <- read.csv("../data/BLM_data.csv", header = TRUE)

blm_df_longlat <- blm_df_distinct %>%
  # mutate_geocode() takes location input and runs it through the Google Maps API
  mutate_geocode(location = location, output = "latlona") # output gives lat, long, and Google Maps address

# Filter out rows with "Cities" or "Worldwide" or just "United States" in the location as these are not mappable 
blm_df_longlat <- blm_df_longlat %>%
  filter(!str_detect(location, "Cities|^United States$|Worldwide"))

# For some reason, mutate_geocode() doesn't catch all of the locations on the first run (may be a connection issue)
# Check row values with lon/lat NAs and figure out which ones need to be re-run with geocode 
blm_longlat_na <- blm_df_longlat[rowSums(is.na(blm_df_longlat)) > 0, ]

# Rerun geocode on these
blm_longlat_na <- blm_longlat_na %>% 
  select(date, location) %>%
  mutate_geocode(location = location, output = "latlona")

# Remove the remaining NAs from the original df and attach the re-run rows to the dataset 
blm_df_longlat <- blm_df_longlat %>%
  filter(!is.na(lon)) %>%
  bind_rows(blm_longlat_na)

# Check structure
str(blm_df_longlat)

# write to csv just in case (to reload from csv, run the code below)
# blm_df_longlat <- read.csv("BLM_data_longlat.csv", header = TRUE)
write.csv(blm_df_longlat, "BLM_data_longlat.csv", row.names = F)