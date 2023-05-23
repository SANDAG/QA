from turtle import update
import pandas as pd
import numpy as np
import geopandas as gpd
import json
import datetime

import requests
from requests.auth import HTTPBasicAuth

from socrata.authorization import Authorization
from IPython.display import clear_output
from socrata import Socrata
import os
import sys


def ODP_authorization(api_key, secret_key):
    """
    Function that returns authorization clients and sessions
    """
    
    # Make an auth object
    socrata_auth = Authorization(
    "internaldata.sandag.org",
    api_key,
    secret_key
    )

    # Authenticate into the domain
    client = Socrata(socrata_auth)

    http_auth = HTTPBasicAuth(api_key, secret_key)
    sess = requests.Session()
    sess.auth = http_auth

    # client is used for ODP Socrata-py and sess is for Request gets and pushes
    return client, sess

def dataset_grabber(sess, link):
    """
    A generalized dataset grabber for json and geojson links
    """
    json_dict = sess.get(link).json()
    if '.geojson' in link:
        dataset = gpd.GeoDataFrame.from_features(json_dict['features'])
    else:
        dataset = pd.DataFrame(json_dict)
    return dataset

def update_data(client, dataset_id, dataset_name, updated_dataset):
    """
    Updates a dataset on ODP using the 4x4 and updated dataset path or dataframe. Must include a dataset name as a string
    """
    view = client.views.lookup(dataset_id)
    revision = view.revisions.create_replace_revision(permission='private')
    upload = revision.create_upload(dataset_name)

    # The path of the updated dataset should be a string to the csv, geojson, shapefile zip, etc.
    if type(updated_dataset) == str:
        with open(updated_dataset, 'rb') as f:
            extension = os.path.splitext(updated_dataset)[1]
            if extension == '.csv':
                source = upload.csv(f)
            elif extension == '.xls':
                source = upload.xls(f)
            elif extension == 'xlsx':
                source = upload.xlsx(f)
            elif extension == '.tsv':
                source = upload.tsv(f)
            elif extension == '.zip':
                source = upload.shapefile(f)
            elif extension == '.kml':
                source = upload.kml(f)
            elif extension == '.geojson':
                source = upload.geojson(f)
            else:
                raise Exception('File format not supported')
    elif type(updated_dataset) == pd.DataFrame or type(updated_dataset) == gpd.GeoDataFrame:
        source = upload.df(updated_dataset)

    output_schema = source.get_latest_input_schema().get_latest_output_schema()

    output_schema = output_schema.wait_for_finish()

    # check for errors
    assert output_schema.attributes['error_count'] == 0
    print(output_schema.attributes['error_count'])

    # If you want, you can get a csv stream of all the errors
    errors = output_schema.schema_errors_csv()
    for line in errors.iter_lines():
        print(line)

    #############################################################################
    # The next few lines of code will update the draft/revision into the asset. #
    # Do not run if you plan on keeping your draft!                             #
    #############################################################################
    job = revision.apply(output_schema=output_schema)

    # This code outputs the status from the Job object
    # Track the async process
    def job_progress(job):
        clear_output(wait=True)
        print(job.attributes['log'][0]['stage'])
        print('Job progress:', job.attributes['status'])

    job = job.wait_for_finish(progress = job_progress)
    sys.exit(0 if job.attributes['status'] == 'successful' else 1)

def update_metadata(sess, asset_link):
    """
    Takes the session and asset link for the dataset and updates the Last Access Date
    """
    get_json = sess.get(asset_link).json()
    update_metadata = get_json['customFields']
    update_metadata['SANDAG Last Access Date'] = datetime.datetime.today().strftime('%D')

    sess.patch(asset_link, 
            data=json.dumps(update_metadata)).json()