"""Helper functions which are generally useful in all parts of Estimates Automation."""

###########
# Imports #
###########

import textwrap

import pandas as pd

#############
# Functions #
#############

def _file_path(components):
    """Return the file path (NO EXTENSION) for saving/loading."""
    return f"QA_{'_'.join(components)}."

def save(dfs, save_folder, *args):
    """Save the input dataframe(s) according to the other inputs.
    
    All files will be saved using the format f"QA_{args[0]}_{args[1]}_{args[2]}_etc.???", where the
    file extension (???) depends on if a pd.DataFrame was input (csv) or a dictionary of 
    pd.DataFrame was input (xlsx). In case the requested save folder does not exist, the function 
    will create the folder and any necessary parent folders. 
    
    In the case of general estimates tables, *args should contain vintage, geography level, and
    table name in that order. Estimates tables should be saved in the folder 
    f"{base_folder}/raw_data/".

    In the case of CA DOF tables, *args should contain DOF and geography level, in that order. DOF
    files should be saved in the folder f"{base_folder}/CA_DOF/".

    In the case of diff tables, *args should contain vintage, geography level, and table name
    in that order. vintage should contain both vintages (ex. "2021_01-2020_06") and {table} should 
    contain the word "diff" (ex. "age_sex_ethnicity_diff"). Diff files should be saved in the 
    folder f"{base_folder}/diff/".

    In the case of check outputs, *args should contain the check number, vintage, geography level,
    and table name in that order. Things may change depending on the specific outputs of the check.
    Check outputs should be saved in the folder "f{base_folder}/outputs/".

    In the case of any other files you want to save, *args should contain the parts of the file name
    in order of most general to most specific. For example, each vintage has multiple different 
    possible geography levels, so vintage should come before geography level in *args

    Args:
        dfs (pd.DataFrame or dict of pd.DataFrame): The table(s) to save. If one df is input,
            then it will be saved as a csv file. If a dict of table(s) is input, then it will
            be saved as an xlsx file, with each key of the dict being a sheet name, and the value
            of the dict being the sheet. Note that since Python 3.6, dictionaries maintain insertion
            order
        save_folder (pathlib.Path): The folder to save data into. See the function description for
            recommended values
        *args (list of str): The defining characteristics of the file name. In general, *args 
            should contain the parts of the file name in order of most general to most specific.

    Returns:
        None

    Raises:
        TypeError: If dfs is not either pd.DataFrame or a dictionary of pd.DataFrame
    """
    # Make sure the save folder exists
    if(not save_folder.is_dir()):
         save_folder.mkdir(parents=True)

    # The general format for all files
    file_name = _file_path(args)

    # If a pd.DataFrame is input, then save as csv
    if(isinstance(dfs, pd.DataFrame)):
        file_name += "csv"
        dfs.to_csv(save_folder / file_name, index=False)

    # If a List of pd.DataFrame is input, then save as xlsx
    elif(isinstance(dfs, dict)):
        file_name += "xlsx"
        with pd.ExcelWriter(save_folder / file_name) as writer:
            for name, table in dfs.items():
                table.to_excel(writer, sheet_name=name, index=False)
    
    # Raise an error if dfs is an unknown type
    else:
        raise TypeError("dfs must be pd.DataFrame or dict of pd.DataFrame")

def load(load_folder, *args):
    """Get the input dataframe(s) according to the other inputs.
    
    See the save function for additional information

    Args:
        load_folder (pathlib.Path): The folder to load data from. See the description for the save 
            function for recommended values
        *args (list of str): The defining characteristics of the file name. In general, *args 
            should contain the parts of the file name in order of most general to most specific.

    Returns:
        dfs (pd.DataFrame or Dict of pd.DataFrame): The table(s) found. The input values should
            uniquely identify one file. If the file is a .csv, then pd.DataFrame will be returned.
            If the file is a .xlsx, then a Dict of pd.DataFrame will be returned.

    Raises:
        FileNotFoundError: No files found or too many files found. When too many files are found,
            this is usually because two files have the same name but different extension.
        IOError: The uniquely identified file has an unknown file extension. Supported file 
            extensions are ".csv" and ".xlsx".
    """
    # Find the file(s) in load_folder which are identified by *args
    files = list(load_folder.glob(f"{_file_path(args)}*"))
    if(len(files) == 0):
        raise FileNotFoundError(textwrap.dedent(f"""\
            No files found for the glob string \"{_file_path(args)}*\" in the folder {load_folder}"""))
    if(len(files) > 1):
        raise FileNotFoundError(textwrap.dedent(f"""\
            Too many files found for the glob string \"{_file_path(args)}*\" in the folder {load_folder}"""))
    file_name = files[0]
    
    # If a csv file was found, then load it
    if(file_name.suffix == ".csv"):
        return pd.read_csv(file_name)

    # If an xlsx file was found, then load it
    elif(file_name.suffix == ".xlsx"):
        return pd.read_excel(file_name, sheet_name=None)
    
    # Raise an error if dfs has an unknown file extension
    else:
        raise FileNotFoundError(f"{file_name} has an unknown file extension")
