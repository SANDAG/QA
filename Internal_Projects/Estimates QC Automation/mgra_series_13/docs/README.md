<!-- markdownlint-disable -->

# API Overview

## Modules

- [`functions`](./functions.md#module-functions): Helper functions which are generally useful in all parts of Estimates Automation.
- [`generate_tables`](./generate_tables.md#module-generate_tables): Classes/functions to return/save various Estimates tables.
- [`perform_checks`](./perform_checks.md#module-perform_checks): Classes/functions to run various checks on Estimates tables.

## Classes

- [`generate_tables.CA_DOF`](./generate_tables.md#class-ca_dof): Functions to get CA Department of Finance population estimates from SQL.
- [`generate_tables.DiffFiles`](./generate_tables.md#class-difffiles): Functions to return/save various Estimates diff tables.
- [`generate_tables.EstimatesTables`](./generate_tables.md#class-estimatestables): Functions to return/save various Estimates tables.
- [`generate_tables.ProportionFiles`](./generate_tables.md#class-proportionfiles): Functions to compute categorical distributions within Estimates tables.
- [`perform_checks.DOFPopulation`](./perform_checks.md#class-dofpopulation): Check that the total population of the region is within 1.5% of CA DOF population.
- [`perform_checks.DOFProportion`](./perform_checks.md#class-dofproportion): Compares the proportion of groups between DOF and Estimates.
- [`perform_checks.InternalConsistency`](./perform_checks.md#class-internalconsistency): Functions to run internal consistency checks.
- [`perform_checks.NullValues`](./perform_checks.md#class-nullvalues): Functions to check for any null values.
- [`perform_checks.ThresholdAnalysis`](./perform_checks.md#class-thresholdanalysis): Calculates yearly change and flags if the changes are more than some % and some value.
- [`perform_checks.TrendAnalysis`](./perform_checks.md#class-trendanalysis): N/A. Done in PowerBI.
- [`perform_checks.VintageComparisons`](./perform_checks.md#class-vintagecomparisons): Functions to check that numbers between vintages does not exceed a % and numeric threshold.

## Functions

- [`functions.load`](./functions.md#function-load): Get the input dataframe(s) according to the other inputs.
- [`functions.save`](./functions.md#function-save): Save the input dataframe(s) according to the other inputs.


---

_This file was automatically generated via [lazydocs](https://github.com/ml-tooling/lazydocs)._
