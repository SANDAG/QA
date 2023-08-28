"""Module for looking up and summarizing info on indicators.
"""

from IPython.core.display import Markdown
import pandas as pd


def describe_indicator(
    indicator: str,
    indicators_xlsx_path: str,
) -> Markdown:
    """Generate markdown description for an indicator.
    """
    indicators = pd.read_excel(
        indicators_xlsx_path,
        sheet_name='indicators',
        index_col=2,
    )
    indicator_info = (
        indicators
        .loc[indicator, :]
    )
    return Markdown(
        f'{indicator_info.brief_description}\n\n'
        f'{indicator_info.description}'
    )


def list_schema(
    indicator: str,
    indicators_xlsx_path: str,
) -> pd.DataFrame:
    """Generate pandas table of schema for indicator.
    """
    columns = pd.read_excel(
        indicators_xlsx_path,
        sheet_name='columns',
        index_col=2,
    )
    indicator_columns = (
        columns
        .loc[[indicator]]
        [['column', 'name', 'description', 'type']]
    )
    return indicator_columns.reset_index(drop=True).set_index('column')


def list_sources(
    indicator: str,
    indicators_xlsx_path: str,
) -> pd.DataFrame:
    """Generate pandas table of sources for indicator.
    """
    sources = pd.read_excel(
        indicators_xlsx_path,
        sheet_name='sources',
        index_col=2,
    )
    indicator_sources = (
        sources
        .loc[[indicator]]
        [['source', 'name', 'organization', 'active', 'notes']]
    )
    return indicator_sources.reset_index(drop=True).set_index('source')


def list_update_steps(
    indicator: str,
    indicators_xlsx_path: str,
) -> pd.DataFrame:
    """Generate pandas table of update steps for indicator.
    """
    updates = pd.read_excel(
        indicators_xlsx_path,
        sheet_name='updates',
        index_col=2,
    )
    indicator_steps = (
        updates
        .loc[[indicator]]
        [['step']]
    )
    return indicator_steps.reset_index(drop=True)


def list_remarks(
    indicator: str,
    indicators_xlsx_path: str,
) -> pd.DataFrame:
    """Generate pandas table of extra notes for indicator.
    """
    remarks = pd.read_excel(
        indicators_xlsx_path,
        sheet_name='remarks',
        index_col=2,
    )
    try:
        indicator_remarks = (
            remarks
            .loc[[indicator]]
            [['author', 'note']]
        )
    except KeyError:
        return pd.DataFrame()
    return indicator_remarks.reset_index(drop=True)
