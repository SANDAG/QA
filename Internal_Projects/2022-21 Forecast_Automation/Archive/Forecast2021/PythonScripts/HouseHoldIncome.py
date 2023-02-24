from sqlalchemy import create_engine
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib as mpl

pd.set_option('display.max_columns', None)
mpl.rc('xtick', labelsize=15)
mpl.rc('ytick', labelsize=15)

pat = os.path.join(os.path.dirname(__file__), '..')
sqlPat = os.path.join(pat, 'Queries\Household Income (HHINC).sql')


def sqlAlchemyTest():
    # Link to SQL Server, download data and do some necessary cleanup
    db_connection_string = 'mssql+pyodbc://sql2014a8/urbansim?driver=SQL+Server+Native+Client+11.0'
    mssql_engine = create_engine(db_connection_string)
    query = open(sqlPat, 'r')
    df = pd.read_sql(query.read(), mssql_engine)
    query.close()

    df = processData(df)

    return df

def processData(df):
    df['countPercent'] = 0
    df['compToSd'] = 0
    df['medianIncome'] = 0
    yrs = df['yr_id'].sort_values().unique()
    #first calc for SD region
    for key1, group1 in df[df['geotype'] == 'region'].groupby('yr_id'):
        ind = group1.index
        df.loc[ind, 'countPercent'] = group1['hh'] / group1['hh'].sum()

    #calculate percentage of hh per income bracket per year and against SD average
    for key1, group1 in df.groupby('geotype'):
        if not key1 == 'region':
            for key2, group2 in group1.groupby('geozone'):
                print(key2)
                ind = group2.index
                df.loc[ind,'medianIncome'] = sum(group2['income_group_id'] * group2['hh'])
                for key3, group3 in group2.groupby('yr_id'):
                    ind = df[(df['geotype'] == key1) & (df['geozone'] == key2) & (df['yr_id'] == key3)].index
                    df.loc[ind, 'countPercent'] = group3['hh'] / group3['hh'].sum()
                    for i,j in enumerate(df.loc[ind, 'name']):
                        df.loc[ind[i],'compToSd'] = df.loc[ind[i],'countPercent'] - df[(df['geotype'] == 'region') & (df['yr_id'] == key3) & (df['name'] == j)]['countPercent'].iloc[0]
                        if key3 != yrs[0]:
                            n = np.where(yrs == key3)[0][0]
                            df.loc[ind[i], 'yr_yr_diff'] = group2[(group2['name'] == j) & (group2['yr_id'] == key3)]['hh'].iloc[0] -\
                                                           group2[(group2['name'] == j) & (group2['yr_id'] == yrs[n-1])]['hh'].iloc[0]
                            df.loc[ind[i], 'yr_yr_percent'] = 100*(group2[(group2['name'] == j) & (group2['yr_id'] == key3)]['hh'].iloc[0] -\
                                                              group2[(group2['name'] == j) & (group2['yr_id'] == yrs[n-1])]['hh'].iloc[0]) / group2[(group2['name'] == j) & (group2['yr_id'] == key3)]['hh'].iloc[0]

    df = df.replace(np.nan, 0)
    df = df.replace('Less than $15,000', '$0 to $15000')
    df = df.sort_values('income_group_id')

    df['bigIncomeBins'] = pd.cut(df['income_group_id'], 5)

    df = df.reset_index()

    return df


def plotIterator(df, tt = 1):

    plt.style.use('seaborn-dark')
    for key, group in df[df['geotype'] == 'jurisdiction'].groupby('geozone'):
        sns.factorplot(x = 'yr_id', y = 'compToSd', hue = 'name', data = group, legend=True)
        plt.title('Comparison of Percent Household Distribution between San Diego Region and ' + key, fontsize = 20)
        plt.ylabel('Difference in Percent between Jurisdiction and SD Region', fontsize = 15)
        plt.xlabel('Year', fontsize = 15)
        #plt.legend(loc='upper right', fancybox = True, ncol = 1)#,bbox_to_anchor=(.01, .01))
        plt.show()
        plt.grid()
        plt.savefig(os.path.join(pat,key + '.png'))
        if tt == 1:
            break


df = sqlAlchemyTest()


print('tt')