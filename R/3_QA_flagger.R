# Ian Hellman
# 2022-Feb-18
#
# This script takes the start and end date of QA flags set in the QA spreadsheet and 
# adds the flags to the actual data.  

library(tidyverse)
library(lubridate)
library(here)
library(readxl)

# Find and load data ---------------------------------------------------------------------------------------
here::i_am("R/3_QA_flagger.R")

# path to csv files
fileLoc <- here("cleaned_data")

# get list of files
files <- list.files(fileLoc, full.names = TRUE, pattern = "*.csv")

# name each of the files.  used to create ID in map function.
files <- set_names(files, 
                   tools::file_path_sans_ext(files) %>%
                     basename() %>%
                     str_split(pattern = "-|_") %>%
                     map(1) %>%
                     unlist()
)

# Read in all h2 data into single data frame
h2dat <- map_dfr(files, read_csv, col_types = cols(.default = col_character()), .id = "basin") %>%
  mutate(DateTimePST = ymd_hms(DateTimePST))

# Read in QA data 
QAdata <- read_excel("~/Documents/enrep_workspace/SedEvent/WY_2021_IN_PROGRESS/metadata/SedEvent_QA_WY2021.xlsx", 
                     sheet = "QAQC",
                     col_types = c("text", "text", "numeric", "text", "text", "text", "date", "date", "text"),
                     trim_ws = TRUE)

# Basin Abbreviations for filtering.  
basinNames <- unique(QAdata$Basin)

# Function for processing  ----------------------------------------------------------------------------------

qaFlagger <- function(basinAbbrev){
  #print(basinAbbrev)
  
  # Filter data sets based on the basin name abbreviation.
  basin.h2dat <- h2dat %>% filter(basin == basinAbbrev)
  basin.QAdata <- QAdata %>% filter(Basin == basinAbbrev)
  
  # Loop through rows in QA form.  Each row has start and end datetime for a flag.    
  for (i in seq(1, nrow(basin.QAdata), 1)){
    
    if (basin.QAdata$QA2_Start[i] > basin.QAdata$QA2_End[i]){
      #print(paste("Start time is after end time on row ", i, "." ,sep = ""))
      #print(paste("Start time is after end time in the following row.  Fix and re-run.")
      
      warning("Start time is after end time in the displayed row.  Fix and re-run.")
      print(basin.QAdata[i,])
    } else {
      if (is.na(basin.QAdata$QA2_Stage[i]) & !is.na(basin.QAdata$QA2_WTmn[i])){
        dateSeq <- seq.POSIXt(basin.QAdata$QA2_Start[i], basin.QAdata$QA2_End[i], by = "15 min")
        basin.h2dat$QA_WTmn[basin.h2dat$DateTimePST %in% dateSeq] <- basin.QAdata$QA2_WTmn[i]
      }
      
      if (is.na(basin.QAdata$QA2_WTmn[i]) & !is.na(basin.QAdata$QA2_Stage[i])){
        dateSeq <- seq.POSIXt(basin.QAdata$QA2_Start[i], basin.QAdata$QA2_End[i], by = "15 min")
        basin.h2dat$QA_Stage[basin.h2dat$DateTimePST %in% dateSeq] <- basin.QAdata$QA2_Stage[i]
      }
    }
  }
  
  # Add last flag for values WTmn > 1600.  Measurement range of DTS-12 is 0-1600 NTU.
  basin.h2dat <- basin.h2dat %>% mutate(QA_WTmn = if_else(as.numeric(WTmn) > 1600, "A", QA_WTmn))
  
  if (!dir.exists(here("cleaned_data", "cleaned_and_flagged"))){
    dir.create(here("cleaned_data", "cleaned_and_flagged"))
  }
  
  write.csv(basin.h2dat, 
            file = paste(here("cleaned_data/cleaned_and_flagged/"), 
                         basinAbbrev, "_WY-", 
                         max(year(basin.h2dat$DateTimePST)),
                         ".csv", 
                         sep = ""),
            row.names = FALSE,
            na = "")
}


# Perform qa function to all basins ---------------------------------------------------------------------------

purrr::walk(basinNames, qaFlagger)
