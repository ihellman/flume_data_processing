# Flume Data Processing

This repository contains scripts for combining and organizing raw data to point where it is ready for manual QAQC procedures. Specifically:

1\) 1_clean_raw_data.R - Takes a folder of unsorted H2 data logger files, imports/cleans, exports a csv file for each basin for the respective water year.

2\) 2_flume_QAQC_plots.Rmd - Creates a html file with plots showing stage and turbidity for a defined basin pair.

3\) 3_QA_flagger.R - Takes the date ranges in the QA form and applies the flag to the respective date ranges in the actual data file.

3\) 4_anatek_report_merger.R - Takes Anatek's Excel-based reports and merges them into a single file.
