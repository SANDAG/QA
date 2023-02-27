/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [mgra_id]
      ,[yr_id]
	  ,age_group_table.name
      ,[population]
  FROM [estimates].[est_2022_01].[dw_age] AS age_table
  LEFT JOIN [demographic_warehouse].[dim].[age_group] AS age_group_table
  ON age_table.age_group_id = age_group_table.age_group_id