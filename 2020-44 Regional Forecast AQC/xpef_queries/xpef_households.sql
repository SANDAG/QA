USE demographic_warehouse;

SELECT [yr_id]
      ,[mgra_id]
      ,sum([households]) as households
  FROM [isam].[xpef33].[dw_households]
  GROUP BY [yr_id]
      ,[mgra_id]
  ORDER BY [yr_id]
      ,[mgra_id]