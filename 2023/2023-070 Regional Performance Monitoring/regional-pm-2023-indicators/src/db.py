"""Module for working with SANDAG database.
"""

import sqlalchemy as sal
from sqlalchemy.engine import URL, Engine


def get_db_connection(
    server: str,
    db: str,  # pylint: disable=invalid-name
) -> Engine:
    """
    Connect to a SANDAG SQL database server.
    """
    # https://docs.sqlalchemy.org/en/14/dialects/mssql.html#pass-through-exact-pyodbc-string
    conn_string: str = "DRIVER={ODBC Driver 18 for SQL Server};"\
        + f"SERVER={server};"\
        + f"DATABASE={db};"\
        + "Trusted_Connection=yes;"\
        + "Encrypt=optional"

    # sqlalchemy uses URLs,
    # so we'll need to translate the odbc-style string into a URL
    url = URL.create(
        "mssql+pyodbc",
        query={"odbc_connect": conn_string}
    )

    return sal.create_engine(url, fast_executemany=True)
