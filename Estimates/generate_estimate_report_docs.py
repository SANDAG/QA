import os
from sqlalchemy import create_engine
import time
from time import strftime
from datetime import timedelta
import pandas as pd
import requests
from requests_ntlm import HttpNtlmAuth
import getpass

db_connection_string = 'mssql+pyodbc://sql2014a8/demographic_warehouse?driver=SQL+Server+Native+Client+11.0'
mssql_engine = create_engine(db_connection_string)

###############################################################################
# Generate and save estimates (pdf) from SQL Server Reporting Services

# Running this script will currently (March 13, 2019) generate estimate pdfs for all geozones of all geotypes.
# The underlying report only works for the v2018 estimates, so it is restricted to this version.
# However, this code should be easily repurposed for future estimate years.
# Hopefully it can be repurposed for other report types with minor edits.

# Usage:
# 1. Place this script in the folder that you would like to generate the reports in.
# 2. Open the command line and navigate to the folder.
# 3. Assuming python.exe is on your path, you can simply type 'python.exe generate_estimate_report_docs.py' into the
# command line.

# The script will ask you for your username and password. Simply follow the instructions.
# [username] = 3-digit login
# [password] = password used to login to computer
# [datasource_id] = the estimate version to use (currently disabled).
# [year] = the year of the estimates (currently iterates all available)

# This script will create a folder for the version (datasource 27, est_2018_03), a folder for the year,
# and additional sub-folders for the geotypes.
# This takes ~2 hours and 20 minutes to run through all permutations per year during testing.
# This should work out to ~21 hours for 2010-2018.

# This script produces files in the following schema:
# .. / Script_folder / Datasource / Year / Geotype / Geozone Name yyyy_mm_dd.pdf
###############################################################################

while True:
    username_input = input('Your 3-letter username:\n')
    username = 'sandagnet\\' + username_input
    break

while True:
    print('\nPlease provide your password:\n(The same password used to login to your computer)')
    password = getpass.getpass()
    break

max_tries = 3

# This query is restricted to only allow one option, which matches the report being called.
# I put this in so it might be repurposed in the future to allow selection of other estimate versions.
datasources_sql = '''
SELECT datasource_id, name
FROM demographic_warehouse.dim.datasource
WHERE datasource_type_id = 2 and datasource_id >= 26
'''
datasources_df = pd.read_sql(datasources_sql, mssql_engine)

# ds_attempts = 0
# while True:
#     print('\nPlease select a datasource_id from the following option(s):\nID: Name')
#     print('\n'.join('{0}: {1}'.format(n[0], n[1]) for i, n in datasources_df.iterrows()))
#     report_id = input('Estimate ID:\n')
#     try:
#         report_id = int(report_id)
#     except ValueError:
#         ds_attempts += 1
#         if ds_attempts < max_tries:
#             print('Please only select a numerical id number.')
#             continue
#         else:
#             print('Too many invalid responses, exiting the script.')
#             exit()
#     if report_id in datasources_df.datasource_id.values:
#         datasource_id = str(report_id)
#         datasource_name = str(datasources_df.loc[datasources_df.datasource_id == report_id].name.tolist()[0])
#         break
#     else:
#         ds_attempts += 1
#         if ds_attempts < max_tries:
#             print('Please select one of the listed option(s).')
#             continue
#         else:
#             print('Too many invalid responses, exiting the script.')
#             exit()
datasource_id = '27'
print('\nThe datasource ID is pre-defined for the current report (id = {0}).'.format(datasource_id))
datasource_name = str(datasources_df.loc[datasources_df.datasource_id == int(datasource_id)].name.tolist()[0])

est_years_sql = '''
SELECT yr_id
FROM demographic_warehouse.fact.population
WHERE datasource_id = {0}
GROUP BY yr_id
ORDER BY yr_id
'''.format(datasource_id)
est_years_df = pd.read_sql(est_years_sql, mssql_engine)
est_years_list = est_years_df.yr_id.tolist()

# yr_attempts = 0
# while True:
#     print('\nPlease select a year from the following list:')
#     print(*est_years_list, sep=' | ')
#     report_year = input('Estimate Year:\n')
#     try:
#         report_year = int(report_year)
#     except ValueError:
#         yr_attempts += 1
#         if yr_attempts < max_tries:
#             print('Please select a numerical year.')
#             continue
#         else:
#             print('Too many invalid responses, exiting the script.')
#             exit()
#     if report_year in est_years_list:
#         yr_id = str(report_year)
#         break
#     else:
#         yr_attempts += 1
#         if yr_attempts < max_tries:
#             print('Please select a valid option.')
#             continue
#         else:
#             print('Too many invalid responses, exiting the script.')
#             exit()

geotypes_sql = '''
SELECT geotype, geotype_pretty
FROM demographic_warehouse.dim.datasource ds
INNER JOIN demographic_warehouse.dim.mgra m ON ds.series = m.series
WHERE datasource_id = {0}
GROUP BY geotype, geotype_pretty
ORDER BY geotype_pretty
'''.format(datasource_id)
geotypes_df = pd.read_sql(geotypes_sql, mssql_engine)

start_time = time.monotonic()

for yr_id in est_years_list:
    print('\n\nNow in estimates year {}'.format(yr_id))
    for a, b in geotypes_df.iterrows():
        geotype_start = time.monotonic()
        geotype = b['geotype']
        print('\nGenerating reports for {0} geotype:'.format(geotype))

        output_path = '{0}\\{1}\\{2}'.format(datasource_name, yr_id, geotype)
        main_path = os.path.join(os.getcwd(), output_path)
        if not (os.access(output_path, os.F_OK)):
            os.makedirs(main_path)

        geozone_sql = '''
        SELECT geozone
        FROM demographic_warehouse.dim.datasource ds
        INNER JOIN demographic_warehouse.dim.mgra m ON ds.series = m.series
        WHERE datasource_id = {0} AND geotype = '{1}'
        GROUP BY geozone
        ORDER BY geozone
        '''.format(datasource_id, geotype)
        geozone_df = pd.read_sql(geozone_sql, mssql_engine)

        for c, d in geozone_df.iterrows():
            geozone = str(d['geozone'])

            if geozone == 'None':
                print('Field contained a NULL value. Skipping this iteration.')
                continue

            geozone_url = geozone.replace(' ', '%20')
            # geozone_url = geozone_url.replace('ñ', 'n')
            # geozone_url = geozone_url.replace('ñ', '%F1')
            # Correction: No special characters should be needed.
            # This should be the only special character that needs encoding.
            # See https://www.w3schools.com/tags/ref_urlencode.asp for more.
            url = 'http://sql2014a8/ReportServer/Pages/ReportViewer.aspx?' \
                  '%2festimates%2festimates_reports%2festimates_profile&' \
                  'DATASOURCE_ID={0}&GEOTYPE={1}&GEOZONE={2}&YEAR={3}&rs:Format=PDF'\
                .format(datasource_id, geotype, geozone_url, yr_id)

            geozone_file = geozone.replace(':', '_')
            geozone_file = geozone_file.replace('.', '_')
            geozone_file = geozone_file.replace('*', '')
            file_name = '{0} {1}.pdf'.format(geozone_file, strftime('%Y_%m_%d'))
            file_path = os.path.join(main_path, file_name)

            try:
                r = requests.get(url, auth=HttpNtlmAuth(username, password))
                r.raise_for_status()

                if (c + 1) % 5 == 0:
                    print('Generating {0} report {1} of {2}...'.format(geotype, c + 1, len(geozone_df)))
                elif c == 0:
                    print('Generating {0} report {1} of {2}...'.format(geotype, c + 1, len(geozone_df)))
                elif c + 1 == len(geozone_df):
                    print('Generating {0} report {1} of {2}...'.format(geotype, c + 1, len(geozone_df)))
                else:
                    pass

                with open(file_path, 'wb') as f:
                    f.write(r.content)

            except requests.exceptions.RequestException as err:
                print(err)
                if err.response.status_code == 401:
                    print(' You have provided an invalid username / password combination.\n The reports will not load.')
                elif err.response.status_code == 500:
                    print(' There is an unknown error. Skipping this iteration.')
                    continue
                else:
                    print(' The request has failed. Use the error code above to determine possible causes.')
                    continue
                # while True:
                #     err_continue = input('\nWould you like to continue? ([y]/n)\n')
                #     if err_continue == 'y':
                #         break
                #     else:
                #         exit()

        geotype_end = time.monotonic()
        print('{0} geotype reports completed in {1}'.format(geotype,
                                                            timedelta(seconds=round(geotype_end - geotype_start, 2))))

end_time = time.monotonic()
print('Total time to run generate all reports: {0}'.format(timedelta(seconds=round(end_time - start_time, 2))))
