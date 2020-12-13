
SELECT [yr]
	  ,[hinccat1]
	  ,[demographic_warehouse].[dim].[mgra_denormalize].[jurisdiction]
      ,count([hh_id]) as hh
	  ,sum([persons]) as persons
	  ,sum([veh]) as veh
	  ,sum([hworkers]) as hworkers
  FROM [isam].[xpef33].[abm_syn_households]
  INNER JOIN [demographic_warehouse].[dim].[mgra_denormalize]
  on [demographic_warehouse].[dim].[mgra_denormalize].[mgra]=[isam].[xpef33].[abm_syn_households].[mgra]
  group by [yr]
	  ,[hinccat1]
	  ,[demographic_warehouse].[dim].[mgra_denormalize].[jurisdiction]
  order by [yr]
	  ,[hinccat1]
	  ,[demographic_warehouse].[dim].[mgra_denormalize].[jurisdiction]