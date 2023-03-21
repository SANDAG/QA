/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [mgra_id]
      ,[yr_id]
      ,housing_id_table.long_name
      ,[units]
      ,[unoccupiable]
      ,[occupied]
      ,[vacancy]
  FROM [estimates].[est_2022_01].[dw_housing] AS housing_table
  LEFT JOIN [demographic_warehouse].[dim].[structure_type] AS housing_id_table
  ON housing_table.structure_type_id = housing_id_table.structure_type_id