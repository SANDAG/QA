
/* MGRA Denormalize Table */
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
  WHERE series = 15 AND mgra_id = 150000100

/* Seeing if the above mgra_id exists in 2022_01 (it doesn't) */
SELECT TOP (1) [mgra_id]
    ,[yr_id]
    ,[age_group_id]
    ,[population]
FROM [estimates].[est_2022_01].[dw_age]
WHERE mgra_id = 150000100

/* The format the mgra is in in 2022_01 */
SELECT TOP (1) [mgra_id]
    ,[yr_id]
    ,[age_group_id]
    ,[population]
FROM [estimates].[est_2022_01].[dw_age]
WHERE mgra_id = 1500000100


