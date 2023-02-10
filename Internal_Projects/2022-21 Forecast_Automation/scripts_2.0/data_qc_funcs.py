import pandas as pd
import numpy as np

# TODO: Build a function that can identify the level of the data


def percentile_outlier_check(df, column, lower_percentile, upper_percentile, level):
    """Returns a dataframe that lies outside the lower and upper percentiles given by the analyst."""
    lower_value = np.percentile(df[column], lower_percentile)
    upper_value = np.percentile(df[column], upper_percentile)

    # Todo: if no function for level, then will need to take in level and do something for it
    output = df[(df[column] < lower_value) | (
        df[column] > upper_value)][['year', level, column]]
    output = output.groupby(['year', level]).sum()

    return output
