<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `perform_checks`
Classes/functions to run various checks on Estimates tables. 

The functions in this file run checks on Estimates tables. These functions can only pull data from saved files. By default, they output only print statements, but there is an option to save a  table containing rows with errors at some location. For more details, see the individual  classes/functions. 



---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L60"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `InternalConsistency`
Functions to run internal consistency checks. 

For the purposes of this class, internal consistency checks mean checking if aggregated values match up when aggregating to/from different geography levels. For example, checking if the total population variable, when aggregated from mgra --> region, matches up with the values at the  region level. 



**Attributes:**
 
 - <b>`geography_aggregation`</b> (dict of List):  A dictionary with key equals to a geography level,   and the value equals to a List containing geographies to aggregate to. For example, for  the key value of "mgra", the value would contain ["jurisdiction", "region"] because   "mgra" aggregates up to both of those geography levels. 




---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L145"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `check_geography_aggregations`

```python
check_geography_aggregations(folder, geo_list=['mgra', 'luz'])
```

Take the outputs of get_data_with_aggregation_levels and check that values match up. 



**Args:**
 
 - <b>`folder`</b> (pathlib.Path):  The folder in which data can be found. 
 - <b>`geo_list`</b> (list):  The list of geographies to aggregate from. Note that region is included   by default, so do not include it here. 



**Returns:**
 None, but prints out differences if present. 


---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L217"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `NullValues`
TODO: One line description. 

TODO: Long form description. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L230"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `VintageComparisons`
TODO: One line description. 

TODO: Long form description. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L243"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ThresholdAnalysis`
TODO: One line description. 

TODO: Long form description. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L262"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFPopulation`
TODO: One line description. 

TODO: Long form description. 





---

<a href="..\..\..\2022\Estimates_Automation\perform_checks.py#L275"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DOFProportion`
TODO: One line description. 

TODO: Long form description. 







---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
