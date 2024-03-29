SELECT
	[{geo_level}] as [geozone]
    ,[yr_id]
    ,SUM([population]) as [count]
	,[dim_age].[group_5yr_lower_bound] as [lower_bound]
	,[dim_age].[group_5yr_upper_bound] as [upper_bound]
  FROM [estimates].[est_{estimates_version}].[dw_age] dw
	LEFT OUTER JOIN [demographic_warehouse].[dim].[age_group] dim_age 
		ON dim_age.age_group_id = dw.age_group_id
	LEFT OUTER JOIN [demographic_warehouse].[dim].[mgra_denormalize] mgra_denorm
		ON mgra_denorm.mgra_id = dw.mgra_id
  GROUP BY {geo_level}, [yr_id], [group_5yr], [group_5yr_lower_bound], [group_5yr_upper_bound]
  ORDER BY {geo_level}, [yr_id], [group_5yr_lower_bound]