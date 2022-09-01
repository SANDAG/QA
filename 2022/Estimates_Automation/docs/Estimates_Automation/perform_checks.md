Module Estimates_Automation.perform_checks
==========================================
TODO: One line description

TODO: Long form description

Classes
-------

`InternalConsistency()`
:   TODO: One line description
    
    TODO: Long form description

    ### Methods

    `get_data(self, folder, filter)`
    :   Finds the best match file in the input folder and returns it as a DataFrame
        
        Args:
            folder (pathlib.Path): The folder in which to search for data. Uses pathlib.Path for 
                platform independent behavoir.
            filter (str): Used to identify *ONE* file in the folder. 
            
        Returns:
            pd.DataFrame: The found file as a df
        
        Raises:
            FileNotFoundError: When either too many files were found or no files were found

    `get_data_with_aggregation_levels(self, folder, geo_list=['mgra', 'luz'])`
    :   Get data and combine with the proper columns of mgra_denormalize for aggregation
        
        Gets region level data by default, and whatever geography levels are present in geo_list. Uses
        [demographic_warehouse].[dim].[mgra_denormalize] and a lookup table (defined in the function, 
        yes I know its bad design) to know which columns to add to each geography level table. For 
        example, the lookup table tells the fuction to add on "jurisdiction" and "region" columns for
        the "mgra" geo_level
        
        Args:
            folder (pathlib.Path): The folder in which data can be found
            geo_list (list): The list of geographies to get data for. Note that region is included by
                default, so do not include it here
        
        Returns:
            dict(pandas.DataFrame): The key is the geography level, and the value is the table

    `check_geography_aggregations(df_dict, geo_list=['mgra', 'luz'])`
    :   Take the outputs of get_data_with_aggregation_levels and check that values match up
        
        Args:
            df_dict (dict of pandas.DataFrame): TODO
            geo_list (list): TODO
            
        Returns:
            None, but prints out differences if present

`NullValues()`
:   TODO: One line description
    
    TODO: Long form description

`VintageComparisons()`
:   TODO: One line description
    
    TODO: Long form description

`ThresholdAnalysis()`
:   TODO: One line description
    
    TODO: Long form description

`DOFPopulation()`
:   TODO: One line description
    
    TODO: Long form description

`DOFProportion()`
:   TODO: One line description
    
    TODO: Long form description