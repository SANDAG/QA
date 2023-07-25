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
      ,SUM([workers_0]) AS 'workers_0'
      ,SUM([workers_1]) AS 'workers_1'
      ,SUM([workers_2]) AS 'workers_2'
      ,SUM([workers_3plus]) AS 'workers_3plus'
  FROM [estimates].[est_{estimates_version}].[households_workers] AS workers_table
  LEFT JOIN series_15_denorm
  ON workers_table.mgra = series_15_denorm.mgra
  GROUP BY series_15_denorm.[{geo_level}], estimates_year
  ORDER BY series_15_denorm.[{geo_level}], estimates_year