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