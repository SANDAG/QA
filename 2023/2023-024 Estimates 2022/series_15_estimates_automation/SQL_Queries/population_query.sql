/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [mgra_id]
      ,[yr_id]
      ,housing_type_id_table.long_name
      ,[population]
  FROM [estimates].[est_2022_01].[dw_population] AS population_table
  LEFT JOIN [demographic_warehouse].[dim].[housing_type] AS housing_type_id_table
  ON population_table.housing_type_id = housing_type_id_table.housing_type_id