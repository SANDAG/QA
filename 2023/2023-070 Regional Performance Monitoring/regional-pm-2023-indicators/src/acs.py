"""Module for pulling ACS data used in PM.
"""
from census import Census
from us import states
import pandas as pd
import requests
from tqdm.auto import tqdm


def download_detail_table_acs_data(
    census_api_key: str,
    years: list[int],
    columns: list[str]
) -> pd.DataFrame:
    census = Census(census_api_key)
    ca_fips = states.CA.fips
    sd_fips = '073'
    # Query raw data for each geography, each year
    return (
        pd.concat(
            [
                (
                    pd.DataFrame(
                        census.acs1.get(
                            ['NAME'] + columns,
                            {
                                'for': f'county:{sd_fips}',
                                'in': f'state:{ca_fips}',
                            },
                            year=year,
                        )  # San Diego County
                        + census.acs1.get(
                            ['NAME'] + columns,
                            {'for': f'state:{sd_fips}'},
                            year=year,
                        )  # California State
                        + census.acs1.get(
                            ['NAME'] + columns,
                            {'for': 'us:1'},
                            year=year,
                        )  # United States of America
                    )
                    .assign(year=year)
                )
                for year in tqdm(years)
            ]
        )
        .assign(year=lambda df: pd.to_datetime(df.year, format='%Y'))
    )


def download_subject_table_acs_data(
    census_api_key: str,
    years: list[int],
    columns: list[str]
) -> pd.DataFrame:
    # Query raw data for each geography, each year
    return (
        pd.concat(
            [
                _get_subject_year(
                    census_api_key,
                    year,
                    columns
                )
                for year in tqdm(years)
            ]
        )
        .assign(year=lambda df: pd.to_datetime(df.year, format='%Y'))
    )


def _get_subject_year(
    census_api_key: str,
    year: int,
    columns: list[str]
) -> pd.DataFrame:
    ca_fips = states.CA.fips
    sd_fips = '073'
    url = 'https://api.census.gov/data/{year}/acs/acs1/subject'

    response = requests.get(
            url=url.format(year=year),
            params={
                'get': ','.join(['NAME'] + columns),
                'for': f'county:{sd_fips}',
                'in': f'state:{ca_fips}',
                'key': census_api_key,
            },
        )
    sd=pd.DataFrame(data=response.json()[1:], columns=response.json()[0])

    response=requests.get(
            url=url.format(year=year),
            params={
                'get': ','.join(['NAME'] + columns),
                'for': f'state:{ca_fips}',
                'key': census_api_key,
            },
        )
    ca=pd.DataFrame(data=response.json()[1:], columns=response.json()[0])

    response=requests.get(
            url=url.format(year=year),
            params={
                'get': ','.join(['NAME'] + columns),
                'for': 'us:1',
                'key': census_api_key,
            },
        )
    us=pd.DataFrame(data=response.json()[1:], columns=response.json()[0])
    
    return pd.concat([sd, ca, us]).assign(year=year)
