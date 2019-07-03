import pandas as pd
import numpy as np
import os
import tabulate

pat1 = r'T:\socioec\pecas\data\parking2016'
file1 = r'mgra13_based_input2016_original.csv'
file2 = r'mgra13_based_input2016_updated_103118.csv'

pat2 = r'T:\socioec\Current_Projects\XPEF10\abm_csv'
file3 = r'mgra13_based_input2016_01.csv'
columns = ['mgra','hparkcost','numfreehrs','dstallsoth','dstallssam','dparkcost','mstallsoth','mstallssam','mparkcost',
           'totint','duden','empden','popden','retempden','totintbin','empdenbin','dudenbin','zip09']

pat11 = os.path.join(pat1, file1)
pat12 = os.path.join(pat1, file2)
pat23 = os.path.join(pat2, file3)

df1 = pd.read_csv(pat11, usecols=columns)
df2 = pd.read_csv(pat23, usecols=columns)

def summaryStatistics(df1, df2, KeyU = 'mgra'):

    KeyU = 'mgra'
    outlierCheck = ['hparkcost', 'numfreehrs', 'dparkcost', 'mparkcost']

    df = pd.DataFrame(columns= ['Category','Original Data', 'SQL Data','Difference'])
    df.loc[len(df)]= ['Count', len(df1), len(df2), len(df2)- len(df1)]
    df.loc[len(df)]= ['Unique Identifiers', df1[KeyU].nunique(), df2[KeyU].nunique(), df2[KeyU].nunique()- df1[KeyU].nunique()]
    df.loc[len(df)]= ['Num Columns', len(df1.columns), len(df2.columns), len(df2.columns) - len(df1.columns)]

    #check for outliers
    highThresh1 = np.max(df1) + 3*np.std(df1)
    highThresh2 = np.max(df2) + 3*np.std(df2)
    lowThres = 0

    out1 = []
    out2 = []
    for i in outlierCheck:
        out1.append(np.sum(df1[i]>highThresh1[i]))
        out2.append(np.sum(df2[i]>highThresh2[i]))
    df.loc[len(df)]= ['Num Outliers (>3sig)', np.sum(out1), np.sum(out2), np.sum(out2)- np.sum(out1)]
    print(tabulate.tabulate(df,headers = 'keys', tablefmt = 'psql',showindex=False))
    df.to_csv(r'C:\Users\skl\Desktop\temp\summary.csv')

def columnSum(df1,df2):
    #Column names present in each database
    colsTot = ['Category'] +  list(df1.columns) + list(set(list(df2.columns)) - set(list(df1.columns)))
    incl1 = ['x' if i in df1.columns else '-' for i in colsTot]
    incl2 = ['x' if i in df2.columns else '-' for i in colsTot]

    df = pd.DataFrame(columns = colsTot)
    incl1[0] = 'Present in Original'
    incl2[0] = 'Present in SQL'
    df.loc[len(df)] = incl1
    df.loc[len(df)] = incl2

    #Print datatypes
    dtyp1 = df1.dtypes.to_dict()
    dtyp2 = df2.dtypes.to_dict()
    dtyp11 = [dtyp1[i] if i in dtyp1.keys() else '-' for i in colsTot]
    dtyp22 = [dtyp2[i] if i in dtyp2.keys() else '-' for i in colsTot]
    dtyp11[0] = 'Datatypes in Original'
    dtyp22[0] = 'Datatypes in SQL'
    df.loc[len(df)] = dtyp11
    df.loc[len(df)] = dtyp22

    # now for nan counting
    nanCount1 = [np.sum(df1.isna())[i] if i in df1.columns else '-' for i in colsTot]
    nanCount2 = [np.sum(df2.isna())[i] if i in df2.columns else '-' for i in colsTot]
    nanCount1[0] = 'Number of Original NaNs/blanks'
    nanCount2[0] = 'Number of SQL NaNs/blanks'
    df.loc[len(df)] = nanCount1
    df.loc[len(df)] = nanCount2

    #Sum row-wise differences between datasets
    if len(df1.columns) == len(df2.columns):
        diffSum = [np.sum(np.abs(df1[i] - df2[i])) if i in df1.columns else '-' for i in colsTot]
        diffSum[0] = 'Sum of row-wise Differences'
        df.loc[len(df)] = diffSum


    print(tabulate.tabulate(df, headers='keys', tablefmt='psql', showindex=False))
    df.to_csv(r'C:\Users\skl\Desktop\temp\ColSummary.csv')




summaryStatistics(df1,df2)
columnSum(df1,df2)
pd.options.display.max_columns = 999
print(df1.describe())
print(df2.describe())

print('tt')