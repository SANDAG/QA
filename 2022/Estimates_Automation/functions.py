"""Helper functions which are generally useful in all parts of Estimates Automation."""

###########
# Imports #
###########

import pandas as pd

#############
# Functions #
#############

def save(dfs, base_folder, vintage, geo, table):
    """Save the input dataframe(s) according to the other inputs.
    
    In general, all files should be saved using the format f"QA_{vintage}_{geo}_{table}.csv". In 
    diff files, {vintage} should contain both vintages (ex. "2021_01-2020_06") and {table} should 
    contain the word "diff" (ex. "age_sex_ethnicity_diff"). For all other files, the file name 
    should be organized with most general category coming first (this should always be "QA") to 
    most specific category coming last.

    This function will create the directory if it is not yet created

    Raw data should be saved in the folder f"{base_folder}/raw_data/".

    DOF data should be saved in the folder f"{base_folder}/DOF/".

    Diff files should be saved in the folder f"{base_folder}/diff/".

    Args:
        dfs (pd.DataFrame or dict of pd.DataFrame): The table(s) to save. If one df is input,
            then it will be saved as a csv file. If a dict of table(s) is input, then it will
            be saved as an xlsx file, with each key of the dict being a sheet name, and the value
            of the dict being the sheet. Note that since Python 3.6, dictionaries maintain insertion
            order
        base_folder (pathlib.Path): The folder to save data into. See the function description for
            acceptable values
        vintage (str): The vintage of the data.
        geo (str): The geography level of the data.
        table (str): The name of the table. This will typically be the name of an estimates table 
            such as "population" or "ethnicity"

    Returns:
        None

    Raises:
        TypeError: If dfs is not either pd.DataFrame or a dictionary of pd.DataFrame
    """
    # Make sure the save file exists
    if(not base_folder.is_dir()):
         base_folder.mkdir(parents=True)

    # The general format for all files
    file_name = f"QA_{vintage}_{geo}_{table}."

    # If a pd.DataFrame is input, then save as csv
    if(isinstance(dfs, pd.DataFrame)):
        file_name += "csv"
        dfs.to_csv(base_folder / file_name, index=False)

    # If a List of pd.DataFrame is input, then save as xlsx
    elif(isinstance(dfs, dict)):
        file_name += "xlsx"
        with pd.ExcelWriter(base_folder / file_name) as writer:
            for name, table in dfs.items():
                table.to_excel(writer, sheet_name=name, index=False)
    
    # Raise an error if dfs is an unknown type
    else:
        raise TypeError("dfs must be pd.DataFrame or dict")

def load(base_folder, vintage, geo, table, extension):
    """Get the input dataframe(s) according to the other inputs.
    
    See the save function for information on the file structure

    Args:
        base_folder (pathlib.Path): The folder to save data into. See the function description for 
            save for acceptable values
        vintage (str): The vintage of the data.
        geo (str): The geography level of the data.
        table (str): The name of the table. This will typically be the name of an estimates table 
            such as "population" or "ethnicity"
        extension (str): The extension of the file. Typically "csv", very rarely "xlsx"

    Returns:
        dfs (pd.DataFrame or Dict of pd.DataFrame): The table(s) found. The input values should
            uniquely identify one file. If the file is a .csv, then pd.DataFrame will be returned.
            If the file is a .xlsx, then a Dict of pd.DataFrame will be returned.

    Raises:
        IOError: The uniquely identified file has an unknown file extension
    """
    # Get all the files in the provided folder
    file = base_folder / f"QA_{vintage}_{geo}_{table}.{extension}"

    # If a csv file was found, then load it
    if(extension == "csv"):
        return pd.read_csv(file)

    # If an xlsx file was found, then load it
    elif(extension == "xlsx"):
        return pd.read_excel(file, sheet_name=None)
    
    # Raise an error if dfs has an unknown file extension
    else:
        raise FileNotFoundError(f"{file} has an unknown file extension")
