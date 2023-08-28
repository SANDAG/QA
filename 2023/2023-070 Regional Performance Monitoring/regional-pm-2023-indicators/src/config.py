"""Module for determining configuration parameters for specific indicators
"""

from pathlib import Path

import pandas as pd
import toml


def get_config(indicator: str, config_path: str) -> dict:
    """Get config variables based on config file.
    """
    config = toml.load(config_path)

    indicators_xlsx_path = config['paths']['indicators_xlsx']
    indicators = pd.read_excel(
        indicators_xlsx_path,
        sheet_name='indicators',
        index_col=2,
    )
    legacy_sheet = (
        indicators
        .loc[indicator, 'legacy_sheet']
    )
    category = str(
        indicators
        .loc[indicator, 'category']
    )
    topic = str(
        indicators
        .loc[indicator, 'topic']
    )
    return {
        'legacy_xlsx_path': config['paths']['legacy_xlsx'],
        'indicators_xlsx_path': config['paths']['indicators_xlsx'],
        'raw_dir': (
            Path(config['paths']['raw_dir'])
            / (f'{category}/{topic}' if category != topic else category)
            / indicator
        ),
        'clean_dir': (
            Path(config['paths']['clean_dir'])
            / (f'{category}/{topic}' if category != topic else category)
            / indicator
        ),
        'legacy_sheet': legacy_sheet,
        'acs_api_key': config['acs_api_key']
    }
