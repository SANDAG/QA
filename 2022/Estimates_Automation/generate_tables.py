"""Classes/functions to return/save various Estimates tables.

The functions in this file all create tables directly using Estimates data from
[DDAMWSQL16].[estimates]. Although the data in the created tables can be analyzed directly for any
errors present in raw data, it is recommended that checks are done using the classes/functions in
the file "perform_checks.py".
"""

###########
# Imports #
###########

import pathlib
import yaml
import textwrap

import pandas as pd
import sqlalchemy as sql

####################
# Estimates Tables #
####################

class EstimatesTables():
    """Functions to return/save various Estimates tables.

    The functions in this class all create tables directly using Estimates data from 
    [DDAMWSQL16].[estimates]. The functions in this file do not run any checks, nor do they 
    create any kind of derived output such as diff files.
    """
    
    def _get_config(self, file=pathlib.Path("./config.yaml")):
        """Get and return the request config file. Default is config.yaml."""
        with open(file, "r") as config_file:
            return yaml.safe_load(config_file)

    def get_table_by_geography(self, est_vintage, est_table, geo_level, pivot=False, debug=False):
        """Get the input estimates table grouped by the input geography level.
        
        This function will return the requested Estimates table from the requested vintage. The relevant
        joins will be made on the base table as specified in the default config file. The returned table
        will by zero indexed and have no multi-columns.

        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this
                variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]"
            est_table (str): The Estimates table to pull from. In DDAMWSQL16, this variable 
                corresponds to XXXX in the table "[estimates].[est_YYYY_MM].[dw_XXXX]"
            geo_level (str): The geography level to aggregate by. This can be any of the columns in 
                the DDAMWSQL16 table [demographic_warehouse].[dim].[mgra_denormalize]. For example,
                you could input "region", "jurisdiction", "mgra", etc.
            pivot (bool): Default False. If True, return the table in wide format instead of tall
            debug (bool): Default False. If True, print out diagnostic print statements during 
                execution including the complete SQL query used

        Returns:
            pd.DataFrame: The requested Estimates table grouped by the geography level
        """
        # It is assumed that the Estimates table will always come from DDAMWSQL16
        # NOTE: This uses desktop authentication so I'm fairly confident to run this fuction you would
        # need to be in the office or on VPN, but I'm not sure. Someone want to test it out?
        DDAM = sql.create_engine('mssql+pymssql://DDAMWSQL16/')

        # Store the config locally 
        config = self._get_config()

        # This variable changes the behavior of the function if the age_ethnicity table is requested.
        # This table does not exist in the estimates table, rather it is the age_sex_ethnicity table
        # grouped by age and ethnicity.
        age_ethnicity = (est_table == "age_ethnicity")

        # This variable is used to deal with the unique behavior of households table. We ignore the 
        # household_size_id column and just group by the geography level
        households = (est_table == "households")

        # This variable is used to deal with the unique behavior of housing table. Used to do some
        # weird transformations when pivoting
        housing = (est_table == "housing")

        # If we want debug, output all function inputs and the two above derived function inputs
        if(debug):
            print("*** BEGIN FUNCTION INPUTS ***")
            print(f"{'connection' : <32}", DDAM)
            print(f"{'config' : <32}", config)
            print(f"{'est_table' : <32}", est_table)
            print(f"{'geo_level' : <32}", geo_level)
            print(f"{'est_vintage' : <32}", est_vintage)
            print(f"{'pivot' : <32}", pivot)
            print(f"{'debug' : <32}", debug)
            print(f"{'age_ethnicity' : <32}", age_ethnicity)
            print(f"{'households' : <32}", households)
            print(f"{'housing' : <32}", housing)
            print("*** END FUNCTION INPUTS ***")
            print()

        # The basic format of every table we are looking at. To use, call
        # EST_BASE_TABLE.format(<TABLE NAME>)
        EST_BASE_TABLE = "[estimates].[est_" + est_vintage + "].[dw_{0}]"

        # The basic format of every dim table we are looking at. To use, call:
        # DIM_BASE_TABLE.format(<TABLE NAME>)
        DIM_BASE_TABLE = "[demographic_warehouse].[dim].[{0}]"

        # Create the basic structure of the SQL query
        # Note, none of the formatted strings should end with a ","
        query = textwrap.dedent("""\
            SELECT {mgra_denormalize_col}, yr_id, {dim_named_cols}, {agg_col}
            FROM {est_base_table} as tbl
            {joins}
            WHERE {geography_filter}
            GROUP BY {mgra_denormalize_col}, yr_id, {join_col}, {dim_named_cols}
            ORDER BY {mgra_denormalize_col}, yr_id, {join_col}
            """)
        if(households):
            # In the households table, we ignore the hosueholds_size_id column, which means we only have
            # to join with mgra_denormalize
            query = textwrap.dedent("""\
                SELECT {mgra_denormalize_col}, yr_id, {agg_col}
                FROM {est_base_table} as tbl
                {joins}
                WHERE {geography_filter}
                GROUP BY {mgra_denormalize_col}, yr_id
                ORDER BY {mgra_denormalize_col}, yr_id
                """)
        
        # The field {est_base_table} is asking for the full table we are pulling data from. Note the
        # different behavior if the table requested is age_ethnicity (does not exist in estimates)
        est_base_table = None
        if(not age_ethnicity):
            est_base_table = EST_BASE_TABLE.format(est_table)
        else:
            est_base_table = EST_BASE_TABLE.format("age_sex_ethnicity")

        # We additionally need the columns that exist in the estimates table
        COLUMNS = pd.read_sql_query(f"""
            SELECT TOP(0) *
            FROM {est_base_table}
        """, con=DDAM).columns
        if(debug):
            print(f"{'Columns in estimates table:' : <32}", list(COLUMNS))
            print()

        # From the list of columns, we can find exactly which columns we want to be joining on. These
        # are the columns which end with "_id" but are not "mgra_id" nor "yr_id"
        ID_COLUMNS = [col for col in COLUMNS if 
            col.endswith("_id") and 
            col != "mgra_id" and 
            col != "yr_id"
        ]
        if(households):
            ID_COLUMNS = []

        # The field {mgra_denormalize_col} is asking for the column name that contains the geography
        # variable ("sra", "college", "jurisdiction", etc.)
        mgra_denormalize_col = geo_level

        # The field {dim_named_cols} is asking for the (formatted) columns in the dim tables that 
        # contain the long form representations of the ids. For example, in the dim table age_group,
        # age_group_id=1 corresponds to name="Under 5", so we want the "name" column as it is the most
        # descriptive
        dim_named_cols = ""
        if(not households):
            for id_col in ID_COLUMNS:
                dim_named_cols += f"{config['dim'][id_col]['dim_table']}.{config['dim'][id_col]['column(s)'][0]}, "
            dim_named_cols = dim_named_cols[:-2] # Remove the trailing comma
        
        # The field {agg_col} is asking for the column of the estimates table we are aggregating on
        # and the function used to aggregate. This information is contained in config["est"]
        agg_list = None
        if(not age_ethnicity):
            agg_list = config["est"][est_table]["aggregations"]
        else:
            agg_list = config["est"]["age_sex_ethnicity"]["aggregations"]
        agg_col = ""
        for aggregation in agg_list:
            agg_col += "{function}({col}) as {col}".format(function=aggregation[1], col=aggregation[0])
            agg_col += ", "
        agg_col = agg_col[:-2] # Remove the trailing comma
        if(debug):
            print(f"{'Aggregation instructions:' : <32}", agg_list)
            print()
        
        # The field {joins} is asking for formatted list of INNER JOINs that add on each dim table to
        # the estimates table. This information is contained in config["dim"]
        # TODO: Are there null mgra_id values? May need to change to LEFT JOIN
        # Note, we always want to join on mgra_id, so add that to the list
        JOIN_COLS = None
        if(not age_ethnicity):
            JOIN_COLS = config["est"][est_table]["joins"]
        else:
            JOIN_COLS = config["est"]["age_sex_ethnicity"]["joins"]
        joins = ""
        for join_col in JOIN_COLS:
            dim_table = config["dim"][join_col]["dim_table"]
            joins += textwrap.dedent(f"""\
                INNER JOIN {DIM_BASE_TABLE.format(dim_table)} as {dim_table} ON
                    {dim_table}.{join_col} = tbl.{join_col}
                """)
        if(debug):
            print(f"{'Columns to join on:' : <32}", list(JOIN_COLS))
            print()
        
        # The field {geography_filter} is asking for the conditional where we only get the rows of the 
        # table where the geography level we are interested in is not NULL
        geography_filter = f"{mgra_denormalize_col} IS NOT NULL"

        # The field {join_col} is asking for the column of the estimates table we are joining on in 
        # order to keep categorical variables in the same order
        # TODO: This assumes there is only one join to be made
        join_col = ""
        if(not households):
            join_col = f"tbl.{ID_COLUMNS[0]}"

        # Fill in the blanks of the query
        if(not households):
            query = query.format(
                mgra_denormalize_col=mgra_denormalize_col,
                dim_named_cols=dim_named_cols,
                agg_col=agg_col,
                est_base_table=est_base_table,
                joins=joins,
                geography_filter=geography_filter,
                join_col = join_col
            )
        else:
            query = query.format(
                mgra_denormalize_col=mgra_denormalize_col,
                agg_col=agg_col,
                est_base_table=est_base_table,
                joins=joins,
                geography_filter=geography_filter,
                join_col = join_col
            )
        if(debug):
            print("*** FULL QUERY BELOW ***")
            print(query)
            print("*** END FULL QUERY ***")

        # Get the table into pandas
        table = pd.read_sql_query(query, con=DDAM)

        # If the age_ethnicity table was requested (and not the age_sex_ethnicity table which was
        # pulled from SQL), then aggregate to remove the sex category
        if(age_ethnicity):
            table = table.groupby([geo_level, "yr_id", "name", "long_name"]).sum().reset_index(drop=False)

        # Pivot the table if requested
        # Note, due to how the households table is created, it is by default already in pivot table 
        # format
        if(pivot and not households):
            # For every table, there are 1-3 categorical columns, and 1-4 value columns. Each unique
            # combination of all categorical columns and one value column will form a new column

            # Some additional weird transformations need to be done on the housing table
            # TODO: why?
            housing_values_table = None
            if(housing):
                housing_values_table = table[[geo_level, "yr_id", "units", "unoccupiable", "occupied", 
                    "vacancy"]].copy(deep=True).groupby([geo_level, "yr_id"]).sum()
                table = table[[geo_level, "yr_id", "long_name", "units"]]

            # First, create the list of index columns, categorical column(s), and value column(s)
            IND_COLS = [geo_level, "yr_id"]
            CAT_COLS = [config["dim"][col]["column(s)"][0] for col in ID_COLUMNS]
            VAL_COLS = None
            if(age_ethnicity):
                IND_COLS += ["name"]
                CAT_COLS = ["long_name"]
                VAL_COLS = ["population"]
            elif(housing):
                CAT_COLS = ["long_name"]
                VAL_COLS = ["units"]
            else:
                VAL_COLS = [col[0] for col in config["est"][est_table]["aggregations"]]

            # Custom behavior for the age_sex_ethnicity table
            if(est_table == "age_sex_ethnicity"):
                IND_COLS += ["name", "sex"]
                CAT_COLS = ["long_name"]

            # Before pivoting, get the category order as for whatever reason, pivot_table() seems
            # to sort automatically, and if you do sort=False it puts the columns in a wierd order...
            col_order = list(table[CAT_COLS[0]].unique())

            # Custom behavior for the population table. Essentially, we want to add on a column
            # with total population. Note, this column will be computer later on
            if(est_table == "population"):
                col_order = ["Total Population"] + col_order

            # For god know why, SQL returns the incorrect column order for the table 
            # age_sex_ethnicity, but only when the geo_level is region or cpa. So when the geo_level
            # is jurisdiction, SQL returns the correct order???
            # Although I really hate to do this, in the interest of time I will just be hardcoding 
            # the correct column order
            # TODO: An actual fix for this bug would be pretty cool
            if(est_table == "age_sex_ethnicity"):
                if(debug):
                    print("Manually adjusting column order, see notebook TODO for why")
                col_order = ["Hispanic", "Non-Hispanic, White", "Non-Hispanic, Asian", 
                    "Non-Hispanic, Hawaiian or Pacific Islander", 
                    "Non-Hispanic, American Indian or Alaska Native", "Non-Hispanic, Other", 
                    "Non-Hispanic, Two or More Races", "Non-Hispanic, Black"]

            # Print how pivoting can be done
            if(debug):
                print(f"{'Pivot index columns:' : <32}", IND_COLS)
                print(f"{'Pivot categorical columns:' : <32}", CAT_COLS)
                print(f"{'Pivot value columns:' : <32}", VAL_COLS)
                print(f"{'Column order:' : <32}", col_order)

            # Pivot the table
            table = table.pivot_table(
                index=IND_COLS, 
                columns=CAT_COLS,
                values=VAL_COLS,
                aggfunc=sum) # Not used except for age_sex_ethnicity table

            # Custom behavior for the population table. Compute the total population column from the 
            # other columns
            if(est_table == "population"):
                table["population", "Total Population"] = (table["population", "Household Population"] + 
                    table["population", "Group Quarters - Military"] + 
                    table["population", "Group Quarters - College"] + 
                    table["population", "Group Quarters - Other"])

            # Put the columns back in the correct order
            table = table.reindex(col_order, axis=1, level=1)

            # Since I hate multi-indices and multi-columns, undo it 
            table = table.reset_index(drop=False)
            table.columns = table.columns.get_level_values(0)[:len(IND_COLS)].append(
                table.columns.get_level_values(1)[len(IND_COLS):])

            # Add back on the housing value columns 
            if(housing):
                table = table.merge(housing_values_table, on=[geo_level, "yr_id"])

        # Return the table
        return table

    def consolidate(self, est_vintage,
        geo_list=["region", "jurisdiction", "cpa"], 
        est_table_list=["age", "ethnicity", "household_income", "households", "housing", "population", "sex"],
        save=False,
        save_folder=None):
        """Create consolidated files with all Estimates table for each geography level.

        This function returns one pd.DataFrame per input geography level, as opposed to combining 
        everything together.

        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this 
                variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]"
            geo_list (List of str): The geographies to cosolidate along. 
            est_table_list (List of str): Which estimates tables we want to consolidate
            save (bool): False by default. If False, then only return the consolidated tables. If 
                True, then use save_folder to save the consolidated tables and return the tables
            save_folder (pathlib.Path): None by default. If save=True, then the folder to save in as a 
                pathlib.Path object

        Returns:
            List of pd.DataFrame: A list containing the consolidated tables in the order of geo_list
        """
        # Store each cosolidated table by geography level here
        combined_tables = []

        # Loop over the geography levels we want to consolidate on
        for geo in geo_list:

            # Each estimate table will create one df each of which has the same number of rows (one row
            # per unique geography region and year). Store them here to merge after
            est_tables = []

            # Loop over every estimate table we want to consolidate
            for est_table_name in est_table_list:

                # Get the estimate table
                est_table = self.get_table_by_geography(est_vintage, est_table_name, geo, pivot=True)

                # Add the transformed estimate table to our list of tables
                est_tables.append(est_table)

            # Combine all the transformed estimate tables into one large table
            combined_table = pd.concat(est_tables, axis=1)

            # Since each of the estimates table has its own version of geo, "yr_id", remove those
            # duplicate columns
            combined_table = combined_table.loc[:, ~combined_table.columns.duplicated()]

            # Store the combined table
            combined_tables.append(combined_table)

            # Save the table if requested
            if(save):
                # Save each table using the geography level to distinguish
                file_name = f"{est_vintage}_consolidated_{geo}_QA.csv"
                combined_table.to_csv(save_folder / file_name, index=False)
                
        # Return all the combined tables
        return combined_tables

    def individual(self, est_vintage,
        geo_list=["region", "jurisdiction", "cpa"], 
        est_table_list=["age", "ethnicity", "household_income", "age_ethnicity", "age_sex_ethnicity"],
        save=False,
        save_folder=None):
        """Create individual files for each unique conbination of Estimate table and geography level.

        Generate individual estimates tables for each input geography. This function returns one
        dataframe for each geography level / estimate table. Because of the way looping is done, the 
        order of dfs is first geo_level each estimate table, second geo_level each estimate table, etc.

        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this 
                variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]"
            geo_list (List of str): The geographies to cosolidate along. 
            est_table_list (List of str): Which estimates tables we want to consolidate
            save (bool): False by default. If False, then only return the consolidated tables. If 
                True, then use save_folder to save the consolidated tables and return the tables
            save_folder (pathlib.Path): None by default. If save=True, then the folder to save in as a 
                pathlib.Path object

        Returns:
            List of pd.DataFrame: A list containing the individual tables in the order of geo_list and
                est_table_list.
        """
        # Store each individual table by geography level x est_table_list here
        individual_tables = []

        # Loop over the geography levels we want to get individual files on
        for geo in geo_list:

            # Loop over every estimate table we want to get
            for est_table_name in est_table_list:

                # Get the estimate table
                est_table = self.get_table_by_geography(est_vintage, est_table_name, geo, pivot=True)

                # Store the individual table
                individual_tables.append(est_table)

                # Save the table if requested
                if(save):
                    # Save each table using the geography level to distinguish
                    file_name = f"{est_vintage}_{est_table_name}_{geo}_QA.csv"
                    est_table.to_csv(save_folder / file_name, index=False)
                
        # Return all the combined tables
        return individual_tables

##############
# Diff Files #
##############

class DiffFiles():
    """Functions to return/save various Estimates diff tables.
    
    The functions in this class create diff files either directly from [DDAMWSQL16].[estimates] or
    from previously saved files. The output diff files will always be returned in case you want
    to hold them in memory. There is also an option to save the files at the specified location.
    The diff files can either be absolute change, percentage change, or both. As with the class
    Esimates Tables, the functions in this file do not run any checks.
    """

    # TODO: Functions to generate diff files. 
    # IMO, the function should have the option to save/not save (see consolidate or individual 
    # above) and the option to generate fresh files or read saved files
    pass