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
	  ,income_group_table.name AS 'breakdown_value'
      ,SUM([households]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_household_income] AS income_table
  LEFT JOIN [demographic_warehouse].[dim].[income_group] AS income_group_table
  ON income_table.income_group_id = income_group_table.income_group_id
  LEFT JOIN series_15_denorm
  ON income_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, income_group_table.name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, income_group_table.name