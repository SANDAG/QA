SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,housing_type_id_table.long_name AS 'breakdown_value'
      ,SUM([population]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_population] AS population_table
  LEFT JOIN [demographic_warehouse].[dim].[housing_type] AS housing_type_id_table
  ON population_table.housing_type_id = housing_type_id_table.housing_type_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON population_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, housing_type_id_table.long_name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, housing_type_id_table.long_name