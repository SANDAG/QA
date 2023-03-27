SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
      ,eth_id_table.long_name AS 'breakdown_value'
      ,SUM([population]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_ethnicity] AS eth_table
  LEFT JOIN [demographic_warehouse].[dim].[ethnicity] as eth_id_table
  ON eth_table.ethnicity_id = eth_id_table.ethnicity_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON eth_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], [yr_id], eth_id_table.long_name
  ORDER BY series_15_denorm.[{geo_level}], [yr_id], eth_id_table.long_name