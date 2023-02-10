/****** Script for SelectTopNRows command from SSMS  ******/
SELECT [isam].[xpef33].[abm_syn_persons].[yr]
	  ,[demographic_warehouse].[dim].[mgra_denormalize].[jurisdiction]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
      ,count([perid]) as pop
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then "10 to 19"
			when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then "20 to 29"
			when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then "30 to 39"
			else NULL 
			end as age_rc
  FROM [isam].[xpef33].[abm_syn_persons]
  INNER JOIN [isam].[xpef33].[abm_syn_households]
  on [isam].[xpef33].[abm_syn_persons].[hh_id]=[isam].[xpef33].[abm_syn_households].[hh_id]
  INNER JOIN [demographic_warehouse].[dim].[mgra_denormalize]
  on [demographic_warehouse].[dim].[mgra_denormalize].[mgra]=[isam].[xpef33].[abm_syn_households].[mgra]
  group by [isam].[xpef33].[abm_syn_persons].[yr]
	  ,[demographic_warehouse].[dim].[mgra_denormalize].[jurisdiction]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then "10 to 19"
			when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then "20 to 29"
			when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then "30 to 39"
			else NULL
			end as age_rc
  order by [isam].[xpef33].[abm_syn_persons].[yr]
	  ,[demographic_warehouse].[dim].[mgra_denormalize].[jurisdiction]
      ,[isam].[xpef33].[abm_syn_persons].[type]
	  ,[isam].[xpef33].[abm_syn_persons].[rac1p]
	  ,[isam].[xpef33].[abm_syn_persons].[pemploy]
	  ,[isam].[xpef33].[abm_syn_persons].[pstudent]
	  ,[isam].[xpef33].[abm_syn_persons].[ptype]
	  ,case when [isam].[xpef33].[abm_syn_persons].[age] between 10 and 19 then "10 to 19"
			when [isam].[xpef33].[abm_syn_persons].[age] between 20 and 29 then "20 to 29"
			when [isam].[xpef33].[abm_syn_persons].[age] between 30 and 39 then "30 to 39"
			else NULL 
			end as age_rc
