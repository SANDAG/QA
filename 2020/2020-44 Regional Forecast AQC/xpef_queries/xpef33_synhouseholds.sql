
SELECT [yr]
	  ,[mgra]
	  ,[hinccat1]
      ,count([hhid]) as hh
	  ,sum([persons]) as persons
	  ,sum([veh]) as veh
	  ,sum([hworkers]) as hworkers
  FROM [isam].[xpef33].[abm_syn_households]
  WHERE [unittype]=0
  group by [yr]
	  ,[mgra]
	  ,[hinccat1]
  order by [yr]
	  ,[mgra]
	  ,[hinccat1]