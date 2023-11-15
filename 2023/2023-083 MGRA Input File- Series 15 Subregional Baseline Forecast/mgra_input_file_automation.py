import os
import pandas as pd
import numpy as np
import pyodbc

# Import Data
def import_mgra_based_data(path):
    df = pd.read_csv(path)

    # I will be rolling up values using the mgra denorm file, so I can drop these columns
    if 'taz' in list(df.columns):
        df = df.drop(['taz'], axis=1)
    if 'LUZ' in list(df.columns):
        df = df.drop(['LUZ'], axis=1)
    return df


# Download sql_data
def download_mgra_denorm_data(geo_level, series):
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                    'Server=DDAMWSQL16.sandag.org;'
                    'Database=estimates;'
                    'Trusted_Connection=yes;')
    if series == 14:
        with open(rf'sql_queries\mgra_denorm_series14.sql', 'r') as sql_file:
            sql_query = sql_file.read()
    
    if series == 15:
        with open(rf'sql_queries\mgra_denorm.sql', 'r') as sql_file:
            sql_query = sql_file.read()
    
    return  pd.read_sql_query(sql_query, conn)[['mgra', geo_level]]


# Add CPA names
def add_cpa_names(cpa_df, series):
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                    'Server=DDAMWSQL16.sandag.org;'
                    'Database=estimates;'
                    'Trusted_Connection=yes;')
    if series == 14:
        with open(rf'sql_queries\mgra_denorm_series14.sql', 'r') as sql_file:
            sql_query = sql_file.read()
    
    if series == 15:
        with open(rf'sql_queries\mgra_denorm.sql', 'r') as sql_file:
            sql_query = sql_file.read()
    
    lookup = pd.read_sql_query(sql_query, conn)[['cpa', 'cpa_name']].drop_duplicates()
    
    return cpa_df.reset_index().merge(lookup, how='right', on = 'cpa')



# Merge and Aggregate Data
def merge_and_aggregate(mgra_input_file, mgra_denorm, geo_level):
    df = pd.merge(mgra_denorm, mgra_input_file, how='left')

    if geo_level != 'mgra':
        df = df.drop('mgra', axis=1)

    if 'year' in list(df.columns):
        df = df.groupby([geo_level, 'year']).sum()
    else:
        df = df.groupby(geo_level).sum()

    return df

def hhs_adjustment(df):
    """Adjusts hhs values, returns the adjusted dataframe"""
    df['hhs'] = df['hhp']/df['hh']
    df['vacancy'] = df['hs'] - df['hh']
    df['vacancy_rate'] = df['vacancy']/df['hs']
    return df

def export_data(output_folder_path, geo_level, version, df):
    df.to_excel(output_folder_path + f"\mgra_based_input_{geo_level}_{version}.xlsx")
    
def create_mgra_denorm_table(mgra_denorm_path, geo_level, version, series, output_folder_path = False):
    '''
    In all paths add the 'r' command before the string
    If you do not want the data outputted set output_folder_path to False'''

    if type(mgra_denorm_path) != str:
        df_1 = mgra_denorm_path
    else:
        df_1 = import_mgra_based_data(path = mgra_denorm_path)

    df_2 = download_mgra_denorm_data(geo_level=geo_level, series=series)

    df_3 = merge_and_aggregate(mgra_input_file=df_1, mgra_denorm=df_2, geo_level=geo_level)

    df_4 = hhs_adjustment(df_3)
    
    if output_folder_path != False:
        export_data(output_folder_path=output_folder_path, geo_level=geo_level, version=version, df=df_4)

    return df_4