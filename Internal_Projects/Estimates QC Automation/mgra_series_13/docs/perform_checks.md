<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `perform_checks`
Classes/functions to run various checks on Estimates tables. 

The functions in this file run checks on Estimates tables. These functions can only pull data from saved files. Each function should by default print out the status of the check, such as which check is being run and the rows where errors may have occurred. 



---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L26"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `InternalConsistency`
Functions to run internal consistency checks. 

For the purposes of this class, internal consistency checks mean one of two things: 1.  Checking if aggregated values match up when aggregating to/from different geography levels.  For example, checking if the total population variable, when aggregated from mgra -->   region, matches up with the values at the region level.  2.  Checking if aggregated values a across Estimates tables match up. For example, checking if  the total population of Carlsbad in 2010 is the same when comparing total population vs   total population from the age_sex_ethnicity table vs total population from household/group  quarters population vs etc. 



**Attributes:**
 
 - <b>`geography_aggregation`</b> (dict of list):  A dictionary with key equals to a geography level,   and the value equals to a list containing geographies to aggregate to. For example, for  the key value of "mgra", the value would contain ["jurisdiction", "region"] because  
 - <b>`"mgra" aggregates up to both of those geography levels. NOTE`</b>:  "luz" or Land Use Zone cannot be added here because "luz" does not exist in  [demographic_warehouse].[dim].[mgra_denormalize]. If you want to add "luz", the  crosswalk has to be pulled from [GeoDepot].[gis].[MGRA##] in sql2014b8 (not  DDAMWSQL16), where ## has the correct MGRA series number. 
 - <b>`_est_table_by_type`</b> (dict of list):  A dictionary with key equals to measure type and the  value equals to a list of the Estimates tables which have that measure type. For   example, for the key "population", the value would include "age" because the age table  breaks down age categories by population. 




---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L121"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_geography_aggregations`

```python
check_geography_aggregations(
    vintage='2020_06',
    geo_list=['mgra', 'luz'],
    est_table='consolidated',
    raw_folder=WindowsPath('data/raw_data'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check that values match up when aggregating geography levels upwards. 



**Args:**
 
 - <b>`vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list):  The list of geographies to aggregate from. Note that region is included   by default, so do not include it here. 
 - <b>`est_table`</b> (str):  Default value of "consolidated". The Estimate table to check. This   should basically always be "consolidated", but it is included here in the off chance  it is not. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/raw_data/". The folder in which   raw Estimates data can be found. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to save   check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 

---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L225"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_internal_aggregations`

```python
check_internal_aggregations(
    vintage='2020_06',
    geo_list=['region', 'jurisdiction'],
    est_table_types=['population', 'households'],
    raw_folder=WindowsPath('data/raw_data'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check that values match up when aggregating across Estimates tables. 

For example, this function could check that the total population in the San Diego region in 2010 is the same between the tables population, age, and sex. 



**Args:**
 
 - <b>`vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list of str):  The list of geographies to aggregate from. Note that region is included   by default, so do not include it here. 
 - <b>`est_table_types`</b> (list of str):  Which kinds of Estimates tables to check. Or in other   words, which value is in the cell. For example, the age table contains the age   breakdown by population, while the household_income table contains the household  income breakdown by number of households. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/raw_data/". The folder in which   raw Estimates data can be found. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to save   check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 


---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L324"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `NullValues`
Functions to check for any null values. 

At this time, this class only checks for missing data. This class does not have the  functionality to check for missing geographies. For example, this class can find that the total population value is missing for a certain mgra in a certain year, but cannot find that an  entire mgra is missing for a certain year. 




---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L407"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `spot_missing_values`

```python
spot_missing_values(
    vintage='2020_06',
    geo_list=['region', 'jurisdiction', 'mgra'],
    est_table_list=['age', 'ethnicity'],
    raw_folder=WindowsPath('data/raw_data'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check that each unique combination of geography and year exist. 

For example, make sure that all 19 jurisdictions (including un-incorporated) has the correct number of years associated with each jurisdiction. This function will print out errors if  encountered, and will save the error outputs if errors are found. 



**Args:**
 
 - <b>`vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list):  The list of geographies to check. 
 - <b>`est_table_list`</b> (str):  The Estimates tables to check. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/raw_data/". The folder in which   raw Estimates data can be found. Due to the extreme runtime of "mgra", it is   possible that files are not saved locally. In that case, or for any files that are  missing, ONLY the geography and year columns will be pulled directly from SQL Server 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to save   check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 

---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L373"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `spot_nulls`

```python
spot_nulls(
    vintage='2020_06',
    geo_list=['region', 'jurisdiction'],
    est_table_list=['household_income', 'age_ethnicity', 'population'],
    raw_folder=WindowsPath('data/raw_data'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check if null values exist in any of the input tables. 



**Args:**
 
 - <b>`vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list):  The list of geographies to check. 
 - <b>`est_table_list`</b> (str):  The Estimates tables to check. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/raw_data/". The folder in which   raw Estimates data can be found. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to save   check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 


---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L488"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `VintageComparisons`
Functions to check that numbers between vintages does not exceed a % and numeric threshold. 




---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L491"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `vintage_change`

```python
vintage_change(
    old_vintage='2020_06',
    new_vintage='2021_01',
    p_threshold=5,
    n_threshold=500,
    diff_data_folder=WindowsPath('data/diff'),
    geo_list=['region', 'jurisdiction'],
    est_table_list=['age', 'ethnicity', 'household_income', 'age_ethnicity'],
    save=True,
    outputs_folder=WindowsPath('data/outputs')
)
```

Get diff data and check for extreme changes in values between vintages. 



**Args:**
 
 - <b>`old_vintage`</b> (str):  The old vintage to compare with 
 - <b>`new_vintage`</b> (str):  The new vintage to compare with. 
 - <b>`p_threshold`</b> (float):  Default value of 5(%). The percentage we can go above/below   previous values and still consider it reasonable. Somewhat arbitrarily chosen to be  honest. 
 - <b>`n_threshold`</b> (float):  Default value of 500. The amount we can go above/below   previous values and still consider it reasonable. Somewhat arbitrarily chosen to be  honest. 
 - <b>`raw_data_folder`</b> (pathlib.Path):  pathlib.Path("./data/raw_data/") by default. The   location where raw data has been saved. It is expected that the files are saved  using functions.save in order to keep file formats consistent 
 - <b>`geo_list`</b> (list of str):  The geographies to create diff files for.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to create diff files.  Because of the unique way file names are generated, a valid item of this list is  "consolidated" 
 - <b>`save`</b> (bool):  True by default. If True, then use save_folder to save the diff files. At  this time, False has no functionality, but this may change later 
 - <b>`save_folder`</b> (pathlib.Path):  pathlib.Path("./data/diff/") by default. The location to   save diff files 



**Returns:**
 None 


---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L608"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ThresholdAnalysis`
Calculates yearly change and flags if the changes are more than some % and some value. 

For the purposes of this class, threshold analysis checks mean checking if between any two  versions, the changes in values differ by more than 5% and 500. For example, flagging if total  population in the region changes by more than 5% and 500 people in one year. The threshold  values are configurable, of course. 




---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L715"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_thresholds`

```python
check_thresholds(
    p_threshold=5,
    n_threshold=500,
    vintage='2020_06',
    geo_list=['region', 'jurisdiction'],
    est_table_list=['household_income', 'age_ethnicity', 'population'],
    raw_folder=WindowsPath('data/raw_data'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Ensure that the yearly change does not exceed a specified threshold. 



**Args:**
 
 - <b>`threshold`</b> (float):  Default value of 5(%). The percentage we can go above/below previous  values and still consider it reasonable. Somewhat arbitrarily chosen to be honest. 
 - <b>`vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list):  The list of geographies to check. 
 - <b>`est_table_list`</b> (str):  The Estimates tables to check. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/raw_data/". The folder in which   raw Estimates data can be found. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to save   check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 

---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L617"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `yearly_change`

```python
yearly_change(
    raw_folder,
    vintage,
    geo,
    table_name,
    p_threshold=5,
    n_threshold=500,
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Get data and check for yearly changes in values. 

Gets region level data by default, and whatever geography levels are present in geo_list.  Then checks to see if there exists any columns where difference in values is larger than 5%. 



**Args:**
 
 - <b>`raw_folder`</b> (pathlib.Path):  The folder in which raw Estimates data can be found. 
 - <b>`vintage`</b> (str):  The vintage of interest. 
 - <b>`geo`</b> (str):  The geography level of interest. 
 - <b>`table_name`</b> (str):  The name of the Estimates table to get. Because it is assumed that  the saved tables are created by the file generate_tables.py, this can be any of  "consolidated" or the name of the Estimates table (such as "age" or "ethnicity"). 
 - <b>`col`</b> (str):  The column name to choose to check for changes. 
 - <b>`p_threshold`</b> (float):  Default value of 5(%). The percentage we can go above/below   previous values and still consider it reasonable. Somewhat arbitrarily chosen to be  honest. 
 - <b>`n_threshold`</b> (float):  Default value of 500. The amount we can go above/below   previous values and still consider it reasonable. Somewhat arbitrarily chosen to be  honest. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  The location to save check results. 



**Returns:**
 None 


---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L758"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `TrendAnalysis`
N/A. Done in PowerBI. 





---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L767"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFPopulation`
Check that the total population of the region is within 1.5% of CA DOF population. 




---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L774"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `region_DOF_population_comparison`

```python
region_DOF_population_comparison(
    raw_folder,
    est_vintage,
    DOF_vintage,
    threshold=1.5,
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check that the total population of the region is within 1.5% of CA DOF population. 



**Attributes:**
 
 - <b>`raw_folder`</b> (pathlib.Path):  The folder where raw Estimates data and CA DOF data can be   found. Most likely "./data/raw_data/". 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates data to compare with DOF data. 
 - <b>`DOF_vintage`</b> (str):  The vintage of DOF data to compare with Estimates data. 
 - <b>`threshold`</b> (float):  Default value of 1.5(%). The percentage we can go above/below CA DOF   population numbers. If the value of this variable is (for example) 1.5%, that means   that our population numbers must be less than DOF + 1.5% and must be greater than   DOF - 1.5%. The reason a value of 1.5% is used is because on SB375 p.23-24, SANDAG   is required to have population projections within a range of 3% of CA DOF population  projections. A range of 3% is equivalent to +/- 1.5% 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  The location to save check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 


---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L842"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFProportion`
Compares the proportion of groups between DOF and Estimates. 




---

<a href="..\..\..\2022\Estimates_QC_Automation\perform_checks.py#L845"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_DOF_proportion`

```python
check_DOF_proportion(
    threshold=1.5,
    est_vintage='2021_01',
    DOF_vintage='2021_07_14',
    prop_folder=WindowsPath('data/proportion'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check the proportions of groups between Estimates and CA DOF are roughly the same. 

Due to limitations of CA DOF data, the only groups which are checked are population values split by age/sex/ethnicity, both row sum proportions and column sum proportions. If you  don't know what row/column sum proportions are, please refer to the function  create_est_proportion_tables in the file generate_tables.py. 

If the differences in proportion distributions between Estimates and CA DOF data are greater than the input threshold, then those rows of data will be printed out and saved if  requested.  

NOTE: Estimates and CA DOF ethnicity categories overlap nicely, with the exception of  Estimates data having an extra category: "Non-Hispanic, Other". This category is ignored when doing proportion checks. Typically, in Estimates, the "Non-Hispanic, Other" category is a very tiny percentage of the row/column total, so it typically does not effect anything 



**Args:**
 
 - <b>`threshold`</b> (float):  Default value of 1.5(%). The amount of absolute allowable difference  in proportions. For example, if the percent of total population in group quarters   compared between DOF and Estimates is greater than threshold, then that row is   flagged 
 - <b>`est_vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull   from.  
 - <b>`DOF_vintage`</b> (str):  Default value of "2021_07_14". The vintage of CA DOF table to pull   from.  
 - <b>`prop_folder`</b> (pathlib.Path):  Default value of "./data/proportion/". The folder in which   proportion data can be found. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to   save check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
