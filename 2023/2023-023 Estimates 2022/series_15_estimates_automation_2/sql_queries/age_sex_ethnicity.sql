SELECT
	series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
      ,age_group_table.name AS 'age group'
      ,sex_table.sex
      ,eth_table.long_name AS 'race'
      ,SUM([population]) AS 'population'
  FROM [estimates].[est_{estimates_version}].[dw_age_sex_ethnicity] as age_sex_eth_table
  left JOIN [demographic_warehouse].[dim].[age_group] as age_group_table
  ON age_sex_eth_table.age_group_id = age_group_table.age_group_id
  LEFT JOIN [demographic_warehouse].[dim].[sex] AS sex_table
  ON age_sex_eth_table.sex_id = sex_table.sex_id
  LEFT JOIN [demographic_warehouse].[dim].[ethnicity] as eth_table
  ON age_sex_eth_table.ethnicity_id = eth_table.ethnicity_id
  LEFT JOIN [demographic_warehouse].[dim].[mgra_denormalize] AS mgra_dnorm
  ON age_sex_eth_table.mgra_id = mgra_dnorm.mgra_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON age_sex_eth_table.mgra_id = series_15_denorm.mgra_id
  WHERE yr_id = 2020 OR yr_id = 2021
  GROUP BY series_15_denorm.[{geo_level}], yr_id, age_group_table.name, sex, eth_table.long_name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, age_group_table.name, sex, eth_table.long_name