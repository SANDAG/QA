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

    _geography_aggregation = {
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
        geo_table = f.load(folder, vintage, geo, table_name)

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
        dim_table = dim_table[[geo] + self._geography_aggregation[geo]].drop_duplicates(ignore_index=True)

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

        # Add on the region level table
        geo_tables["region"] = f.load(folder, vintage, "region", "consolidated")

        # Check each geography level at the specified aggregation levels
        for agg_col in self._geography_aggregation[geo]:
            # Let the user know what we are aggregating to/from and what we are comparing to
            print(f"Aggregating {geo} level data to {agg_col} and comparing with {agg_col} csv file")

            # Aggregate the geo_level table to the geography level in agg_col. 
            # Note, the geography table is copied before aggregating, because sometimes we want to 
            # aggregate to multiple geography levels and we don't want to modify the original table
            # BUG: Not all variables should be aggregated with a simple sum, some of them (like 
            # household size) are averages.
            aggregated = geo_tables[geo].copy(deep=True).groupby([agg_col, "yr_id"]).sum().reset_index()

            # NOTE: The current generation code does not have hhs nor vacancy_rate
            # # The hacky fix to the above bug
            # # Note, hhs = household size 
            # #           = total population / number of households 
            # #           = pop / hh
            # # BUG: Why does documentation above use total population (pop) while the code below uses
            # # household population (hhp)? Can someone confirm which of these is correct?
            # aggregated["hhs"] = aggregated["hhp"] / aggregated["hh"]
            # aggregated["vacancy_rate"] = 100 \
            #     * (aggregated["vacancy"] - aggregated["unoccupiable"]) \
            #     / aggregated["units"]

            # Check the values match up
            check_results = (aggregated == geo_tables[agg_col])
            pd.set_option('display.max_colwidth', None)
            pd.set_option("display.max_columns", None)

            # Print out error stuff if the number of True values is less than the number of cells.
            # Or in other words, print out error stuff if at least one cell is False
            if(check_results.to_numpy().sum() != check_results.shape[0] * check_results.shape[1]):
                error_rows = ((check_results.sum(axis=1) - check_results.shape[1]) != 0)
                print(aggregated.loc[error_rows])
                print(geo_tables[agg_col].loc[error_rows])
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

    def spot_nulls(self, folder, vintage, geo, table_name):
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
        geo_table = f.load(folder, vintage, geo, table_name)

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

    def yearly_change(self, folder, vintage, geo, table_name, col):
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
        geo_table = f.load(folder, vintage, geo, table_name)

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
    """Check that the total population of the region is within 1.5% of CA DOF population.
    
    Attributes:
        threshold (float): The percentage we can go above/below CA DOF population numbers. If the 
            value of this variable is (for example) 1.5%, that means that our population numbers
            must be less than DOF + 1.5% and must be greater than DOF - 1.5%
    """

    threshold = 1.5

    def _abs_percent_change(self, df, baseline, comparison):
        """Compute the absolute percent change in the input df between the baseline and comparison columns."""
        return abs(100 * (df[comparison] - df[baseline]) / df[baseline])

    def region_DOF_population_comparison(self, DOF_folder, raw_folder, vintage):
        """Check that the total population of the region is within 1.5% of CA DOF population.
        
        As written in SB 375 on p. 23-24, our population numbers need to be within a RANGE of 3% of
        CA DOF population numbers. We interpret RANGE to be plus or minus 1.5%.

        Attributes:
            DOF_folder (pathlib.Path):
            raw_folder (pathlib.Path):
            vintage (str):

        Returns:
            None
        """
        # Print what test is going on
        print("Running Check 6: DOF Total Population Comparison")

        # Get the two datasets
        DOF_data = f.load(DOF_folder, "DOF", "region")
        est_data = f.load(raw_folder, vintage, "region", "population")

        # Clean up the datasets so that they are in the same format with the same years of data
        # 1. Create new columns as necessary
        # 2. Rename columns
        # 3. Select only the relevant columns for comparison
        
        # 1. Create new columns as necessary
        est_data["Est Group Quarters"] = est_data[
            ["Group Quarters - Military", "Group Quarters - College", "Group Quarters - Other"]].sum(axis=1)

        # 2. Rename columns
        DOF_data = DOF_data.rename({
            "Total Population": "DOF Total Population",
            "Household Population": "DOF Household Population",
            "Group Quarters": "DOF Group Quarters"}, axis=1)
        est_data = est_data.rename({
            "yr_id": "Year",
            "Total Population": "Est Total Population",
            "Household Population": "Est Household Population"}, axis=1)

        # 3. Select only the relevant columns for comparison
        DOF_data = DOF_data[["Year", "DOF Total Population", "DOF Household Population", "DOF Group Quarters"]]
        est_data = est_data[["Year", "Est Total Population", "Est Household Population", "Est Group Quarters"]]

        # Combine the datasets together and compute the percent difference
        combined_data = pd.merge(est_data, DOF_data, how="left", on="Year")
        combined_data["% Total Population"] = \
            self._abs_percent_change(combined_data, "DOF Total Population", "Est Total Population")
        combined_data["% Household Population"] = \
            self._abs_percent_change(combined_data, "DOF Household Population", "Est Household Population")
        combined_data["% Group Quarters"] = \
            self._abs_percent_change(combined_data, "DOF Group Quarters", "Est Group Quarters")
        
        # Print out the rows that have a percent change larger than the allowed amount
        error_rows = combined_data[
            (combined_data["% Total Population"] > self.threshold) | 
            (combined_data["% Household Population"] > self.threshold) | 
            (combined_data["% Group Quarters"] > self.threshold)]
        if(error_rows.shape[0] > 0):
            print("Errors have occured on the following rows:")
            print(error_rows)
        else:
            print("No errors")
        print()

if __name__ == "__main__":
    DOFPopulation().region_DOF_population_comparison(
        pathlib.Path("data/CA_DOF/"),
        pathlib.Path("data/raw_data/"),
        "2020_06"
    )

######################################
# Check 7: DOF Proportion Comparison #
######################################

class DOFProportion():
    """Compares the proportion of groups in total pop between DOF and Estimates at Regional Level.

    Comparison is across different groups like household income, age, gender, ethnicity, ethnicity 
    by age, ethnicity by gender by age.
    """

    def shares(df, threshold_dict): # Calvin's code copied and pasted; need to make changes still
        """Get data and compare the proportion changes between DOF and Estimates.
        
        Checks at region level whether there exists any columns where proportion of groups is different.

        TODO: Below is Calvin's documentation, format as a Google-style docstring

        input: multi-index dataframe (index = (geo_level, year)), columns to check threshold in,
        value threshold (numeric), percentage threshold (numeric value in {0,1})
        
        output: rows of the input multi-index dataframe with yearly differences outside the
        designated threshold (inclusive)

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
        # Add column values and divides each column by total to get the proportion breakdown
        df = df[threshold_dict.keys()]
        df.loc[:, 'Total'] = df[threshold_dict.keys()].sum(axis=1)
            
        shares = df[threshold_dict.keys()].div(df['Total'], axis=0) * 100
        
        years = list(df.index.get_level_values(1).unique()) # List of the unique years 
        year_diffs = {}

        # Creating a dictionary of the differences, just naming conventions
        index=0
        while index < len(years)-1:
            year_diffs[years[index+1]] = f"{str(years[index])}-{str(years[index+1])}"
            index+=1
        
        # Group together MGRA and subtract newer year from older year. Rename the index according to the year_diffs dataframe. Then drop rows where every value is NA (Which will be all rows for 2016)    
        renamed_df = shares.groupby(level=0).diff().rename(index=year_diffs).dropna(how='all')

        # Subsets dataframe by column, checks to see if the value is greater than the threshold and returns true or false depending on if the threshold was crossed. 
        condition = pd.DataFrame([abs(renamed_df[key]) >= val for key, val in threshold_dict.items()]).T.all(axis=1)
        
        renamed_df['Flag'] = condition
        
        return renamed_df
    
