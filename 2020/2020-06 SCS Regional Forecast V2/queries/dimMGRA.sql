
SELECT [mgra_id]
      ,[mgra]
  FROM [demographic_warehouse].[dim].[mgra_denormalize]
  GROUP BY [mgra_id]
      ,[mgra]
