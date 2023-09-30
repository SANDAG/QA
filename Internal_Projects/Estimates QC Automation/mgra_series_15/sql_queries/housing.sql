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
	  ,housing_id_table.long_name AS 'breakdown_value'
      ,SUM([units]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_housing] AS housing_table
  LEFT JOIN [demographic_warehouse].[dim].[structure_type] AS housing_id_table
  ON housing_table.structure_type_id = housing_id_table.structure_type_id
  LEFT JOIN series_15_denorm
  ON housing_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, housing_id_table.long_name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, housing_id_table.long_name