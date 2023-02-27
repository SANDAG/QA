/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [mgra_id]
      ,[yr_id]
      ,eth_id_table.long_name
      ,[population]
  FROM [estimates].[est_2022_01].[dw_ethnicity] AS eth_table
  LEFT JOIN [demographic_warehouse].[dim].[ethnicity] as eth_id_table
  ON eth_table.ethnicity_id = eth_id_table.ethnicity_id