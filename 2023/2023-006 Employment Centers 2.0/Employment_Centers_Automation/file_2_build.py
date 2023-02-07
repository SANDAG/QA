# Libraries
import os
import numpy as np
import pandas as pd
import pyodbc
import copy
import warnings
warnings.filterwarnings("ignore")


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
            FROM [ws].[employment_centers].[dim_employment_center_2.0]
            """
    ec_list = pd.read_sql_query(query, conn)

    ec_list['Type'] = np.where((ec_list['tier'] == 0) & (ec_list['parent'].isna()), 'Combined Center',
                               np.where((ec_list['tier'] == 0) & (~ec_list['parent'].isna()), 'Sub-Center',
                                        np.nan))
    ec_list['Type'].replace('nan', np.nan, inplace=True)
    return ec_list.set_index('employment_center_id').sort_index(ascending=True)


def avg_wage_grab(conn):
    query = """
        DECLARE	@return_value int

        EXEC	@return_value = [employment_centers].[sp_avg_wage_by_center]
                @release_id = 2
        """

    return pd.read_sql_query(query, conn)[['employment_center', 'avg_wage']].set_index('employment_center')


def download_jt_data(JT_Val, conn):
    """
    Downloads the proper JTtable
    Input opitons are: 'JT00' and 'JT02' 
    """
    query = f"""
    DECLARE	@return_value int

    EXEC	@return_value = [employment_centers].[sp_wac_characteristics_by_center_{JT_Val}]
            @release_id = 2
    """

    return pd.read_sql_query(query, conn)


def build_df_and_find_percentages(SQL_Data, is_all):
    # Cleaning
    sql_prep = copy.deepcopy(SQL_Data)
    sql_prep = sql_prep.drop(['tier', 'employment_center_name'], axis=1)
    sql_prep = sql_prep.set_index('employment_center_id')

    # Drop columns that sum to zero, should only effect JT00
    to_drop = sql_prep.columns[(sql_prep == 0).all()].tolist()
    sql_prep = sql_prep.drop(columns=to_drop)

    # Grab and delete total
    total = sql_prep['jobs']
    sql_prep = sql_prep.drop('jobs', axis=1)

    output_df = pd.DataFrame(index=sql_prep.index)

    # Check and set status of employment level that we are looking at
    if is_all:
        employment_status = 'All_Jobs'
    else:
        employment_status = 'Priv_Jobs'

    # Set the core columns
    for col in sql_prep.columns:
        output_df[f"{employment_status}_{col}"] = sql_prep[col]

    # Calculate the remaining columns
    for col in sql_prep.columns:
        if 'educ30' in col:
            output_df[f"{employment_status}_%_{col}"] = round(
                sql_prep[col] / (total-sql_prep['age_lt30']), 4) * 100
        else:
            output_df[f"{employment_status}_%_{col}"] = round(
                sql_prep[col] / total, 4) * 100

    output_df.insert(0, f'{employment_status}_Total', total)

    output_df = output_df.sort_index(ascending=True)

    return output_df


def main():
    ec_list = download_and_clean_employment_center_data(conn)
    JT00 = download_jt_data(JT_Val='JT00', conn=conn)
    print('JT00 is downloaded')
    JT02 = download_jt_data(JT_Val='JT02', conn=conn)
    print('JT02 is downloaded')
    averge_wage = avg_wage_grab(conn)
    print('Average wage downloaded')

    print('Now Processing JT00 and JT02 Data')
    processed_JT00 = build_df_and_find_percentages(JT00, is_all=True)
    processed_JT02 = build_df_and_find_percentages(JT02, is_all=False)

    output = ec_list.merge(processed_JT00, how='left', left_index=True, right_index=True).merge(
        processed_JT02, how='left', left_index=True, right_index=True).merge(averge_wage, how='left', left_index=True, right_index=True)

    output.fillna(0, inplace=True)

    return output


# output = main()
# print(output)

def create_output():
    # Get the path to the Downloads folder
    downloads_folder = os.path.join(os.path.expanduser("~"), "Downloads")

    print('File 2 Output Creation Beginning')
    # Create a sample data frame
    df = main()

    # Write the data frame to a CSV file in the Downloads folder
    df.to_csv(os.path.join(downloads_folder, "file_2.csv"), index=True)


if __name__ == '__main__':
    create_output()
