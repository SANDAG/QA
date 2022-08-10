# Eric Liu
# 
# Run some tests on the three functions in "estimates_automation.py". In reality, this function 
# only runs tests on "get_table_by_geography", as the other two functions have bare minimum logic
# at this point.
#
# To run tests, pytest is required, you can install with "pip install pytest". To run the tests, 
# type in your command line "pytest" in the folder this file exists in.
# 
# Updated: August 10, 2022

###########
# Imports #
###########

import json

import sqlalchemy as sql

import estimates_automation as ea

####################
# Global Variables #
####################

# These variables are used in basically every single test
DDAM = sql.create_engine('mssql+pymssql://DDAMWSQL16')
CONFIG = None
with open("./config.json", "r") as f:
    CONFIG = json.load(f)
EST_TABLES = ["age", "ethnicity", "household_income", "households", "housing", 
    "population", "sex", "age_sex_ethnicity", "age_ethnicity"] 

#########
# Tests #
#########

class Test_get_table_by_geography():
    """
    Runs a whole bunch of different tests (that I can think of) on the function 
    "get_table_by_geography".
    """
    # Not necessary as other tests baiscally do this already
    # def test_any_errors(self):
    #     # Test that no errors are raised in any of the estimates tables, at the geography level of
    #     # region
    #     for table_name in EST_TABLES:
    #         ea.get_table_by_geography(DDAM, CONFIG, table_name, "region")

    #     # Do the same for pivot tables
    #     for table_name in EST_TABLES:
    #         ea.get_table_by_geography(DDAM, CONFIG, table_name, "region", pivot=True)

    def test_no_multi_index_cols(self):
        # Test that no multi-indicies nor multi-columns exist in any of the output tables
        for table_name in EST_TABLES:
            table = ea.get_table_by_geography(DDAM, CONFIG, table_name, "region")
            assert (table.index.nlevels == 1)
            assert (table.columns.nlevels == 1)

        # Do the same for pivot tables
        for table_name in EST_TABLES:
            table = ea.get_table_by_geography(DDAM, CONFIG, table_name, "region", pivot=True)
            assert (table.index.nlevels == 1)
            assert (table.columns.nlevels == 1)

    # TODO: More tests if I can find the time