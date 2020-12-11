# Load the data to be pre-processed. 
blm_df_longlat <- read.csv("../data/BLM_data_longlat.csv", header = TRUE)

# Create weekyear function
# Note that this function messes up for 12/31 in certain years. This will be fixed later
weekyear <- function(d){
  week_year <- paste(year(d), week(d), 1, sep = "-")
  weekof <- as.Date(week_year, "%Y-%U-%u")
  return(weekof)
}

# check function
weekyear("2017-12-30")

# Add a column to the BLM dataset that aggregates dates to week/year format. 
# Also add year column
blm_df_ll_wk <- blm_df_longlat %>%
  mutate(weekof = weekyear(date),
         year = year(date)) 

#check for NAs 
blm_df_ll_wk[rowSums(is.na(blm_df_ll_wk)) > 0, ]

#manually fix the weird 12/31 cases
blm_df_ll_wk <- blm_df_ll_wk %>%
  mutate(weekof = replace(weekof, date=="2017-12-31", weekyear("2017-12-30")),
         weekof = replace(weekof, date=="2015-12-31", weekyear("2015-12-30")),
         weekof = replace(weekof, date=="2014-12-31", weekyear("2014-12-30"))
  )

# Write data with weeks to CSV
write.csv(blm_df_ll_wk, "data/BLM_data_weeks.csv", row.names = F)
##############################
# Create USA only dataset
blm_df_usa <- blm_df_ll_wk %>%
  filter(str_detect(address, ', usa'))
# And non-USA only dataset
blm_df_notusa <- blm_df_ll_wk %>%
  filter(!str_detect(address, ', usa'))

# Write US-only CSV
write.csv(blm_df_usa, "data/BLM_data_USA.csv", row.names = F)
##############################
library(sf)
library(urbnmapr)
# Create a US-only dataset with data for 2014 (1st wave) and for after May 25th 2020 (2nd wave)
# Also remove HI & AK data as these cannot be mapped to county by the current method
# Move long/lat columns to the front to allow for easier county mapping
blm_df_comp <- blm_df_usa %>%
  filter(year == 2014 | 
           date >= as.Date("2020-05-25")) %>%
  subset(select=c(lon, lat, location, address, date, weekof, year))

# Create a function to add county spatial data based on the lat long data 
## pointsDF: A data.frame whose first column contains longitudes and
##           whose second column contains latitudes.
##
## counties:   An sf MULTIPOLYGON object of US counties, including AK, HI, and territories.
##
## name_col: Name of a column in `counties` that supplies the county names.
##
lonlat_to_county <- function(pointsDF,
                             counties = get_urbn_map(map = "territories_counties", sf = TRUE),
                             fips_col = "county_fips") {
  ## Convert points data.frame to an sf POINTS object
  pts <- st_as_sf(pointsDF, coords = 1:2, crs = 4326)
  
  ## Transform spatial data to some planar coordinate system
  ## (e.g. Web Mercator) as required for geometric operations
  counties <- st_transform(counties, crs = 3857)
  pts <- st_transform(pts, crs = 3857)
  
  ## Find names of state (if any) intersected by each point
  county_fips <- counties[[fips_col]]
  ii <- as.integer(st_intersects(pts, counties))
  
  # Create dataframe that adds columns for county names original
  pointsDF_county <- data.frame(pointsDF, county_fips = county_fips[ii])
  # Return a dataframe that joins the spatial county df with the blm county df
  blm_counties_join <-left_join(pointsDF_county, counties, by = "county_fips")
  return(blm_counties_join)
}

blm_df_county <- lonlat_to_county(blm_df_comp)

# Manually add county data for Alaska & Hawaii
# Filter out rows with NA values for county FIPS
blm_county_na <- blm_df_county[rowSums(is.na(blm_df_county)) > 0, ] %>%
  select(lon, lat, location, address, date, weekof, year, county_fips) %>%
  # Manually add county FIPS codes - use paste0 to retain leading zeros
  mutate(county_fips = replace(county_fips, location=="Anchorage, AK", paste0("0", 02020)),
         county_fips = replace(county_fips, location=="Bethel, AK", paste0("0", 02050)),
         county_fips = replace(county_fips, location=="Juneau, AK", paste0("0", 02110)),
         county_fips = replace(county_fips, location=="Fairbanks, AK", paste0("0", 02090)),
         county_fips = replace(county_fips, location=="Kotzebue, AK", paste0("0", 02188)),
         county_fips = replace(county_fips, location=="Kahului, Maui, Hawaii", 15009),
         county_fips = replace(county_fips, location=="Hilo, Hawaii, HI", 15001),
         county_fips = replace(county_fips, location=="Honolulu, Oahu, HI", 15003),
         county_fips = replace(county_fips, location=="Nanakuli, Oahu, HI", 15003),
         county_fips = replace(county_fips, location=="Hanalei, Kauai, HI", 15007),
         county_fips = replace(county_fips, location=="Lihue, Kauai, HI", 15009),
         county_fips = replace(county_fips, location=="Kapolei, Oahu, HI", 15003),
         county_fips = replace(county_fips, location=="Waikiki, Honolulu, Hawaii", 15003))
# Join the rest of county spatial data via fips code
blm_na_join <- right_join(counties, blm_county_na, by = "county_fips")

# Filter out NAs from original dataset and add in AK & HI rows 
blm_df_county <- blm_df_county %>%
  filter(!is.na(county_fips)) %>%
  bind_rows(blm_na_join) %>%
  arrange(desc(date))

blm_2014 <- count(filter(blm_df_county, year == 2014), county_fips, name = "protests")
blm_2020 <- count(filter(blm_df_county, year == 2020), county_fips, name = "protests")

# Write county data to CSV 
#(remember to use st_write since the data needs to be converted from sf object to dataframe)
st_write(blm_df_county, "data/BLM_data_county.csv", row.names=FALSE)
# Write 2014 county data to CSV 
write.csv(blm_2014, "data/BLM_counts_2014.csv", row.names=FALSE)
# Write 2020 county data to CSV 
write.csv(blm_2020, "data/BLM_counts_2020.csv", row.names=FALSE)
###########################
