import numpy as np
import pandas as pd
import yaml
import pyodbc

# -------------------------- Class: Configuration functions

# Download and concatonate files from T drive


def download_and_concat_Tdrive_files(dsid, desired_data):
    """
    Downloads all of the files from T drive for this particular dsid and adds the year
    desired_data input options: 'T_Drive_files', 'Household_Files', 'Person_Files' 

    """

    with open('ds_config_2.yml', "r") as yml_file:
        config = yaml.safe_load(yml_file)

    concatonated_dfs = pd.DataFrame()

    for key, path in config[dsid][desired_data].items():
        temp_df = pd.read_csv(path)
        temp_df['year'] = key[-4:]
        concatonated_dfs = pd.concat([concatonated_dfs, temp_df])

    return concatonated_dfs

# mgra_vacancy_additions

# mgra_school_pop_additions

# mgra_age_pop_additions

# mgra_ethn_pop_additions

# mgra_sex_pop_additions

# MGRA output


def mgra_output(dsid, to_jdrive):
    output = download_and_concat_Tdrive_files(dsid, 'T_Drive_files')
    output.insert(1, 'year', output.pop('year'))
    if to_jdrive:
        print('outputting')
        output.to_csv(
            rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\aggregated_data\mgra_DS{dsid}_ind_QA.csv", index=False)
    return output


# Download the data function
def download_ind_file(dsid, geo_level):
    output = pd.read_csv(
        rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\aggregated_data\{geo_level}_DS{dsid}_ind_QA.csv")

    return output

# Make adjustments to specific, specified columns that need it - should work at all levels
# HHS Adjusment


def hhs_adjustment(df):
    """Adjusts hhs values, returns the adjusted dataframe"""
    df['hhs'] = df['hhp']/df['hh']
    return df

# Find columns that we want at particular geography levels


def wanted_geography_cols(df, geo_level):
    """This function takes in the dataframe you would like to fold up and the geography level you would like to fold up to. This function then outputs the columns in the dataframe that can be rolled up, dropping other geography specific columns."""
    geography_levels = ['mgra', 'cpa', 'luz', 'LUZ', 'census_tract', 'zip', 'sra',
                        'jurisdiction', 'luz_id', 'taz', 'region']
    geography_levels.remove(geo_level)

    return [col for col in df.columns if col not in geography_levels]

# mgra denormalize


def download_mgra_denorm_data(geo_level):
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                          'Server=DDAMWSQL16.sandag.org;'
                          'Database=demographic_warehouse;'
                          'Trusted_Connection=yes;')

    mgra_denorm_query = '''SELECT [mgra_id]
      ,denorm_table.[mgra]
	  ,[tract] AS 'census_tract'
	  ,[cpa]
      ,taz
	  ,[jurisdiction]
	  ,[sra]
	  ,geo_depot_mgra15.LUZ AS 'luz'
      ,[region]
  FROM [demographic_warehouse].[dim].[mgra_denormalize] AS denorm_table
  LEFT OUTER JOIN OPENQUERY([sql2014b8], 'SELECT [MGRA], [LUZ] FROM [GeoDepot].[gis].[MGRA15]') geo_depot_mgra15
	ON denorm_table.mgra = geo_depot_mgra15.MGRA
  WHERE series = 15'''

    return pd.read_sql_query(mgra_denorm_query, conn)[['mgra', geo_level]]

# Roll up code:


def rollup_data(dsid, geo_level, to_jdrive):
    df = download_ind_file(dsid=dsid, geo_level='mgra')
    # This is so in the merge we with mgradenormalize we don't get something like 'taz_x' and 'taz_y'
    columns_to_drop = ['taz', 'luz', 'LUZ']
    df = df.drop([col for col in columns_to_drop if col in df.columns], axis=1)

    mgra_denorm_table = download_mgra_denorm_data(geo_level=geo_level)

    temp_df = df.merge(mgra_denorm_table, on='mgra', how='left')
    temp_df = temp_df.drop('mgra', axis=1)
    temp_df = temp_df.groupby([geo_level, 'year']).sum().reset_index()

    final_output_columns = wanted_geography_cols(
        df=temp_df, geo_level=geo_level)

    final_output = temp_df[final_output_columns]

    final_output = hhs_adjustment(final_output)

    if to_jdrive:
        final_output.to_csv(
            rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\aggregated_data\{geo_level}_DS{dsid}_ind_QA.csv", index=False)

    return final_output

# -------------------- Class Manipulation Functions:

# Common values function


def common_values(series1, series2):
    """Take in two pandas series objects (generally dataframe columns) and outputs a list of the similar values."""
    series1 = list(set(series1))
    series2 = list(set(series2))

    common_values = [value for value in series1 if value in series2]

    return common_values


# DF Comparison Function - checking shape and columns and such, returns similar columns

# Check to see if the desired output exists

# Create Both file


def create_both_df(dsid_1, dsid_2, geo_level, to_jdrive):
    df1 = download_ind_file(dsid_1, geo_level)
    df2 = download_ind_file(dsid_2, geo_level)

    # Adjust for common years
    common_years = common_values(df1['year'], df2['year'])
    df1 = df1[df1['year'].isin(common_years)]
    df2 = df2[df2['year'].isin(common_years)]

    # Adjust for common geography levels
    common_geographies = common_values(df1[geo_level], df2[geo_level])
    df1 = df1[df1[geo_level].isin(common_geographies)]
    df2 = df2[df2[geo_level].isin(common_geographies)]

    # Set necessary index
    df1 = df1.set_index([geo_level, 'year'])
    df2 = df2.set_index([geo_level, 'year'])

    # Merge them based on the index
    output = pd.merge(df1, df2, left_index=True, right_index=True,
                      how='left', suffixes=(f'_{dsid_1}', f'_{dsid_2}'))

    if to_jdrive:
        output.to_csv(
            f"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\both_files\{geo_level}_both_DS{dsid_1}__DS{dsid_2}_QA.csv", index=True)

    return output


def common_columns_names_in_order(df, dsid, geo_level):
    """This function takes all of the columns from the inputted dataframe and outputs these columns in the correct order according to the order of the original input files"""
    current_headers = df.columns

    correct_headers = pd.read_csv(
        rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\aggregated_data\{geo_level}_DS{dsid}_ind_QA.csv", nrows=0).columns

    return [header for header in correct_headers if header in current_headers]

# Create Diff File


def create_diff_df(dsid_1, dsid_2, geo_level, to_jdrive):
    df1 = download_ind_file(dsid_1, geo_level)
    df2 = download_ind_file(dsid_2, geo_level)

    # Adjust for common years
    common_years = common_values(df1['year'], df2['year'])
    df1 = df1[df1['year'].isin(common_years)]
    df2 = df2[df2['year'].isin(common_years)]

    # Adjust for common geography levels
    common_geographies = common_values(df1[geo_level], df2[geo_level])
    df1 = df1[df1[geo_level].isin(common_geographies)]
    df2 = df2[df2[geo_level].isin(common_geographies)]

    # Remove other geography related columns
    # It doesn't matter which df goes inside
    wanted_columns = wanted_geography_cols(df1, geo_level)
    df1 = df1[wanted_columns]
    df2 = df2[wanted_columns]

    # Common Columns
    common_columns = common_values(df1.columns, df2.columns)
    df1 = df1[common_columns]
    df2 = df2[common_columns]

    # Set necessary index
    df1 = df1.set_index([geo_level, 'year'])
    df2 = df2.set_index([geo_level, 'year'])

    # Drop non-numeric columns
    df1 = df1.select_dtypes(include='number')
    df2 = df2.select_dtypes(include='number')

    # Ensure columns are identical
    assert sum(~(df1.columns == df2.columns)) == 0

    # Create the diff file
    output = df1.subtract(df2)

    # Order the columns according to original files - It doesn't matter which DSID is inputted
    correctly_ordered_columns_df = output.reset_index()[common_columns_names_in_order(
        output.reset_index(), dsid_1, geo_level)]

    correctly_ordered_columns_df = correctly_ordered_columns_df.set_index([
                                                                          geo_level, 'year'])
    if to_jdrive:
        correctly_ordered_columns_df.to_csv(
            f"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\diff_files\{geo_level}_diff_DS{dsid_1}_minus_DS{dsid_2}_QA.csv", index=True)

    return correctly_ordered_columns_df


# ---------------------- Class Other Outpus

# Number of persons (from households) at MGRA level depending on GQ preference


def population_from_households_dataset(dsid, gq_only, no_gq):
    '''Downloads and aggregates population data from the households dataset depending on inputted GQ preference.'''
    # From households file
    household_file_all = download_and_concat_Tdrive_files(
        dsid, 'Household_Files')
    household_file_subset = household_file_all[['year', 'mgra', 'persons']]
    household_file_subset['year'] = pd.to_numeric(
        household_file_subset['year'])

    if gq_only:
        household_file_subset = household_file_subset[household_file_all['unittype'] == 1]
    elif no_gq:
        household_file_subset = household_file_subset[household_file_all['unittype'] == 0]

    population_household_file = household_file_subset.groupby(
        ['year', 'mgra']).sum().reset_index()
    population_household_file.columns = [
        'year', 'mgra', 'pop_count_household_file']
    return population_household_file

# Combine with the mgra file (will need other files created) - create the diff -- population


def population_comparison_households_and_input_files(dsid, gq_only, no_gq, to_jdrive):
    '''Compare MGRA population data to household dataset population data based on gq preference.'''
    # Input Files
    mgra_data = pd.read_csv(rf'J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\aggregated_data\mgra_DS{dsid}_ind_QA.csv', usecols=[
                            'year', 'mgra', 'pop', 'hhp'])
    mgra_data['gq_pop_input_files'] = mgra_data['pop'] - mgra_data['hhp']

    # gq_only = True , no_gq = False
    if (gq_only == no_gq) & (gq_only == False):
        mgra_data = mgra_data[['mgra', 'year', 'pop']]
        output_type = 'all'
    elif gq_only:
        mgra_data = mgra_data[['mgra', 'year', 'gq_pop_input_files']]
        output_type = 'GQ_only'
    else:
        mgra_data = mgra_data[['mgra', 'year', 'hhp']]
        output_type = 'no_GQ'

    # Concatonate and merge
    output = population_from_households_dataset(dsid, gq_only, no_gq).merge(
        mgra_data, how='left', on=['mgra', 'year'])
    output.columns = ['year', 'mgra',
                      'pop_count_household_file', 'pop_input_files']
    output['Diff'] = output['pop_count_household_file'] - \
        output['pop_input_files']

    if to_jdrive:
        output.to_csv(
            rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\other_outputs\mgra_households_dataset_population_comparison_{output_type}_DS{dsid}_QA.csv", index=False)

    return output


# Number of households (from households) at MGRA level -- use the T drie function grabber


def number_of_households_from_households_dataset(dsid):
    '''Downloads and aggregates number of households data from the households dataset for Non-GQ households.'''
    household_file_all = download_and_concat_Tdrive_files(
        dsid, 'Household_Files')
    household_file_subset = household_file_all[['year', 'mgra', 'hhid']]
    household_file_subset['year'] = pd.to_numeric(
        household_file_subset['year'])

    # Non-GQ
    household_file_no_gq = household_file_subset[household_file_all['unittype'] == 0]
    household_count_household_file_no_gq = household_file_no_gq.groupby(
        ['year', 'mgra']).count().reset_index()
    household_count_household_file_no_gq.columns = [
        'year', 'mgra', 'house_count_household_file']

    return household_count_household_file_no_gq


# Combine with the MGRA file -- number of households
def household_number_comparison_houseolds_and_input_files(dsid, to_jdrive):
    '''Compare number of households between input files and households dataset. Only at the 'No GQ' level.'''
    # Bring in input files and process
    mgra_data = pd.read_csv(rf'J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\aggregated_data\mgra_DS{dsid}_ind_QA.csv', usecols=[
                            'year', 'mgra', 'hh'])
    mgra_data = mgra_data.rename(columns={'hh': 'hh_count_input_files'})

    output = number_of_households_from_households_dataset(dsid).merge(
        mgra_data, how='left', on=['year', 'mgra'])
    output = output[['mgra', 'year',
                     'house_count_household_file', 'hh_count_input_files']]
    output['Diff'] = output['house_count_household_file'] - \
        output['hh_count_input_files']
    if to_jdrive:
        output.to_csv(
            rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\other_outputs\mgra_households_dataset_hh_count_comparison_no_GQ_DS{dsid}_QA.csv", index=False)
    return output


# ------------------------ Class Persons and Household Dataset Checks


def download_individual_persons_file(dsid, year):
    """Downloads an individual person file for one particular year. Year is a string value."""

    with open('ds_config_2.yml', "r") as yml_file:
        config = yaml.safe_load(yml_file)

    file_path = config[dsid]['Person_Files'][f'DS{dsid}_persons_{year}']
    return pd.read_csv(file_path, usecols=['hhid', 'miltary'])


def download_individual_households_file_for_person_comp(dsid, year):
    """Downloads an individual person file for one particular year. Year is a string value."""

    with open('ds_config_2.yml', "r") as yml_file:
        config = yaml.safe_load(yml_file)

    file_path = config[dsid]['Household_Files'][f'DS{dsid}_households_{year}']
    return pd.read_csv(file_path, usecols=['hhid', 'persons', 'unittype'])


def persons_dataset_hhid_population(dsid, year, gq_only):
    persons_df = download_individual_persons_file(dsid, year)

    if gq_only:
        persons_df = persons_df[persons_df['miltary'] == 1]

    persons_df = persons_df.groupby('hhid').count()
    persons_df.columns = ['Persons_Dataset_Pop']

    return persons_df.reset_index()


def persons_households_dataset_pop_comparison(dsid, year, gq_only):
    """This functions joins the persons and household data together and compares population figures."""
    persons_df = persons_dataset_hhid_population(dsid, year, gq_only)
    households_df = download_individual_households_file_for_person_comp(
        dsid, year)

    if gq_only:  # This gets handled for persons in the "persons_dataset_hhid_population" function
        households_df = households_df[households_df['unittype'] == 1]

    # Rename Household df
    households_df = households_df.rename(
        columns={'persons': 'Households_Dataset_Pop'})

    # Grab columns of interest
    persons_df = persons_df[['hhid', 'Persons_Dataset_Pop']]
    households_df = households_df[['hhid', 'Households_Dataset_Pop']]

    # Combine
    output = persons_df.merge(households_df, how='left', on='hhid')

    # Diff
    output['Diff_P_minus_H'] = output['Persons_Dataset_Pop'] - \
        output['Households_Dataset_Pop']

    # Add year
    output['year'] = year

    return output


def find_individual_years_for_dsid(dsid):
    "Takes in a dsid and returns a list of years that this dsid covers."
    with open('ds_config_2.yml', "r") as yml_file:
        config = yaml.safe_load(yml_file)

    t_drive_file_keys = config[dsid]['T_Drive_files'].keys()

    return [x[-4:] for x in t_drive_file_keys]


def aggregate_persons_households_population_comparison(dsid, gq_only, to_jdrive):
    """Compares population numbers between household csv and population csv"""
    concatonated_dfs = pd.DataFrame()

    for year in find_individual_years_for_dsid(dsid):
        temp_df = persons_households_dataset_pop_comparison(
            dsid, year, gq_only)
        concatonated_dfs = pd.concat([concatonated_dfs, temp_df])
        del temp_df
        print(f"{year} is complete")

    if gq_only:
        gq_status = 'gq_only'
    else:
        gq_status = 'all'

    if to_jdrive:
        concatonated_dfs.to_csv(
            rf"J:\DataScience\DataQuality\QAQC\Forecast QC Automation\mgra_series_15\other_outputs\DS{dsid}_persons_household_population_comparison_{gq_status}_QA.csv", index=False)

    return concatonated_dfs


# ------------------------ Class QC Checks
def check_internal_consistency(df):
    # Define the total and breakdown columns
    columns_dict = {
        'pop': ['hhp', 'gq'],
        'gq': ['gq_civ', 'gq_mil'],
        'gq_civ': ['gq_civ_college', 'gq_civ_other'],
        'hs': ['hs_sf', 'hs_mf', 'hs_mh'],
        'hh': ['hh_sf', 'hh_mf', 'hh_mh'],
        'emp_tot': ['emp_civ', 'emp_mil'],
        'emp_civ': ['emp_gov', 'emp_ag_min', 'emp_bus_svcs', 'emp_fin_res_mgm', 'emp_educ', 'emp_hlth', 'emp_ret', 'emp_trn_wrh', 'emp_con', 'emp_utl', 'emp_mnf', 'emp_whl', 'emp_ent', 'emp_accm', 'emp_food', 'emp_oth'],
        'hh_income': ['i1', 'i2', 'i3', 'i4', 'i5', 'i6', 'i7', 'i8', 'i9', 'i10']
    }

    inconsistencies = []

    # Loop through the columns and check consistency
    for total_column, breakdown_columns in columns_dict.items():
        if total_column == 'hh_units':
            total_column = 'hh'
        elif total_column == 'hh_income':
            total_column = 'hh'
        expected_value = df[breakdown_columns].sum(axis=1)
        difference = df[total_column] - expected_value

        # Check if any rows have a difference
        inconsistent_rows = difference[difference != 0]
        for index, value in inconsistent_rows.items():
            inconsistencies.append({
                # Added 'year' column to the output
                'year': df['year'].iloc[index],
                'breakdown_columns': ', '.join(breakdown_columns),
                'row value': index,
                'expected': df[total_column].iloc[index],
                'found': expected_value.iloc[index],
                'difference': value
            })

    # If inconsistencies were found, print them as a DataFrame
    if inconsistencies:
        print('There are internal inconsistencies - run individually to collect dataframe')
        inconsistencies_df = pd.DataFrame(inconsistencies)
        return inconsistencies_df
    # else:
        print("Internal consistency has passed!")


def validate_df(input_df, regional_control_df):
    # Group input_df by year and sum the relevant columns
    grouped_df = input_df.groupby(
        'year')[['pop', 'gq', 'hh']].sum().reset_index()

    # Merge with the regional_control_df on 'year' to compare the values
    merged_df = pd.merge(grouped_df, regional_control_df[[
                         'year', 'pop', 'gq', 'hh']], on='year', how='left', suffixes=('', '_regional'))

    # Check if the values match
    inconsistencies = []
    for _, row in merged_df.iterrows():
        if row['pop'] != row['pop_regional']:
            inconsistencies.append(
                (row['year'], 'pop', row['pop'], row['pop_regional']))
        if row['gq'] != row['gq_regional']:
            inconsistencies.append(
                (row['year'], 'gq', row['gq'], row['gq_regional']))
        if row['hh'] != row['hh_regional']:
            inconsistencies.append(
                (row['year'], 'hh', row['hh'], row['hh_regional']))

    if inconsistencies:
        print("Found inconsistencies:")
        for year, col, actual, expected in inconsistencies:
            print(
                f"Year {year}, Column {col}: Expected {expected}, Found {actual}")
    else:
        print("All values match!")


# Check to see which aggregate files still need to be created (return a list), comparison with what we have in our config file
# Could also check which diff files also need to be created
# TODO: Update config file to have persons and household datasets
# TODO: Python doesn't like the way that I do this: household_file_subset['year'] = pd.to_numeric(
'''
ideas:
- Could have that SQL connection setup in a yml file, have a seperate yml file for more input related things (Or just build a function for majority of SQL stuff and I just pass in the query or something?)
- for functions that take in a dataframe (like the Qc ones, I could have a function that checks in the index has been grouped or not, or have it go in as an argument) - The argument will be asking if the index has been set or not
- if forecast series ID is 14 then don't add anything from SQL or do any rollups, only mgra and region 
- I still want a complete data dictionary that I can use 
- Ideally would like to just be able to runthis script and it populates all the aggregated parts, it will check the config file to see if there is some that still need to be done

'''
