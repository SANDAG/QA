SELECT
	[{geo_level}] as [geozone]
    ,[yr_id]
    ,SUM([households]) as [count]
	,[dim_income].[lower_bound] as [lower_bound]
	,[dim_income].[upper_bound] as [upper_bound]
  FROM [estimates].[est_{estimates_version}].[dw_household_income] dw
	LEFT OUTER JOIN [demographic_warehouse].[dim].[income_group] dim_income 
		ON dim_income.income_group_id = dw.income_group_id
	LEFT OUTER JOIN [demographic_warehouse].[dim].[mgra_denormalize] mgra_denorm
		ON mgra_denorm.mgra_id = dw.mgra_id
  GROUP BY {geo_level}, [yr_id], [lower_bound], [upper_bound]
  ORDER BY {geo_level}, [yr_id], [lower_bound]