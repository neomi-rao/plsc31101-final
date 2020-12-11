# plsc31101-final
## Short Description

This project collects BLM protest data by date and location to create visualizations of BLM protest data and to prepare datasets for future analysis against various location- and date-specific measures. The project involves several coding tasks, including: 

1. Using RSelenium to scrape from a dynamic webpage. 
2. Using Google Maps API to get geolocation data
3. Working with ggplot and maps to create static map visualizations.
4. Working with gganimate to create dynamic map visualizations (GIFs)
5. Using urbanmapr and sf to aggregate location data by US county and produce choropleth maps.

## Dependencies

1. R, 4.0.2
2. Firefox, 83.0
3. Package - RSelenium
4. Package - wdman
5. Package - tidyverse
6. Package - rvest
7. Package - lubridate
8. Package - stringr
9. Package - ggmap
10. Package - purrr
11. Package - maptools
12. Package - maps
13. Package - sf
14. Package - ggplot2
15. Package - ggthemes
16. Package - gganimate
17. Package - gifski
18. Package - glue
19. Package - plotly
20. Package - urbnmapr

## Files

All files (other than `README.md` and `Final-Project.RProj`) contained in the repo, along with a brief description of each one:

#### /

1. Narrative.Rmd: Provides a narrative of the project, main challenges, solutions, and results.
2. Narrative.pdf: A 7 page knitted pdf of Narrative.Rmd. 
3. Slides-BLM.pptx: Lightning talk slides, in Powerpoint format.

#### Code/
1. Scraping.R: Collects BLM protest data from Elephrame via Selenium and RVest, exports data to the file BLM_data.csv
2. Geolocation.R: Takes Elephrame raw data and runs it through Google Map's API to get geolocation data which is exported to the file BLM_data_longlat.csv.
3. Preprocessing.R: Takes geolocation data and performs various cleaning and additional processing. Exports several datasets to files: BLM_data_weeks.csv; BLM_data_USA.csv; BLM_data_county.csv; BLM_counts_2014.csv; BLM_counts_2020.csv

#### Data/

1. BLM_data.csv: Raw data scraped from Elephrame's BLM protest data, available here: https://elephrame.com/textbook/BLM/chart
2. BLM_data_longlat.csv: Adds geolocation data (long/lat) matched to the raw BLM protest data.
3. BLM_data_weeks.csv: Adds a column for *year* & *weekof* which aggregates dates by week.
4. BLM_data_USA.csv: A filtered dataset for US-only protest events.
5. BLM_data_county.csv: Merges dataset with county locations, to add more columns, including:
    - *lon*: Longitude coordinate
    - *lat*: Latitude coordinate
    - *location*: Raw location from scraped data
    - *address*: Google Map address based on location
    - *date*: Raw date from scraped data
    - *weekof*: Aggregates dates by week
    - *year*: Year of protest date
    - *county_fips*: Unique FIPS code for US county
    - *state_abbv*: 2 character US state abbreviation
    - *state_fips*: Unique FIPS code for US state
    - *county_name*: Name of the county
    - *fips_class*: A classification of US counties
    - *state_name*: Name of the state
6. BLM_counts_2014.csv: Counts of BLM protest events by US county in 2014. 
7. BLM_counts_2020.csv: Counts of BLM protest events by US county in 2020.

#### Results/

1. BLMmap_world.gif: Animated visualization of BLM protest events around the world from 2014-2020.
2. BLMmap_usa.txt: Animated visualization of BLM protest events in the US from 2014-2020.
3. BLM_Map_County_2014.pdf: Choropleth map of BLM protest counts by US county in 2014.
4. BLM_Map_County_2020.pdf: Choropleth map of BLM protest counts by US county in 2020.

## More Information

* Selenium can be a little sticky at times and I had to page through the Javascript table a few extra times, which resulted in duplicate data. This was likely because of a slow internet connection. 
* You have to sign up for the Google Maps API with payment information, but you are only charged if you exceed $200 worth of usage in a month. 
* For some reason, the mutate_geocode() command for the Google Maps API doesn't always return location data for all observations, so it may need to be re-run on rows which initially return NA values.
* The week() function from lubridate doesn't work for 12/31 dates of some years. These dates have to be manually aggregated to the correct week of the year. 
* Urbnmapr is very handy for providing county and state spatial data as well as mapping tools, but it insets AK & HI in its spatial maps, so these states' spatial locations no longer match up with lat/long. I had to do additional manual adjustments to get spatial data for the observations in AK & HI.
