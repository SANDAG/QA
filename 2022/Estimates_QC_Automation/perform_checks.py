"""Classes/functions to run various checks on Estimates tables.

The functions in this file run checks on Estimates tables. These functions can only pull data
from saved files. Each function should by default print out the status of the check, such as
which check is being run and the rows where errors may have occurred.
"""

###########
# Imports #
###########

import pathlib
import textwrap

import pandas as pd
import numpy as np
import sqlalchemy as sql

# Local modules
import functions as f

########################################
# Check 1: Internal Consistency Checks #
########################################

class InternalConsistency():
    """Functions to run internal consistency checks.
    
    For the purposes of this class, internal consistency checks mean one of two things:
    1.  Checking if aggregated values match up when aggregating to/from different geography levels.
        For example, checking if the total population variable, when aggregated from mgra --> 
        region, matches up with the values at the region level. 
    2.  Checking if aggregated values a across Estimates tables match up. For example, checking if
        the total population of Carlsbad in 2010 is the same when comparing total population vs 
        total population from the age_sex_ethnicity table vs total population from household/group
        quarters population vs etc.

    Attributes:
        _geography_aggregation (dict of list): A dictionary with key equals to a geography level, 
            and the value equals to a list containing geographies to aggregate to. For example, for
            the key value of "mgra", the value would contain ["jurisdiction", "region"] because 
            "mgra" aggregates up to both of those geography levels.
        _est_table_by_type (dict of list): A dictionary with key equals to measure type and the
            value equals to a list of the Estimates tables which have that measure type. For 
            example, for the key "population", the value would include "age" because the age table
            breaks down age categories by population.
    """

    _geography_aggregation = {
        "mgra": ["luz", "cpa", "jurisdiction", "region"],
        "jurisdiction": ["region"],
        "cpa": ["jurisdiction", "region"],
        "luz": ["region"],
    }

    # TODO: Add on more such as "age_sex_ethnicity" or "age_ethnicity". This will require additional
    # work in check_internal_aggregations as both of those tables cannot be done with a simple
    # sum across the columns
    _est_table_by_type = {
        "population": ["age", "population", "sex"],
        "households": ["household_income", "households", "housing"],
    }

    def _get_data_with_aggregation_level(self, folder, vintage, geo, table_name):
        """Get data and combine with the proper columns of mgra_denormalize for aggregation.
        
        Gets region level data by default, and whatever geography levels are present in geo_list. 
        Uses [demographic_warehouse].[dim].[mgra_denormalize] and a lookup table to know which 
        columns to add to each geography level table. For example, the lookup table tells the 
        function to add on "jurisdiction" and "region" columns for the "mgra" geo_level.

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

        # The config file is needed to tell us what series of mgra_denormalize to use when 
        # aggregating
        config = f._get_config()

        # Do this for every geography level requested (typically only "mgra" and "jurisdiction", but 
        # could be extended to include "taz", "cpa", etc.).
        # BUG: If additional geography levels are requested, the variables file_search and 
        # dim_table_columns would need to updated

        # Get the table we want to add additional geographies to
        geo_table = f.load(folder, vintage, geo, table_name)

        # Get those additional geographies
        geographies = [geo] + self._geography_aggregation[geo]
        query = textwrap.dedent(f"""
            SELECT {", ".join(geographies)}
            FROM [demographic_warehouse].[dim].[mgra_denormalize]
            WHERE series={config["series"][vintage]}
            """)
        dim_table = pd.read_sql_query(query, con=DDAM)

        # Combine them together
        dim_table = dim_table[[geo] + self._geography_aggregation[geo]].drop_duplicates(ignore_index=True)
        geo_table = pd.merge(geo_table, dim_table, how="left", on=geo)
        return geo_table

    def check_geography_aggregations(self, 
        vintage="2020_06", 
        geo_list=["mgra", "luz"],
        est_table="consolidated",
        raw_folder=pathlib.Path("./data/raw_data/"),
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Check that values match up when aggregating geography levels upwards.
        
        Args:
            vintage (str): Default value of "2020_06". The vintage of Estimates table to pull from. 
            geo_list (list): The list of geographies to aggregate from. Note that region is included 
                by default, so do not include it here.
            est_table (str): Default value of "consolidated". The Estimate table to check. This 
                should basically always be "consolidated", but it is included here in the off chance
                it is not.
            raw_folder (pathlib.Path): Default value of "./data/raw_data/". The folder in which 
                raw Estimates data can be found.
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): Default value of "./data/outputs/". The location to save 
                check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what test is going on
        print("Running Check 1: Check aggregated values between geography levels")

        # Get the table at each geography level
        geo_tables = {}
        for geo in geo_list:
            geo_tables[geo] = self._get_data_with_aggregation_level(raw_folder, vintage, geo, est_table)

        # Add on the region level table
        geo_tables["region"] = f.load(raw_folder, vintage, "region", est_table)

        # Check each geography level at the specified aggregation levels
        for geo in geo_list:
            for agg_col in self._geography_aggregation[geo]:
                # Let the user know what we are aggregating to/from and what we are comparing to
                print(f"Aggregating {geo} level data to {agg_col} and comparing with {agg_col} csv file")

                # Continue with the next geography if cpa is being aggregated to anything
                if(geo == "cpa"):
                    print("CPA cannot be aggregated")
                    print()
                    continue

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
                    # Save if errors and requested
                    if(save):
                        f.save(geo_tables[agg_col].loc[error_rows], save_location, "C1", vintage, 
                            f"{geo}->{agg_col}", "consolidated")
                else:
                    print("No errors")
                print()

    def check_internal_aggregations(self, 
        vintage="2020_06", 
        geo_list=["region", "jurisdiction"],
        est_table_types=["population", "households"],
        raw_folder=pathlib.Path("./data/raw_data/"),
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Check that values match up when aggregating across Estimates tables.

        For example, this function could check that the total population in the San Diego region
        in 2010 is the same between the tables population, age, and sex.
        
        Args:
            vintage (str): Default value of "2020_06". The vintage of Estimates table to pull from. 
            geo_list (list of str): The list of geographies to aggregate from. Note that region is included 
                by default, so do not include it here.
            est_table_types (list of str): Which kinds of Estimates tables to check. Or in other 
                words, which value is in the cell. For example, the age table contains the age 
                breakdown by population, while the household_income table contains the household
                income breakdown by number of households.
            raw_folder (pathlib.Path): Default value of "./data/raw_data/". The folder in which 
                raw Estimates data can be found.
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): Default value of "./data/outputs/". The location to save 
                check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what test we are running
        print("Running Check 1: Check aggregated values between Estimates tables")

        # Iterate over the kinds of tables we want
        for est_type in est_table_types:
            for geo in geo_list:
                print(f"Checking Estimates tables with {est_type} values at the {geo} level")

                # Get the tables at the specified geography levels
                tables = {}
                for table in self._est_table_by_type[est_type]:
                    try:
                        tables[table] = f.load(raw_folder, vintage, geo, table)
                    except FileNotFoundError:
                        print(f"Could not find {f._file_path(vintage, geo, table)}")

                # To avoid errors where table geography/year become misaligned, sort
                for key, table in tables.items():
                    tables[key] = table.sort_values(
                        by=[geo, "yr_id"], 
                        ascending=[True, True], axis=0
                        ).reset_index(drop=True)

                # Get the total est_type for each table 
                totals = tables[list(tables.keys())[0]][[geo, "yr_id"]].copy(deep=True)
                for table_name, table in tables.items():
                    new_total_col = table.drop([geo, "yr_id"], axis=1)

                    # Custom behavior for certain tables
                    # TODO: See documentation above self._est_table_by_type
                    if(table_name == "population"):
                        household_breakdown = new_total_col.drop(["Total Population"], axis=1)
                        totals[f"{table_name}_{est_type}_household_breakdown"] = \
                            household_breakdown.sum(axis=1)
                        new_total_col = new_total_col[["Total Population"]]
                    elif(table_name == "housing"):
                        totals[f"{table_name}_{est_type}_housing_type_breakdown"] = \
                            new_total_col[["Single Family - Detached", 
                                "Single Family - Multiple Unit",
                                "Multifamily",
                                "Mobile Home",
                                "Single-family Detached",
                                "Single-family Attached"]].sum(axis=1) - new_total_col["vacancy"]
                        new_total_col = new_total_col[["occupied"]]

                    new_total_col = new_total_col.sum(axis=1)
                    totals[f"{table_name}_{est_type}"] = new_total_col

                # Find the rows where est_type values are not identical across every column
                totals_compare = totals.drop([geo, "yr_id"], axis=1)
                mask = ~totals_compare.eq(totals_compare.iloc[:, 0], axis=0).all(1)

                # Print out error stuff and save if requested
                if(mask.sum() != 0):
                    print("Errors found on the following rows:")
                    print(totals[mask])
                    # Save if errors and requested
                    if(save):
                        f.save(totals[mask], save_location, "C1", vintage,
                            geo, est_type)
                else:
                    print("No errors")
                print() 

########################
# Check 2: Null Values #
########################

class NullValues():
    """Functions to check for any null values.
    
    At this time, this class only checks for missing data. This class does not have the 
    functionality to check for missing geographies. For example, this class can find that the total
    population value is missing for a certain mgra in a certain year, but cannot find that an 
    entire mgra is missing for a certain year.
    """

    def _spot_null(self, folder, vintage, geo, table_name,
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Get data and check for nulls.

        Args:
            folder (pathlib.Path): The folder in which data can be found.
            vintage (str): The vintage of Estimates table to pull from. 
            geo (str): The geography level to get data for and add aggregation columns onto.
            table_name (str): The name of the Estimates table to get. Because it is assumed that
                the saved tables are created by the file generate_tables.py, this can be any of
                "consolidated" or the name of the Estimates table (such as "age" or "ethnicity").
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): The location to save check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what file we are checking
        print(f"Checking {f._file_path([vintage, geo, table_name])}")

        # Get the table
        geo_table = f.load(folder, vintage, geo, table_name)

        # Get rows where null values exist
        geo_table = geo_table[geo_table.isnull().any(axis=1)]

        # Print out error stuff if there are null values
        if(geo_table.shape[0] > 0):
            print("Errors have occurred on the following rows:")
            print(geo_table)
            # Save if errors and requested
            if(save):
                f.save(geo_table, save_location, "C2", vintage, geo, table_name)
        else:
            print("No errors")
        print()

    def spot_nulls(self,
        vintage="2020_06", 
        geo_list=["region", "jurisdiction"],
        est_table_list=["household_income", "age_ethnicity", "population"],
        raw_folder=pathlib.Path("./data/raw_data/"),
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Check if null values exist in any of the input tables.
        
        Args:
            vintage (str): Default value of "2020_06". The vintage of Estimates table to pull from. 
            geo_list (list): The list of geographies to check.
            est_table_list (str): The Estimates tables to check.
            raw_folder (pathlib.Path): Default value of "./data/raw_data/". The folder in which 
                raw Estimates data can be found.
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): Default value of "./data/outputs/". The location to save 
                check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what test is going on
        print("Running Check 2: Spot Nulls")

        # Iterate over each unique table and run the test
        for geo in geo_list:
            for est_table in est_table_list:
                self._spot_null(raw_folder, vintage, geo, est_table, 
                    save=save, 
                    save_location=save_location)

    def spot_missing_values(self,
        vintage="2020_06", 
        geo_list=["region", "jurisdiction", "mgra"],
        est_table_list=["age", "ethnicity"],
        raw_folder=pathlib.Path("./data/raw_data/"),
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Check that each unique combination of geography and year exist.
        
        For example, make sure that all 19 jurisdictions (including un-incorporated) has the correct
        number of years associated with each jurisdiction. This function will print out errors if 
        encountered, and will save the error outputs if errors are found.

        Args:
            vintage (str): Default value of "2020_06". The vintage of Estimates table to pull from. 
            geo_list (list): The list of geographies to check.
            est_table_list (str): The Estimates tables to check.
            raw_folder (pathlib.Path): Default value of "./data/raw_data/". The folder in which 
                raw Estimates data can be found. Due to the extreme runtime of "mgra", it is 
                possible that files are not saved locally. In that case, or for any files that are
                missing, ONLY the geography and year columns will be pulled directly from SQL Server
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): Default value of "./data/outputs/". The location to save 
                check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what test is going on
        print("Running Check 2: Spot Missing Geographies/Years")

        # Create a connection to SQL Server in case data needs to be pulled directly
        DDAM = sql.create_engine('mssql+pymssql://DDAMWSQL16/')

        # Iterate over each unique table and run the test
        for geo in geo_list:
            for est_table in est_table_list:

                # Print what file we are checking
                print(f"Checking {f._file_path([vintage, geo, est_table])}")
                
                # Attempt to get the table from the locally saved version
                table = None
                try:
                    table = f.load(raw_folder, vintage, geo, est_table)
                    table = table[[geo, "yr_id"]]

                # If the table has not been locally saved, then pull ONLY the geography and year
                # columns from SQL Server
                except FileNotFoundError:
                    print("Data is not saved locally, pulling from DDAMWSQL16")
                    query = textwrap.dedent(f"""\
                        SELECT {geo}, yr_id
                        FROM [estimates].[est_{vintage}].[dw_{est_table}] as est
                        JOIN [demographic_warehouse].[dim].[mgra_denormalize] as mgra_d ON 
	                        est.mgra_id = mgra_d.mgra_id
                        GROUP BY {geo}, yr_id
                        ORDER BY {geo} ASC, yr_id ASC""")
                    table = pd.read_sql_query(query, con=DDAM)

                # Check the following:
                # 1. Each geography has the same number of years associated with it
                # 2. Each year has the same number of geographies associated with it
                geo_check = (table.groupby(geo).count().nunique() == 1).values[0]
                year_check = (table.groupby("yr_id").count().nunique() == 1).values[0]
                
                # Then print out errors if present
                if(geo_check and year_check):
                    print("No Errors")
                else:
                    # TODO: Implement printing out errors and saving errors
                    print("Errors found but not implemented yet")

                print()
    
#################################
# Check 3: Vintage Comparisons #
#################################

class VintageComparisons():
    """N/A. Done already by generate_tables.DiffFiles."""

    pass

###############################
# Check 4: Threshold Analysis #
###############################

class ThresholdAnalysis():
    """Calculates year-on-year% changes and flags if the changes are more than 5%.
    
    For the purposes of this class, threshold analysis checks mean checking if between any two 
    versions, the changes in values differ by more than 5%. For example, flagging if total 
    population in the region changes by more than 5% in one year. The threshold value is 
    configurable, of course.
    """

    def _yearly_change(self, raw_folder, vintage, geo, table_name, 
        threshold=5,
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Get data and check for yearly changes in values.
        
        Gets region level data by default, and whatever geography levels are present in geo_list. 
        Then checks to see if there exists any columns where difference in values is larger than 5%.

        Args:
            raw_folder (pathlib.Path): The folder in which raw Estimates data can be found.
            vintage (str): The vintage of interest.
            geo (str): The geography level of interest.
            table_name (str): The name of the Estimates table to get. Because it is assumed that
                the saved tables are created by the file generate_tables.py, this can be any of
                "consolidated" or the name of the Estimates table (such as "age" or "ethnicity").
            col (str): The column name to choose to check for changes.
            threshold (float): Default value of 5(%). The percentage we can go above/below previous
                values and still consider it reasonable. Somewhat arbitrarily chosen to be honest.
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): The location to save check results.

        Returns:
            None
        """
        # Print what test is running
        print(f"Checking file {f._file_path([vintage, geo, table_name])}")

        # Get the table
        geo_table = f.load(raw_folder, vintage, geo, table_name)

        # Compute the percent change

        # First sort on year
        sort_order = [geo, "yr_id"]
        if(table_name == "age_ethnicity"):
            sort_order.insert(1, "name")
        elif(table_name == "age_sex_ethnicity"):
            sort_order.insert(1, "name")
            sort_order.insert(1, "sex")
        geo_table = geo_table.sort_values(by=sort_order).reset_index(drop=True)
        pop_change = geo_table.copy(deep=True)

        # Compute percent change
        pop_change = pop_change.drop(sort_order + [geo], axis=1)
        pop_change = abs(pop_change.pct_change()) * 100

        # Find the rows of pop_change that are the base rows (2010 usually) and set to no value
        min_year = geo_table["yr_id"].min()
        base_year_rows = (geo_table["yr_id"] == min_year)
        pop_change[base_year_rows] = np.nan

        # Remember column order for later
        columns = pop_change.columns.copy(deep=True)

        # Add a prefix to the percent change columns
        pop_change = pop_change.add_prefix("|% Diff| ")
        
        # Merge the % change with the original table and order the columns
        # I'll be honest, I don't know what the "x for y" stuff is doing, I just know it works. 
        # Essentially, it is merging the columns so that variable and |% Diff| variable alternate
        combined_df = pd.merge(geo_table, pop_change, how="left", left_index=True, right_index=True)
        column_order = list(geo_table.columns)[:(geo_table.shape[1] - columns.shape[0])] + \
            [x for y in zip(columns, pop_change.columns) for x in y]
        combined_df = combined_df[column_order]

        # Create a boolean mask to select rows with errors
        # Also select the rows before to add context to the percent change
        error_rows = (pop_change > threshold).any(1)
        error_rows = error_rows | error_rows.shift(periods=-1)

        # TODO: New feature?
        # # Create a boolean mask to select columns with errors
        # # Also select the columns before to add context to the percent change
        # error_cols = (pop_change > threshold).any(0)
        # error_cols = error_cols | error_cols.shift(periods=-1)

        # Print the results
        if(not combined_df[error_rows].empty):
            print("Errors have occurred on the following rows:")
            print(combined_df[error_rows])
            # Save if errors and requested
            if(save):
                f.save(combined_df[error_rows], save_location, f"C4({threshold}%)", vintage, 
                    geo, table_name)
        else:
            print("No errors")
        print()

    def check_thresholds(self, 
        threshold=5,
        vintage="2020_06", 
        geo_list=["region", "jurisdiction"],
        est_table_list=["household_income", "age_ethnicity", "population"],
        raw_folder=pathlib.Path("./data/raw_data/"),
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Ensure that the yearly change does not exceed a specified threshold.
        
        Args:
            threshold (float): Default value of 5(%). The percentage we can go above/below previous
                values and still consider it reasonable. Somewhat arbitrarily chosen to be honest.
            vintage (str): Default value of "2020_06". The vintage of Estimates table to pull from. 
            geo_list (list): The list of geographies to check.
            est_table_list (str): The Estimates tables to check.
            raw_folder (pathlib.Path): Default value of "./data/raw_data/". The folder in which 
                raw Estimates data can be found.
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): Default value of "./data/outputs/". The location to save 
                check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print out what test is running
        print("Running check 4: Threshold Analysis")

        for geo in geo_list:
            for est_table in est_table_list:
                self._yearly_change(raw_folder, vintage, geo, est_table, 
                    threshold=threshold,
                    save=save,
                    save_location=save_location)

###########################
# Check 5: Trend Analysis #
###########################

class TrendAnalysis():
    """N/A. Done in PowerBI."""

    pass

############################################
# Check 6: DOF Total Population Comparison #
############################################

class DOFPopulation():
    """Check that the total population of the region is within 1.5% of CA DOF population."""

    def _abs_percent_change(self, df, baseline, comparison):
        """Compute the absolute percent change between the baseline and comparison columns."""
        return abs(100 * (df[comparison] - df[baseline]) / df[baseline])

    def region_DOF_population_comparison(self, raw_folder, est_vintage, DOF_vintage,
        threshold=1.5,
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Check that the total population of the region is within 1.5% of CA DOF population.

        Attributes:
            raw_folder (pathlib.Path): The folder where raw Estimates data and CA DOF data can be 
                found. Most likely "./data/raw_data/".
            est_vintage (str): The vintage of Estimates data to compare with DOF data.
            DOF_vintage (str): The vintage of DOF data to compare with Estimates data.
            threshold (float): Default value of 1.5(%). The percentage we can go above/below CA DOF 
                population numbers. If the value of this variable is (for example) 1.5%, that means 
                that our population numbers must be less than DOF + 1.5% and must be greater than 
                DOF - 1.5%. The reason a value of 1.5% is used is because on SB375 p.23-24, SANDAG 
                is required to have population projections within a range of 3% of CA DOF population
                projections. A range of 3% is equivalent to +/- 1.5%
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): The location to save check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what test is going on
        print("Running Check 6: Estimates vs DOF Population Values")

        # Parameters used in the function that should never change
        geo = "region"
        table = "population"

        # Get Estimates and DOF Data
        est_table = f.load(raw_folder, est_vintage, geo, table)
        DOF_table = f.load(raw_folder, "DOF", DOF_vintage, geo, table)

        # Sync up table columns
        est_table = est_table.rename({"yr_id": "Year", "Total Population": "Est Population"}, axis=1)
        DOF_table = DOF_table.rename({"fiscal_yr": "Year", "population": "DOF Population"}, axis=1)

        # Keep only the Year and Population columns
        est_table = est_table[["Year", "Est Population"]]
        DOF_table = DOF_table[["Year", "DOF Population"]]

        # Join the tables
        combined = est_table.merge(DOF_table, how="left", on="Year")

        # Compute and create the absolute percent difference column
        combined["|% Difference|"] = abs(100 * \
            (combined["Est Population"] - combined["DOF Population"]) / (combined["DOF Population"]))

        # Find the rows where there are errors
        error_rows = (combined["|% Difference|"] > threshold)

        if(error_rows.sum() != 0):
            print("Errors have occurred on the following rows:")
            print(combined[error_rows])
            # Save if errors and requested
            if(save):
                f.save(combined[error_rows], save_location, f"C6({threshold})", "region", "population")
        else:
            print("No errors")
        print()

######################################
# Check 7: DOF Proportion Comparison #
######################################

class DOFProportion():
    """Compares the proportion of groups between DOF and Estimates."""

    def check_DOF_proportion(self, 
        threshold=4,
        est_vintage="2020_06", 
        DOF_vintage="2021_07_14",
        geo_list=["region", "jurisdiction"],
        raw_folder=pathlib.Path("./data/raw_data/"),
        save=False,
        save_location=pathlib.Path("./data/outputs/")):
        """Check the proportions of groups between Estimates and CA DOF are roughly the same.

        BUG: This function no longer works with the updated CA DOF table format. 

        Specifically, the groups which are checked are % of population in households vs group
        quarters, % of households which are single detached vs single attached vs mobile home vs
        multifamily, and % of households which are occupied vs vacant. If the differences in 
        percent between Estimates and CA DOF data are greater than the input threshold, then
        those rows of data will be printed out and saved if requested.
        
        Args:
            threshold (float): Default value of 4(%). The amount of absolute allowable difference
                in proportions. For example, if the percent of total population in group quarters 
                compared between DOF and Estimates is greater than threshold, then that row is 
                flagged
            est_vintage (str): Default value of "2020_06". The vintage of Estimates table to pull 
                from. 
            DOF_vintage (str): Default value of "2021_07_14". The vintage of CA DOF table to pull 
                from. 
            geo_list (list): The list of geographies to check. This can only contain "region" and
                "jurisdiction" due to limitations of DOF data.
            raw_folder (pathlib.Path): Default value of "./data/raw_data/". The folder in which 
                raw Estimates data can be found.
            raw_folder (pathlib.Path): Default value of "./data/CA_DOF/". The folder in which 
                transformed CA DOF data can be found.
            save (bool): Default value of False. If True, save the outputs of the check to the input
                save_location if and only if errors have been found.
            save_location (pathlib.Path): Default value of "./data/outputs/". The location to save 
                check results.

        Returns:
            None, but prints out differences if present. Also saves output if requested and errors
                have been found.
        """
        # Print what test is going on
        print("Running Check 7: DOF Categorical Proportion Check")

        # Iterate over the requested geographies
        for geo in geo_list:
            # Print what geography level we are checking
            print(f"Checking {geo} level data")

            # Get Estimates and CA DOF data
            est_table = f.load(raw_folder, est_vintage, geo, "consolidated")
            DOF_table = f.load(raw_folder, "DOF", DOF_vintage, geo, "population")

            # Transform Estimates data into the format we want
            # 1. Create new column to sync up with DOF data format
            # 2. Select only the columns we want
            # 3. Sync up column naming

            # 1. Create new column to sync up with DOF data format
            est_table["Group Quarters"] = est_table[["Group Quarters - Military", 
                "Group Quarters - College", "Group Quarters - Other"]].sum(axis=1)

            # 2. Select only the columns we want
            est_table = est_table[[geo, "yr_id", 
                "Total Population", "Household Population", "Group Quarters", 
                "households", "Single Family - Detached", "Single Family - Multiple Unit", 
                    "Multifamily", "Mobile Home",
                "units", "occupied", "vacancy"]]

            # 3. Sync up column naming
            est_table = est_table.rename({
                "yr_id": "Year",
                "households": "Households",
                "Single Family - Detached": "Single Detached", 
                "Single Family - Multiple Unit": "Single Attached",
                "Mobile Home": "Mobile Homes",
                "occupied": "Occupied Housing Units",
                "units": "Housing Units",
                "vacancy": "Vacant Housing Units"}, axis=1)

            # Transform CA DOF data into the format we want
            # 1. Create new columns to sync up with Estimates data format
            # 2. Select only the columns we want
            # 3. Sync up column naming
            
            # 1. Create new columns to sync up with Estimates data format
            DOF_table["Multifamily"] = DOF_table[["Two to Four", "Five Plus"]].sum(axis=1)
            DOF_table["Vacant Housing Units"] = (DOF_table["Households"] * DOF_table["Vacancy Rate"]).astype(int)
            DOF_table["Housing Units"] = DOF_table[["Occupied", "Vacant Housing Units"]].sum(axis=1)

            # 2. Select only the columns we want
            DOF_geo = "County" if geo == "Region" else "City"
            DOF_table = DOF_table[[DOF_geo, "Year", 
                "Total Population", "Household Population", "Group Quarters", 
                "Households", "Single Detached", "Single Attached", "Multifamily", "Mobile Homes",
                "Housing Units", "Occupied", "Vacant Housing Units"]]

            # 3. Sync up column naming
            DOF_table = DOF_table.rename({
                DOF_geo: geo,
                "Occupied": "Occupied Housing Units"}, axis=1)

            # Modify both tables to be percentages
            # In theory, both tables should have the exact same format so this is to prevent 
            # duplication of code
            for table in [est_table, DOF_table]:
                table[["Household Population", "Group Quarters"]] = 100 * \
                    table[["Household Population", "Group Quarters"]].divide(table["Total Population"], axis=0)
                table[["Single Detached", "Single Attached", "Multifamily", "Mobile Homes"]] = 100 * \
                    table[["Single Detached", "Single Attached", "Multifamily", "Mobile Homes"]].divide(table["Households"], axis=0)
                table[["Occupied Housing Units", "Vacant Housing Units"]] = 100 * \
                    table[["Occupied Housing Units", "Vacant Housing Units"]].divide(table["Housing Units"], axis=0)

            # Sync up the sorting order
            # BUG: For God knows what reason, these sorts CANNOT be done inside the above for
            # loop using the generic variable table. It just doesn't work. Why? I wish I knew :(
            est_table = est_table.sort_values(by=[geo, "Year"], ascending=[True, True], axis=0)
            DOF_table = DOF_table.sort_values(by=[geo, "Year"], ascending=[True, True], axis=0)

            # Filter rows of DOF_table to match the years in est_table
            DOF_table = DOF_table[DOF_table["Year"].isin(pd.unique(est_table["Year"]))].reset_index(drop=True)

            # Get the differences 
            diff = est_table[[geo, "Year"]].copy(deep=True).join(
                abs(est_table.iloc[:, 2:] - DOF_table.iloc[:, 2:]))

            # Drop the non percent differences columns
            diff = diff.drop(["Total Population", "Households", "Housing Units"], axis=1)

            # Find the rows with errors
            error_rows = (diff.drop([geo, "Year"], axis=1) > threshold).any(1)

            # Print out the rows that have a percent change larger than the allowed amount
            if(error_rows.sum() != 0):
                print("Errors have occurred on the following rows:")
                print(diff[error_rows])
                # Save if errors and requested
                if(save):
                    f.save(diff[error_rows], save_location, f"C7({threshold}%)", f"DOF-{est_vintage}", geo)
            else:
                print("No errors")
            print()

        pass
