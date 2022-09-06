<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `generate_tables`
Classes/functions to return/save various Estimates tables. 

The functions in this file all create tables directly using Estimates data from [DDAMWSQL16].[estimates]. Although the data in the created tables can be analyzed directly for any errors present in raw data, it is recommended that checks are done using the classes/functions in the file "perform_checks.py". 



---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L27"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `EstimatesTables`
Functions to return/save various Estimates tables. 

The functions in this class all create tables directly using Estimates data from  [DDAMWSQL16].[estimates]. The functions in this file do not run any checks, nor do they  create any kind of derived output such as diff files. 




---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L344"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `consolidate`

```python
consolidate(
    est_vintage,
    geo_list=['region', 'jurisdiction', 'cpa'],
    est_table_list=['age', 'ethnicity', 'household_income', 'households', 'housing', 'population', 'sex'],
    save=False,
    save_folder=None
)
```

Create consolidated files with all Estimates table for each geography level. 

This function returns one pd.DataFrame per input geography level, as opposed to combining  everything together. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates table to pull from. In DDAMWSQL16, this   variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]" 
 - <b>`geo_list`</b> (List of str):  The geographies to cosolidate along.  
 - <b>`est_table_list`</b> (List of str):  Which estimates tables we want to consolidate 
 - <b>`save`</b> (bool):  False by default. If False, then only return the consolidated tables. If   True, then use save_folder to save the consolidated tables and return the tables 
 - <b>`save_folder`</b> (pathlib.Path):  None by default. If save=True, then the folder to save in as a   pathlib.Path object 



**Returns:**
 
 - <b>`List of pd.DataFrame`</b>:  A list containing the consolidated tables in the order of geo_list 

---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L40"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `get_table_by_geography`

```python
get_table_by_geography(
    est_vintage,
    est_table,
    geo_level,
    pivot=False,
    debug=False
)
```

Get the input estimates table grouped by the input geography level. 

This function will return the requested Estimates table from the requested vintage. The relevant joins will be made on the base table as specified in the default config file. The returned table will by zero indexed and have no multi-columns. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates table to pull from. In DDAMWSQL16, this  variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]" 
 - <b>`est_table`</b> (str):  The Estimates table to pull from. In DDAMWSQL16, this variable   corresponds to XXXX in the table "[estimates].[est_YYYY_MM].[dw_XXXX]" 
 - <b>`geo_level`</b> (str):  The geography level to aggregate by. This can be any of the columns in   the DDAMWSQL16 table [demographic_warehouse].[dim].[mgra_denormalize]. For example,  you could input "region", "jurisdiction", "mgra", etc. 
 - <b>`pivot`</b> (bool):  Default False. If True, return the table in wide format instead of tall 
 - <b>`debug`</b> (bool):  Default False. If True, print out diagnostic print statements during   execution including the complete SQL query used 



**Returns:**
 
 - <b>`pd.DataFrame`</b>:  The requested Estimates table grouped by the geography level 

---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L403"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `individual`

```python
individual(
    est_vintage,
    geo_list=['region', 'jurisdiction', 'cpa'],
    est_table_list=['age', 'ethnicity', 'household_income', 'age_ethnicity', 'age_sex_ethnicity'],
    save=False,
    save_folder=None
)
```

Create individual files for each unique conbination of Estimate table and geography level. 

Generate individual estimates tables for each input geography. This function returns one dataframe for each geography level / estimate table. Because of the way looping is done, the  order of dfs is first geo_level each estimate table, second geo_level each estimate table, etc. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates table to pull from. In DDAMWSQL16, this   variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]" 
 - <b>`geo_list`</b> (List of str):  The geographies to cosolidate along.  
 - <b>`est_table_list`</b> (List of str):  Which estimates tables we want to consolidate 
 - <b>`save`</b> (bool):  False by default. If False, then only return the consolidated tables. If   True, then use save_folder to save the consolidated tables and return the tables 
 - <b>`save_folder`</b> (pathlib.Path):  None by default. If save=True, then the folder to save in as a   pathlib.Path object 



**Returns:**
 
 - <b>`List of pd.DataFrame`</b>:  A list containing the individual tables in the order of geo_list and  est_table_list. 


---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L454"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DiffFiles`
Functions to return/save various Estimates diff tables. 

The functions in this class create diff files either directly from [DDAMWSQL16].[estimates] or from previously saved files. The output diff files will always be returned in case you want to hold them in memory. There is also an option to save the files at the specified location. The diff files can either be absolute change, percentage change, or both. As with the class Esimates Tables, the functions in this file do not run any checks. 







---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
