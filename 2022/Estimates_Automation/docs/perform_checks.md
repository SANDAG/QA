<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `perform_checks`
Classes/functions to run various checks on Estimates tables. 

The functions in this file run checks on Estimates tables. These functions can only pull data from saved files. Each function should by default print out the status of the check, such as which check is being run and the rows where errors may have occurred. 

Currently work in progress is the ability to save the outputs of the checks if requested. For  which checks currently have this functionality, look for the save=False and save_location=??? parameters in the function signature. 



---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L30"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `InternalConsistency`
Functions to run internal consistency checks. 

For the purposes of this class, internal consistency checks mean checking if aggregated values match up when aggregating to/from different geography levels. For example, checking if the total population variable, when aggregated from mgra --> region, matches up with the values at the  region level. 



**Attributes:**
 
 - <b>`_geography_aggregation`</b> (dict of list):  A dictionary with key equals to a geography level,   and the value equals to a list containing geographies to aggregate to. For example, for  the key value of "mgra", the value would contain ["jurisdiction", "region"] because   "mgra" aggregates up to both of those geography levels. 
 - <b>`_est_table_by_type`</b> (dict of list):  A dictionary with key equals to measure type and the  value equals to a list of the Estimates tables which have that measure type. For   example, for the key "population", the value would include "age" because the age table  breaks down age categories by population. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L128"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L209"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L300"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `NullValues`
Functions to check for any null values. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L343"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L381"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `VintageComparisons`
N/A. Done already by generate_tables.DiffFiles. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L390"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ThresholdAnalysis`
Calculates year-on-year% changes and flags if the changes are more than 5%. 

For the purposes of this class, threshold analysis checks mean checking if between any two  versions, the changes in values differ by more than 5%. For example, flagging if total  population in the region changes by more than 5% in one year. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L487"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L528"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `TrendAnalysis`
N/A. Done in PowerBI. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L537"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFPopulation`
Check that the total population of the region is within 1.5% of CA DOF population. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L628"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

Check Estimates population are within a certain threshold of CA DOF population values. 

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

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L672"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFProportion`
Compares the proportion of groups between DOF and Estimates. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L675"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_DOF_proportion`

```python
check_DOF_proportion(
    threshold=4,
    vintage='2020_06',
    geo_list=['region', 'jurisdiction'],
    raw_folder=WindowsPath('data/raw_data'),
    DOF_folder=WindowsPath('data/CA_DOF'),
    save=False,
    save_location=WindowsPath('data/outputs')
)
```

Check the proportions of groups between Estimates and CA DOF are roughly the same. 

Specifically, the groups which are checked are % of population in households vs group quarters, % of households which are single detached vs single attached vs mobile home vs multifamily, and % of households which are occupied vs vacant. If the differences in  percent between Estimates and CA DOF data are greater than the input threshold, then those rows of data will be printed out and saved if requested 



**Args:**
 
 - <b>`threshold`</b> (float):  Default value of 4(%). The amount of absolute allowable difference  in proportions. For example, if the percent of total population in group quarters   compared between DOF and Estimates is greater than threshold, then that row is   flagged 
 - <b>`vintage`</b> (str):  Default value of "2020_06". The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list):  The list of geographies to check. This can only contain "region" and  "jurisdiction" due to limitations of DOF data. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/raw_data/". The folder in which   raw Estimates data can be found. 
 - <b>`raw_folder`</b> (pathlib.Path):  Default value of "./data/CA_DOF/". The folder in which   transformed CA DOF data can be found. 
 - <b>`save`</b> (bool):  Default value of False. If True, save the outputs of the check to the input  save_location if and only if errors have been found. 
 - <b>`save_location`</b> (pathlib.Path):  Default value of "./data/outputs/". The location to save   check results. 



**Returns:**
 None, but prints out differences if present. Also saves output if requested and errors  have been found. 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
