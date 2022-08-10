# Eric Liu
# 
# Functions which can be used to generate csv files from estimates and dimensions tables. To use, 
# simply put the following import at the top of your code "import estimates_automation as ea"
#
# For details on what does what, just refer to the individual functions.
# 
# There is some automated testing of the functions in the file "test_estimates_automation.py", but 
# it is very sparse. I would love to add more tests if I can find the time
#
# Note, I'm pretty sure this code can be used for both estimates and forecasts, at which point the
# file would change to "forecasts_estimates_automation.py". I would love to find a way to put in
# a bunch of iron related puns (fe=iron)
#
# Updated: August 10, 2022

###########
# Imports #
###########

import pandas as pd

#############
# Functions #
#############

def get_table_by_geography(connection, config, est_table, geo_level, 
    est_vintage="2020_06",
    pivot=False, 
    debug=False):
    """
    Get the input estimates table grouped by the input geography level. Because I hate dealing
    with multi-indexes of any kind, every table returned from this function (whether pivoted
    or not) will never have a multi-index or a multi-column

    :param connection:  The connection to the relevant SQL server (AFAIK always DDAMWSWL16)
    :param config:      The config file. See "./config.json" for details
    :param est_table:   The name of the estimates table. This is the part after "dw_"
    :param geo_level:   The geography level to group by. This is a string input corresponding to one
                        of the column names of [demographic_warehouse].[dim].[mgra_denormalize]. For
                        example, this variable could contain "sra", "college", or "jurisdiction"
    :param est_vintage: Which estimates table to pull from. See the variable EST_BASE_TABLE for
                        more details on how this variable is used
    :param pivot:       By default, False. If True, change the format of the table from being tall
                        to wide. For more details, see the bottom of the function for exactly what 
                        is going on
    :param debug:       By default, False. If True, then print out diagnostic statements including
                        the complete SQL query used
    :returns:           Dataframe containing the requested table grouped by the geography level
    """
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
        print(f"{'connection' : <32}", connection)
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
    query = """
SELECT {mgra_denormalize_col}, yr_id, {dim_named_cols}, {agg_col}
FROM {est_base_table} as tbl
{joins}
WHERE {geography_filter}
GROUP BY {mgra_denormalize_col}, yr_id, {join_col}, {dim_named_cols}
ORDER BY {mgra_denormalize_col}, yr_id, {join_col}
"""
    if(households):
        # In the households table, we ignore the hosueholds_size_id column, which means we only have
        # to join with mgra_denormalize
        query = """
SELECT {mgra_denormalize_col}, yr_id, {agg_col}
FROM {est_base_table} as tbl
{joins}
WHERE {geography_filter}
GROUP BY {mgra_denormalize_col}, yr_id
ORDER BY {mgra_denormalize_col}, yr_id
"""
    
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
    """, con=connection).columns
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
        agg_list = config["est"][est_table]
    else:
        agg_list = config["est"]["age_sex_ethnicity"]
    agg_col = ""
    for aggregation in agg_list:
        agg_col += "{function}({col}) as {col}".format(function=aggregation[1], col=aggregation[0])
        agg_col += ", "
    agg_col = agg_col[:-2] # Remove the trailing comma
    if(debug):
        if(not age_ethnicity):
            print(f"{'Aggregation instructions:' : <32}", config["est"][est_table])
        else:
            print(f"{'Aggregation instructions:' : <32}", config["est"]["age_sex_ethnicity"])
        print()
    
    # The field {joins} is asking for formatted list of INNER JOINs that add on each dim table to
    # the estimates table. This information is contained in config["dim"]
    # TODO: Are there null mgra_id values? May need to change to LEFT JOIN
    # Note, we always want to join on mgra_id, so add that to the list
    JOIN_COLS = ["mgra_id"] + ID_COLUMNS
    if(households):
        JOIN_COLS = ["mgra_id"]
    joins = ""
    for join_col in JOIN_COLS:
        dim_table = config["dim"][join_col]["dim_table"]
        joins += f"""
INNER JOIN {DIM_BASE_TABLE.format(dim_table)} as {dim_table} ON
    {dim_table}.{join_col} = tbl.{join_col}
"""
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
    table = pd.read_sql_query(query, con=connection)

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
            VAL_COLS = [col[0] for col in config["est"][est_table]]

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

def consolidate(connection, config,
    est_vintage="2020_06",
    geo_list=["region", "jurisdiction", "cpa"], 
    est_table_list=["age", "ethnicity", "household_income", "households", "housing", "population", "sex"],
    save=False,
    save_folder=None):
    """
    Conoslidate the input estimates tables column wise for each input geography. This function 
    returns one dataframe per geography level, as opposed to combining everything together

    :param connection:      The connection to the relevant SQL server (AFAIK always DDAMWSWL16)
    :param config:          The config file. See "./config.json" for details
    :param est_vintage:     Which estimates table to pull from. See the variable EST_BASE_TABLE in 
                            the function get_table_by_geography for more details
    :param geo_list:        The geographies to cosolidate along.
    :param est_table_list:  Whcih estimates tables we want to consolidate
    :param save:            False by default. If False, then only return the consolidated tables. If 
                            True, then use save_folder to save the consolidated tables and return
                            the tables
    :param save_folder:     The folder in which to save consolidated files. Only used if save=True
    :returns:               A list containing the consolidated tables (dataframes) in the order of 
                            geo_list
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
            est_table = get_table_by_geography(connection, config, est_table_name, geo, 
                est_vintage=est_vintage, pivot=True)

            # AS OF UPDATE 8/10/2022, THE FUNCTION get_table_by_geography SHOULD ALWAYS RETURN
            # TABLES WHICH HAVE NO MULTI-INDICIS NOR MULTI-COLUMNS. THUS, THE FOLLOWING 
            # TRANSFORMATIONS ARE NO LONGER NECESSARY

            # # Do some transformations to align the format with what we want in the csv
            # # Similar to in get_table_by_geography, we have different behavior for the households
            # # table as we ignore the column household_size_id. As a result, the table returned by
            # # get_table_by_geography is already in the correct format
            # est_table = est_table.reset_index()
            # if(est_table_name != "households"):
            #     # TODO: Possible bug when consolidating age_sex_ethncity table relating to usage
            #     # of hardcoded number 2 below
            #     est_table.columns = est_table.columns.get_level_values(0)[:2].append(
            #         est_table.columns.get_level_values(1)[2:])
                
            #     # Due to the odd format of the housing pivot table, different processing needs to be
            #     # done
            #     if(est_table_name == "housing"):
            #         # Specifically, the above column manipulation loses information about # of 
            #         # units, unoccupiable, occupied, and vacancy. This table can be best found in 
            #         # the unpivoted version of the table
            #         housing_unpivot = get_table_by_geography(connection, config, est_table_name, geo, 
            #             est_name=est_name, pivot=False)

            #         # Since the type of housing information is already contained in ths pivot table,
            #         # we can drop that column
            #         housing_unpivot = housing_unpivot.drop("long_name", axis=1)

            #         # Sum up values for each distinct geo, yr_id combination
            #         housing_unpivot = housing_unpivot.groupby([geo, "yr_id"]).sum()

            #         # The groupby results in a multi-index, remove it
            #         housing_unpivot = housing_unpivot.reset_index(drop=False)

            #         # Join the four additional columns to the original estimates table
            #         est_table = est_table.merge(housing_unpivot, how="left", on=[geo, "yr_id"], sort=False)

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

def individual(connection, config,
    est_vintage="2020_06",
    geo_list=["region", "jurisdiction", "cpa"], 
    est_table_list=["age", "ethnicity", "household_income", "age_ethnicity", "age_sex_ethnicity"],
    save=False,
    save_folder=None):
    """
    Generate individual estimates tables for each input geography. This function returns one
    dataframe for each geography level / estimate table. Because of the way looping is done, the 
    order of dfs is first geo_level each estimate table, second geo_level each estimate table, etc.

    :param connection:      The connection to the relevant SQL server (AFAIK always DDAMWSWL16)
    :param config:          The config file. See "./config.json" for details
    :param est_vintage:     Which estimates table to pull from. See the variable EST_BASE_TABLE in 
                            the function get_table_by_geography for more details
    :param geo_list:        The desired geographies
    :param est_table_list:  The desired estimates tables
    :param save:            False by default. If False, then only return the individual tables. If 
                            True, then use save_folder to save the individual tables and return
                            the tables
    :param save_folder:     The folder in which to save individual files. Only used if save=True
    :returns:               A list containing the individual tables (dataframes) in the order of 
                            geo_list x (est_table_list + eth_by_age)
    """
    # Store each individual table by geography level x est_table_list here
    individual_tables = []

    # Loop over the geography levels we want to get individual files on
    for geo in geo_list:

        # Loop over every estimate table we want to get
        for est_table_name in est_table_list:

            # Get the estimate table
            est_table = get_table_by_geography(connection, config, est_table_name, geo, 
                est_vintage=est_vintage, pivot=True)

            # AS OF UPDATE 8/10/2022, THE FUNCTION get_table_by_geography SHOULD ALWAYS RETURN
            # TABLES WHICH HAVE NO MULTI-INDICIS NOR MULTI-COLUMNS. THUS, THE FOLLOWING 
            # TRANSFORMATIONS ARE NO LONGER NECESSARY

            # # Do some transformations to align the format with what we want in the csv
            # # Similar to in get_table_by_geography, we have different behavior for the households
            # # table as we ignore the column household_size_id. As a result, the table returned by
            # # get_table_by_geography is already in the correct format
            # est_table = est_table.reset_index()
            # if(est_table_name != "households"):
            #     # Due to the odd format of the housing pivot table, different processing needs to be
            #     # done
            #     if(est_table_name == "housing"):
            #         print(est_table)
            #         # TODO: Possible bug when consolidating age_sex_ethncity table relating to usage
            #         # of hardcoded number 2 below
            #         est_table.columns = est_table.columns.get_level_values(0)[:2].append(
            #             est_table.columns.get_level_values(1)[2:])

            #         print(est_table)

            #         # Specifically, the above column manipulation loses information about # of 
            #         # units, unoccupiable, occupied, and vacancy. This table can be best found in 
            #         # the unpivoted version of the table
            #         housing_unpivot = get_table_by_geography(connection, config, est_table_name, geo, 
            #             est_name=est_name, pivot=False)

            #         # Since the type of housing information is already contained in ths pivot table,
            #         # we can drop that column
            #         housing_unpivot = housing_unpivot.drop("long_name", axis=1)

            #         # Sum up values for each distinct geo, yr_id combination
            #         housing_unpivot = housing_unpivot.groupby([geo, "yr_id"]).sum()

            #         # The groupby results in a multi-index, remove it
            #         housing_unpivot = housing_unpivot.reset_index(drop=False)

            #         # Join the four additional columns to the original estimates table
            #         est_table = est_table.merge(housing_unpivot, how="left", on=[geo, "yr_id"], sort=False)
            #     else:
            #         column_name_pivot_point = list(est_table.columns.get_level_values(0)).index(
            #             config["est"][est_table_name][0][0])
            #         est_table.columns = est_table.columns.get_level_values(0)[:column_name_pivot_point].append(
            #             est_table.columns.get_level_values(1)[column_name_pivot_point:])

            # Store the individual table
            individual_tables.append(est_table)

            # Save the table if requested
            if(save):
                # Save each table using the geography level to distinguish
                file_name = f"{est_vintage}_{est_table_name}_{geo}_QA.csv"
                est_table.to_csv(save_folder / file_name, index=False)

        # # Check if we additionally want to get ethnicity broken down by only age (not gender)
        # if(eth_by_age):
        #     # Get the age_sex_ethnicity table
        #     est_table = get_table_by_geography(connection, config, "age_sex_ethnicity", geo, 
        #         est_vintage=est_vintage, pivot=True).reset_index()

        #     # Do the same transforms
        #     column_name_pivot_point = list(est_table.columns.get_level_values(0)).index("population")
        #     est_table.columns = est_table.columns.get_level_values(0)[:column_name_pivot_point].append(
        #         est_table.columns.get_level_values(1)[column_name_pivot_point:])

        #     # Group by every categorical variable except sex
        #     est_table = est_table.groupby([geo, "yr_id", "name"]).sum().reset_index()

        #     # Store the individual table
        #     individual_tables.append(est_table)

        #     # Save the table if requested
        #     if(save):
        #         # Save each table using the geography level to distinguish
        #         file_name = f"{est_vintage}_age_ethnicity_{geo}_QA.csv"
        #         est_table.to_csv(save_folder / file_name, index=False)
            
    # Return all the combined tables
    return individual_tables
