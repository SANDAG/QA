SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,sex_id_table.sex AS 'breakdown_value'
      ,SUM([population]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_sex] AS sex_table 
  LEFT JOIN [demographic_warehouse].[dim].[sex] AS sex_id_table
  ON sex_table.sex_id = sex_id_table.sex_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON sex_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, sex_id_table.sex
  ORDER BY series_15_denorm.[{geo_level}], yr_id, sex_id_table.sex