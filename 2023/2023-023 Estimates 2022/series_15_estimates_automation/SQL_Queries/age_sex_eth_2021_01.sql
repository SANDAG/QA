SELECT
	mgra_dnorm.mgra
      ,[yr_id]
      ,age_group_table.name AS 'age_group'
      ,sex_table.sex
      ,eth_table.long_name AS 'race'
      ,SUM([population])
  FROM [estimates].[est_2021_01].[dw_age_sex_ethnicity] as age_sex_eth_table
  left JOIN [demographic_warehouse].[dim].[age_group] as age_group_table
  ON age_sex_eth_table.age_group_id = age_group_table.age_group_id
  LEFT JOIN [demographic_warehouse].[dim].[sex] AS sex_table
  ON age_sex_eth_table.sex_id = sex_table.sex_id
  LEFT JOIN [demographic_warehouse].[dim].[ethnicity] as eth_table
  ON age_sex_eth_table.ethnicity_id = eth_table.ethnicity_id
  LEFT JOIN [demographic_warehouse].[dim].[mgra_denormalize] AS mgra_dnorm
  ON age_sex_eth_table.mgra_id = mgra_dnorm.mgra_id
  WHERE yr_id = 2020 OR yr_id = 2021
  GROUP BY mgra, yr_id, age_group_table.name, sex, eth_table.long_name