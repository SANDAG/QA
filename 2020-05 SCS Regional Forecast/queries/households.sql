USE demographic_warehouse;

SELECT [housing_id]
      ,[datasource_id]
      ,[yr_id]
      ,[mgra_id]
      ,[structure_type_id]
      ,[units]
      ,[unoccupiable]
      ,[occupied]
      ,[vacancy]
  FROM [demographic_warehouse].[fact].[housing]
  WHERE datasource_id = ds_id

