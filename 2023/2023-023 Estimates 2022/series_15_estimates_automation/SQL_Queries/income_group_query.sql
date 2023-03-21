/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [mgra_id]
      ,[yr_id]
      ,income_group_table.name AS 'income_group'
      ,[households]
  FROM [estimates].[est_2022_01].[dw_household_income] AS income_table
  LEFT JOIN [demographic_warehouse].[dim].[income_group] AS income_group_table
  ON income_table.income_group_id = income_group_table.income_group_id