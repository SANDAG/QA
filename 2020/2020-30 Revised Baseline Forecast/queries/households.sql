USE demographic_warehouse;

SELECT [datasource_id]
      ,[yr_id]
      ,[mgra_id]
      ,sum([units]) as units
      ,sum([unoccupiable]) as unoccupiable
      ,sum([occupied]) as occupied
      ,sum([vacancy]) as vacancy
  FROM [demographic_warehouse].[fact].[housing]
  WHERE datasource_id = ds_id
  GROUP BY [datasource_id]
      ,[yr_id]
      ,[mgra_id]
  ORDER BY [datasource_id]
      ,[yr_id]
      ,[mgra_id]
  

