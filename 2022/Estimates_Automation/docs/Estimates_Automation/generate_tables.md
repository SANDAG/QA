Module Estimates_Automation.generate_tables
===========================================
Functions to return/save various Estimates tables.

In a general sense, the functions in this file all create tables directly using Estimates data from
[DDAMWSQL16].[estimates]. The functions in this file do not run any checks, nor do they create any
kind of derived output such as diff files.

Classes
-------

`EstimatesTables()`
:   Functions to return/save various Estimates tables.
    
    In a general sense, the functions in this file all create tables directly using Estimates data 
    from [DDAMWSQL16].[estimates]. The functions in this file do not run any checks, nor do they 
    create any kind of derived output such as diff files.

    ### Methods

    `get_table_by_geography(self, est_vintage, est_table, geo_level, pivot=False, debug=False)`
    :   Get the input estimates table grouped by the input geography level.
        
        This function will return the requested Estimates table from the requested vintage. The relevant
        joins will be made on the base table as specified in the default config file. The returned table
        will by zero indexed and have no multi-columns.
        
        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this
                variable corresponds to YYYY_MM in the table: "[estimates].[est_YYYY_MM]"
            est_table (str): The Estimates table to pull from. In DDAMWSQL16, this variable corresponds
                to XXXX in the table "[estimates].[est_YYYY_MM].[dw_XXXX]"
            geo_level (str): The geography level to aggregate by. This can be any of the columns in the
                DDAMWSQL16 table [demographic_warehouse].[dim].[mgra_denormalize]. For example, you 
                could input "region", "jurisdiction", "mgra", etc.
            pivot (bool): Default False. If True, return the table in wide format instead of tall
            debug (bool): Default False. If True, print out diagnostic print statements during execution
                including the complete SQL query used
        
        Returns:
            pd.DataFrame: The requested Estimates table grouped by the geography level

    `consolidate(self, est_vintage, geo_list=['region', 'jurisdiction', 'cpa'], est_table_list=['age', 'ethnicity', 'household_income', 'households', 'housing', 'population', 'sex'], save=False, save_folder=None)`
    :   Create consolidated files with all Estimates table for each geography level.
        
        This function returns one pd.DataFrame per input geography level, as opposed to combining 
        everything together.
        
        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this 
                variable corresponds to YYYY_MM in the table: "[estimates].[est_YYYY_MM]"
            geo_list (List of str): The geographies to cosolidate along. 
            est_table_list (List of str): Which estimates tables we want to consolidate
            save (bool): False by default. If False, then only return the consolidated tables. If 
                True, then use save_folder to save the consolidated tables and return the tables
            save_folder (pathlib.Path): None by default. If save=True, then the folder to save in as a 
                pathlib.Path object
        
        Returns:
            List of pd.DataFrame: A list containing the consolidated tables in the order of geo_list

    `individual(self, est_vintage, geo_list=['region', 'jurisdiction', 'cpa'], est_table_list=['age', 'ethnicity', 'household_income', 'age_ethnicity', 'age_sex_ethnicity'], save=False, save_folder=None)`
    :   Create individual files for each unique conbination of Estimate table and geography level.
        
        Generate individual estimates tables for each input geography. This function returns one
        dataframe for each geography level / estimate table. Because of the way looping is done, the 
        order of dfs is first geo_level each estimate table, second geo_level each estimate table, etc.
        
        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this 
                variable corresponds to YYYY_MM in the table: "[estimates].[est_YYYY_MM]"
            geo_list (List of str): The geographies to cosolidate along. 
            est_table_list (List of str): Which estimates tables we want to consolidate
            save (bool): False by default. If False, then only return the consolidated tables. If 
                True, then use save_folder to save the consolidated tables and return the tables
            save_folder (pathlib.Path): None by default. If save=True, then the folder to save in as a 
                pathlib.Path object
        
        Returns:
            List of pd.DataFrame: A list containing the individual tables in the order of geo_list and
                est_table_list.

`DiffFiles()`
:   TODO: One line description
    
    TODO: Long form description