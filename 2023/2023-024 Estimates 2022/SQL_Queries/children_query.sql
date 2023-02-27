/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [estimates_year] AS 'yr_id'
      ,[mgra]
      ,[with_children]
      ,[without_children]
  FROM [estimates].[est_2022_01].[households_children]