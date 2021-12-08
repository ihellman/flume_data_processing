# Import and prepare raw SedEvent Data.
# Ian Hellman 2021-Dec-7
#
# This script expects a data folder containing raw site visit folders.  It then
# selects only data files (not config, etc), imports them, and cleans them up a bit.
# Finally, it expors a csv per basin.


library(tidyverse)
library(lubridate)
library(here)

# Set relative location of this file
here::i_am("scripts/1_clean_raw_data.R")

# Location of raw H2 download folders
fileLocation <- here("input_data")

### Provide dates to filter by.  
StartDate <- "2020-10-01 00:00:00"
EndDate <- "2021-09-30 23:45:00"

# Lookup table to convert the datalogger's name to 2 letter abbreviation
lut <- c("BLUEGROUSE_N" = "bn",
         "BLUEGROUSE_S" = "bs",
         "COXIT_E"      = "ce",
         "COXIT_W"      = "cw",
         "FISH_E"       = "fe",
         "FISH_W"       = "fw",
         "SPRINGDALE_N" = "sn",
         "SPRINGDALE_S" = "ss",
         "TRIPPSKNOB_E" = "te",
         "TRIPPSKNOB_W" = "tw"
)

# Get all datafiles.  Looks for csv files then removes config files and zero-byte files.  
dataFiles <- list.files(here("input_data"), recursive = TRUE, pattern = "*.csv", full.names = TRUE) %>%
  str_subset(pattern = "Config", negate = TRUE) %>% 
  .[file.size(.) > 0]

# Function to import raw csv files and give proper column names.  
importSedEvent <- function(fileName) {
  # Extract headers.  Maybe hacky but gets around needing to ignore rows 1 and 3 
  headers <- read.delim(fileName, ",", header = FALSE, skip = 1, nrows = 1, as.is = T)
  
  # Bring in the data and assign headers
  df <- read.delim(fileName, ",", header = FALSE, skip = 3)
  colnames(df) <- headers
  basinName <- str_split(basename(fileName), pattern = "-") %>% pluck(1,1) %>%
    str_replace_all(lut)
  
  # Springdale South had some strange issue with duplicate columns.  This takes care of that.  
  df <- df[,!duplicated(names(df))]
  
  # Adding extra metadata columns and filtering based on start and end dates.
  df <- df %>% mutate(file_name = fileName,
                      basin = basinName,
                      DateTimePST = ymd_hms(DateTime) - hours(8),
                      DateTimePST = as.character(DateTimePST)) %>%
    filter(DateTimePST >= StartDate & DateTimePST <= EndDate)
  
  # Replace FTS "nodata" values with NA
  df[df == -99999 | df == -9999999] <- NA
  
  return(df)
} #end importSedEvent function

# Pulls all files from a basin into single dataframe
datMerged <- purrr::map_dfr(dataFiles, importSedEvent)

# Remote duplicate rows, add extra columns for QAQC, and organize columns
datDistinct <- datMerged %>%
  distinct(across(-'file_name'), .keep_all = TRUE) %>% # across and keep_all prevent file_name column from being removed.
  mutate(SampleID_UI = "",
         SampleID_Anatek = "",
         SSC_mgL = "",
         QA_SSC = "",
         QA_Stage = "",
         QA_WTmn = "") %>%
  select(DateTimePST, Stage,
         YI, VB,
         WT, WTmn,
         WTmx, WTvr,
         TW, LSU,
         TS_slot, TS_smp_code,
         TS_thr_code, Stg_Qual,
         basin, SampleID_UI,
         SampleID_Anatek, SSC_mgL,
         QA_SSC, QA_Stage,
         QA_WTmn)  

# Export a CSV per basin.
purrr::walk(unique(datDistinct$basin), 
            ~ filter(.data = datDistinct, basin == .x) %>% 
              write.csv(paste(here("cleaned_data/"), .x, "_WY-", year(EndDate),".csv", sep = ""), row.names = FALSE, na = ""))

