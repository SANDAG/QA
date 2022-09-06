<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\functions.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `functions`
Helper functions which are generally useful in all parts of Estimates Automation. 


---

<a href="..\..\..\2022\Estimates_Automation\functions.py#L13"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>function</kbd> `save`

```python
save(dfs, base_folder, vintage, geo, table)
```

Save the input dataframe(s) according to the other inputs. 

In general, all files should be saved using the format f"QA_{vintage}_{geo}_{table}.csv". In  diff files, {vintage} should contain both vintages (ex. "2021_01-2020_06") and {table} should  contain the word "diff" (ex. "age_sex_ethnicity_diff"). For all other files, the file name  should be organized with most general category coming first (this should always be "QA") to  most specific category coming last. 

This function will create the directory if it is not yet created 

Raw data should be saved in the folder f"{base_folder}/raw_data/". 

DOF data should be saved in the folder f"{base_folder}/DOF/". 

Diff files should be saved in the folder f"{base_folder}/diff/". 



**Args:**
 
 - <b>`dfs`</b> (pd.DataFrame or dict of pd.DataFRame):  The table(s) to save. If one df is input,  then it will be saved as a csv file. If a dict of table(s) is input, then it will  be saved as an xlsx file, with each key of the dict being a sheet name, and the value  of the dict being the sheet. Note that since Python 3.6, dictionaries maintain insertion  order 
 - <b>`base_folder`</b> (pathlib.Path):  The folder to save data into. See the function description for  acceptable values 
 - <b>`vintage`</b> (str):  The vintage of the data. 
 - <b>`geo`</b> (str):  The geography level of the data. 
 - <b>`table`</b> (str):  The name of the table. This will typically be the name of an estimates table   such as "population" or "ethnicity" 



**Returns:**
 None 



**Raises:**
 
 - <b>`TypeError`</b>:  If dfs is not either pd.DataFrame or a dictionary of pd.DataFrame 


---

<a href="..\..\..\2022\Estimates_Automation\functions.py#L72"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>function</kbd> `load`

```python
load(base_folder, vintage, geo, table)
```

Get the input dataframe(s) according to the other inputs. 

See the save function for information on the file structure 



**Args:**
 
 - <b>`base_folder`</b> (pathlib.Path):  The folder to save data into. See the function description for   save for acceptable values 
 - <b>`vintage`</b> (str):  The vintage of the data. 
 - <b>`geo`</b> (str):  The geography level of the data. 
 - <b>`table`</b> (str):  The name of the table. This will typically be the name of an estimates table   such as "population" or "ethnicity" 



**Returns:**
 
 - <b>`dfs`</b> (pd.DataFrame or Dict of pd.DataFrame):  The table(s) found. The input values should  uniquely identify one file. If the file is a .csv, then pd.DataFrame will be returned.  If the file is a .xlsx, then a Dict of pd.DataFrame will be returned. 



**Raises:**
 
 - <b>`FileNotFoundError`</b>:  The combination of function inputs does not uniquely identify a file 
 - <b>`FileNotFoundError`</b>:  The combination of function inputs uniquely identifies more than one  file 
 - <b>`IOError`</b>:  The uniquely identified file has an unknown file extension 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
