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

SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,household_size_id AS 'breakdown_value'
      ,SUM([households]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_households] AS households_table
  LEFT JOIN series_15_denorm
  ON households_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, household_size_id
  ORDER BY series_15_denorm.[{geo_level}], yr_id, household_size_id