/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
      [yr_id]
      ,dim.long_name
      ,SUM([population]) AS 'population'
  FROM [demographic_warehouse].[fact].[ethnicity] AS base
    LEFT JOIN [demographic_warehouse].[dim].[ethnicity] AS dim
	ON base.ethnicity_id = dim.ethnicity_id
  WHERE datasource_id = 42
  GROUP BY yr_id, long_name