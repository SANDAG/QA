# Eric Liu
# 
# TODO
#
# Last Updated: 8/12/2022

import pathlib
import textwrap
import pandas as pd
import sqlalchemy as sql

def get_data(folder, filter) -> pd.DataFrame:
    """Finds the best match file in the input folder and returns it as a DataFrame
    
    Args:
        folder (pathlib.Path): The folder in which to search for data. Uses pathlib.Path for 
            platform independent behavoir.
        filter (str): Used to identify *ONE* file in the folder. 
        
    Returns:
        pd.DataFrame: The found file as a df

    Raises:
        FileNotFoundError: When either too many files were found or no files were found
    """
    # Get all the files in the provided folder
    files_found = list(folder.iterdir())

    # Filter the files 
    filtered_file = [file for file in files_found if filter in file.name]

    # Check that the input filter was fine enough
    if(len(filtered_file) > 1):
        raise FileNotFoundError("Too many files found")
    # Check that the input filter was not too fine
    if(len(filtered_file) == 0):
        raise FileNotFoundError("No files found")

    # Load the file into a df and return it
    # TODO: Read other file formats?
    return pd.read_csv(filtered_file[0])

def get_data_with_aggregation_levels(folder, 
    geo_list=["mgra", "luz"]) -> dict:
    """Get data and combine with the proper columns of mgra_denormalize for aggregation
    
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
    """
    # Where to pull dimension tables from
    DDAM = sql.create_engine('mssql+pymssql://DDAMWSQL16')

    # Some configuation to help this function know how to search for the correct files
    # Note, even though there is no larger geography level than "region", we still pull the file
    # so we can compare
    file_search = {"mgra": "_mgra_", "jurisdiction": "_jur_", "region": "_region_", "luz": "_luz_"}

    # And some more configuration to know how to combine with dim tables and later on aggregate
    # to compare totals between geography levels. So "mgra" would be aggregated to "jurisdiction" 
    # and "region", while "jurisdiction" would only be aggregated to "region"
    # TODO: There is likely a better way to format this, where the function could recursively look
    # through the dictionary to derive how aggregation should be done, but that for a later date
    dim_table_columns = {
        "mgra": ["region"],
        "luz": ["region"]
    }

    # Store tables at each geography level here
    geo_level_tables = {}

    # Get the region level table, since we always want that
    geo_level_tables["region"] = get_data(folder, file_search["region"])
    geo_level_tables["region"]["region"] = "San Diego"

    # Do this for every geography level requested (typically only "mgra" and "jurisdiction", but 
    # could be extended to include "taz", "cpa", etc.).
    # BUG: If additional geography levels are requested, the variables file_search and 
    # dim_table_columns would need to updated
    for geo in geo_list:
        # Get the table
        geo_level_tables[geo] = get_data(folder, file_search[geo])

        # # Combine with the correct columns of the dim table
        # agg_cols = ", ".join(dim_table_columns[geo])
        # # BUG: query needs "WHERE series=?"
        # # BUG: series=15 IS NOT IN mgra_denormalize yet
        # query = textwrap.dedent(f"""\
        #     SELECT {geo}, {agg_cols}
        #     FROM [demographic_warehouse].[dim].[mgra_denormalize]
        #     """)
        # dim_table = pd.read_sql_query(query, con=DDAM)

        # Due to the above bug, MGRA15 data will be pulled from [sql2014b8].[GeoDepot].[gis].[MGRA15]
        # instead
        query = textwrap.dedent(f"""\
            SELECT [MGRA], [Name], [LUZ]
            FROM [GeoDepot].[gis].[MGRA15] as MGRA15
            LEFT JOIN [GeoDepot].[gis].[CITIES] as cities ON
                MGRA15.City = cities.City
            """)
        SQL2014B8 = sql.create_engine("mssql+pymssql://sql2014b8")
        dim_table = pd.read_sql_query(query, con=SQL2014B8)
        dim_table = dim_table.rename({"MGRA": "mgra", "Name": "jurisdiction", "LUZ": "luz"}, axis=1)
        dim_table["region"] = "San Diego"
        dim_table = dim_table[[geo] + dim_table_columns[geo]].drop_duplicates(ignore_index=True)

        # The luz file has geography as luz_id, and not luz. Change to keep our merge the same
        if(geo == "luz"):
            geo_level_tables[geo] = geo_level_tables[geo].rename({"luz_id": "luz"}, axis=1)

        geo_level_tables[geo] = pd.merge(geo_level_tables[geo], dim_table, 
            how="left", on=geo)

    return geo_level_tables

def check_geography_aggregations(df_dict, geo_list=["mgra", "luz"]) -> None:
    """Take the outputs of get_data_with_aggregation_levels and check that values match up
    
    Args:
        df_dict (dict of pandas.DataFrame): TODO
        geo_list (list): TODO
        
    Returns:
        None, but prints out differences if present
    """
    # Yes this is copy pasted from the previous funciton, and yes it is awlful code design, but I am
    # currently too lazy to do this correctly
    dim_table_columns = {
        "mgra": ["region"],
        "luz": ["region"]
    }
    
    # Basically, we want to check for the input geography levels each aggregation
    for geo, agg_cols in dim_table_columns.items():
        for agg_col in agg_cols:
            # Let the user know what we are aggregating to/from and what we are comparing to
            print(f"Aggregating {geo} level data to {agg_col} and comparing with {agg_col} csv file")

            # Aggregate the geo_level table to the geography level in agg_col
            # BUG: Not all variables should be aggregated with a simple sum, some of them (like 
            # household size) are averages.
            aggregated = df_dict[geo].groupby(agg_col).sum().reset_index()

            # The hacky fix to the above bug
            # Note, hhs = household size = total population / number of households = pop / hh
            aggregated["hhs"] = aggregated["hhp"] / aggregated["hh"]
            aggregated["vacancy_rate"] = 100 \
                * (aggregated["vacancy"] - aggregated["unoccupiable"]) \
                / aggregated["units"]

            # Now that things are aggregated, check the aggregated files with the non-aggregated
            # geography level file
            # Note, becuase my checks are limited to only a few columns, select them here
            # hs = housing structures, hh = total number of households, hhs = household size,
            # vacant = number of vacant units, vacancy_rate = not actually a rate, but the 
            # percentage
            columns_of_interest = [agg_col, "hs", "hh", "hhs", "vacancy", "vacancy_rate", "hhp"]

            # Also, we want to check employment values
            columns_of_interest += [emp_cat for emp_cat in aggregated if "emp_" in emp_cat]

            # print(aggregated, df_dict[agg_col])

            # Check the values match up
            check_results = aggregated[columns_of_interest] == df_dict[agg_col][columns_of_interest]
            pd.set_option('display.max_colwidth', None)
            pd.set_option("display.max_columns", None)
            if(check_results.to_numpy().sum() != check_results.shape[0] * check_results.shape[1]):
                print(aggregated[columns_of_interest])
                print(df_dict[agg_col][columns_of_interest])
                print(check_results)
            else:
                print("No errors")

            print()

if(__name__ == "__main__"):
    
    user = "eli"
    base_folder = pathlib.Path(f"C:/Users/{user}/San Diego Association of Governments/SANDAG QA QC - Documents/Projects/2022/2022-58 2019 Base Year Forecast Output QC/data/MGRA15 Data/")

    df_dict = get_data_with_aggregation_levels(base_folder)
    check_geography_aggregations(df_dict)
