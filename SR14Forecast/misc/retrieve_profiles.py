import os
import sys
import urllib
from sqlalchemy import create_engine
from time import strftime
import pandas as pd
import requests,getpass
from requests_ntlm import HttpNtlmAuth


###############################################################################
# Generate and save profiles (pdf) from SQL Server Reporting Services 
#                    for jursidiction and cpa for a given datasource id

# Usage:
# retrieve_profiles.py [datasource_id] [geotype] [user] [password]

# [datasource_id] = version of forecast in demographic_warehouse (e.g. 16)
# [geotype] = geography type (e.g. jurisdiction of cpa)
# [win_user] = login to reach the reporting server
# [win_user_password] = password to reach the reporting server

# Note: valid Geography types are jurisdiction and cpa

# Run from terminal:
# e.g. python retrieve_profiles.py 16 jursidiction username password
# or
# e.g. python retrieve_profiles.py 16 cpa username password

# note: no commas, just spaces between arguments and no quotes
###############################################################################

if len(sys.argv) != 5:
     sys.exit("Must provide data source id, geotype, username, and password")
datasource_id = sys.argv[1] # 16
geotype = sys.argv[2] # jurisdiction or cpa
### Windows username and password to access report server
username = sys.argv[3]
password = sys.argv[4]

# Link to SQL Server
db_connection_string = 'mssql+pyodbc://sql2014a8/demographic_warehouse?driver=SQL+Server+Native+Client+11.0'
mssql_engine = create_engine(db_connection_string)

jurisdictions_names_sql = '''
SELECT [zone] as geo_id
    ,[name]
FROM [data_cafe].[ref].[geography_zone]
WHERE [geography_type_id] = 150
ORDER BY [zone]
'''

cocpa_names_sql = '''
    SELECT zone as geo_id, name
    FROM data_cafe.ref.geography_zone WHERE geography_type_id = 20'''

cicpa_names_sql = '''
    SELECT zone as geo_id, name
    FROM data_cafe.ref.geography_zone WHERE geography_type_id = 15'''

if geotype=='jurisdiction':
    geo_df = pd.read_sql(jurisdictions_names_sql, mssql_engine)
    geo_df['name'] = geo_df['name'].astype(str)
else:
    cocpa_names = pd.read_sql(cocpa_names_sql, mssql_engine)
    cocpa_names['name'] = cocpa_names['name'].astype(str)
    cicpa_names = pd.read_sql(cicpa_names_sql, mssql_engine)
    cicpa_names['name'] = cicpa_names['name'].astype(str)
    geo_df = pd.concat([cocpa_names,cicpa_names])

# remove colon from name
geo_df['name'] = geo_df['name'].str.replace(':', '_')

output_path = 'profiles_{0}_{1}\\{2}'.format(datasource_id, strftime('%Y_%m_%d'),geotype)
print(output_path)

if not (os.access(output_path, os.F_OK)):
    os.makedirs(os.getcwd() + '/' + output_path)

for geo in geo_df['name'].tolist():
    url = 'http://sql2014a8/ReportServer/Pages/ReportViewer.aspx?%2fsocioec%2fsr14%2fsinglezone&datasource_id={0}&geotype={1}&geozone={2}&rs:Format=PDF'.\
        format(datasource_id,geotype,urllib.parse.quote(geo))
    print(url)
    r = requests.get(url, auth=HttpNtlmAuth(username, password))
    jcpa = str(geo_df.loc[geo_df.name == geo].geo_id.values[0])
    outpath = '{0}\\sandag_profiles_{1}_{2}.pdf'.format(output_path, jcpa, geo.replace('%20', ' '))
    with open(outpath, 'wb') as f:
        f.write(r.content)
