USE demographic_warehouse;

SELECT [yr_id]
      ,[mgra_id]
	  ,[employment_type_id]
      ,sum([jobs]) as jobs
  FROM [isam].[xpef33].[dw_jobs]
  GROUP BY [yr_id]
      ,[mgra_id]
	  ,[employment_type_id]
  ORDER BY [yr_id]
      ,[mgra_id]
	  ,[employment_type_id]