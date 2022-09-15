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

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L379"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `consolidate`

```python
consolidate(
    est_vintage,
    geo_list=['region', 'jurisdiction', 'cpa'],
    est_table_list=['age', 'ethnicity', 'household_income', 'households', 'housing', 'population', 'sex'],
    get_from_file=False,
    raw_folder=None,
    save=False,
    save_folder=None
)
```

Create consolidated files with all Estimates table for each geography level. 

This function returns one pd.DataFrame per input geography level, as opposed to combining  everything together. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates table to pull from. In DDAMWSQL16, this   variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]" 
 - <b>`geo_list`</b> (list of str):  The geographies to consolidate along.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to consolidate. This   function cannot consolidate using the age_ethnicity table nor the   age_sex_ethnicity table  
 - <b>`get_from_file`</b> (bool):  False by default. If True, then pull data from downloaded files  instead of re-downloading and holding in memory 
 - <b>`raw_folder`</b> (pathlib.Path):  Where to find pre-downloaded files 
 - <b>`save`</b> (bool):  False by default. If False, then only return the consolidated tables. If   True, then use save_folder to save the consolidated tables and return the tables 
 - <b>`save_folder`</b> (pathlib.Path):  None by default. If save=True, then the folder to save in as a   pathlib.Path object 



**Returns:**
 None 

---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L40"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `get_table_by_geography`

```python
get_table_by_geography(
    est_vintage,
    geo_level,
    est_table,
    pivot=False,
    debug=False
)
```

Get the input estimates table grouped by the input geography level. 

This function will return the requested Estimates table from the requested vintage. The relevant joins will be made on the base table as specified in the default config file. The returned table will by zero indexed and have no multi-columns. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates table to pull from. In DDAMWSQL16, this  variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]" 
 - <b>`geo_level`</b> (str):  The geography level to aggregate by. This can be any of the columns in   the DDAMWSQL16 table [demographic_warehouse].[dim].[mgra_denormalize]. For example,  you could input "region", "jurisdiction", "mgra", etc. 
 - <b>`est_table`</b> (str):  The Estimates table to pull from. In DDAMWSQL16, this variable   corresponds to XXXX in the table "[estimates].[est_YYYY_MM].[dw_XXXX]" 
 - <b>`pivot`</b> (bool):  Default False. If True, return the table in wide format instead of tall 
 - <b>`debug`</b> (bool):  Default False. If True, print out diagnostic print statements during   execution including the complete SQL query used 



**Returns:**
 
 - <b>`pd.DataFrame`</b>:  The requested Estimates table grouped by the geography level 

---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L452"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

Create individual files for each unique combination of Estimate table and geography level. 

Generate individual estimates tables for each input geography. This function returns one dataframe for each geography level / estimate table. Because of the way looping is done, the  order of dfs is first geo_level each estimate table, second geo_level each estimate table, etc. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage of Estimates table to pull from. In DDAMWSQL16, this   variable corresponds to YYYY_MM in the table "[estimates].[est_YYYY_MM]" 
 - <b>`geo_list`</b> (list of str):  The geographies to consolidate along.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to consolidate 
 - <b>`save`</b> (bool):  False by default. If False, then only return the consolidated tables. If   True, then use save_folder to save the consolidated tables and return the tables 
 - <b>`save_folder`</b> (pathlib.Path):  None by default. If save=True, then the folder to save in as a   pathlib.Path object 



**Returns:**
 None 


---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L516"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `CA_DOF`
Functions to get CA Department of Finance population estimates from SQL. 

This class currently only has the functionality of getting region level population data from SQL. At some point, additional functionality will be added that gets population data split by age, sex, and ethnicity. 




---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L524"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `get_CA_DOF_data`

```python
get_CA_DOF_data(
    dof_vintage='2021_07_14',
    save_folder=WindowsPath('data/raw_data')
)
```

Get and save region level population data from CA DOF. 

Due to the limited nature of the checks run on this, this function will only pull population data at the region level. 



**Args:**
 
 - <b>`dof_vintage`</b> (str):  Default value of "2021_07_14". What vintage of dof data to pull from.  The input vintage will be used to access a table using the following f string:  f"[socioec_data].[ca_dof].[population_proj_{dof_vintage}]" 
 - <b>`save_folder`</b> (pathlib.Path):  The location where transformed CA DOF data should be saved.  Currently, this function will only save, there is no option for returning data. 



**Returns:**
 None 


---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L567"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DiffFiles`
Functions to return/save various Estimates diff tables. 

The functions in this class create diff files either directly from [DDAMWSQL16].[estimates] or from previously saved files. The output diff files will always be returned in case you want to hold them in memory. There is also an option to save the files at the specified location. The diff files can either be absolute change, percentage change, or both. As with the class Estimates Tables, the functions in this file do not run any checks. 




---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L577"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `create_diff_tables`

```python
create_diff_tables(
    old_vintage,
    new_vintage,
    raw_data_folder=WindowsPath('data/raw_data'),
    geo_list=['region', 'jurisdiction', 'cpa'],
    est_table_list=['age', 'ethnicity', 'household_income', 'age_ethnicity', 'age_sex_ethnicity'],
    save=True,
    save_folder=WindowsPath('data/diff')
)
```

Create diff files from the old vintage to the new vintage. 

This function will create and save diff files for each unique combination of geo_list and  est_table_list. The saved diff files will be in the xlsx format with three sheets. The first sheet contains the old vintage data, the second sheet contains the new vintage data, and the third sheet contains (new vintage data - old vintage data), also know as the change from old vintage to new vintage. 



**Args:**
 
 - <b>`old_vintage`</b> (str):  The old vintage to compare with 
 - <b>`new_vintage`</b> (str):  The new vintage to compare with. 
 - <b>`raw_data_folder`</b> (pathlib.Path):  pathlib.Path("./data/raw_data/") by default. The   location where raw data has been saved. It is expected that the files are saved  using functions.save in order to keep file formats consistent 
 - <b>`geo_list`</b> (list of str):  The geographies to create diff files for.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to create diff files.  Because of the unique way file names are generated, a valid item of this list is  "consolidated" 
 - <b>`save`</b> (bool):  True by default. If True, then use save_folder to save the diff files. At  this time, False has no functionality, but this may change later 
 - <b>`save_folder`</b> (pathlib.Path):  pathlib.Path("./data/diff/") by default. The location to   save diff files 



**Returns:**
 None 



**Raises:**
 
 - <b>`NotImplementedError`</b>:  Raised if save=False. If this function is not saving files, then  it is literally doing nothing 


---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L650"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `ProportionFiles`
Functions to compute categorical distributions within Estimates tables. 

By categorical distributions, we mean (for example) what percentage of the total population is split up between households vs group quarters. Or (for example) what percentage of Female people aged 10 to 14 in Carlsbad in 2010 were Hispanic vs Non-Hispanic, White vs Non-Hispanic, Black vs etc. 




---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L659"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `create_proportion_tables`

```python
create_proportion_tables(
    est_vintage,
    geo_list=['region'],
    est_table_list=['age', 'sex', 'ethnicity', 'household_income', 'age_ethnicity', 'age_sex_ethnicity'],
    raw_data_folder=WindowsPath('data/raw_data'),
    save=True,
    save_folder=WindowsPath('data/proportion')
)
```

Create the row sum and column sum proportion tables. 

Specifically in the row sum tables, the each cell in the row is divided by the sum value in  the row. For the column sum tables, the cells for each year and column name are divided by the sum of those cells. For example, in the age_ethnicity table, we would take the San Diego region, the year 2010, and the column Hispanic. Then we would get the distribution of age groups for San Diego Hispanics in 2010. 



**Args:**
 
 - <b>`est_vintage`</b> (str):  The vintage to compute proportions for. 
 - <b>`geo_list`</b> (list of str):  The geographies to create proportion files for.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to create proportion files  for. 
 - <b>`raw_data_folder`</b> (pathlib.Path):  pathlib.Path("./data/raw_data/") by default. The   location where raw Estimates data has been saved 
 - <b>`save`</b> (bool):  True by default. If True, then use save_folder to save the proportion   files. At this time, False has no functionality, but this may change later 
 - <b>`save_folder`</b> (pathlib.Path):  pathlib.Path("./data/proportion/") by default. The location  to save proportion files 



**Returns:**
 None 



**Raises:**
 
 - <b>`NotImplementedError`</b>:  Raised if save=False. If this function is not saving files, then  it is literally doing nothing 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
