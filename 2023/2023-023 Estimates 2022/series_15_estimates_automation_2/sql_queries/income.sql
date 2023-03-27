SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,income_group_table.name AS 'breakdown_value'
      ,SUM([households]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_household_income] AS income_table
  LEFT JOIN [demographic_warehouse].[dim].[income_group] AS income_group_table
  ON income_table.income_group_id = income_group_table.income_group_id
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON income_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, income_group_table.name
  ORDER BY series_15_denorm.[{geo_level}], yr_id, income_group_table.name