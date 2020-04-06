USE demographic_warehouse;

SELECT  [datasource_id]
      ,[datasource_type_id]
      ,[name]
      ,[description]
      ,[is_active]
      ,[series]
      ,[publish_year]
      ,[source_system_version]
  FROM [demographic_warehouse].[dim].[datasource]
  WHERE datasource_id IN (ds_id)
