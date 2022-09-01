<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `perform_checks`
TODO: One line description 

TODO: Long form description 



---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L16"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `InternalConsistency`
TODO: One line description 

TODO: Long form description 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L138"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_geography_aggregations`

```python
check_geography_aggregations(df_dict, geo_list=['mgra', 'luz'])
```

Take the outputs of get_data_with_aggregation_levels and check that values match up 



**Args:**
 
 - <b>`df_dict`</b> (dict of pandas.DataFrame):  TODO 
 - <b>`geo_list`</b> (list):  TODO 



**Returns:**
 None, but prints out differences if present 

---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L24"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `get_data`

```python
get_data(folder, filter)
```

Finds the best match file in the input folder and returns it as a DataFrame 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which to search for data. Uses pathlib.Path for   platform independent behavoir. 
 - <b>`filter`</b> (str):  Used to identify *ONE* file in the folder.  



**Returns:**
 
 - <b>`pd.DataFrame`</b>:  The found file as a df 



**Raises:**
 
 - <b>`FileNotFoundError`</b>:  When either too many files were found or no files were found 

---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L55"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `get_data_with_aggregation_levels`

```python
get_data_with_aggregation_levels(folder, geo_list=['mgra', 'luz'])
```

Get data and combine with the proper columns of mgra_denormalize for aggregation 

Gets region level data by default, and whatever geography levels are present in geo_list. Uses [demographic_warehouse].[dim].[mgra_denormalize] and a lookup table (defined in the function,  yes I know its bad design) to know which columns to add to each geography level table. For  example, the lookup table tells the fuction to add on "jurisdiction" and "region" columns for the "mgra" geo_level 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found 
 - <b>`geo_list`</b> (list):  The list of geographies to get data for. Note that region is included by  default, so do not include it here 



**Returns:**
 
 - <b>`dict`</b> (pandas.DataFrame):  The key is the geography level, and the value is the table 


---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L203"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `NullValues`
TODO: One line description 

TODO: Long form description 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L216"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `VintageComparisons`
TODO: One line description 

TODO: Long form description 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L229"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ThresholdAnalysis`
TODO: One line description 

TODO: Long form description 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L248"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFPopulation`
TODO: One line description 

TODO: Long form description 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L261"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFProportion`
TODO: One line description 

TODO: Long form description 







---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
