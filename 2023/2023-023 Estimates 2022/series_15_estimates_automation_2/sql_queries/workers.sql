SELECT series_15_denorm.[{geo_level}]
	,[estimates_year] AS 'yr_id'
      ,SUM([workers_0]) AS 'workers_0'
      ,SUM([workers_1]) AS 'workers_1'
      ,SUM([workers_3plus]) AS 'workers_3plus'
  FROM [estimates].[est_{estimates_version}].[households_workers] AS workers_table
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON workers_table.mgra = series_15_denorm.mgra
  GROUP BY series_15_denorm.[{geo_level}], estimates_year
  ORDER BY series_15_denorm.[{geo_level}], estimates_year