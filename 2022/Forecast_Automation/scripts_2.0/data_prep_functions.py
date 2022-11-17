import numpy as np
import pandas as pd
import yaml

# -------------------------- Class: Configuration functions

# Download and concatonate files from T drive


def download_and_concat_Tdrive_files(dsid):
    """Downloads all of the files from T drive for this particular dsid and adds the year"""

    with open('ds_config_2.yml', "r") as yml_file:
        config = yaml.safe_load(yml_file)

    concatonated_dfs = pd.DataFrame()

    for key, path in config[dsid]['T_Drive_files'].items():
        temp_df = pd.read_csv(path)
        temp_df['year'] = key[-4:]
        concatonated_dfs = pd.concat([concatonated_dfs, temp_df])

    return concatonated_dfs

# mgra_vacancy_additions

# mgra_school_pop_additions

# mgra_age_pop_additions

# mgra_ethn_pop_additions

# mgra_sex_pop_additions

# Make adjustments to specific, specified columns that need it - should work at all levels

# Find columns that we want at particular geography levels


def wanted_geography_cols(df, wanted_geo_level):
    """Returns a list of columns that do not include unwanted geography levels."""
    geography_levels = ['mgra', 'cpa', 'jurisdiction', 'luz_id', 'taz']
    geography_levels.remove(wanted_geo_level)

    return [col for col in df.columns if col not in geography_levels]

# Roll up to CPA - adjustments will be needed

# Roll up to Jurisdiction - adjustments will be needed

# Roll up to Region - adjustments will be needed

# Potentially doing LUZ and TAZ as well?

# -------------------- Class Manipulation Functions:

# Download the data function

# DF Comparison Function - checking shape and columns and such, returns similar columns

# Check to see if the desired output exists

# Both functions - will house both of the above functions

# Diff Functions --- will use the first two functions

# ---------------------- Class Other Outpus

# Household file path grab

# Number of persons (from households) at MGRA level.

# Combine with the mgra file (will need other files created) - create the diff and output to J drive

# Number of households (from households) at MGRA level 

# Combine with the MGRA file

# ------------------------ Class QC Checks

# Check to see which aggregate files still need to be created (return a list), comparison with what we have in our config file

# Could also check which diff files also need to be created


# TODO: Update config file to have persons and household datasets


'''
ideas:
- Could have that SQL connection setup in a yml file, have a seperate yml file for more input related things 
- for functions that take in a dataframe (like the Qc ones, I could have a function that checks in the index has been grouped or not, or have it go in as an argument) - The argument will be asking if the index has been set or not
- if forecast series ID is 14 then don't add anything from SQL or do any rollups, only mgra and region 
- I still want a complete data dictionary that I can use 
- Ideally would like to just be able to runthis script and it populates all the aggregated parts, it will check the config file to see if there is some that still need to be done

'''
