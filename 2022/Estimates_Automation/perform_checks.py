"""Classes/functions to run various checks on Estimates tables.

The functions in this file run checks on Estimates tables. These functions can only pull data
from saved files. By default, they output only print statements, but there is an option to save a 
table containing rows with errors at some location. For more details, see the individual 
classes/functions.
"""

###########
# Imports #
###########

import pathlib
import textwrap

import pandas as pd
import sqlalchemy as sql

# Local modules
import functions as f

########################################
# Check 1: Internal Consistency Checks #
########################################

class InternalConsistency():
    """Functions to run internal consistency checks.
    
    For the purposes of this class, internal consistency checks mean checking if aggregated values
    match up when aggregating to/from different geography levels. For example, checking if the total
    population variable, when aggregated from mgra --> region, matches up with the values at the 
    region level.

    Attributes:
        geography_aggregation (dict of List): A dictionary with key equals to a geography level, 
            and the value equals to a List containing geographies to aggregate to. For example, for
            the key value of "mgra", the value would contain ["jurisdiction", "region"] because 
            "mgra" aggregates up to both of those geography levels.
    """

    geography_aggregation = {
        "mgra": ["jurisdiction", "region"],
        "jurisdiction": ["region"],
        "luz": ["region"],
    }

    def _get_data_with_aggregation_level(self, folder, vintage, geo, table_name):
        """Get data and combine with the proper columns of mgra_denormalize for aggregation.
        
        Gets region level data by default, and whatever geography levels are present in geo_list. 
        Uses [demographic_warehouse].[dim].[mgra_denormalize] and a lookup table to know which 
        columns to add to each geography level table. For example, the lookup table tells the 
        fuction to add on "jurisdiction" and "region" columns for the "mgra" geo_level.

        Args:
            folder (pathlib.Path): The folder in which data can be found.
            vintage (str): The vintage of Estimates table to pull from. 
            geo (str): The geography level to get data for and add aggregation columns onto
            table_name (str): The name of the Estimates table to get. Because it is assumed that
                the saved tables are created by the file generate_tables.py, this can be any of
                "consolidated" or the name of the Estimates table (such as "age" or "ethnicity")

        Returns:
            pd.DataFrame: The table contains data at the input geography level, with additional 
                geography columns for aggregation. THIS TABLE IS NOT YET AGGREGATED!
        """
        # Where to pull dimension tables from
        DDAM = sql.create_engine('mssql+pymssql://DDAMWSQL16')

        # Do this for every geography level requested (typically only "mgra" and "jurisdiction", but 
        # could be extended to include "taz", "cpa", etc.).
        # BUG: If additional geography levels are requested, the variables file_search and 
        # dim_table_columns would need to updated

        # Get the table
        geo_table = f.load(folder, vintage, geo, table_name, "csv")

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
        # BUG: The below query only selects mgra, jurisdiction, and luz. Additional geography
        # levels may need to be added
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
        dim_table = dim_table[[geo] + self.geography_aggregation[geo]].drop_duplicates(ignore_index=True)

        # The luz file has geography as luz_id, and not luz. Change to keep our merge the same
        if(geo == "luz"):
            geo_table = geo_table.rename({"luz_id": "luz"}, axis=1)

        geo_table = pd.merge(geo_table, dim_table, how="left", on=geo)

        return geo_table

    def check_geography_aggregations(self, folder, vintage, geo_list=["mgra", "luz"]):
        """Take the outputs of get_data_with_aggregation_levels and check that values match up.
        
        Args:
            folder (pathlib.Path): The folder in which data can be found.
            vintage (str): The vintage of Estimates table to pull from. 
            geo_list (list): The list of geographies to aggregate from. Note that region is included 
                by default, so do not include it here.
            
        Returns:
            None, but prints out differences if present.
        """
        # Get the table at each geography level
        geo_tables = {}
        for geo in geo_list:
            geo_tables[geo] = self._get_data_with_aggregation_level(folder, vintage, geo, "consolidated")

        # Check each geography level at the specified aggregation levels
        for agg_col in self.geography_aggregation[geo]:
            # Let the user know what we are aggregating to/from and what we are comparing to
            print(f"Aggregating {geo} level data to {agg_col} and comparing with {agg_col} csv file")

            # Aggregate the geo_level table to the geography level in agg_col. 
            # Note, the geography table is copied before aggregating, because sometimes we want to 
            # aggregate to multiple geography levels and we don't want to modify the original table
            # BUG: Not all variables should be aggregated with a simple sum, some of them (like 
            # household size) are averages.
            aggregated = geo_tables[geo].copy(deep=True).groupby(agg_col).sum().reset_index()

            # The hacky fix to the above bug
            # Note, hhs = household size 
            #           = total population / number of households 
            #           = pop / hh
            # BUG: Why does documentation above use total population (pop) while the code below uses
            # household population (hhp)? Can someone confirm which of these is correct?
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
            check_results = aggregated[columns_of_interest] == geo_tables[agg_col][columns_of_interest]
            pd.set_option('display.max_colwidth', None)
            pd.set_option("display.max_columns", None)

            # Print out error stuff if the number of True values is less than the number of cells.
            # Or in other words, print out error stuff if at least one cell is False
            if(check_results.to_numpy().sum() != check_results.shape[0] * check_results.shape[1]):
                print(aggregated[columns_of_interest])
                print(geo_tables[agg_col][columns_of_interest])
                print(check_results)
            else:
                print("No errors")

            print()

########################
# Check 2: Null Values #
########################

class NullValues():
    """Function to check for any null values.
    
    For the purposes of this function, null value checks mean checking each and every columns
    to see if there are any null values present.
    """

    def spot_nulls(self, folder, table_name, geo):
        """Get data and check for nulls.
        
        Gets region level data by default, and whatever geography levels are present in geo_list. 
        Then checks to see if there are any null values present

        Args:
            folder (pathlib.Path): The folder in which data can be found.
            table_name (str): The name of the Estimates table to get. Because it is assumed that
                the saved tables are created by the file generate_tables.py, this can be any of
                "consolidated" or the name of the Estimates table (such as "age" or "ethnicity")
            geo (str): The geography level to get data for and add aggregation columns onto

        Returns:
            List: the list contains column names that contain null values along with the string "Null values present in the following columns:"
        """
        # Get the table
        geo_table = get_table(folder, table_name, geo)

        # prints and returns columns if it finds any null values
        if (geo_table.isna().sum() > 0).any():
            print('Null values present in the following columns:')
            return geo_table.columns[geo_table.isnull().any()].tolist()

#################################
# Check 3: Vintage Comparisions #
#################################

class VintageComparisons():
    """TODO: One line description.
    
    TODO: Long form description.
    """

    # TODO: Functions to do check 3
    pass

##############################
# Check 4: ThresholdAnalysis #
##############################

class ThresholdAnalysis():
    """Calculates year-on-year% changes and flags if the changes are more than 5%.
    
    For the purposes of this class, threshold analysis checks mean checking if between any two versions,
    the changes in values differ by more than 5%. For example, flagging if total population in certain region 
    changes by more than 5%.
    """

    def yearly_change(self, folder, table_name, geo, col):
        """Get data and check for yearly changes in values.
        
        Gets region level data by default, and whatever geography levels are present in geo_list. 
        Then checks to see if there exists any columns where difference in values is larger than 5%.

        Args:
            folder (pathlib.Path): The folder in which data can be found.
            table_name (str): The name of the Estimates table to get. Because it is assumed that
                the saved tables are created by the file generate_tables.py, this can be any of
                "consolidated" or the name of the Estimates table (such as "age" or "ethnicity")
            geo (str): The geography level to get data for and add aggregation columns onto
            col (str): The column name to choose to check for changes > 5%
            
        Returns:
            List: the list contains years where the yearly changes > 5%
        """
        # Get the table
        geo_table = get_table(folder, table_name, geo)

        # Excluding the geography level column
        df = geo_table.loc[:,~df.columns.isin([geo])]

        # NumPy function calculates the percent change for us
        pop_change = df.groupby('yr_id').sum().pct_change()[[col]]

        # Since we grouped by `yr_id`, returns a list of years where yearly changes in the specified column is more than 5% 
        return pop_change[pop_change[col]>0.05].index.to_list()

###########################
# Check 5: Trend Analysis #
###########################

# N/A, done in PowerBI

############################################
# Check 6: DOF Total Population Comparison #
############################################

class DOFPopulation():
    """TODO: One line description.
    
    TODO: Long form description.
    """

    # TODO: Functions to do check 6
    pass

######################################
# Check 7: DOF Proportion Comparison #
######################################

class DOFProportion():
    """TODO: One line description.
    
    TODO: Long form description.
    """

    # TODO: Functions to do check 7
    pass
