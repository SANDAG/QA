#!/usr/bin/env python
# coding: utf-8

# TODOS / Questions:
# - Determine how input process will work
# - (Input QC Check) determine how to check all variables and years
# - (Comparison of EDAM DOF) how will we know which version to pull from sql (I think it's in sql?)
# - (Threshold Analysis) Determine how to handle division by 0 cases where the total is 0 (currently just ignoring them)
# - (Threshold Analysis) Determine whether we should look for both value and percentage thresholds, or just one of them
# - (Trend Analysis) How do we want to create visualizations of all features?
#     - What tool do we use? Currently Matplotlib
#     - What geo_level do we do it for? Currently just Region level...

# # Info: 
# - Purva's Outline: https://sandag.sharepoint.com/:w:/r/qaqc/_layouts/15/Doc.aspx?sourcedoc=%7B01edb2de-9cd9-49a3-919d-dc1fe0896e30%7D&action=edit&wdPid=2061df5d&params=eyJBcHBOYW1lIjoiVGVhbXMtRGVza3RvcCIsIkFwcFZlcnNpb24iOiIyNy8yMjAzMDcwMTYxMCJ9&cid=2e4b8383-fba2-42f6-a5b4-bf7bfd17373e
# - Data Dictionary: https://github.com/SANDAG/ABM/wiki/input-files#input-files-data-dictionary

# # Part Two

# In[1]:


# Import Libraries
import pandas as pd
import numpy as np
import yaml
import matplotlib.pyplot as plt
import seaborn as sns

import os
import pyodbc
import glob
import copy
import PySimpleGUI as sg
import traceback
import xlsxwriter
import sys


# In[2]:


# Important to avoid Latex formatting (with dollar signs)
pd.options.display.html.use_mathjax = False


# # Import YML information

# In[3]:


config_filename = './part_2_config.yml'
with open(config_filename, "r") as yml_file:
    config = yaml.safe_load(yml_file)


# In[4]:


# Inputs
comparison = bool(config['ID_information']['ID_inputs']['comparison'])
first_ID = config['ID_information']['ID_inputs']['first_id']
second_ID = config['ID_information']['ID_inputs']['second_id']
default_folder = config['ID_information']['ID_inputs']['default_folder']


# In[5]:


ds_config = './ds_config.yml'
with open(ds_config, "r") as yml_file:
    ds_config = yaml.safe_load(yml_file)


# ## Importing / downloading data

# In[20]:


# add note that filenames need to be consistent


# In[6]:


# Checking if all the files needed exists, and if not, pulls up the code from part 1. 
if comparison:
    necessary_files = [
    f'cpa_both_{first_ID}_{second_ID}.csv',
    f'cpa_diff_{first_ID}_minus_{second_ID}.csv',
    f'cpa_ind_{first_ID}.csv',
    f'cpa_ind_{second_ID}.csv',
    f'jur_both_{first_ID}_{second_ID}.csv',
    f'jur_diff_{first_ID}_minus_{second_ID}.csv',
    f'jur_ind_{first_ID}.csv',
    f'jur_ind_{second_ID}.csv',
    f'mgra_both_{first_ID}_{second_ID}.csv',
    f'mgra_diff_{first_ID}_minus_{second_ID}.csv',
    f'mgra_ind_{first_ID}.csv',
    f'mgra_ind_{second_ID}.csv',
    f'region_both_{first_ID}_{second_ID}.csv',
    f'region_diff_{first_ID}_minus_{second_ID}.csv',
    f'region_ind_{first_ID}.csv',
    f'region_ind_{second_ID}.csv']
    entries = os.scandir(default_folder)
    available_files = [file.name for file in list(entries) if first_ID in file.name or second_ID in file.name] #Grab all files that have either firs or second DS ID in them 
    needed_files = [file for file in necessary_files if file not in available_files] # Grab all the files that are in our file list that are not in the available files, these are the files  that we need. 
    if len(needed_files) != 0:
        print(f"Please download the following files: {needed_files}")
        get_ipython().run_line_magic('run', 'Part_1.ipynb')
    print('You have all the files you need to run the comparison functions')
    
    # Download all the data files
    mgra_first = pd.read_csv(default_folder + f'mgra_ind_{first_ID}.csv').groupby(['mgra', 'year']).sum()
    mgra_second = pd.read_csv(default_folder + f'mgra_ind_{second_ID}.csv').groupby(['mgra', 'year']).sum()

    cpa_first = pd.read_csv(default_folder + f'cpa_ind_{first_ID}.csv').groupby(['cpa', 'year']).sum()
    cpa_second = pd.read_csv(default_folder + f'cpa_ind_{second_ID}.csv').groupby(['cpa', 'year']).sum()

    jur_first = pd.read_csv(default_folder + f'jur_ind_{first_ID}.csv').groupby(['jurisdiction', 'year']).sum()
    jur_second = pd.read_csv(default_folder + f'jur_ind_{second_ID}.csv').groupby(['jurisdiction', 'year']).sum()

    reg_first = pd.read_csv(default_folder + f'region_ind_{first_ID}.csv').groupby('year').sum()
    reg_second = pd.read_csv(default_folder + f'region_ind_{second_ID}.csv').groupby('year').sum()

    mgra_both = pd.read_csv(default_folder + f'mgra_both_{first_ID}_{second_ID}.csv').groupby(['mgra', 'year']).sum()
    mgra_diff = pd.read_csv(default_folder + f'mgra_diff_{first_ID}_minus_{second_ID}.csv').groupby(['mgra', 'year']).sum()
else:
    necessary_files = [
    f'cpa_ind_{first_ID}.csv',
    f'cpa_ind_{second_ID}.csv',
    f'jur_ind_{first_ID}.csv',
    f'jur_ind_{second_ID}.csv',
    f'mgra_ind_{first_ID}.csv',
    f'mgra_ind_{second_ID}.csv',
    f'region_ind_{first_ID}.csv',
    f'region_ind_{second_ID}.csv']
    entries = os.scandir(default_folder)
    available_files = [file.name for file in list(entries) if first_ID in file.name or second_ID in file.name] #Grab all files that have either firs or second DS ID in them 
    needed_files = [file for file in necessary_files if file not in available_files] # Grab all the files that are in our file list that are not in the available files, these are the files  that we need. 
    if len(needed_files) != 0:
        print(f"Please download the following files: {needed_files}")
        get_ipython().run_line_magic('run', 'Part_1.ipynb')
    print('You have all the files you need to run the non-comparison functions')

    # Downlaod all non-comparison files 
    mgra_first = pd.read_csv(default_folder + f'mgra_ind_{first_ID}.csv').groupby(['mgra', 'year']).sum()
    mgra_second = pd.read_csv(default_folder + f'mgra_ind_{second_ID}.csv').groupby(['mgra', 'year']).sum()

    cpa_first = pd.read_csv(default_folder + f'cpa_ind_{first_ID}.csv').groupby(['cpa', 'year']).sum()
    cpa_second = pd.read_csv(default_folder + f'cpa_ind_{second_ID}.csv').groupby(['cpa', 'year']).sum()

    jur_first = pd.read_csv(default_folder + f'jur_ind_{first_ID}.csv').groupby(['jurisdiction', 'year']).sum()
    jur_second = pd.read_csv(default_folder + f'jur_ind_{second_ID}.csv').groupby(['jurisdiction', 'year']).sum()

    reg_first = pd.read_csv(default_folder + f'region_ind_{first_ID}.csv').groupby('year').sum()
    reg_second = pd.read_csv(default_folder + f'region_ind_{second_ID}.csv').groupby('year').sum()


# In[22]:


# for i in mgra_first.columns:
#     print(f"'{i}',")


# In[23]:


# In YML 
housing_cols = [
    'hs',
    'hs_Single_Family',
    'hs_Multiple_Family',
    'hs_Mobile_Homes',
    'Household Population (hh)',
    'hh_Single_Family',
    'hh_Multiple_Family',
    'hh_Mobile_Homes',
    'gq_civ',
    'Group Quarters - Military (gq_mil)',    
]

income_cols = [
    'Less than $15,000',
    '$15,000 to $29,999',
    '$30,000 to $44,999',
    '$45,000 to $59,999',
    '$60,000 to $74,999',
    '$75,000 to $99,999',
    '$100,000 to $124,999',
    '$125,000 to $149,999',
    '$150,000 to $199,999',
    '$200,000 or more',
]

emp_cols = [
    'emp_Agricultural_and_Extractive',
    'emp_const_non_bldg_prod',
    'emp_const_non_bldg_Office',
    'emp_utilities_prod',
    'emp_utilities_Office',
    'emp_const_bldg_prod',
    'emp_const_bldg_Office',
    'emp_Manufacturing_prod',
    'emp_Manufacturing_Office',
    'emp_whsle_whs',
    'emp_trans',
    'emp_retail',
    'emp_prof_bus_svcs',
    'emp_prof_bus_svcs_bldg_maint',
    'emp_pvt_ed_k12',
    'emp_pvt_ed_post_k12_Other_Residential',
    'emp_health',
    'emp_personal_svcs_Office',
    'emp_amusement',
    'emp_hotel',
    'emp_restaurant_bar',
    'emp_personal_svcs_retail',
    'emp_religious',
    'emp_pvt_hh',
    'emp_state_local_Government_ent',
    'emp_fed_non_Military',
    'emp_fed_Military',
    'emp_state_local_Government_blue',
    'emp_state_local_Government_white',
    'emp_public_ed',
    'emp_own_occ_dwell_mgmt',
    'emp_fed_Government_accts',
    'emp_st_lcl_Government_accts',
    'emp_cap_accts',
    'emp_total',
]


# ## Input QC Check

# In[24]:


# TODO: check that all the variables and years were successfully loaded (Reference Table A)
# Table A is the notes documentation we have (That Purva made)
# Hardcode it with yml file maybe


'''
Checking that part 1 had proper outputs:
- Checking to make sure all columns expected are there & identical years (Harcoded in YML)
- Making sure that all years expected are present (Years can be hardcoded in YML) 
- 


Checking that Part 2 can be ran: 
- Check to see that column names are identical (Between the DSIDs that need to be identical)

'''


# In[32]:


def check_cols(mgra_df):
    
    if list(mgra_df.columns) != config['columns']:
        return set(list(mgra_df.columns)) ^ set(config['columns'])
    
    return list(mgra_df.columns) == config['columns']


# In[33]:


check_cols(mgra_first)


# In[34]:


# t drive and database column names are different
# csv column names should be consistent (can be hardcoded)
# if column missing, proceed but give warning


# ## Internal Consistency Checks
# 
# Check if the totals at mgra, jurisdiction, and region level are consistent.

# In[37]:


mgra_first.groupby('year').sum()


# In[57]:


def compare_totals(mgra_df, jur_df, region_df):
    """
    Aggregates sum of values by year in mgra, cpa, jurisdiction, and region level and compares them together to
    see if they match.
    """
    mgra_totals = mgra_df.groupby('year').sum()
    jur_totals = jur_df.groupby('year').sum()
    reg_totals = region_df
    
    non_matches_dict = {}
    jur_non_matches = []
    for col in mgra_totals.columns:
        if not np.isclose(jur_totals[col], mgra_totals[col]).all():
            jur_non_matches.append(col)
            
    if len(jur_non_matches) == len(mgra_totals.columns):
        non_matches_dict['jurisdiction'] = 'all columns did not match.'
    elif len(jur_non_matches) == 0:
        non_matches_dict['jurisdiction'] = 'all columns matched.'
    else:
        if len(jur_non_matches) > 10:
            non_matches_dict['jurisdiction'] = f"{len(jur_non_matches)} columns did not match out of {len(mgra_totals.columns)} columns."
        else:
            non_matches_dict['jurisdiction'] = ', '.join(jur_non_matches) + ' columns did not match.'
    
    reg_non_matches = []
    for col in mgra_totals.columns:
        if not np.isclose(reg_totals[col], mgra_totals[col]).all():
            reg_non_matches.append(col)
    if len(reg_non_matches) == len(mgra_totals.columns):
        non_matches_dict['region'] = 'all columns did not match.'
    elif len(reg_non_matches) == 0:
        non_matches_dict['region'] = 'all columns matched.'
    else:
        if len(reg_non_matches) > 10:
            non_matches_dict['region'] = f"{len(reg_non_matches)} columns did not match out of {len(mgra_totals.columns)}."
        else:
            non_matches_dict['region'] = ', '.join(reg_non_matches) + ' columns did not match.'
    
    return non_matches_dict


# In[58]:


compare_totals(mgra_first, jur_first, reg_first)


# In[ ]:


# this is fine but reformat the list into a dataframe or something easier to view. add count for how many columns there are and how many didn't match


# ## Comparison of EDAM total population forecast with California Department of Finance (Cal DOF) forecast
# 
# more context here: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={b24ae5c1-9536-4de5-a6fd-bb2860a98fcf}&action=edit&wd=target%28Untitled%20Section.one%7C5e99c4cf-2421-42e4-b4d3-85012f1cee55%2FComments%20on%20DOF%20Data%7C56d66d69-1259-4679-b2c7-0997e99786b2%2F%29
# 
# dof data: https://dof.ca.gov/forecasting/Demographics/projections/

# In[13]:


# dof files in sql socioec_data database (determine how to select correct version)


# In[21]:


conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                      'Server=DDAMWSQL16.sandag.org;'
                      'Database=socioec_data;'
                      'Trusted_Connection=yes;')


# In[28]:


query_all = "SELECT * FROM socioec_data.ca_dof.population_housing_estimates WHERE area_name = 'San Diego' AND summary_type = 'Total' AND area_type = 'County'" #Query for specific dof version


# In[29]:


dof = pd.read_sql(query_all, conn)
dof


# In[39]:


cleaned_dof = dof[['area_type', 'area_name','summary_type','county_name','est_yr','est_md', 'total_pop']]

print(len(cleaned_dof[cleaned_dof['est_md']=='APR_1']))
print(len(cleaned_dof[cleaned_dof['est_md']=='JAN_1']))

cleaned_dof = cleaned_dof[cleaned_dof['est_md']=='JAN_1'] # This is arbitrary and it could have been 'APR_1'


# In[51]:


unique_dates = list(set([x[1] for x in mgra_first.index]))
cleaned_dof = cleaned_dof[cleaned_dof['est_yr'].isin(unique_dates)]
cleaned_dof.drop_duplicates()


# In[41]:


yearly_pop_edam = mgra_first['pop'].groupby('year').sum()
yearly_pop_edam


# In[44]:


type(mgra_first.index)


# In[48]:


# Individual years (using set)
list(set([x[1] for x in mgra_first.index]))


# In[ ]:


# email daniel ask for which table/version dof to use.

# there is a single dof table but we need to know the release date or some kind of identifier (could be an input for the user)

# when comparing, use 1.5% range of difference in population numbers, flag it if its outside of that range


# ## Threshold Analysis

# ### Row-wise yearly difference threshold (individual)

# In[17]:


year_thresholds = config['year_thresholds']


# In[18]:


def yearly_diff_threshold(df, threshold_dict):
    """
    input: multi-index dataframe (index = (geo_level, year)), columns to check threshold in,
    value threshold (numeric), percentage threshold (numeric value in {0,1})
    
    output: rows of the input multi-index dataframe with yearly differences outside the
    designated threshold (inclusive)
    """
    
    years = list(df.index.get_level_values(1).unique()) # List of the unique years 
    year_diffs = {}

    # Creating a dictionary of the differnces, just naming convetions
    index=0
    while index < len(years)-1:
        year_diffs[years[index+1]] = f"{str(years[index])}-{str(years[index+1])}"
        index+=1
    
    # Group together MGRA and subtract newer year from older year. Rename the index according to the year_diffs dataframe. Then drop rows where every value is NA (Which will be all rows for 2016)    
    renamed_df = df.groupby(level=0).diff().rename(index=year_diffs).dropna(how='all')
    
    # Take the dataframe and remove 2016 and rename the indexes to match the renamed df
    non_2016_df = df[df.index.get_level_values('year') != 2016].rename(index=year_diffs)
    
    # Difference divided by original, filling na with 'inf'
    percentage_df = renamed_df.div(non_2016_df).fillna(float('inf'))
    
    # Subsets dataframe by column, checks to see if the value is greater than the threshold and returns true or false depending on if the threshold was crossed. 
    perc_condition = pd.DataFrame([abs(percentage_df[key]) >= val['percentage_threshold'] for key, val in threshold_dict.items()]).T.all(axis=1)
    value_condition = pd.DataFrame([abs(renamed_df[key]) >= val['value_threshold'] for key, val in threshold_dict.items()]).T.all(axis=1)
    
    renamed_df['Flag'] = (perc_condition & value_condition)
    
    return renamed_df


# In[19]:


a = yearly_diff_threshold(mgra_first, year_thresholds)


# In[41]:


a


# In[ ]:


# add a note on flag labels (True=flag, False=ok)


# ### DS_ID difference (comparison)

# In[20]:


ds_thresholds = config['ds_thresholds']


# In[21]:


def ds_diff_threshold(diff_df, mgra_second, threshold_dict):
    """
    input: Multi-index diff dataframe (index = (geo_level, year)), Multi-index first_ID_df
    dataframe (index = (geo_level, year)), column(s) to check threshold, value threshold (numeric),
    percentage threshold (numeric value in {0,1})
    
    output: rows of the input multi-index dataframe with DS differences outside the
    designated thresholds (inclusive)
    """
    
    # Rename the columns in mgra_second so  it matches the columns in diff. Need this for the division in the next step.
    mgra_second.columns = [f"{col}_diff" for col in mgra_second.columns]
    
    #Get the pecentage dataframe based on percentgages divided by second df 
    percentage_df = diff_df.div(mgra_second).fillna(float('inf'))
    
    # Return True/False dataframes for each of the threshold checks 
    perc_condition = pd.DataFrame([abs(percentage_df[f'{key}_diff']) >= val['percentage_threshold'] for key, val in threshold_dict.items()]).T.all(axis=1)
    value_condition = pd.DataFrame([abs(diff_df[f'{key}_diff']) >= val['value_threshold'] for key, val in threshold_dict.items()]).T.all(axis=1)
    
    diff_df['Flag'] = (perc_condition & value_condition)
    
    return diff_df


# In[22]:


ds_diff_example = ds_diff_threshold(mgra_diff, mgra_second, ds_thresholds)


# In[23]:


ds_diff_example


# In[ ]:


# add note for flag label

# for threshold functions, thresholds need to be updated often so we could use a dictionary here or something easier to update


# ## Trend Analysis
# 
# Visually analyze forecast trends for years of interest to identify any unexpected trends. 
# 
# Decision items: Should output from this check be pushed into PowerBI? 

# ### Proportion Checks
# We expect this to be mainly visual. 

# In[ ]:


# employment, income, ethnicity, age, gender categories

# update to use proportion

# check for change in proportion across years
# don't use viz, just implement check for every geo level (threshold should be input by user for difference in proportion)


# In[46]:


mgra_first[income_cols]


# In[108]:


def shares(df, cols, threshold_dict):
    """
    input: multi-index dataframe (index = (geo_level, year)), columns to check threshold in,
    value threshold (numeric), percentage threshold (numeric value in {0,1})
    
    output: rows of the input multi-index dataframe with yearly differences outside the
    designated threshold (inclusive)
    """
    
    # Add column values and divides each column by total to get the proportion breakdown
    df = df[cols]
    df['Total'] = df[cols].sum(axis=1)
    shares = df[cols].div(df['Total'], axis=0) * 100
    
    years = list(df.index.get_level_values(1).unique()) # List of the unique years 
    year_diffs = {}

    # Creating a dictionary of the differences, just naming conventions
    index=0
    while index < len(years)-1:
        year_diffs[years[index+1]] = f"{str(years[index])}-{str(years[index+1])}"
        index+=1
    
    # Group together MGRA and subtract newer year from older year. Rename the index according to the year_diffs dataframe. Then drop rows where every value is NA (Which will be all rows for 2016)    
    renamed_df = shares.groupby(level=0).diff().rename(index=year_diffs).dropna(how='all')

    # Subsets dataframe by column, checks to see if the value is greater than the threshold and returns true or false depending on if the threshold was crossed. 
    condition = pd.DataFrame([abs(renamed_df[key]) >= val for key, val in threshold_dict.items()]).T.all(axis=1)
    
    renamed_df['Flag'] = condition
    
    return renamed_df


# In[146]:


income_thresholds = {'Less than $15,000': 0,
 '$15,000 to $29,999': 0,
 '$30,000 to $44,999': 0,
 '$45,000 to $59,999': 0,
 '$60,000 to $74,999': 0,
 '$75,000 to $99,999': 0,
 '$100,000 to $124,999': 0,
 '$125,000 to $149,999': 0,
 '$150,000 to $199,999': 0,
 '$200,000 or more': 0}


# In[139]:


income_example = shares(mgra_first, income_cols, income_thresholds) # example of income shares at mgra level
income_example[income_example['Flag']]


# In[141]:


income_jur_example = shares(jur_first, income_cols, income_thresholds) # example of income shares at jur level
income_jur_example[income_jur_example['Flag']]


# In[126]:


employment_thresholds = {'emp_Agricultural_and_Extractive': 2,
 'emp_const_non_bldg_prod': 0,
 'emp_const_non_bldg_Office': 0,
 'emp_utilities_prod': 0,
 'emp_utilities_Office': 0,
 'emp_const_bldg_prod': 0,
 'emp_const_bldg_Office': 0,
 'emp_Manufacturing_prod': 0,
 'emp_Manufacturing_Office': 0,
 'emp_whsle_whs': 0,
 'emp_trans': 0,
 'emp_retail': 0,
 'emp_prof_bus_svcs': 0,
 'emp_prof_bus_svcs_bldg_maint': 0,
 'emp_pvt_ed_k12': 0,
 'emp_pvt_ed_post_k12_Other_Residential': 0,
 'emp_health': 0,
 'emp_personal_svcs_Office': 0,
 'emp_amusement': 0,
 'emp_hotel': 0,
 'emp_restaurant_bar': 0,
 'emp_personal_svcs_retail': 0,
 'emp_religious': 0,
 'emp_pvt_hh': 0,
 'emp_state_local_Government_ent': 0,
 'emp_fed_non_Military': 0,
 'emp_fed_Military': 0,
 'emp_state_local_Government_blue': 0,
 'emp_state_local_Government_white': 0,
 'emp_public_ed': 0,
 'emp_own_occ_dwell_mgmt': 0,
 'emp_fed_Government_accts': 0,
 'emp_st_lcl_Government_accts': 0,
 'emp_cap_accts': 0,
 'emp_total': 0}


# In[127]:


emp_example = shares(mgra_first, emp_cols, employment_thresholds) # example of employment shares at mgra level
emp_example[emp_example['Flag']]


# In[168]:


emp_jur_example = shares(jur_first, emp_cols, employment_thresholds) # example of employment shares at jur level
emp_jur_example[emp_jur_example['Flag']]


# In[222]:


conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                   'Server=ddamwsql16.sandag.org;'
                  'Database=demographic_warehouse;'
                 'Trusted_Connection=yes;')

dim_mgra = "SELECT [mgra_id], [mgra], [cpa], [cpa_id], [jurisdiction] FROM [demographic_warehouse].[dim].[mgra_denormalize]  WHERE series=14"
d_mgra = pd.read_sql_query(dim_mgra, conn)

dim_ethn = "SELECT [ethnicity_id],[short_name] FROM [demographic_warehouse].[dim].[ethnicity]"
d_ethn = pd.read_sql_query(dim_ethn, conn)

ethn = "SELECT [yr_id],[mgra_id],[ethnicity_id],[population] FROM [demographic_warehouse].[fact].[ethnicity] WHERE datasource_id= 38"
ethn = pd.read_sql_query(ethn, conn)


# In[238]:


merged_df = ethn.merge(d_ethn, on='ethnicity_id').merge(d_mgra, on='mgra_id')
ethnicities = list(merged_df['short_name'].unique())


# In[242]:


mgra_ethn = merged_df.groupby(['mgra', 'yr_id', 'short_name'], as_index=False).sum().pivot(index=['mgra','yr_id'], columns='short_name', values='population')
cpa_ethn = merged_df.groupby(['cpa', 'yr_id', 'short_name'], as_index=False).sum().pivot(index=['cpa','yr_id'], columns='short_name', values='population')
jur_ethn = merged_df.groupby(['jurisdiction', 'yr_id', 'short_name'], as_index=False).sum().pivot(index=['jurisdiction','yr_id'], columns='short_name', values='population')
reg_ethn = merged_df.groupby(['yr_id', 'short_name'], as_index=False).sum().pivot(index='yr_id', columns='short_name', values='population')


# In[241]:


shares(mgra_ethn, cols=ethnicities, threshold_dict={x:0 for x in ethnicities}) # example of ethnicity shares at mgra level


# In[243]:


shares(jur_ethn, cols=ethnicities, threshold_dict={x:0 for x in ethnicities}) # example of ethnicity shares at jur level


# In[ ]:





# In[165]:


def reg_shares(df, cols, threshold_dict):
    """
    input: multi-index dataframe (index = (geo_level, year)), columns to check threshold in,
    value threshold (numeric), percentage threshold (numeric value in {0,1})
    
    output: rows of the input multi-index dataframe with yearly differences outside the
    designated threshold (inclusive)
    """
    
    df = df[cols]
    df['Total'] = df[cols].sum(axis=1)
    shares = df[cols].div(df['Total'], axis=0) * 100
        
    years = list(df.index.unique()) # List of the unique years 
    year_diffs = {}

    # Creating a dictionary of the differences, just naming conventions
    index=0
    while index < len(years)-1:
        year_diffs[years[index+1]] = f"{str(years[index])}-{str(years[index+1])}"
        index+=1
    
    #return shares
    
    # Group together MGRA and subtract newer year from older year. Rename the index according to the year_diffs dataframe. Then drop rows where every value is NA (Which will be all rows for 2016)    
    renamed_df = shares.diff().rename(index=year_diffs).dropna(how='all')
    
    # Subsets dataframe by column, checks to see if the value is greater than the threshold and returns true or false depending on if the threshold was crossed. 
    condition = pd.DataFrame([abs(renamed_df[key]) >= val for key, val in threshold_dict.items()]).T.all(axis=1)
    
    renamed_df['Flag'] = condition
    
    return renamed_df


# In[167]:


reg_example = reg_shares(reg_first, income_cols, income_thresholds)
reg_example


# In[245]:


reg_shares(reg_ethn, cols=ethnicities, threshold_dict={x:0 for x in ethnicities}) # example of ethnicity shares at reg level


# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[24]:


# In consideration
'''
- Income breakdown visual(s)
- Housing breakdown visual(s) 



'''


# In[25]:


import plotly.graph_objects as go

# Create figure
fig = go.Figure()

# Add traces (replace is to avoid latex rendering)
fig.add_traces(go.Bar(x=[col.replace('$', '&#36;') for col in reg_first[income_cols].columns], y=reg_first[income_cols].loc[2016]))

buttons = []
for index, row in reg_first[income_cols].iterrows():
    # Add traces
    buttons.append({'method': 'update',
                             'label': str(index),
                             'args': [{'y': [row]},]
                              })

fig.update_layout(
    title="Distribution of Income Groups", # Can be more specific...
    xaxis_title="Income Group",
    yaxis_title="Value", # Not sure what is represented by the value here
    updatemenus=[
        dict(
            type="buttons",
            buttons=buttons,
            showactive= True,
        )
    ],
    showlegend=False,
)

fig.show()


# In[26]:


# Create figure
fig = go.Figure()

# Add traces
fig.add_traces(go.Bar(x=reg_first[housing_cols].columns, y=reg_first[housing_cols].loc[2016]))

buttons = []
for index, row in reg_first[housing_cols].iterrows():
    # Add traces
    buttons.append({'method': 'update',
                             'label': str(index),
                             'args': [{'y': [row]},]
                              })

fig.update_layout(
    title="Distribution of Housing Groups",
    xaxis_title="Housing Group",
    yaxis_title="Value",
    updatemenus=[
        dict(
            type="buttons",
            buttons=buttons,
            showactive= True,
        )
    ],
    showlegend=False,
)

fig.show()


# ### Share Checks
# This is a reasonable test checking if one column value changes drastically then subsequent 'connected' columns change as expected. Most likely this will be ran at the jurisdiction and CPA level. 

# In[27]:


'''
- Hypothetical relationship between population and number of households, an increase in one likely would lead to an increase in another. *Get clarification on expected relationships*
- More visuals 


'''


# ## Parking Formula Checks
# 
# More info: https://sandag.sharepoint.com/qaqc/_layouts/15/Doc.aspx?sourcedoc={276bc2d7-75c5-4865-b7ab-6032aa492e45}&action=edit&wd=target%28Untitled%20Section.one%7Cd0bb8408-498b-4411-9b1d-7704a49975eb%2FDecision%20Tree-V2%7C59dc5bcf-f997-4640-9040-5fdfde0e3eee%2F%29

# ![image.png](attachment:image.png)

# ![image.png](attachment:image.png)

# In[179]:


# def parking_formula(df):
#     if df['emp_total'] INCREASES:
#         new_stalls = df['hstallssam'] + new_jobs_since_baseline * 300 / baseline_req_mgra
#     else:
#         new_stalls = NO CHANGE
        
#     if baseline_req_pricing == NULL:
#         # stall value set back to original series
#     else:
#         if emp_total INCREASES:
#             decay = base_stalls * ((1 + annual_chg_2036_2050) ** (current_year - comp_year))
#         else:
#             decay = base_parking_stalls + (current_emp - base_emp) * (300 / baseline_req_mgra) * ((1 + annual_chg_2036_2050) ** (current_year - comp_year))

#     return ...


# In[29]:


# parking_formula(mgra_first)


# In[ ]:





# ## Custom Checks

# In[ ]:





# ## Spatial Density

# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# In[ ]:





# ## Input output check- Check if inputs and outputs for housing/scheduled developments are consistent (cannot be automated)

# In[ ]:





# In[ ]:





# # GUI Code (Usage unconfirmed)

# In[30]:


ds_options = list(ds_config.keys())[:-1]


# In[31]:


col_dicts = {'housing_cols': housing_cols, 'emp_cols': emp_cols}


# In[32]:


def threshold_window(cols, thresh_dict=None):
    """
    Creates SimplePyGUI window that enables user to select a single DS_ID along with desired outputs. The window will
    also have a console section where any output notes or errors will be displayed.
    Returns click event as well as selected values (might remove return values since no purpose as of now).
    """
    sg.theme('SandyBeach')
    
    ######################################
    
    column_gui_col = [[sg.Text('Column')]]
    for column in cols:
        column_gui_col.append([sg.Text(column)])
    
    if thresh_dict:
        
        value_gui_col = [[sg.Text('Value Threshold')]]
        for column in cols:
            default_val = '0'
            if column+'_value_threshold' in thresh_dict.keys():
                default_val = thresh_dict[column+'_value_threshold']
            value_gui_col.append([sg.Input(default_val, key=column+'_value_threshold', size=15)])

        percentage_gui_col = [[sg.Text('Percentage Threshold')]]
        for column in cols:
            default_val = '0'
            if column+'_percentage_threshold' in thresh_dict.keys():
                default_val = thresh_dict[column+'_percentage_threshold']
            percentage_gui_col.append([sg.Input(default_val, key=column+'_percentage_threshold', size=15)])
        
    else:

        value_gui_col = [[sg.Text('Value Threshold')]]
        for column in cols:
            value_gui_col.append([sg.Input('0', key=column+'_value_threshold', size=15)])

        percentage_gui_col = [[sg.Text('Percentage Threshold')]]
        for column in cols:
            percentage_gui_col.append([sg.Input('0', key=column+'_percentage_threshold', size=15)])
        
        
    #####################################

    layout_housing = [
        [sg.Column(column_gui_col), sg.Column(value_gui_col), sg.Column(percentage_gui_col)],
        [sg.Submit(key='Submit'), sg.Button('Cancel/Close', key='Cancel')],
    ]
    
    window = sg.Window('Household Thresholds Window', layout_housing, element_justification='c')
    
    while True: # Event Loop
        event, values = window.Read(timeout=10)
        if event in (None, 'Cancel', 'Submit'):
            break
        if event == 'select_all':
            select_all_options()
        if event == 'clear_all':
            deselect_all_options()
        if event == 'select_all_ds':
            select_all_ds()
        if event == 'clear_all_ds':
            deselect_all_ds()

    window.Close()
    # window['output'].__del__()
    
    return event, values


# In[33]:


def comparison_window(filepath):
    """
    Creates SimplePyGUI window that enables user to select multiple DS_ID's along with desired outputs. The window will
    also have a console section where any output notes or errors will be displayed.
    Returns click event as well as selected values
    """
    
    sg.theme('SandyBeach')
    
#     default_dicts = {{col_name: '0' for col_name in col_list} for col_list in [housing_cols, emp_cols]}
#     print(default_dicts)
    
    lb = sg.Listbox(values=ds_options, select_mode='multiple', size=(30, len(ds_options)+1), key='ds_input')
    
    layout_comparison = [
        [sg.Text('Please Select 2 DS_IDs')],
        [lb],
        [sg.Submit(key='Submit'), sg.Button('Cancel/Close', key='Cancel')],
        [sg.Button('Housing Columns', key='housing_thresholds'), sg.Button('Employment Columns', key='employment_thresholds')]
    ]
    
    window = sg.Window('Comparison window', layout_comparison, element_justification='c')
    
    while True: # Event Loop
        event, window_values = window.Read(timeout=10)
        if event in (None, 'Cancel', 'Submit'):
            break
        if event == 'housing_thresholds':
            try:
                event, housing_values = threshold_window(housing_cols, thresh_dict=housing_values)
            except:
                event, housing_values = threshold_window(housing_cols, thresh_dict=None)
        if event == 'employment_thresholds':
            try:
                event, emp_values = threshold_window(emp_cols, thresh_dict=emp_values)
            except:
                event, emp_values = threshold_window(emp_cols, thresh_dict=None)
        if event == 'clear_all':
            deselect_all()
            
    window.Close()
    
    if event == 'Back':
        initiate_window()
    
    return window_values, housing_values # , emp_values # returns error if thresholds have unset vals. Make a defaultdict
# or something that can catch undefined variables


# In[34]:


def base_window():
    """
    Creates SimplePyGUI window that enables user to select output path and output option (comparison or individual).
    Returns click event as well as selected values (click event will indicate output option and values will indicate 
    output path).
    """
    
    sg.theme('SandyBeach')
    
    layout_first = [ 
        [sg.Text('Please Select the Directory that Contains Necessary Files')],
        [sg.Text('Directory Path', size =(15, 1)), sg.FolderBrowse(key='filepath')],
        [sg.Text('Select An Output Option')],
        [sg.Button(button_text='Comparison', key='comparison-select'),
         sg.Button(button_text='Individual', key='individual-select'),
         sg.Cancel()]
    ]
    
    window = sg.Window('Base window', layout_first, element_justification='c')
    
    while True: # Event Loop
        event, values = window.Read(timeout=10)
        if event in (None, 'Cancel', 'Submit'):
            break
        if event == 'comparison-select':
            event, values = comparison_window(values['filepath'])
            break
        if event == 'individual-select':
            break
            
    window.close()

    return event, values


# In[40]:


base_window()


# In[ ]:


# add note on column selection window


# In[ ]:


# add selection for specific checks


# In[ ]:


# consider new DS_ID (part 1 and part 2 guis and yml docs)


# In[ ]:


# csv files have different job categories than the job categories in database
# consider adding feature to look at data in database (part 1)


# In[ ]:


# Part 1: add ds17 and ds36


# In[ ]:


# (future) users should be able to interact/edit the yml file. If a DS_ID becomes obselete, they should be able to remove it


# In[ ]:


# re-evaluate files needed process for ind vs comparison. analyst should have option to select local directory files stored


# In[ ]:


# school enrollment first, a lot of checks would be done in gis. for this one we can start with a year on year check

# school district data is in denormalized mgra database table

# school district data can be broken up in part 1 and the data...

#first, see if mgras have a 1 on 1 alignment with school districts
#if that's good, then we can think about breaking it up as a new geo level
#non-inverse relationship should hold true up until college edu level
#see if there'a relationship between college enrollment and higher-education jobs

#may want to just flag which mgra's have colleges and see the employment relationship in those

#purva will ask about hotelroom feature. they're collected from costar and there's a formula to calculate hotel room with
# a formula check or something

# can compare hotel to services sector or employment

#vacancyrate is just vacant units = total unit / occupiable unit by household population
# should not exceed 4 percent in any year at any geo level

#adu's: don't worry about it for now






#as inputs in part 1, have estimate vs forecast selection and which dof version to be used.

#make this forecast specific, estimations will need minor tweaks later on.


# # Vacancy

# In[223]:


def mgra_vacancy_additions(mgra_df, ds_id, forecast_series_ID): 
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                       'Server=ddamwsql16.sandag.org;'
                      'Database=demographic_warehouse;'
                     'Trusted_Connection=yes;')

    # This series 14 corresponds to the forecast version 
    # that we are using (Which used series 13 of the MGRAS). If I am looking at MGRA from a GIS layer, that is based 
    # on series 13 of MGRA. Series 14 MGRA was never used. Series 14 of the forecasts will have MGRA_ID because 
    # Series 13 mgra has an issue.
    dim_mgra = f"SELECT [mgra_id], [mgra], [cpa], [cpa_id], [jurisdiction] FROM [demographic_warehouse].    [dim].[mgra_denormalize]  WHERE series={forecast_series_ID}" 
    d_mgra= pd.read_sql_query(dim_mgra, conn)

    housing= f"SELECT [housing_id],[datasource_id],[yr_id],[mgra_id],[structure_type_id],[units],[occupied],    [vacancy],[unoccupiable] FROM [demographic_warehouse].[fact].[housing]  WHERE datasource_id={ds_id}"
    d_housing= pd.read_sql_query(housing, conn)
    
    merged = d_housing.merge(d_mgra, how='left', on='mgra_id')
    
    # MGRA
    mgra_vacancy = merged[['mgra', 'yr_id', 'units', 'vacancy', 'unoccupiable']]
    mgra_vacancy = mgra_vacancy.groupby(['mgra', 'yr_id']).sum()
    mgra_vacancy['vacancy_rate'] = ((mgra_vacancy['vacancy'] - mgra_vacancy['unoccupiable']) / mgra_vacancy['units']) * 100

    mgra_vacancy.index = mgra_vacancy.index.set_names('year', level=1)
    
    # Merge this dataframe with the mgra_df
    return mgra_df.join(mgra_vacancy, how='left')


# In[224]:


vacancy_test = mgra_vacancy_additions(mgra_second, 35, 14)
vacancy_test


# In[ ]:





# In[225]:


# CAN BE USED FOR ROLL UP TEST FUNCTION MAYBE?

# # CPA
# cpa_vacancy = merged[['cpa', 'yr_id', 'units', 'vacancy', 'unoccupiable']]
# cpa_vacancy = cpa_vacancy.groupby(['cpa', 'yr_id']).sum()
# cpa_vacancy['vacancy_rate'] = ((cpa_vacancy['vacancy']-cpa_vacancy['unoccupiable']) / cpa_vacancy['units']) * 100
# cpa_vacancy

# # Jurisdiction
# jur_vacancy = merged[['jurisdiction', 'yr_id', 'units', 'vacancy', 'unoccupiable']]
# jur_vacancy = jur_vacancy.groupby(['jurisdiction', 'yr_id']).sum()
# jur_vacancy['vacancy_rate'] = ((jur_vacancy['vacancy']-jur_vacancy['unoccupiable']) / jur_vacancy['units'])*100
# jur_vacancy

# # Region 
# reg_vacancy = merged[['yr_id', 'units', 'vacancy', 'unoccupiable']]
# reg_vacancy = reg_vacancy.groupby('yr_id').sum()
# reg_vacancy['vacancy_rate'] = ((reg_vacancy['vacancy']-reg_vacancy['unoccupiable']) / reg_vacancy['units'])*100
# reg_vacancy


# In[ ]:





# In[226]:


def check_vacancy_rate(mgra_df):
    
    vacancy_flag = copy.deepcopy(mgra_df)
    vacancy_flag['Flag'] = mgra_df['vacancy_rate'] >= 4
    
    return vacancy_flag


# In[227]:


vacancy_check_test = check_vacancy_rate(vacancy_test)
vacancy_check_test


# In[ ]:





# 

# # Schools

# In[228]:


# Population by age group, School enrollment 
# Further dissection we will look at: elementary or secondary or unified 
# Seperate out into columns 


# ### Category Breakdown 
# Below are the only options
# 1. Just Unified - 16086
# 2. Secondary and Elementary no Unified - 11230

# ### Population work

# ### Join Age Group Data with school data

# ### School/Population Function
# This is the building of a function that appends the extra school information to the MGRA level dataframe. 

# In[229]:


def mgra_school_pop_additions(mgra_df, ds_id, forecast_series_ID): 
    # From the dim table bring in information on elementary,secondary, and school district info. 
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                   'Server=ddamwsql16.sandag.org;'
                  'Database=demographic_warehouse;'
                 'Trusted_Connection=yes;')

    query = "SELECT * FROM [demographic_warehouse].[dim].[mgra_denormalize]"
    school_data = pd.read_sql_query(query, conn)

    s_14_school_data = school_data[school_data['series']==forecast_series_ID] # This is forecast 14

    mgra_school_data = s_14_school_data[['mgra_id', 'mgra', 'secondary', 'elementary','unified']]

    # This is creating a new column that tells us which information is present in regards to school district, secondary, elementary info.
    conditions = [
        (mgra_school_data['secondary'].isna()) & (mgra_school_data['elementary'].isna()) & (~mgra_school_data['unified'].isna()),
        (~mgra_school_data['secondary'].isna()) & (~mgra_school_data['elementary'].isna()) & (mgra_school_data['unified'].isna())
    ]

    values = ['Only Unified', 'S&E No Unified']

    mgra_school_data['School Data Present'] = np.select(conditions, values)

    mgra_school_data = mgra_school_data.reset_index()

    # Here we are bringing in from the fact table, age information  
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                    'Server=ddamwsql16.sandag.org;'
                    'Database=demographic_warehouse;'
                    'Trusted_Connection=yes;')

    age_group_breakdown_query = f"SELECT [yr_id],[mgra_id],[age_group_id],[population] FROM [demographic_warehouse].[fact].[age] WHERE [age_group_id] IN (1,2,3,4,5) AND [yr_id] >= 2016 AND [datasource_id] = {ds_id};"

    age_group_breakdown = pd.read_sql_query(age_group_breakdown_query, conn)

    # Using the names of the category IDs (Found: [demographic_warehouse].[dim].[age_group]) this will rename the categories to their actual names
    conditions_2 = [
        (age_group_breakdown['age_group_id'] == 1),
        (age_group_breakdown['age_group_id'] == 2),
        (age_group_breakdown['age_group_id'] == 3),
        (age_group_breakdown['age_group_id'] == 4),
        (age_group_breakdown['age_group_id'] == 5)
        ]

    values_2 = ['Under 5', '5 to 9', '10 to 14', '15 to 17', '18 to 19']

    age_group_breakdown['Age Group'] = np.select(conditions_2, values_2)

    age_group_breakdown = age_group_breakdown.drop('age_group_id', axis=1)

    # Joining age with school data
    age_school_combined = age_group_breakdown.merge(mgra_school_data, on='mgra_id', how='left')

    final_school_age_combo = age_school_combined.set_index(['mgra','yr_id']) # This is for DSID 35

    # Splitting into different population: High school age and Elementary school age
    elem, high = ['Under 5', '5 to 9', '10 to 14'], ['15 to 17', '18 to 19']
    school_pop = pd.DataFrame()

    school_pop['elem_population'] = final_school_age_combo[final_school_age_combo['Age Group'].isin(elem)].reset_index().groupby(['mgra', 'yr_id']).sum()['population']
    school_pop['high_population'] = final_school_age_combo[final_school_age_combo['Age Group'].isin(high)].reset_index().groupby(['mgra', 'yr_id']).sum()['population']

    school_pop.index = school_pop.index.set_names('year', level=1)

    # Merge this dataframe with the mgra_df
    return mgra_df.join(school_pop, how='left')


# In[230]:


school_pop_test = mgra_school_pop_additions(mgra_second, 35, 14)
school_pop_test


# # Age

# In[231]:


def mgra_age_pop_additions(mgra_df, ds_id, forecast_series_ID):
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                   'Server=ddamwsql16.sandag.org;'
                  'Database=demographic_warehouse;'
                 'Trusted_Connection=yes;')

    # This series 14 corresponds to the forecast version 
    # that we are using (Which used series 13 of the MGRAS). If I am looking at MGRA from a GIS layer, that is based 
    # on series 13 of MGRA. Series 14 MGRA was never used. Series 14 of the forecasts will have MGRA_ID because 
    # Series 13 mgra has an issue.
    dim_mgra = f"SELECT [mgra_id], [mgra], [cpa], [cpa_id], [jurisdiction] FROM [demographic_warehouse].    [dim].[mgra_denormalize]  WHERE series={forecast_series_ID}" 
    d_mgra= pd.read_sql_query(dim_mgra, conn)

    # Age population query 
    age_query = f"SELECT [yr_id],[mgra_id],dim.name,[population] FROM [demographic_warehouse].[fact].[age]    AS fact LEFT JOIN dim.age_group AS dim ON dim.age_group_id = fact.age_group_id WHERE     datasource_id = {ds_id};"

    age = pd.read_sql_query(age_query, conn)
    
    # merge to add mgra_id / mgra values. Pivot to group mgra and yr_id as index, name as columns, and population as values
    age_merged = age.merge(d_mgra, on='mgra_id')
    age_pop = age_merged.pivot_table(columns='name', index=['mgra', 'yr_id'], values='population', aggfunc='sum')
    age_pop.index = age_pop.index.set_names('year', level=1) # rename index to join with mgra dataframe

    return mgra_second.join(age_pop, how='left')


# In[232]:


age_test = mgra_age_pop_additions(mgra_second, 35, 14)
age_test


# # Ethnicity

# In[233]:


def mgra_ethn_pop_additions(mgra_df, ds_id, forecast_series_ID):
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                   'Server=ddamwsql16.sandag.org;'
                  'Database=demographic_warehouse;'
                 'Trusted_Connection=yes;')

    # This series 14 corresponds to the forecast version 
    # that we are using (Which used series 13 of the MGRAS). If I am looking at MGRA from a GIS layer, that is based 
    # on series 13 of MGRA. Series 14 MGRA was never used. Series 14 of the forecasts will have MGRA_ID because 
    # Series 13 mgra has an issue.
    dim_mgra = f"SELECT [mgra_id], [mgra], [cpa], [cpa_id], [jurisdiction] FROM [demographic_warehouse].    [dim].[mgra_denormalize]  WHERE series={forecast_series_ID}" 
    d_mgra= pd.read_sql_query(dim_mgra, conn)

    # Ethnicity population query 
    ethn_query = f"SELECT [yr_id],[mgra_id],dim.short_name,[population] FROM [demographic_warehouse].[fact].[ethnicity]    AS fact LEFT JOIN [demographic_warehouse].[dim].[ethnicity] AS dim ON fact.ethnicity_id = dim.ethnicity_id WHERE     fact.datasource_id = {ds_id};"

    ethn = pd.read_sql_query(ethn_query, conn)
    
    # merge to add mgra_id / mgra values. Pivot to group mgra and yr_id as index, short_name as columns, and population as values
    ethn_merged = ethn.merge(d_mgra, on='mgra_id')
    ethn_pop = ethn_merged.pivot_table(columns='short_name', index=['mgra', 'yr_id'], values='population', aggfunc='sum')
    ethn_pop.index = ethn_pop.index.set_names('year', level=1) # rename index to join with mgra dataframe

    return mgra_second.join(ethn_pop, how='left')


# In[234]:


ethn_test = mgra_ethn_pop_additions(mgra_second, 35, 14)
ethn_test


# # Sex

# In[235]:


def mgra_sex_pop_additions(mgra_df, ds_id, forecast_series_ID):
    conn = pyodbc.connect('Driver={ODBC Driver 17 for SQL Server};'
                       'Server=ddamwsql16.sandag.org;'
                      'Database=demographic_warehouse;'
                     'Trusted_Connection=yes;')
    
    # This series 14 corresponds to the forecast version 
    # that we are using (Which used series 13 of the MGRAS). If I am looking at MGRA from a GIS layer, that is based 
    # on series 13 of MGRA. Series 14 MGRA was never used. Series 14 of the forecasts will have MGRA_ID because 
    # Series 13 mgra has an issue.
    dim_mgra = f"SELECT [mgra_id], [mgra], [cpa], [cpa_id], [jurisdiction] FROM [demographic_warehouse].    [dim].[mgra_denormalize]  WHERE series={forecast_series_ID}" 
    d_mgra= pd.read_sql_query(dim_mgra, conn)

    # Sex population query 
    sex_query = f"SELECT [yr_id],[mgra_id],dim.sex,[population] FROM [demographic_warehouse].[fact].[sex]    AS fact LEFT JOIN dim.sex AS dim ON fact.sex_id = dim.sex_id WHERE     fact.datasource_id = {ds_id};"

    sex = pd.read_sql_query(sex_query, conn)

    # merge to add mgra_id / mgra values. Pivot to group mgra and yr_id as index, short_name as columns, and 
    # aggregate by summing the population values
    sex_merged = sex.merge(d_mgra, on='mgra_id')
    sex_pop = sex_merged.pivot_table(columns='sex', index=['mgra', 'yr_id'], values='population', aggfunc='sum')
    sex_pop.index = sex_pop.index.set_names('year', level=1) # rename index to join with mgra dataframe

    return mgra_second.join(sex_pop, how='left')


# In[236]:


sex_test = mgra_sex_pop_additions(mgra_second, 35, 14)
sex_test


# In[ ]:




