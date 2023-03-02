/****** Script for SelectTopNRows command from SSMS  ******/
SELECT 
	geo_table.cpa
      ,[yr_id]
      ,household_type_id.name AS 'household_type'
      ,[households]
  FROM [estimates].[est_2021_01].[dw_households] AS household_table
  LEFT JOIN [demographic_warehouse].[dim].[household_type] AS household_type_id
  ON household_table.household_size_id = household_type_id.household_type_id
  LEFT JOIN [demographic_warehouse].[dim].[mgra_denormalize] AS geo_table 
  ON household_table.mgra_id = geo_table.mgra_id
  WHERE yr_id = 2020 OR yr_id = 2021 AND geo_table.series = 14