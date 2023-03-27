/****** Script for SelectTopNRows command from SSMS  ******/
SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,age_group_table.name AS 'breakdown_value'
      ,SUM([population]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_age] AS age_table
  LEFT JOIN [demographic_warehouse].[dim].[age_group] AS age_group_table
  ON age_table.age_group_id = age_group_table.age_group_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON age_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, age_group_table.name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, age_group_table.name