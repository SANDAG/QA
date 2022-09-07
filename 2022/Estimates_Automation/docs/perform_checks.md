<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `perform_checks`
Classes/functions to run various checks on Estimates tables. 

The functions in this file run checks on Estimates tables. These functions can only pull data from saved files. By default, they output only print statements, but there is an option to save a  table containing rows with errors at some location. For more details, see the individual  classes/functions. 



---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L26"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `InternalConsistency`
Functions to run internal consistency checks. 

For the purposes of this class, internal consistency checks mean checking if aggregated values match up when aggregating to/from different geography levels. For example, checking if the total population variable, when aggregated from mgra --> region, matches up with the values at the  region level. 



**Attributes:**
 
 - <b>`geography_aggregation`</b> (dict of List):  A dictionary with key equals to a geography level,   and the value equals to a List containing geographies to aggregate to. For example, for  the key value of "mgra", the value would contain ["jurisdiction", "region"] because   "mgra" aggregates up to both of those geography levels. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L112"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_geography_aggregations`

```python
check_geography_aggregations(folder, vintage, geo_list=['mgra', 'luz'])
```

Take the outputs of get_data_with_aggregation_levels and check that values match up. 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found. 
 - <b>`vintage`</b> (str):  The vintage of Estimates table to pull from.  
 - <b>`geo_list`</b> (list):  The list of geographies to aggregate from. Note that region is included   by default, so do not include it here. 



**Returns:**
 None, but prints out differences if present. 


---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L185"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `NullValues`
Function to check for any null values. 

For the purposes of this function, null value checks mean checking each and every columns to see if there are any null values present. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L192"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `spot_nulls`

```python
spot_nulls(folder, vintage, geo, table_name)
```

Get data and check for nulls. 

Gets region level data by default, and whatever geography levels are present in geo_list.  Then checks to see if there are any null values present 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found. 
 - <b>`table_name`</b> (str):  The name of the Estimates table to get. Because it is assumed that  the saved tables are created by the file generate_tables.py, this can be any of  "consolidated" or the name of the Estimates table (such as "age" or "ethnicity") 
 - <b>`geo`</b> (str):  The geography level to get data for and add aggregation columns onto 



**Returns:**
 
 - <b>`List`</b>:  the list contains column names that contain null values along with the string "Null values present in the following columns:" 


---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L221"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `VintageComparisons`
TODO: One line description. 

TODO: Long form description. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L234"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ThresholdAnalysis`
Calculates year-on-year% changes and flags if the changes are more than 5%. 

For the purposes of this class, threshold analysis checks mean checking if between any two versions, the changes in values differ by more than 5%. For example, flagging if total population in certain region  changes by more than 5%. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L242"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `yearly_change`

```python
yearly_change(folder, vintage, geo, table_name, col)
```

Get data and check for yearly changes in values. 

Gets region level data by default, and whatever geography levels are present in geo_list.  Then checks to see if there exists any columns where difference in values is larger than 5%. 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found. 
 - <b>`table_name`</b> (str):  The name of the Estimates table to get. Because it is assumed that  the saved tables are created by the file generate_tables.py, this can be any of  "consolidated" or the name of the Estimates table (such as "age" or "ethnicity") 
 - <b>`geo`</b> (str):  The geography level to get data for and add aggregation columns onto 
 - <b>`col`</b> (str):  The column name to choose to check for changes > 5% 



**Returns:**
 
 - <b>`List`</b>:  the list contains years where the yearly changes > 5% 


---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L281"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFPopulation`
TODO: One line description. 

TODO: Long form description. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L294"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFProportion`
Compares the proportion of groups in total pop between DOF and Estimates at Regional Level 

Comparison is across different groups like household income, age, gender, ethnicity, ethnicity by age, ethnicity by gender by age. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L299"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `shares`

```python
shares(df, threshold_dict)
```

Get data and compare the proportion changes between DOF and Estimates. 

Checks at region level whether there exists any columns where proportion of groups is different. 

**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found. 
 - <b>`table_name`</b> (str):  The name of the Estimates table to get. Because it is assumed that  the saved tables are created by the file generate_tables.py, this can be any of  "consolidated" or the name of the Estimates table (such as "age" or "ethnicity") 
 - <b>`geo`</b> (str):  The geography level to get data for and add aggregation columns onto 
 - <b>`col`</b> (str):  The column name to choose to check for changes > 5% 



**Returns:**
 
 - <b>`List`</b>:  the list contains years where the yearly changes > 5% 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
