SELECT TOP(100) series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,housing_id_table.long_name AS 'breakdown_value'
      ,SUM([units]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_housing] AS housing_table
  LEFT JOIN [demographic_warehouse].[dim].[structure_type] AS housing_id_table
  ON housing_table.structure_type_id = housing_id_table.structure_type_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON housing_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, housing_id_table.long_name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, housing_id_table.long_name