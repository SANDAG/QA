# Libraries
import numpy as np
import pandas as pd
import pyodbc
import warnings
warnings.filterwarnings("ignore", category=UserWarning)


def estimates_mgra_denormalize():
    # Staging Data (SQL)
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                          'Server=DDAMWSQL16.sandag.org;'
                          'Database=ws;'
                          'Trusted_Connection=yes;')

    query = """
    SELECT [mgra_id]
        ,[mgra]
    FROM [estimates].[est_2022_01].[mgra_denormalize]
    """
    return pd.read_sql_query(query, conn)


def geodepot_layer():
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                          'Server=sql2014b8.sandag.org;'
                          'Database=GeoDepot;'
                          'Trusted_Connection=yes;')

    query = """
    SELECT
        [MGRA]
        ,[CT20] AS 'census_tract'
        ,[City] AS 'jurisdiction_id'
        ,[CPA] AS 'cpa_id'
        ,[LUZ]
    FROM [GeoDepot].[gis].[MGRA15]
    """
    return pd.read_sql_query(query, conn)


def cpa_crosswalk():
    # Staging Data (SQL)
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                          'Server=DDAMWSQL16.sandag.org;'
                          'Database=demographic_warehouse;'
                          'Trusted_Connection=yes;')

    query = """
    SELECT DISTINCT 
        [cpa_id]
        ,[cpa]
    FROM [demographic_warehouse].[dim].[mgra_denormalize]
    WHERE series = 14
    """
    return pd.read_sql_query(query, conn)


def jurisdiction_crosswalk():
    # Staging Data (SQL)
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                          'Server=DDAMWSQL16.sandag.org;'
                          'Database=demographic_warehouse;'
                          'Trusted_Connection=yes;')

    query = """
    SELECT DISTINCT 
        [jurisdiction_id]
        ,[jurisdiction]
    FROM [demographic_warehouse].[dim].[mgra_denormalize]
    WHERE series = 14
    """
    return pd.read_sql_query(query, conn)


def create_and_merge_all_data():
    output = estimates_mgra_denormalize().merge(
        geodepot_layer(), how='left', left_on='mgra', right_on='MGRA')
    output = output.merge(cpa_crosswalk(), how='left',
                          left_on='cpa_id', right_on='cpa_id')
    output = output.merge(jurisdiction_crosswalk(),
                          how='left', on='jurisdiction_id')
    output = output.drop(['cpa_id', 'jurisdiction_id', 'MGRA'], axis=1)
    return output
