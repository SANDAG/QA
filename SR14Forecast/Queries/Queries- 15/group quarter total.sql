/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [yr_id]
      ,sum(population) as pop_tot
  FROM [demographic_warehouse].[fact].[population]
  where datasource_id=15 and housing_type_id>1
  group by yr_id
  order by yr_id