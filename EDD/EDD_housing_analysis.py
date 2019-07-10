import sqlite3
import pandas as pd
import pyodbc
import numpy as np
import pymssql
import tabulate
import os
import getpass
import raw_db_compare
import math
import seaborn as sns
from sqlalchemy import create_engine

from sklearn import cluster
import matplotlib.pyplot as plt
import matplotlib.cm as mplcm
import matplotlib.colors as colors

pat = os.path.dirname(__file__)
sqlFile = 'EDD_housing_link_functionized.sql'
sqlPat = os.path.join(pat, sqlFile)
naicsLookupPat = os.path.join(pat,r'naicsLookup.csv')
server = 'Sql2014A8'
database = 'urbansim'


sql = '''SELECT p.parcel_id AS parcel_id, 
    m.emp_id AS emp_id, SUM(m.emp1) AS emp1,SUM(m.emp2) AS emp2,SUM(m.emp3) AS emp3, SUM(m.naics) AS naics, m.dba, 
    SUM(m.payroll) as payroll, b.building_id AS building_id, SUM(b.non_residential_sqft) AS nonresSqft,
    SUM(b.residential_sqft) AS resSqft, d.name --, SUM(dbo.GetDataForID(m.naics)) as Data
From urbansim.urbansim.parcel p

INNER JOIN urbansim.urbansim.building b
	ON b.parcel_id = p.parcel_id

INNER JOIN urbansim.ref.development_type as d
	ON b.development_type_id = d.development_type_id

RIGHT Join OPENQUERY(sql2014b8, 'SELECT * FROM  EMPCORE.dbo.CA_EDD_EMP2017') AS m
	ON m.shape.STIntersects(b.shape) = 1

Group By p.parcel_id, m.emp_id, m.dba, d.name, b.building_id'''

def sqlAlchemyTest():
    # Link to SQL Server
    db_connection_string = 'mssql+pyodbc://sql2014a8/urbansim?driver=SQL+Server+Native+Client+11.0'
    mssql_engine = create_engine(db_connection_string)
    query = open(sqlPat, 'r')
    df = pd.read_sql(query.read(), mssql_engine)

    for i in ['emp1', 'emp2', 'emp3', 'payroll']:
        df[i] = pd.to_numeric(df[i])
    df.replace(np.inf, np.nan, inplace=True)


    df = df.dropna(subset=['emp1','emp2','emp3'])
    df['naicsInd'] = df['naics'].astype('str')
    df['naicsInd2'] = df['naicsInd'].str[:2].astype(int)
    df['naicsInd3'] = df['naicsInd'].str[:3].astype(int)
    df['naicsInd4'] = df['naicsInd'].str[:4].astype(int)
    df['naicsInd'] = df['naics'].astype(int)
    df['maxE'] = np.max(df[['emp1', 'emp2', 'emp3']], axis=1)
    df['sumSqft'] = df['nonresSqft'] + df['resSqft']
    df['resFlag'] = np.where(df['resSqft'] > 0, 'Residential', 'Industrial')
    df['sqftPerEmp'] = df['sumSqft'] / df['maxE'].where(df['maxE'] != 0)
    df['logMaxE'] = np.log(df['maxE']+ 1)
    df['moneyPerE'] = df['payroll'] / df['maxE'].where(df['maxE'] != 0)
    df['logMoneyPerE'] = np.log(df['payroll'] / df['maxE'].where(df['maxE'] != 0) + 1)
    df['logPayroll'] = np.log(df['payroll'] + 1)

    return df

def naicsLookup():
    #Get sorted list of all naics Code meanings
    df = pd.read_csv(naicsLookupPat)
    return df['Name'].to_list()

def getSyncedEddBuildingData():
    while True:
        username_input = input('Your 3-letter username:\n')
        username = 'sandagnet\\' + username_input
        break

    while True:
        print('\nPlease provide your password:\n(The same password used to login to your computer)')
        password = getpass.getpass()
        break

    max_tries = 3

    query = open(sqlPat, 'r')
    connection = pymssql.connect(server=server, database=database, user=username, password=password, port=1433)
    # connection = pymssql.connect(server=server, database=database)

    df = pd.read_sql_query(query.read(), connection)

    for i in ['emp1', 'emp2', 'emp3']:
        df[i] = pd.to_numeric(df[i])
    df.replace(np.inf, np.nan, inplace=True)

    df = df.dropna(subset=['emp1','emp2','emp3'])
    df['naicsInd'] = df['naics'].astype('str')
    df['naicsInd2'] = df['naicsInd'].str[:2].astype(int)
    df['naicsInd3'] = df['naicsInd'].str[:3].astype(int)
    df['naicsInd4'] = df['naicsInd'].str[:4].astype(int)
    df['naicsInd'] = df['naics'].astype(int)
    df['maxE'] = np.max(df[['emp1', 'emp2', 'emp3']], axis=1)
    df['sumSqft'] = df['nonresSqft'] + df['resSqft']
    df['resFlag'] = np.where(df['resSqft'] > 0, 'Residential', 'Industrial')
    df['sqftPerEmp'] = df['sumSqft'] / df['maxE'].where(df['maxE'] != 0)
    df['logMaxE'] = np.log2(df['maxE']+ 1)
    df['moneyPerE'] = df['payroll'] / df['maxE'].where(df['maxE'] != 0)
    df['logPayroll'] = np.log(df['payroll'] + 1)
    df['logMoneyPerE'] = np.log(df['payroll'] / df['maxE'].where(df['maxE'] != 0) + 1)

    return df

def summaryStatistics(tt):
    #Generate a table describing what's going on in the data
    df1 = tt[~tt['parcel_id'].isna()]
    df2 = tt[tt['parcel_id'].isna()]


    colsTot = ['Category'] + list(df1.columns) + list(set(list(df2.columns)) - set(list(df1.columns)))
    incl1 = ['x' if i in df1.columns else '-' for i in colsTot]
    incl2 = ['x' if i in df2.columns else '-' for i in colsTot]

    df = pd.DataFrame(columns = colsTot)
    incl1[0] = 'Present in Matched'
    incl2[0] = 'Present in Unmatched'
    df.loc[len(df)] = incl1
    df.loc[len(df)] = incl2

    #print counts
    Count1 = [df1[i].count() if i in df1.columns else '-' for i in colsTot]
    Count2 = [df2[i].count() if i in df2.columns else '-' for i in colsTot]
    Count1[0] = 'Count of Matched'
    Count2[0] = 'Count of Unmatched'
    df.loc[len(df)] = Count1
    df.loc[len(df)] = Count2

    #Print datatypes
    dtyp1 = df1.dtypes.to_dict()
    dtyp2 = df2.dtypes.to_dict()
    dtyp11 = [dtyp1[i] if i in dtyp1.keys() else '-' for i in colsTot]
    dtyp22 = [dtyp2[i] if i in dtyp2.keys() else '-' for i in colsTot]
    dtyp11[0] = 'Datatypes in Matched'
    dtyp22[0] = 'Datatypes in Unmatched'
    df.loc[len(df)] = dtyp11
    df.loc[len(df)] = dtyp22

    # now for nan counting
    nanCount1 = [np.sum(df1.isna())[i] if i in df1.columns else '-' for i in colsTot]
    nanCount2 = [np.sum(df2.isna())[i] if i in df2.columns else '-' for i in colsTot]
    nanCount1[0] = 'Number of Matched NaNs/blanks'
    nanCount2[0] = 'Number of Unmatched NaNs/blanks'
    df.loc[len(df)] = nanCount1
    df.loc[len(df)] = nanCount2

    # mean compare
    mean1 = [np.mean(df1[i]).__round__(2) if i in df1.columns and df1[i].dtype != 'O' else '-' for i in colsTot]
    mean2 = [np.mean(df2[i]).__round__(2) if i in df2.columns and df2[i].dtype != 'O' else '-' for i in colsTot]
    mean1[0] = 'Mean of Matched'
    mean2[0] = 'Mean of Unmatched'
    df.loc[len(df)] = mean1
    df.loc[len(df)] = mean2

    print(tabulate.tabulate(df, headers='keys', tablefmt='psql', showindex=False))
    df.to_csv(os.path.join(pat,'summary.csv'))


def groupbyPlot(df, groupId = 'naicsInd2', x = 'maxE',y = 'sumSqft'):
    plt.style.use('ggplot')
    df['naicsInd2'] = df['naicsInd2'].astype(str)
    # df['naicsInd'] = df['naicsInd'].astype(str)
    df = df.sort_values(by = 'naicsInd')
    NUM_COLORS = df[groupId].nunique()

    fig, ax = plt.subplots(figsize=(10, 4))

    cm = plt.get_cmap('gist_rainbow')
    ax.set_prop_cycle(color=[cm(1. * i / NUM_COLORS) for i in range(NUM_COLORS)])

    for key, group in df.groupby([groupId]):
        ax.plot(group[x],group[y], label = key, linestyle = 'None',marker = 'o')

    if x == 'naicsInd':
        cm = plt.get_cmap('Spectral')
        ax.set_prop_cycle(color=[cm(1. * i / NUM_COLORS) for i in range(NUM_COLORS)])
        for key, group in df.groupby([groupId]):
            xx = np.unique(group['naicsInd2'])
            yy = [np.mean(group[group['naicsInd2'] == i][y]) for i in xx]
            ax.plot(xx, yy, label=key + ' Average', linestyle = '-.', marker = 'o')

    if x == 'naicsInd2':
        cm = plt.get_cmap('plasma')
        start, end = ax.get_xlim()
        #ax.xaxis.set_ticks(np.arange(math.floor(start), math.ceil(end), 2 * 10 ** int(math.log10(end) - 2)))
        plt.xticks(rotation = 50)
        ax2 = ax.twinx()
        ax2.set_prop_cycle(color=[cm(1. * i / NUM_COLORS) for i in range(NUM_COLORS)])

        for key, group in df.groupby([groupId]):
            xx = np.unique(group['naicsInd2']).astype(str)
            yy = [np.mean(group[group['naicsInd2'] == i][y]) for i in xx]
            ax2.plot(xx, yy, label=key + ' Average (' + y + ')', linestyle = '-.', marker = 'o')
            ax2.grid(False)



    ax.grid(False)
    ax.legend(loc = 'upper left')
    ax.set_ylabel(y)
    ax2.set_ylabel('Average of ' + y)
    # ax.xaxis.set_ticks(naicsLookup())
    # ax2.xaxis.set_ticks(naicsLookup())
    ax.set_xlabel(x)
    zz = naicsLookup()
    plt.xticks(xx)#, naicsLookup())
    ax2.legend(loc= 'upper right')
    plt.show()

    return plt, [np.mean(df[df['naicsInd2'] == i][y]) for i in xx]

def empCompare(tt):
    #Compare different truncs of employees

    y = ['sqftPerEmp','moneyPerE']
    fig, ax = plt.subplots(211, figsize=(10, 4))
    plt.style.use('ggplot')

    tt = tt[tt['maxE'] > 0]
    tt['group'] = pd.qcut(tt['maxE'],[0, .4, .6, .8, 1])

    #for y[0]
    for key, group in tt.groupby('group'):
        xx = np.unique(group['naicsInd2'])
        yy = [np.mean(group[group['naicsInd2'] == i][y[0]]) for i in xx]
        plt.plot(xx, yy, label='<' + str(key.right) + ' Average', linestyle='-.', marker='o')

    plt.subplot(212)
    #for y[1]
    for key, group in tt.groupby('group'):
        xx = np.unique(group['naicsInd2'])
        yy = [np.mean(group[group['naicsInd2'] == i][y[1]]) for i in xx]
        plt.plot(xx, yy, label='<' + str(key.right) + ' Average', linestyle='-.', marker='o')

    plt.legend(loc= 'upper right')
    plt.show()

def stackedPairPlot(df):
    #Plot stacked bar charts comparing naics codes to building types

    MINIMAL_USE = ['Active Park','Agriculture and Mining','College Dormitory','Depot','Dump Space','Heavy Industry',
                   'Military Reservation','Parking Lot','Secondary Schools','Recreation','Religious',
                   'Post-Secondary Institution','Mobile Home','Transportation Right-of-way',
                   'Undeveloped Open Space','Vacant Developable Land','Water','Government Operations','Health Care',
                   'Hotel/Motel','Mixed Use','Primary Schools']
    y = 'naicsInd2'


    for i in range(0,2):
        fig, ax = plt.subplots(figsize=(10, 4))
        if i == 1:
            tt = df[df['name'].isin(MINIMAL_USE)]
            NUM_COLORS = df['name'].nunique()
            cm = plt.get_cmap('gist_rainbow')
            ax.set_prop_cycle(color=[cm(1. * i / NUM_COLORS) for i in range(NUM_COLORS)])
        else:
            tt = df[~df['name'].isin(MINIMAL_USE)]

        if 1: #Turn on to remove residential fields from the plots
            tt = tt[tt['resFlag'] == 'Industrial']

        xx = pd.unique(tt[y])
        for key, group in tt.groupby('name'):
            yy = [np.log2(np.count_nonzero(group[group[y] == i][y])) for i in xx]
            ax.bar(xx, yy, label=key)

        plt.xlabel('naicsInd2')
        plt.ylabel('Log - Count of Building type in each 2-digit NAICS number, greater than 100 counts')
        ax.legend()
        plt.show()



def jobsOnRes(df, state = 1):
    #Number of jobs/buildings in residential buildings per naics
    x = 'naicsInd2'
    y = 'maxE'
    fig, ax = plt.subplots(figsize=(10, 4))

    if state:  # Turn on to remove residential fields from the plots
        tt = df[df['resFlag'] == 'Industrial']
        title = "Industrial Cases Only"
    else:
        tt = df[df['resFlag'] == 'Residential']
        title = 'Residential Cases Only'

    tt[x] = tt[x].astype(str)
    xx = pd.unique(tt[x])
    yy1 = [np.sum(tt[tt[x] == i][y]) for i in xx]
    ax = sns.barplot(xx, yy1, data=tt)
    ax.set(xlabel = "NAICS number, first 2 digits", ylabel = 'Sum of Employees', title = title)
    tempDF1 = pd.DataFrame(list(zip(xx, yy1, ['Employment' for i in xx])), columns= ['x','y','flag'])




    x = 'naicsInd2'
    y = 'resFlag'
    fig, ax = plt.subplots(figsize=(10, 4))

    if state:  # Turn on to remove residential fields from the plots
        tt = df[df['resFlag'] == 'Industrial']
        title = "Industrial Cases Only"
    else:
        tt = df[df['resFlag'] == 'Residential']
        title = 'Residential Cases Only'

    tt[x] = tt[x].astype(str)
    xx = pd.unique(tt[x])
    yy2 = [np.count_nonzero(tt[tt[x] == i][y]) for i in xx]

    #Find scale value to scale second y axis
    scale = int(np.mean(yy1)/np.mean(yy2))
    yy2Scale = yy2*scale

    tempDF2 = pd.DataFrame(list(zip(xx, yy2Scale,['Buildings' for i in xx])), columns= ['x','y','flag'])
    concatDf = pd.concat([tempDF1,tempDF2])
    ax = sns.barplot('x', 'y', data=concatDf, hue = 'flag', dodge = True, ax = ax, ci = None)
    ax.set_ylabel('Sum of Employees')
    ax2 = ax.twinx()
    ax2.set_ylim(ax.get_ylim())
    ax2.set_yticklabels(np.round(ax.get_yticks()/scale, 1))
    ax2.set_ylabel('Count of Buildings')
    ax2.grid(False)
    ax.set(xlabel = "NAICS number, first 2 digits", ylabel = 'Count of Employees', title = title)


def groupedBoxplots(df):
    #make grouped boxplots comparing discriptive statistics of companies by naics

    yy = 'payroll'#'moneyPerE'#'moneyPerE' #logMaxE, logPayroll
    df[yy].replace(0,np.nan,inplace = True)
    df['naicsInd2'] = df['naicsInd2'].astype(str)

    fig, ax = plt.subplots(figsize=(10, 4))
    ax = sns.boxplot(x='naicsInd2', y=yy, data=df)
    ax.set(yscale="log")


df = sqlAlchemyTest()

print('tt')