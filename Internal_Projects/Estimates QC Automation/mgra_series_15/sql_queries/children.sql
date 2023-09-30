with series_15_denorm as
(
SELECT [mgra_id]
      ,denorm_table.[mgra]
	  ,[tract] AS 'census_tract'
	  ,[cpa]
	  ,[jurisdiction]
	  ,[sra]
	  ,geo_depot_mgra15.LUZ AS 'luz'
      ,[region]
  FROM [demographic_warehouse].[dim].[mgra_denormalize] AS denorm_table
  LEFT OUTER JOIN OPENQUERY([sql2014b8], 'SELECT [MGRA], [LUZ] FROM [GeoDepot].[gis].[MGRA15]') geo_depot_mgra15
	ON denorm_table.mgra = geo_depot_mgra15.MGRA
  WHERE series = 15
)

SELECT series_15_denorm.[{geo_level}]
	,[estimates_year] AS 'yr_id'
      ,SUM([with_children]) AS 'with_children'
      ,SUM([without_children]) AS 'without_children'
  FROM [estimates].[est_{estimates_version}].[households_children] AS children_table
  LEFT JOIN series_15_denorm
  ON children_table.mgra = series_15_denorm.mgra
  GROUP BY series_15_denorm.[{geo_level}], [estimates_year]
  ORDER BY series_15_denorm.[{geo_level}], estimates_year