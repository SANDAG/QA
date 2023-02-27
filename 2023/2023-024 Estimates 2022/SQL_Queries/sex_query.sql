/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [mgra_id]
      ,[yr_id]
      ,sex_id_table.sex
      ,[population]
  FROM [estimates].[est_2022_01].[dw_sex] AS sex_table 
  LEFT JOIN [demographic_warehouse].[dim].[sex] AS sex_id_table
  ON sex_table.sex_id = sex_id_table.sex_id