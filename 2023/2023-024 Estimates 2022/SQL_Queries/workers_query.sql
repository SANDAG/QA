/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [estimates_year] AS 'yr_id'
      ,[mgra]
      ,[workers_0]
      ,[workers_1]
      ,[workers_2]
      ,[workers_3plus]
  FROM [estimates].[est_2022_01].[households_workers]