SELECT [mgra_id]
      ,[mgra]
      ,[region]
      ,[cpa]
      ,[jurisdiction]
      ,[zip]
      ,[jurisdiction_id]
      ,[cpa_id]
 FROM 
 [demographic_warehouse].[dim].[mgra_denormalize]
 WHERE 
 [series] = 14