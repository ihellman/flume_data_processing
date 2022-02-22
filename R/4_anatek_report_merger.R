# Ian Hellman
# 2022-02-14
#
# Import Anatek's Excel-based reports to single file.

library(tidyverse)
library(here)
library(readxl)

# Set where this script is located.
here::i_am("R/4_anatek_report_merger.R")

# Read in file names of all reports in the data folder.
files <- list.files(here("data"), full.names = TRUE) 
files <- set_names(files, nm = basename(tools::file_path_sans_ext(files)))

# Import all report data to a single dataframe.
df <- map_dfr(.x = files, read_excel, col_types = "text", .id = "origFileName" ) 

# Clean the imported data
dfCleaned <- df %>%
  select(origFileName, SampleNumber, Test, Method, Units, Result, DetectionLimit, CustomerSampleNumber) %>%
  mutate(basin = substr(CustomerSampleNumber, start = 1, stop = 2)) %>%
  relocate(CustomerSampleNumber, Result)

# Export cleaned data.
write_csv(dfCleaned, here("results/anataek_out.csv"))