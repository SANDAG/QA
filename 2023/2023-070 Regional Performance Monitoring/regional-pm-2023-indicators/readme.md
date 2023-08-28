# Regional Performance Monitoring 2023
This repository contains documentation and code for the 2023 update to Regional Performance Monitoring data.

## Motivation
[Appendix-E](https://sandag.sharepoint.com/:b:/r/sites/ResearchandProgramManagementRPM/Shared%20Documents/Performance%20Monitoring/Regional%20Performance%20Monitoring/2023/appendix-e---performance-monitoring.pdf?csf=1&web=1&e=spz1eA) of the 2021 Regional Plan promises that data for a list of performance monitoring (PM) indicators would be released before the next 2025 Regional Plan. Similar reports have been produced by SANDAG in the past, [the last one was in 2018](https://sandag.sharepoint.com/:b:/r/sites/ResearchandProgramManagementRPM/Shared%20Documents/Performance%20Monitoring/Regional%20Performance%20Monitoring/2023/FINAL%202018%20Regional%20Monitoring%20Report.pdf?csf=1&web=1&e=9W5BAx). Several new indicators were added in the appendix, while several historical indicators were removed.

### Changes to Appendix
Note that the following changes were made to what we'd expect from the appendix.
* Energy and Water: Impaired waterbodies
  * It makes more sense for this to be under Healthy Environment, as it's a measure of polluted open bodies of water and not regarding the water supply.
* Transit ridership
  * This is usually equivalent to boardings.
Open data was never published alongside the reports. The data itself is archived with inconsistent formatting and documentation. And the current Applied Research Division wants to improve on the format and data visualizations used in prior reporting. This repository tries to solve these three issues for the next report, and be a general first step at improving how performance monitoring data is handled at SANDAG.

## Structure
* `./src/`: contains common code used between indicators.
* `./notebooks/`: one exists for each indicator and should contain the bulk of it's documentation and update procedure.
* `./scripts/`: code meant to be ran as individual scripts.
* `config.toml`: the code and notebooks expect a toml file with the following schema:

```
acs_api_key = '33e09cdb67ea2efa8fabcfd616fb697c2ad2483a'

[paths]
# Path to legacy Performance Monitoring XLSX workbook.
legacy_xlsx = 'C:\Users\tan\src\regional-pm-2023\data\raw\abc.xlsx'
# Path to main Indicator config workbook.
indicators_xlsx = 'C:\Users\tan\src\regional-pm-2023\data\config\Indicators.xlsx'
# Directory where raw data gets staged.
raw_dir = 'C:\Users\tan\src\regional-pm-2023\data\raw'
# Directory where cleaned data gets saved.
clean_dir = 'C:\Users\tan\src\regional-pm-2023\data\clean'
```

* `{config_dir}/Indicators.xlsx`: Workbook with the following sheets:
  * `[categories]`: general categories for indicators.
  * `[topics]`: general topics for indicators.
  * `[indicators]`: indicators (each one should map to a separate output table).
  * `[columns]`: columns in indicators (contains names and metadata for documentation/eventual use in ODP).
  * `[sources]`: data sources for indicators.
  * `[updates]`: information on new udpates made from the legacy PM workbook.
  * `[remarks]`: additional comments that can get added to an indicator's sheet.

## Data 
The sections below are only brief summaries on the data used in this project. Individual data sources are reported in the `Indicators.xlsx` files and shown in each workbook.

### Legacy
This project is a step in migrating away from the [legacy PM SharePoint site](https://sandag.sharepoint.com/:f:/r/sites/ResearchandProgramManagementRPM/Shared%20Documents/Performance%20Monitoring/Regional%20Performance%20Monitoring?csf=1&web=1&e=tlRBeM) and the [legacy PM workbook](https://sandag.sharepoint.com/:x:/r/sites/ResearchandProgramManagementRPM/Shared%20Documents/Performance%20Monitoring/Regional%20Performance%20Monitoring/2023/Performance%20Monitoring%20Tables%20and%20Charts-2023.xlsx?d=wda01bb6a2b6a47bea786af8df5bdca19&csf=1&web=1&e=tbD9Ef).

### Sources
The type of data sources vary between different indicators. These are the main genres:
* Data with processes that can be fully automated with public web APIs.
* Data with processes that can be partially automated (downloads have to be manual).
* Data that currently cannot be automated because our current data sources are inconsistent (PDFs and changing geometry).

### Quality
Data Quality varies between indicator. The current aim is to treat data reported on the historical workbook as correct, unless there was an obvious methodology change and data was availible in order to recalculate it.

### Governance
Governance varies between indicators. We have had some communication with other teams at SANDAG with overlapping data needs. Some of these indicators use data that several teams prepare in parallel. These eventually should be moved into a single place and maintained by one of the teams.

