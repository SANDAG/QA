/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [mgra_id]
      ,[yr_id]
      ,household_type_id.name AS 'household_type'
      ,[households]
  FROM [estimates].[est_2022_01].[dw_households] AS household_table
  LEFT JOIN [demographic_warehouse].[dim].[household_type] AS household_type_id
  ON household_table.household_size_id = household_type_id.household_type_id