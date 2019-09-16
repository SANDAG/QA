from sqlalchemy import create_engine
import os
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib as mpl
import shutil
import time

pd.set_option('display.max_columns', None)
plt.style.use('ggplot')
mpl.rc('xtick', labelsize=15)
mpl.rc('ytick', labelsize=15)

pat = os.path.join(os.path.dirname(__file__))
sqlPat = os.path.join(pat, 'jobsProfile.sql')


def sqlAlchemyTest():
    # Link to SQL Server, download data and do some necessary cleanup
    db_connection_string = 'mssql+pyodbc://sql2014a8/demographic_warehouse?driver=SQL+Server+Native+Client+11.0'
    mssql_engine = create_engine(db_connection_string)
    query = open(sqlPat, 'r')
    df = pd.read_sql(query.read(), mssql_engine)
    query.close()

    df = processData(df)

    return df


def processData(df):
    #stuff

    return df


def makePlots(df):

    if os.path.exists(os.path.join(pat,'img')):
        shutil.rmtree(os.path.join(pat,'img'))
        time.sleep(2)
    
    os.mkdir(os.path.join(pat,'img'))

    geo = df['geozone'].unique()

    for idx,group in df.groupby(['geozone']):
        tt = plt.figure(figsize = (13,9))
        plt.plot(group['yr_id'],group['jobs'],'.-')
        plt.xlabel('Year',fontsize = 20)
        plt.ylabel(idx + ' Jobs', fontsize = 20)
        plt.title(idx)
        plt.show()
        plt.grid(True)
        name = ''.join(ch for ch in idx if ch.isalnum())
        plt.savefig(os.path.join(os.path.join(pat,'img'),name + '.png'))
        plt.close(tt)



if __name__=="__main__":
    df = sqlAlchemyTest()


    print('tt')