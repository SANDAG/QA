SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
      ,SUM([units]) AS 'units'
	  ,SUM([occupied]) AS 'occupied'
      ,SUM([vacancy]) AS 'vacancy'
  FROM [estimates].[est_{estimates_version}].[dw_housing] AS housing_table
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON housing_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id
  ORDER BY series_15_denorm.[{geo_level}], yr_id