USE demographic_warehouse;

SELECT [mgra_id]
      ,[yr_id]
      ,[ethnicity_id]
      ,sum([population]) as population
  FROM [isam].[xpef33].[dw_ethnicity]
  GROUP BY [mgra_id]
      ,[yr_id]
      ,[ethnicity_id]
  ORDER BY [mgra_id]
      ,[yr_id]
      ,[ethnicity_id]