USE [demographic_warehouse]

SELECT [datasource_id]
      ,[yr_id]
      ,[geotype]
      ,[geozone]
      ,[employment_type_id]
      ,[full_name] as Industry_Sector
      ,[jobs]
  FROM [demographic_warehouse].[dbo].[vi_emp_datasource_id]
  where geotype = 'jurisdiction' and datasource_id= ds_id