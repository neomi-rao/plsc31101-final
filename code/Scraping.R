# Load required libraries
library(RSelenium)
library(wdman)
library(tidyverse)
library(rvest)
library(lubridate)
library(stringr)

# Start a selenium server and browser
rD <- rsDriver(browser = "firefox")
remDr <- rD[["client"]]

#remDr$getStatus() #check status (optional)
# remDr$open() #Run if the Firefox browser does not automatically open or navigate

# Navigate to site
remDr$navigate("https://elephrame.com/textbook/BLM/")

# Function to get info from single protest event entry
# code courtesy of Rochelle Terman
get_event <- function(a_event){
  date <- a_event$findChildElements(using = "css selector", value = ".protest-start")[[1]]
  date_text <- date$getElementText()[[1]]
  
  location <- a_event$findChildElements(using = "css selector", value = ".item-protest-location")[[1]]
  location_text <- location$getElementText()[[1]]
  
  all_info <- list(date = date_text,
                   location = location_text)
  
  return(all_info)
}

# Get data from the first page of results. 
# Done separately because CSS selector for next button ('>') is different on page 1. 
#This will be the overall list of data by results page
resultlist = list()

# First, get the data from page 1 because the css selector for '>' is different.
events <- remDr$findElements(using = "css selector", value = ".chart")
resultlist[[1]] <- map(events, get_event)
# Click on '>' to go from page 1 to page 2 because this is unique for page 1.
# find pagination
pages <- remDr$findElements(using = "css selector", value = "#blm-results .inactive")
# we want the first item
pages[[1]]$getElementText()
#click the '>' button 
#(check the Selenium window - this might need to be manually run twice to click through)
pages[[1]]$clickElement()

# Loop through from pages 2:240 with the other '>' CSS selector. 
# When I ran this step, I sometimes needed extra loops and ended up with duplicate scraped data. 
# This may be because of slow connection which was not able to load the next page of results before the scrape command was called again. 
# Tried to fix with lengthening Sys.sleep, but may still require manual adjustment.
i=1
repeat {
  i = i+1
  events <- remDr$findElements(using = "css selector", value = ".chart")
  resultlist[[i]] <- map(events, get_event)
  
  if (i>240) break
  
  # find pagination
  pages <- remDr$findElements(using = "css selector", value = "#blm-results .inactive") 
  # click on the third item
  pages[[3]]$clickElement()
  
  # pause for 4 seconds to allow the page to load
  Sys.sleep(4)
}

# check length of output list
length(resultlist)
# check final output page to make sure it matches the site
resultlist[[-1]]
```
```{r}
# Create a dataframe from the list of lists
blm_df <- resultlist %>% 
  unlist(recursive = F) %>%
  bind_rows()

# Check new dataframe
head(blm_df)

#Initial cleaning
# Remove duplicate rows from the dataframe 
blm_df_distinct <- blm_df %>%
  distinct()

# Write to CSV to have a backup
write.csv(blm_df_distinct, "BLM_data.csv", row.names = F)