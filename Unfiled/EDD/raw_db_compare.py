import sqlite3
import pandas as pd
import pyodbc
import numpy as np
import pymssql
import tabulate
import os


from sklearn import cluster
import matplotlib.pyplot as plt
import matplotlib.cm as mplcm
import matplotlib.colors as colors

pat = r'M:\RES\DataSolutions\GIS\Data\EDD_QCEW_Microdata\SANDAG 2017-3ascii.csv'
pat2 = os.path.dirname(__file__)
server = 'Sql2014B8'
database = 'EMPCORE'
table = 'dbo.CA_EDD_EMP2017'

def importFromRaw(pat):
    df = pd.read_csv(pat)
    # df.columns = ['OBJECTID', 'dba', 'address', 'city', 'zip', 'emp1', 'emp2', 'emp3', 'payroll', 'naics', 'own',
    #               'meei', 'init', 'end', 'react', 'x', 'y']
    df = df.replace(' ', np.nan)
    for i in ['payroll', 'emp1', 'emp2', 'emp3']:
        df[i] = pd.to_numeric(df[i])
    return df


def importFromDb(server, database, table):
    sql = 'select * from ' + table
    conn = pymssql.connect(server = server, database = database)
    #df['emp1', 'emp2', 'emp3', 'payroll'] = pd.to_numeric(df['emp1', 'emp2', 'emp3', 'payroll'])
    return pd.read_sql(sql,conn)

def diffCalc(df1,df2):
    #Calculate row-wise differences (df1 is the original, df2 is the sql)
    #Find which rows exist in the sql db
    numerics = ['int16', 'int32', 'int64', 'float16', 'float32', 'float64']

    availEmp = df2['emp_id']
    tempDf1 = df1[df1['emp_id'].isin(availEmp)].sort_values('emp_id')
    tempDf2 = df2.sort_values('emp_id')

    diff1 = tempDf1.select_dtypes(include=numerics).diff()
    diff2 = tempDf2.select_dtypes(include=numerics).diff().reset_index()
    colsTot = list(set(list(diff2.columns)) &  set(list(diff1.columns)))


    print(diff1[colsTot].equals(diff2[colsTot]))



def summaryStatistics(df1, df2, uniqueId = 'emp_id'):

    df = pd.DataFrame(columns= ['Category','Original Data', 'SQL Data','Difference'])
    df.loc[len(df)]= ['Count', len(df1), len(df2), len(df2)- len(df1)]
    df.loc[len(df)]= ['Unique Identifiers', df1['emp_id'].nunique(), df2['emp_id'].nunique(), df2['emp_id'].nunique()- df1['emp_id'].nunique()]
    df.loc[len(df)]= ['Num Columns', len(df1.columns), len(df2.columns), len(df2.columns) - len(df1.columns)]
    df.loc[len(df)] = ['Unique Entries Of Business Name', df1['dba'].nunique(), df2['dba'].nunique(), df2['dba'].nunique() - df1['dba'].nunique()]
    df.loc[len(df)] = ['Unique Entries Of Address', df1['address'].nunique(), df2['address'].nunique(), df2['address'].nunique() - df1['address'].nunique()]

    #check for outliers
    highThresh1 = np.max(df1) + 3*np.std(df1)
    highThresh2 = np.max(df2) + 3*np.std(df2)
    lowThres = 0
    outlierCheck = ['emp1','emp2','emp3','payroll']
    out1 = []
    out2 = []
    for i in outlierCheck:
        out1.append(np.sum(df1[i]>highThresh1[i]))
        out2.append(np.sum(df2[i]>highThresh2[i]))
    df.loc[len(df)]= ['Num Outliers (>3sig)', np.sum(out1), np.sum(out2), np.sum(out2)- np.sum(out1)]
    print(tabulate.tabulate(df,headers = 'keys', tablefmt = 'psql',showindex=False))
    df.to_csv(os.path.join(pat2,'summary.csv'))

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

    # descriptive statistics
    desCount1 = [df1[i].describe() if i in df1.columns else '-' for i in colsTot]
    desCount2 = [df2[i].describe() if i in df2.columns else '-' for i in colsTot]
    desCount1[0] = 'Original Descriptive Statistics'
    desCount2[0] = 'SQL Descriptive Statistics'
    df.loc[len(df)] = desCount1
    df.loc[len(df)] = desCount2

    print(tabulate.tabulate(df, headers='keys', tablefmt='psql', showindex=False))
    df.to_csv(os.path.join(pat2,'ColSummary.csv'))


def digData(tt):
    tt = tt[['emp_id','dba','address','city','zip','payroll','emp1','emp2','emp3','naics']]
    tt.replace(' ', np.nan, inplace=True)
    tt = tt.dropna()
    for i in ['payroll', 'emp1', 'emp2', 'emp3']:
        tt[i] = pd.to_numeric(tt[i])
    tt['test'] = 4 * tt['payroll'] / np.max(tt[['emp1', 'emp2', 'emp3']], axis=1)
    tt['maxE'] = np.max(tt[['emp1', 'emp2', 'emp3']], axis=1)
    tt.replace(np.inf, np.nan, inplace=True)
    tt = tt.dropna()
    tt = tt.sort_values('test', ascending = False)
    tt['naicsInd'] = tt['naics'].astype('str')
    tt['naicsInd'] = tt['naicsInd'].str[:2]

    return tt

def groupbyPlot(df, group = 'naicsInd', x = 'maxE',y = 'payroll'):
    plt.style.use('ggplot')

    NUM_COLORS = df[group].nunique()

    fig, ax = plt.subplots(figsize=(10, 4))

    cm = plt.get_cmap('gist_rainbow')

    ax.set_prop_cycle(color=[cm(1. * i / NUM_COLORS) for i in range(NUM_COLORS)])
    for key, group in df.groupby([group]):
        ax.plot(group[x],group[y], label = key, linestyle = 'None',marker = 'o')
    ax.legend()
    plt.show()


def plot_hist(tt, key):
    plt.rc('font', size = 20)
    tt = tt.sort_values([key])
    tt = tt.reset_index()
    fig = plt.figure(figsize=(12,12))
    ax = fig.add_subplot(111)
    ax.scatter(tt.index,tt[key])
    ax.set_xlabel("Index")
    ax.set_title(key + " Distribution Check")
    ax.set_ylabel(key)
    plt.grid(b=True, which='major')
    plt.show()



if __name__ == '__main__':

    df1 = importFromRaw(pat)
    df2 = importFromDb(server, database, table)
    summaryStatistics(df1,df2)
    columnSum(df1,df2)
    tt = digData(importFromDb(server, database, table))

    y_pred = cluster.MiniBatchKMeans(n_clusters=3).fit_predict(tt[['maxE','test']])

    fig = plt.figure(figsize=(12,12))
    ax = fig.add_subplot(111)
    ax.scatter(tt['maxE'],tt['payroll'], c=y_pred)
    plt.show()


    tt = digData(importFromDb(server, database, table))

    print('tt')