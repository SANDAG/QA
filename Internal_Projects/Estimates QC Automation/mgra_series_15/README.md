## Estimates QC Automation

This project contains Python notebooks that automate the process of quality control for estimates. The core functionality revolves around manipulating census and redistricting data, with functionalities such as building individual estimate tables, diff files, and combo files.

---

### Directory Structure

- **`individual_files_build.ipynb`**: Core notebook containing all necessary functions to create individual estimates tables.
- **`diff_file_build.ipynb`**: Constructs difference files, utilizing outputs from the individual files build.
- **`combo_file_build.ipynb`**: Houses functions to build combo files.
- **`census_redistricting_data.ipynb`**
- **`housing_census_redistricting_data.ipynb`**
- **`population.ipynb`**
- **`SQL_queries/`**: Folder containing all SQL queries used across notebooks.

---

### Getting Started

1. **`individual_files_build.ipynb`**: This is the primary and most crucial notebook. Within it, you'll find all the required functions for creating individual estimate tables, especially various data manipulation functions. Towards the end of the notebook, there's a section labeled `create_output`. Execute this to generate unique tables across different geographical levels. This process then pushes the data to a Jade Rife.

   - **Prerequisite**: Ensure you run this notebook first before any other.

2. **`diff_file_build.ipynb`**: Upon generating outputs with the individual files build, proceed to this notebook. Here, you can produce all the necessary difference files.

3. **`combo_file_build.ipynb`**: This notebook contains all functions required for creating the combo data segments. All data integrated here originates from SQL servers.

---

### Data Sources

All the project's data is sourced from SQL servers. Queries essential to these processes are housed in the `SQL_queries` folder.

---

### Future Improvements

To view potential enhancements or outstanding tasks for this project, check the `todo.txt` file, which offers a comprehensive list of "to-dos" we aim to address in subsequent versions.
