# Libraries 
import numpy as np
import pandas as pd
import pyodbc

# Staging Data (SQL)
conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                    'Server=DDAMWSQL16.sandag.org;'
                    'Database=ws;'
                    'Trusted_Connection=yes;')

def download_and_clean_employment_center_data(conn):
    query = """
            -- EC List Info 
            SELECT [employment_center_id],
                [employment_center_name],
                [tier],
                [parent]
            FROM [ws].[employment_centers].[dim_employment_center_2]
            """
    ec_list =  pd.read_sql_query(query, conn)

    ec_list['Type'] = np.where((ec_list['tier'] == 0) & (ec_list['parent'].isna()), 'Combined Center',
                            np.where((ec_list['tier'] == 0) & (~ec_list['parent'].isna()), 'Sub-Center',
                                     np.nan))
    ec_list['Type'].replace('nan', np.nan, inplace=True)
    ec_list = ec_list.rename(columns={'employment_center_id': 'EC_ID', 'employment_center_name': 'EC_Name', 'tier': 'Tier', 'parent':'Parent'})
    
    ec_list.sort_values("EC_ID", ascending=True, inplace=True)

    return ec_list

# Takes in from above 
def ec_by_land_area_transformations(ec_list):

    query = """
            -- Land Area (in square miles) 
            DECLARE	@return_value int

            EXEC	@return_value = [employment_centers].[sp_land_area]
                    @release_id = 2
            """

    EC_by_Land_Area_SQL =  pd.read_sql_query(query, conn)


    ec_sq_miles_dict = dict(zip(EC_by_Land_Area_SQL.employment_center_id, EC_by_Land_Area_SQL.sq_miles))

    ec_list['Area_Sq_Mi'] = ec_list['EC_ID'].map(ec_sq_miles_dict)

    return ec_list

# Takes in from above 
def pop_by_type_transformations(ec_list):
    query = """
        -- Population by HH & GQ
        DECLARE	@return_value int

        EXEC	@return_value = [employment_centers].[sp_demographics_by_center]
                @release_id = 2,
                @demographic_warehouse_datasource_id = 45,
                @year = 2021
        """

    Pop_by_Type_SQL =  pd.read_sql_query(query, conn)

    pop_by_type_clean = Pop_by_Type_SQL[['employment_center_id', 'long_name', 'pop']]

    pop_by_type_pivot = pd.pivot_table(pop_by_type_clean, index='employment_center_id', columns='long_name', values='pop')
    pop_by_type_pivot['Total'] = pop_by_type_pivot.sum(axis=1)
    pop_by_type_pivot.columns.name = ''
    pop_by_type_pivot = pop_by_type_pivot.rename(columns={'Total':'Pop_Total', 'Household Population':'Pop_HH', 'Group Quarters - Military':'GQ_Mil', 'Group Quarters - College': 'GQ_Col', 'Group Quarters - Other': 'GQ_Oth'})
    pop_by_type_pivot['Pop_GQ'] = pop_by_type_pivot['GQ_Mil'] + pop_by_type_pivot['GQ_Col'] + pop_by_type_pivot['GQ_Oth']
    pop_by_type_pivot = pop_by_type_pivot[['Pop_Total', 'Pop_HH', 'Pop_GQ', 'GQ_Mil', 'GQ_Col', 'GQ_Oth']]
    pop_by_type_pivot['Pop_HH_%'] = round(pop_by_type_pivot['Pop_HH'] / pop_by_type_pivot['Pop_Total'], 4)*100
    pop_by_type_pivot['Pop_GQ_%'] = round(pop_by_type_pivot['Pop_GQ'] / pop_by_type_pivot['Pop_Total'], 4)*100 
    pop_by_type_pivot['GQ_Mil_%'] = round(pop_by_type_pivot['GQ_Mil'] / pop_by_type_pivot['Pop_Total'], 4)*100
    pop_by_type_pivot['GQ_Col_%'] = round(pop_by_type_pivot['GQ_Col'] / pop_by_type_pivot['Pop_Total'], 4)*100
    pop_by_type_pivot['GQ_Oth_%'] = round(pop_by_type_pivot['GQ_Oth'] / pop_by_type_pivot['Pop_Total'], 4)*100

    return pd.merge(ec_list, pop_by_type_pivot, how = 'inner', left_on='EC_ID', right_index=True)


