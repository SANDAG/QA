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

# Local modules
import functions as f

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

    def get_table_by_geography(self, est_vintage, geo_level, est_table, pivot=False, debug=False):
        """Get the input estimates table grouped by the input geography level.
        
        This function will return the requested Estimates table from the requested vintage. The relevant
        joins will be made on the base table as specified in the default config file. The returned table
        will by zero indexed and have no multi-columns.

        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this
                variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]"
            geo_level (str): The geography level to aggregate by. This can be any of the columns in 
                the DDAMWSQL16 table [demographic_warehouse].[dim].[mgra_denormalize]. For example,
                you could input "region", "jurisdiction", "mgra", etc.
            est_table (str): The Estimates table to pull from. In DDAMWSQL16, this variable 
                corresponds to XXXX in the table "[estimates].[est_YYYY_MM].[dw_XXXX]"
            pivot (bool): Default False. If True, return the table in wide format instead of tall
            debug (bool): Default False. If True, print out diagnostic print statements during 
                execution including the complete SQL query used

        Returns:
            pd.DataFrame: The requested Estimates table grouped by the geography level
        """
        # It is assumed that the Estimates table will always come from DDAMWSQL16
        # NOTE: This uses desktop authentication so I'm fairly confident to run this function you 
        # would need to be in the office or on VPN, but I'm not sure. Someone want to test it out?
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

        # This variable is used to modify the behavior to use chunks for very large tables. 
        # Specifically, it will be used if asking for age_ethnicity or age_sex_ethnicity at the
        # mgra level
        use_chunks = ((geo_level == "mgra") and (est_table in ["age_ethnicity", "age_sex_ethnicity"]))

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
        # NOTE: Use chunksize if asking for age_ethnicity or age_sex_ethnicity at the mgra level
        table = None
        if(not use_chunks):
            table = pd.read_sql_query(query, con=DDAM)
        else:
            table = pd.read_sql_query(query, con=DDAM, chunksize=1000)

        # If the age_ethnicity table was requested (and not the age_sex_ethnicity table which was
        # pulled from SQL), then aggregate to remove the sex category
        if(age_ethnicity):
            if(not use_chunks):
                table = table.groupby(
                    [geo_level, "yr_id", "name", "long_name"]).sum().reset_index(drop=False)
            else:
                for chunk in table:
                    print("Removing sex column from chunk")
                    chunk = chunk.groupby(
                        [geo_level, "yr_id", "name", "long_name"]).sum().reset_index(drop=False)

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
            # to sort automatically, and if you do sort=False it puts the columns in a weird order...
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
            if(not use_chunks):
                table = table.pivot_table(
                    index=IND_COLS, 
                    columns=CAT_COLS,
                    values=VAL_COLS,
                    aggfunc=sum) # Not used except for age_sex_ethnicity table
            else:
                for chunk in table:
                    chunk = chunk.pivot_table(
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
            if(not use_chunks):
                table = table.reindex(col_order, axis=1, level=1)
            else:
                for chunk in table:
                    chunk = chunk.reindex(col_order, axis=1, level=1)

            # Since I hate multi-indices and multi-columns, undo it 
            if(not use_chunks):
                table = table.reset_index(drop=False)
                table.columns = table.columns.get_level_values(0)[:len(IND_COLS)].append(
                    table.columns.get_level_values(1)[len(IND_COLS):])
            else:
                for chunk in table:
                    chunk = chunk.reset_index(drop=False)
                    chunk.columns = chunk.columns.get_level_values(0)[:len(IND_COLS)].append(
                        chunk.columns.get_level_values(1)[len(IND_COLS):])

            # Add back on the housing value columns 
            if(housing):
                table = table.merge(housing_values_table, on=[geo_level, "yr_id"])

        # Return the table
        return table

    def consolidate(self, est_vintage,
        geo_list=["region", "jurisdiction", "cpa"], 
        est_table_list=["age", "ethnicity", "household_income", "households", "housing", "population", "sex"],
        get_from_file=False,
        raw_folder=None,
        save=False,
        save_folder=None):
        """Create consolidated files with all Estimates table for each geography level.

        This function returns one pd.DataFrame per input geography level, as opposed to combining 
        everything together.

        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this 
                variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]"
            geo_list (list of str): The geographies to consolidate along. 
            est_table_list (list of str): Which estimates tables we want to consolidate. This 
                function cannot consolidate using the age_ethnicity table nor the 
                age_sex_ethnicity table 
            get_from_file (bool): False by default. If True, then pull data from downloaded files
                instead of re-downloading and holding in memory
            raw_folder (pathlib.Path): Where to find pre-downloaded files
            save (bool): False by default. If False, then only return the consolidated tables. If 
                True, then use save_folder to save the consolidated tables and return the tables
            save_folder (pathlib.Path): None by default. If save=True, then the folder to save in as a 
                pathlib.Path object

        Returns:
            None
        """
        # NOTE: Save on memory by not storing/returning anything
        # # Store each consolidated table by geography level here
        # combined_tables = []

        # Loop over the geography levels we want to consolidate on
        for geo in geo_list:

            # Each estimate table will create one df each of which has the same number of rows (one row
            # per unique geography region and year). Store them here to merge after
            est_tables = []

            # Loop over every estimate table we want to consolidate
            for est_table_name in est_table_list:

                # Get the estimate table
                est_table = None
                if(not get_from_file):
                    est_table = self.get_table_by_geography(est_vintage, geo, est_table_name, pivot=True)
                else:
                    est_table = f.load(raw_folder, est_vintage, geo, est_table_name)

                # Add the transformed estimate table to our list of tables
                est_tables.append(est_table)

            # Combine all the transformed estimate tables into one large table
            combined_table = pd.concat(est_tables, axis=1)

            # Since each of the estimates table has its own version of geo, "yr_id", remove those
            # duplicate columns
            combined_table = combined_table.loc[:, ~combined_table.columns.duplicated()]
        
            # NOTE: Save on memory by not storing/returning anything
            # # Store the combined table
            # combined_tables.append(combined_table)

            # Save the table if requested
            if(save):
                f.save(combined_table, save_folder, est_vintage, geo, "consolidated")
        
        # NOTE: Save on memory by not storing/returning anything                
        # # Return all the combined tables
        # return combined_tables

    def individual(self, est_vintage,
        geo_list=["region", "jurisdiction", "cpa"], 
        est_table_list=["age", "ethnicity", "household_income", "age_ethnicity", "age_sex_ethnicity"],
        save=False,
        save_folder=None):
        """Create individual files for each unique combination of Estimate table and geography level.

        Generate individual estimates tables for each input geography. This function returns one
        dataframe for each geography level / estimate table. Because of the way looping is done, the 
        order of dfs is first geo_level each estimate table, second geo_level each estimate table, etc.

        Args:
            est_vintage (str): The vintage of Estimates table to pull from. In DDAMWSQL16, this 
                variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]"
            geo_list (list of str): The geographies to consolidate along. 
            est_table_list (list of str): Which estimates tables we want to consolidate
            save (bool): False by default. If False, then only return the consolidated tables. If 
                True, then use save_folder to save the consolidated tables and return the tables
            save_folder (pathlib.Path): None by default. If save=True, then the folder to save in as a 
                pathlib.Path object

        Returns:
            None
        """
        # NOTE: Save on memory by not storing/returning anything
        # # Store each individual table by geography level x est_table_list here
        # individual_tables = []

        # Loop over the geography levels we want to get individual files on
        for geo in geo_list:

            # Loop over every estimate table we want to get
            for est_table_name in est_table_list:

                # Get the estimate table
                est_table = self.get_table_by_geography(est_vintage, geo, est_table_name, pivot=True)

                # NOTE: Save on memory by not storing/returning anything
                # # Store the individual table
                # individual_tables.append(est_table)

                # Save the table if requested
                # est_table may be a pd.dataframe split up into chunks, modify the behavior
                # accordingly
                if(save):
                    if((geo == "mgra") and (est_table_name in ["age_ethnicity", "age_sex_ethnicity"])):
                        header=True
                        for chunk in est_table:
                            chunk.to_csv(
                                save_folder / f"{f._file_path(est_vintage, geo, est_table_name)}csv",
                                header=header,
                                mode="a")
                            header=False
                    else:
                        f.save(est_table, save_folder, est_vintage, geo, est_table_name)

        # NOTE: Save on memory by not storing/returning anything                
        # # Return all the combined tables
        # return individual_tables

############################################
# CA Department of Finance Population Data #
############################################

class CA_DOF():
    """Functions to get CA Department of Finance population estimates from SQL.
    
    This class currently only has the functionality of getting region level population data from
    SQL. At some point, additional functionality will be added that gets population data split by
    age, sex, and ethnicity.
    """

    def get_CA_DOF_data(self, 
        dof_vintage="2021_07_14",
        save_folder=pathlib.Path("./data/raw_data/")):
        """Get and save region level population data from CA DOF.

        Due to the limited nature of the checks run on this, this function will only pull population
        data at the region level.
        
        Args:
            dof_vintage (str): Default value of "2021_07_14". What vintage of dof data to pull from.
                The input vintage will be used to access a table using the following f string:
                f"[socioec_data].[ca_dof].[population_proj_{dof_vintage}]"
            save_folder (pathlib.Path): The location where transformed CA DOF data should be saved.
                Currently, this function will only save, there is no option for returning data.

        Returns:
            None
        """
        # Create the connection to the SQL server
        DDAM = sql.create_engine('mssql+pymssql://DDAMWSQL16/')

        # The query
        query = textwrap.dedent(f"""\
            SELECT dof.county_fips_code, dof.fiscal_yr, SUM(dof.population) as population
            FROM [socioec_data].[ca_dof].[population_proj_{dof_vintage}] as dof
            WHERE county_fips_code='06073'
            GROUP BY dof.county_fips_code, dof.fiscal_yr
            ORDER BY dof.county_fips_code, dof.fiscal_yr ASC""")

        # Get the data into pandas
        data = pd.read_sql_query(query, con=DDAM)

        # Save the data
        # No additional processing needs to be done as the original database is already highly
        # simplified
        f.save(data, save_folder, "DOF", dof_vintage, "region", "population")

##############
# Diff Files #
##############

class DiffFiles():
    """Functions to return/save various Estimates diff tables.
    
    The functions in this class create diff files either directly from [DDAMWSQL16].[estimates] or
    from previously saved files. The output diff files will always be returned in case you want
    to hold them in memory. There is also an option to save the files at the specified location.
    The diff files can either be absolute change, percentage change, or both. As with the class
    Estimates Tables, the functions in this file do not run any checks.
    """

    def create_diff_tables(self, old_vintage, new_vintage, 
        raw_data_folder=pathlib.Path("./data/raw_data/"),
        geo_list=['region', 'jurisdiction', 'cpa'],
        est_table_list=['age', 'ethnicity', 'household_income', 'age_ethnicity', 'age_sex_ethnicity'],
        save=True,
        save_folder=pathlib.Path("./data/diff/")):
        """Create diff files from the old vintage to the new vintage.

        This function will create and save diff files for each unique combination of geo_list and 
        est_table_list. The saved diff files will be in the xlsx format with three sheets. The first
        sheet contains the old vintage data, the second sheet contains the new vintage data, and the
        third sheet contains (new vintage data - old vintage data), also know as the change from
        old vintage to new vintage.

        Args:
            old_vintage (str): The old vintage to compare with
            new_vintage (str): The new vintage to compare with.
            raw_data_folder (pathlib.Path): pathlib.Path("./data/raw_data/") by default. The 
                location where raw data has been saved. It is expected that the files are saved
                using functions.save in order to keep file formats consistent
            geo_list (list of str): The geographies to create diff files for. 
            est_table_list (list of str): Which estimates tables we want to create diff files.
                Because of the unique way file names are generated, a valid item of this list is
                "consolidated"
            save (bool): True by default. If True, then use save_folder to save the diff files. At
                this time, False has no functionality, but this may change later
            save_folder (pathlib.Path): pathlib.Path("./data/diff/") by default. The location to 
                save diff files

        Returns:
            None

        Raises:
            NotImplementedError: Raised if save=False. If this function is not saving files, then
                it is literally doing nothing
        """
        # Get the files that correspond to each vintage
        for geo in geo_list:
            for est_table in est_table_list:
                old_vintage_df = f.load(raw_data_folder, old_vintage, geo, est_table)
                new_vintage_df = f.load(raw_data_folder, new_vintage, geo, est_table)

                # Create the diff df
                # TODO: I cannot for the life of my figure out how to do a subtract when there
                # are string columns in a non-hacky way. Please help :(
                # diff_df = new_vintage_df - old_vintage_df
                diff_df = pd.DataFrame(columns=old_vintage_df.columns)
                for col_name, _ in diff_df.items():
                    try:
                        if(col_name == "yr_id"):
                            raise BaseException
                        diff_df[col_name] = new_vintage_df[col_name] - old_vintage_df[col_name]
                    except:
                        diff_df[col_name] = new_vintage_df[col_name]

                # Put the three dfs into a Dict for saving as a xlsx
                # Since Python 3.6, dictionaries are ordered based on the order in which key/values
                # were entered in.
                save_dict = {}
                save_dict[old_vintage] = old_vintage_df
                save_dict[new_vintage] = new_vintage_df
                save_dict[f"{new_vintage}-{old_vintage}"] = diff_df

                # Save using the generic function
                if(save):
                    f.save(save_dict, save_folder, f"{new_vintage}-{old_vintage}", geo, est_table)
                else:
                    raise NotImplementedError("save=False has no functionality.")

####################
# Proportion Files #
####################

class ProportionFiles():
    """Functions to compute categorical distributions within Estimates tables.
    
    By categorical distributions, we mean (for example) what percentage of the total population is
    split up between households vs group quarters. Or (for example) what percentage of Female people
    aged 10 to 14 in Carlsbad in 2010 were Hispanic vs Non-Hispanic, White vs Non-Hispanic, Black vs
    etc.
    """

    def create_proportion_tables(self, est_vintage, 
        geo_list=['region'],
        est_table_list=['age', "sex", 'ethnicity', 'household_income', 'age_ethnicity', 'age_sex_ethnicity'],
        raw_data_folder=pathlib.Path("./data/raw_data/"),
        save=True,
        save_folder=pathlib.Path("./data/proportion/")):
        """Create the row sum and column sum proportion tables.

        Specifically in the row sum tables, the each cell in the row is divided by the sum value in 
        the row. For the column sum tables, the cells for each year and column name are divided by
        the sum of those cells. For example, in the age_ethnicity table, we would take the San
        Diego region, the year 2010, and the column Hispanic. Then we would get the distribution
        of age groups for San Diego Hispanics in 2010.

        Args:
            est_vintage (str): The vintage to compute proportions for.
            geo_list (list of str): The geographies to create proportion files for. 
            est_table_list (list of str): Which estimates tables we want to create proportion files
                for.
            raw_data_folder (pathlib.Path): pathlib.Path("./data/raw_data/") by default. The 
                location where raw Estimates data has been saved
            save (bool): True by default. If True, then use save_folder to save the proportion 
                files. At this time, False has no functionality, but this may change later
            save_folder (pathlib.Path): pathlib.Path("./data/proportion/") by default. The location
                to save proportion files

        Returns:
            None

        Raises:
            NotImplementedError: Raised if save=False. If this function is not saving files, then
                it is literally doing nothing
        """
        # Get the files that correspond to each vintage
        for geo in geo_list:
            for est_table in est_table_list:
                table = f.load(raw_data_folder, est_vintage, geo, est_table)

                # Keep track of the key value columns
                keys = [geo, "yr_id"]
                if(est_table == "age_ethnicity"):
                    keys += ["name"]
                elif(est_table == "age_sex_ethnicity"):
                    keys += ["name", "sex"]

                # Compute the row wise sums then compute the proportions (actually a percentage 
                # (note the 100 *), but oh well)
                row_prop = table.copy(deep=True)
                row_totals = row_prop.drop(keys, axis=1).sum(axis=1)
                row_prop.iloc[:,len(keys):] = \
                    100 * row_prop.iloc[:,len(keys):].divide(row_totals, axis=0) 
                
                # Compute the column wise proportions. As stated in the function description, our
                # populations are considered to be only the grouping geography and year
                # NOTE: Column wise proportions only make sense when the data is broken down more
                # than just geography and year. As such, this is only done for age_ethnicity and
                # age_sex_ethnicity
                column_prop = None
                if(est_table == "age_ethnicity" or est_table == "age_sex_ethnicity"):
                    column_prop = table.copy(deep=True)
                    column_prop.iloc[:,len(keys):] /= 100 * \
                        column_prop.groupby([geo, "yr_id"])[column_prop.columns[len(keys):]].transform("sum")
                
                # Save using the generic function
                if(save):
                    f.save(row_prop, save_folder, est_vintage, geo, f"{est_table}_row_prop")
                    if(est_table == "age_ethnicity" or est_table == "age_sex_ethnicity"):
                        f.save(column_prop, save_folder, est_vintage, geo, f"{est_table}_col_prop")
                else:
                    raise NotImplementedError("save=False has no functionality.")
