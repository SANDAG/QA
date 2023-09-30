# Forecast QC Automation

This repository contains essential notebooks and files for automating the quality control process of forecasting. The project emphasizes the proper configuration of paths and the utilization of functional modules to streamline the forecast quality check.

## Project Structure

### Configuration

- **`ds_config_2.yaml`**:
  - This YAML configuration file dictates the paths to individual forecast files located on the T drive.
  - It categorizes data based on DS IDs and further breaks down each DS ID into sections for T drive files, household files, person files, and their associated forecast IDs.
  - The structure and manipulation of these configurations can be understood in depth within this file.

### Python Scripts and Notebooks

- **`data_prep_functions.py`**:

  - A comprehensive Python script containing all core functions essential for data preparation and generation of desired outputs.
  - The functions are grouped into distinct sections, providing clarity on their purposes and functionality.

- **`data_prep_user_notebook.ipynb`**:

  - An interactive Jupyter notebook designed to facilitate users in employing functions from the `data_prep_functions.py` script.
  - The structured markdown and layout ensure users can efficiently generate the required outputs.

- **`data_QC_functions.py`**:
  - A dedicated python file that differs from the `data_prep_functions` as it emphasizes QC tests.
  - While the `data_prep_functions` file deals primarily with data preparation, this notebook focuses on the quality control tests.

## Getting Started

1. Ensure all paths in the `ds_config_w.yaml` are correctly configured to match the forecast file locations.
2. Familiarize yourself with the functions in the `data_prep_functions.py` script.
3. Launch the `data_prep_user_notebook.ipynb` to start using the system and generating outputs.

## Future Iterations

Consult the `TODO.txt` file in the repository for insights into future developments and potential enhancements. One significant forthcoming addition is the roll-up function for different Sandbag geographies.

---
