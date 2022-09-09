<!-- markdownlint-disable -->

<a href="..\..\..\2022\Estimates_Automation\functions.py#L0"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

# <kbd>module</kbd> `functions`
Helper functions which are generally useful in all parts of Estimates Automation. 


---

<a href="..\..\..\2022\Estimates_Automation\functions.py#L19"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>function</kbd> `save`

```python
save(dfs, save_folder, *args)
```

Save the input dataframe(s) according to the other inputs. 

All files will be saved using the format f"QA_{args[0]}_{args[1]}_{args[2]}_etc.???", where the file extension (???) depends on if a pd.DataFrame was input (csv) or a dictionary of  pd.DataFrame was input (xlsx). In case the requested save folder does not exist, the function  will create the folder and any necessary parent folders.  

In the case of general estimates tables, *args should contain vintage, geography level, and table name in that order. Estimates tables should be saved in the folder  f"{base_folder}/raw_data/". 

In the case of CA DOF tables, *args should contain DOF and geography level, in that order. DOF files should be saved in the folder f"{base_folder}/CA_DOF/". 

In the case of diff tables, *args should contain vintage, geography level, and table name in that order. vintage should contain both vintages (ex. "2021_01-2020_06") and {table} should  contain the word "diff" (ex. "age_sex_ethnicity_diff"). Diff files should be saved in the  folder f"{base_folder}/diff/". 

In the case of any other files you want to save, *args should contain the parts of the file name in order of most general to most specific. For example, each vintage has multiple different  possible geography levels, so vintage should come before geography level in *args 



**Args:**
 
 - <b>`dfs`</b> (pd.DataFrame or dict of pd.DataFrame):  The table(s) to save. If one df is input,  then it will be saved as a csv file. If a dict of table(s) is input, then it will  be saved as an xlsx file, with each key of the dict being a sheet name, and the value  of the dict being the sheet. Note that since Python 3.6, dictionaries maintain insertion  order 
 - <b>`save_folder`</b> (pathlib.Path):  The folder to save data into. See the function description for  recommended values 
 - <b>`*args (list of str)`</b>:  The defining characteristics of the file name. In general, *args   should contain the parts of the file name in order of most general to most specific. 



**Returns:**
 None 



**Raises:**
 
 - <b>`TypeError`</b>:  If dfs is not either pd.DataFrame or a dictionary of pd.DataFrame 


---

<a href="..\..\..\2022\Estimates_Automation\functions.py#L83"><img align="right" style="float:right;" src="https://img.shields.io/badge/-source-cccccc?style=flat-square"></a>

## <kbd>function</kbd> `load`

```python
load(load_folder, *args)
```

Get the input dataframe(s) according to the other inputs. 

See the save function for additional information 



**Args:**
 
 - <b>`load_folder`</b> (pathlib.Path):  The folder to load data from. See the description for the save   funciton for recommended values 
 - <b>`*args (list of str)`</b>:  The defining characteristics of the file name. In general, *args   should contain the parts of the file name in order of most general to most specific. 



**Returns:**
 
 - <b>`dfs`</b> (pd.DataFrame or Dict of pd.DataFrame):  The table(s) found. The input values should  uniquely identify one file. If the file is a .csv, then pd.DataFrame will be returned.  If the file is a .xlsx, then a Dict of pd.DataFrame will be returned. 



**Raises:**
 
 - <b>`IOError`</b>:  The uniquely identified file has an unknown file extension 




---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
