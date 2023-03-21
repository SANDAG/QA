/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
	geo_table.sra
      ,[yr_id]
	  ,housing_id_table.long_name
      ,[population]
  FROM [estimates].[est_2021_01].[dw_population] AS pop_base_table
  LEFT JOIN [demographic_warehouse].[dim].[mgra_denormalize] AS geo_table
  ON pop_base_table.mgra_id = geo_table.mgra_id
  LEFT JOIN [demographic_warehouse].[dim].[housing_type] AS housing_id_table
  ON pop_base_table.housing_type_id = housing_id_table.housing_type_id







 /* 
 1. Geography roll-up: [demographic_warehouse].[dim].[mgra_denormalize]
 2. id matching: [demographic_warehouse].[dim].[housing_type]


 */
