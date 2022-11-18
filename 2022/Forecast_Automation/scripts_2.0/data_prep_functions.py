import numpy as np
import pandas as pd
import yaml

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

# Make adjustments to specific, specified columns that need it - should work at all levels

# Find columns that we want at particular geography levels


def wanted_geography_cols(df, wanted_geo_level):
    """Returns a list of columns that do not include unwanted geography levels."""
    geography_levels = ['mgra', 'cpa', 'jurisdiction', 'luz_id', 'taz']
    geography_levels.remove(wanted_geo_level)

    return [col for col in df.columns if col not in geography_levels]

# Roll up to CPA - adjustments will be needed

# Roll up to Jurisdiction - adjustments will be needed

# Roll up to Region - adjustments will be needed

# Potentially doing LUZ and TAZ as well?

# -------------------- Class Manipulation Functions:

# Download the data function

# DF Comparison Function - checking shape and columns and such, returns similar columns

# Check to see if the desired output exists

# Both functions - will house both of the above functions

# Diff Functions --- will use the first two functions

# ---------------------- Class Other Outpus

# Number of persons (from households) at MGRA level depending on GQ preference


def population_from_households_dataset(dsid, gq_only, no_gq):
    '''Downloads and aggregates population data from the households dataset depending on GQ preference.'''
    # From households file
    household_file_all = download_and_concat_Tdrive_files(
        dsid, 'Household_Files')
    household_file_subset = household_file_all[['year', 'mgra', 'persons']]
    household_file_subset['year'] = pd.to_numeric(
        household_file_subset['year'])

    if (gq_only == no_gq) & (gq_only == False):
        # GQ and Non-GQ Person Comparison
        population_household_file_all = household_file_subset.groupby(
            ['year', 'mgra']).sum().reset_index()
        population_household_file_all.columns = [
            'year', 'mgra', 'pop_count_household_file']
        return population_household_file_all
    elif gq_only == True:
        # Just GQ Population Comparison
        household_file_gq_only = household_file_subset[household_file_all['unittype'] == 1]
        population_household_file_gq_only = household_file_gq_only.groupby(
            ['year', 'mgra']).sum().reset_index()
        population_household_file_gq_only.columns = [
            'year', 'mgra', 'pop_count_household_file']
        return population_household_file_gq_only
    else:
        # Just Non-GQ Person Comparison
        household_file_no_gq = household_file_subset[household_file_all['unittype'] == 0]
        population_household_file_no_gq = household_file_no_gq.groupby(
            ['year', 'mgra']).sum().reset_index()
        population_household_file_no_gq.columns = [
            'year', 'mgra', 'pop_count_household_file']
        return population_household_file_no_gq


# Combine with the mgra file (will need other files created) - create the diff -- population
def population_comparison_houseolds_and_input_files(dsid, gq_only, no_gq, to_jdrive):
    '''Compare MGRA population data to household dataset population data based on gq preference.'''
    # Bring in input files and process
    mgra_data = pd.read_csv(rf'J:\DataScience\DataQuality\QAQC\forecast_automation\mgra_series_13_outputs_CSV_data\aggregated_data\mgra_DS{dsid}_ind_QA.csv', usecols=[
                            'year', 'mgra', 'pop', 'hhp'])
    mgra_data['gq_pop_input_files'] = mgra_data['pop'] - mgra_data['hhp']
    mgra_data = mgra_data.rename(
        columns={'pop': 'pop_input_files', 'hhp': 'hhp_input_files'})

    if (gq_only == no_gq) & (gq_only == False):
        # GQ and Non-GQ Person Comparison
        output = population_from_households_dataset(dsid, gq_only, no_gq).merge(
            mgra_data, how='left', on=['year', 'mgra'])
        output = output[['year', 'mgra', 'pop_count_household_file',
                         'pop_input_files']]
        output['Diff'] = output['pop_count_household_file'] - \
            output['pop_input_files']
        if to_jdrive:
            output.to_csv(
                rf"J:\DataScience\DataQuality\QAQC\forecast_automation\mgra_series_13_outputs_CSV_data\other_outputs\mgra_households_dataset_population_comparison_all_DS{dsid}_QA.csv", index=False)
        return output

    elif gq_only == True:
        # Just GQ Population Comparison
        output = population_from_households_dataset(dsid, gq_only, no_gq).merge(
            mgra_data, how='left', on=['year', 'mgra'])
        output = output[['year', 'mgra', 'pop_count_household_file',
                         'gq_pop_input_files']]
        output['Diff'] = output['pop_count_household_file'] - \
            output['gq_pop_input_files']
        if to_jdrive:
            output.to_csv(
                rf"J:\DataScience\DataQuality\QAQC\forecast_automation\mgra_series_13_outputs_CSV_data\other_outputs\mgra_households_dataset_population_comparison_GQ_only_DS{dsid}_QA.csv", index=False)
        return output
    else:
        # Just Non-GQ Person Comparison
        output = population_from_households_dataset(dsid, gq_only, no_gq).merge(
            mgra_data, how='left', on=['year', 'mgra'])
        output = output[['year', 'mgra', 'pop_count_household_file',
                         'hhp_input_files']]
        output['Diff'] = output['pop_count_household_file'] - \
            output['hhp_input_files']
        if to_jdrive:
            output.to_csv(
                rf"J:\DataScience\DataQuality\QAQC\forecast_automation\mgra_series_13_outputs_CSV_data\other_outputs\mgra_households_dataset_population_comparison_no_GQ_DS{dsid}_QA.csv", index=False)
        return output

# Number of households (from households) at MGRA level -- use the T drie function grabber


def number_of_households_from_households_dataset(dsid, gq_only, no_gq):
    '''Downloads and aggregates number of households data from the households dataset depending on GQ preference.'''
    # TODO for this one we only need non-GQ, we arn't looking at diffs in any other level
    # From households file
    household_file_all = download_and_concat_Tdrive_files(
        dsid, 'Household_Files')
    household_file_subset = household_file_all[['year', 'mgra', 'hhid']]
    household_file_subset['year'] = pd.to_numeric(
        household_file_subset['year'])

    if (gq_only == no_gq) & (gq_only == False):
        # GQ and Non-GQ Person Comparison
        household_count_household_file_all = household_file_subset.groupby(
            ['year', 'mgra']).count().reset_index()
        household_count_household_file_all.columns = [
            'year', 'mgra', 'house_count_household_file']
        return household_count_household_file_all
    elif gq_only == True:
        # Just GQ Population Comparison
        household_file_gq_only = household_file_subset[household_file_all['unittype'] == 1]
        household_count_household_file_gq_only = household_file_gq_only.groupby(
            ['year', 'mgra']).count().reset_index()
        household_count_household_file_gq_only.columns = [
            'year', 'mgra', 'house_count_household_file']
        return household_count_household_file_gq_only
    else:
        # Non GQ
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
    mgra_data = pd.read_csv(rf'J:\DataScience\DataQuality\QAQC\forecast_automation\mgra_series_13_outputs_CSV_data\aggregated_data\mgra_DS{dsid}_ind_QA.csv', usecols=[
                            'year', 'mgra', 'hh'])
    mgra_data = mgra_data.rename(columns={'hh': 'hh_count_input_files'})

    output = number_of_households_from_households_dataset(dsid, gq_only=False, no_gq=True).merge(
        mgra_data, how='left', on=['year', 'mgra'])
    output = output[['year', 'mgra',
                     'house_count_household_file', 'hh_count_input_files']]
    output['Diff'] = output['house_count_household_file'] - \
        output['hh_count_input_files']
    if to_jdrive:
        output.to_csv(
            rf"J:\DataScience\DataQuality\QAQC\forecast_automation\mgra_series_13_outputs_CSV_data\other_outputs\mgra_households_dataset_hh_count_comparison_no_GQ_DS{dsid}_QA.csv", index=False)
    return output

# ------------------------ Class QC Checks


# Check to see which aggregate files still need to be created (return a list), comparison with what we have in our config file
# Could also check which diff files also need to be created
# TODO: Update config file to have persons and household datasets
# TODO: Python doesn't like the way that I do this: household_file_subset['year'] = pd.to_numeric(
'''
ideas:
- Could have that SQL connection setup in a yml file, have a seperate yml file for more input related things 
- for functions that take in a dataframe (like the Qc ones, I could have a function that checks in the index has been grouped or not, or have it go in as an argument) - The argument will be asking if the index has been set or not
- if forecast series ID is 14 then don't add anything from SQL or do any rollups, only mgra and region 
- I still want a complete data dictionary that I can use 
- Ideally would like to just be able to runthis script and it populates all the aggregated parts, it will check the config file to see if there is some that still need to be done

'''
