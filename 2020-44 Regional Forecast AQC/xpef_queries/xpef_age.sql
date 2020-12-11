
SELECT [mgra_id]
      ,[yr_id]
      ,[age_group_id]
	  ,sum([population]) as pop
FROM [isam].[xpef33].[dw_age]
GROUP BY [mgra_id]
      ,[yr_id]
      ,[age_group_id]
ORDER BY [mgra_id]
      ,[yr_id]
      ,[age_group_id]
