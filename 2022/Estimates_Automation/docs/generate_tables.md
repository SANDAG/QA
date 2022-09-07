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
 - <b>`geo_list`</b> (list of str):  The geographies to cosolidate along.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to consolidate 
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
 - <b>`geo_list`</b> (list of str):  The geographies to cosolidate along.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to consolidate 
 - <b>`save`</b> (bool):  False by default. If False, then only return the consolidated tables. If   True, then use save_folder to save the consolidated tables and return the tables 
 - <b>`save_folder`</b> (pathlib.Path):  None by default. If save=True, then the folder to save in as a   pathlib.Path object 



**Returns:**
 
 - <b>`List of pd.DataFrame`</b>:  A list containing the individual tables in the order of geo_list and  est_table_list. 


---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L454"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `CA_DOF`
Functions to get CA Department of Finance population estimates. 

Unfourtunately, CA DOF does not have an API endpoint, so some manual work needs to be done. First, you need to go here: https://dof.ca.gov/forecasting/demographics/estimates/ and  look at the section titled "E-5 Population and Housing Estimates for Cities, Counties, and the  State". For the years of data you want, click on the relvant links (For years that end in 0  like 2020, use the higher range (2020- rather than -2020)). Download the Excel sheets that are "Organized by Geography". DO NOT USE THE "Cities, Counties, and the State" EXCEL FILES. I would recommend you save these files in "./data/raw_data/", but it is up to you as long as you provide the correct paths. 




---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L510"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

### <kbd>method</kbd> `get_CA_DOF_data`

```python
get_CA_DOF_data(
    raw_folder=WindowsPath('data/raw_data'),
    save_folder=WindowsPath('data/CA_DOF'),
    years=range(2010, 2022),
    geo_list=['region', 'jurisdiction']
)
```

Get and save CA DOF data for each input year and geography level. 



**Args:**
 
 - <b>`raw_folder`</b> (pathlib.Path):  The location where raw CA DOF data is stored. See the class  description for more details. 
 - <b>`save_folder`</b> (pathlb.Path):  The location where transformed CA DOF data should be saved.  Currently, this function will only save, there is no option for returning data. 
 - <b>`years`</b> (list of int):  The years of CA DOF data to pull. It is recommended that you pull  all available data, which corresponds to the years 2010-current year. 
 - <b>`geo_list`</b> (list of str):  The geography levels to split by. Each distinct geography level  will have its own file. 



**Returns:**
 None 


---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L591"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>class</kbd> `DiffFiles`
Functions to return/save various Estimates diff tables. 

The functions in this class create diff files either directly from [DDAMWSQL16].[estimates] or from previously saved files. The output diff files will always be returned in case you want to hold them in memory. There is also an option to save the files at the specified location. The diff files can either be absolute change, percentage change, or both. As with the class Esimates Tables, the functions in this file do not run any checks. 




---

<a href="..\..\..\2022\Estimates_Automation\generate_tables.py#L601"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

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

Create diff files from the old vintage to the new vintage................. 

This function will create and save diff files for each unique combination of geo_list and  est_table_list. The saved diff files will be in the xlsx format with three sheets. The first sheet contains the old vintage data, the second sheet contains the new vintage data, and the third sheet contains (new vintage data - old vintage data), also know as the change from old vintage to new vintage. 



**Args:**
 
 - <b>`old_vintage`</b> (str):  The old vintage to compare with 
 - <b>`new_vintage`</b> (str):  The new vintage to compare with. 
 - <b>`raw_data_folder`</b> (pathlib.Path):  pathlib.Path("./data/raw_data/") by default. The   location where raw data has been saved. It is expected that the files are saved  using functions.save in order to keep file formats consistent 
 - <b>`geo_list`</b> (list of str):  The geographies to create diff files for.  
 - <b>`est_table_list`</b> (list of str):  Which estimates tables we want to create diff files.  Becasue of the unique way file names are generated, a valid item of this list is  "consolidated" 
 - <b>`save`</b> (bool):  True by default. If True, then use save_folder to save the diff files. At  this time, False has no functionality, but this may change later 
 - <b>`save_folder`</b> (pathlib.Path):  pathlib.Path("./data/diff/") by default. The location to   save diff files 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
