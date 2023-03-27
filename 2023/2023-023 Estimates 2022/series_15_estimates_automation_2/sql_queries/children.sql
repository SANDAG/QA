SELECT series_15_denorm.[{geo_level}]
	,[estimates_year] AS 'yr_id'
      ,SUM([with_children]) AS 'with_children'
      ,SUM([without_children]) AS 'without_children'
  FROM [estimates].[est_{estimates_version}].[households_children] AS children_table
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON children_table.mgra = series_15_denorm.mgra
  GROUP BY series_15_denorm.[{geo_level}], [estimates_year]
  ORDER BY series_15_denorm.[{geo_level}], estimates_year