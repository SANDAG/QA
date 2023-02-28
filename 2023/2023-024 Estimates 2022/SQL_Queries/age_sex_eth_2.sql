SELECT
	mgra_dnorm.mgra
      ,[yr_id]
      ,age_group_table.name AS 'age_group'
      ,sex_table.sex
      ,eth_table.long_name AS 'race'
      ,SUM([population])
  FROM [estimates].[est_2022_01].[dw_age_sex_ethnicity] as age_sex_eth_table
  left JOIN [demographic_warehouse].[dim].[age_group] as age_group_table
  ON age_sex_eth_table.age_group_id = age_group_table.age_group_id
  LEFT JOIN [demographic_warehouse].[dim].[sex] AS sex_table
  ON age_sex_eth_table.sex_id = sex_table.sex_id
  LEFT JOIN [demographic_warehouse].[dim].[ethnicity] as eth_table
  ON age_sex_eth_table.ethnicity_id = eth_table.ethnicity_id
  LEFT JOIN [estimates].[est_2022_01].[mgra_denormalize] AS mgra_dnorm
  ON age_sex_eth_table.mgra_id = mgra_dnorm.mgra_id
  GROUP BY mgra, yr_id, age_group_table.name, sex, eth_table.long_name