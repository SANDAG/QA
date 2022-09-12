<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `perform_checks`
Classes/functions to run various checks on Estimates tables. 

The functions in this file run checks on Estimates tables. These functions can only pull data from saved files. Each function should by default print out the status of the check, such as which check is being run and the rows where errors may have occured. 

Currently work in progress is the ability to save the outputs of the checks if requested. For  which checks currently have this functionality, look for the save=False and save_location=??? parameters in the function signnature. 



---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L30"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `InternalConsistency`
Functions to run internal consistency checks. 

For the purposes of this class, internal consistency checks mean checking if aggregated values match up when aggregating to/from different geography levels. For example, checking if the total population variable, when aggregated from mgra --> region, matches up with the values at the  region level. 



**Attributes:**
 
 - <b>`geography_aggregation`</b> (dict of List):  A dictionary with key equals to a geography level,   and the value equals to a List containing geographies to aggregate to. For example, for  the key value of "mgra", the value would contain ["jurisdiction", "region"] because   "mgra" aggregates up to both of those geography levels. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L116"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

Take the outputs of get_data_with_aggregation_levels and check that values match up. 



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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L201"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `NullValues`
Functions to check for any null values. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L244"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L282"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `VintageComparisons`
N/A. Done already by generate_tables.DiffFiles. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L291"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ThresholdAnalysis`
Calculates year-on-year% changes and flags if the changes are more than 5%. 

For the purposes of this class, threshold analysis checks mean checking if between any two  versions, the changes in values differ by more than 5%. For example, flagging if total  population in the region changes by more than 5% in one year. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L367"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_thresholds`

```python
check_thresholds(
    threshold=5,
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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L408"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `TrendAnalysis`
N/A. Done in PowerBI. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L417"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFPopulation`
Check that the total population of the region is within 1.5% of CA DOF population. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L508"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_DOF_population`

```python
check_DOF_population(
    threshold=1.5,
    vintage='2020_06',
    geo_list=['region', 'jurisdiction'],
    raw_folder=WindowsPath('data/raw_data'),
    DOF_folder=WindowsPath('data/CA_DOF'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Estimates population values are within a certain threshold of CA DOF population values. 

The default threshold is 1.5%, because as written in SB 375 on p. 23-24, our population  numbers need to be within a RANGE of 3% of CA DOF population numbers. We interpret RANGE to be plus or minus 1.5%. 



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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L555"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFProportion`
Compares the proportion of groups in total pop between DOF and Estimates at Regional Level. 

Comparison is across different groups like household income, age, gender, ethnicity, ethnicity  by age, ethnicity by gender by age. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L562"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `shares`

```python
shares(df, threshold_dict)
```

Get data and compare the proportion changes between DOF and Estimates. 

Checks at region level whether there exists any columns where proportion of groups is different. 

TODO: Below is Calvin's documentation, format as a Google-style docstring 

input: multi-index dataframe (index = (geo_level, year)), columns to check threshold in, value threshold (numeric), percentage threshold (numeric value in {0,1}) 

output: rows of the input multi-index dataframe with yearly differences outside the designated threshold (inclusive) 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found. 
 - <b>`table_name`</b> (str):  The name of the Estimates table to get. Because it is assumed that  the saved tables are created by the file generate_tables.py, this can be any of  "consolidated" or the name of the Estimates table (such as "age" or "ethnicity") 
 - <b>`geo`</b> (str):  The geography level to get data for and add aggregation columns onto 
 - <b>`col`</b> (str):  The column name to choose to check for changes > 5% 



**Returns:**
 
 - <b>`List`</b>:  the list contains years where the yearly changes > 5% 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
