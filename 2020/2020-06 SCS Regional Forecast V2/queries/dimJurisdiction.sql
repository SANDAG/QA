
SELECT [jurisdiction]
  FROM [demographic_warehouse].[dim].[mgra_denormalize]
  GROUP BY [jurisdiction]
