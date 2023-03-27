SELECT series_15_denorm.[{geo_level}] AS 'geo_level'
      ,[yr_id]
	  ,household_size_id AS 'breakdown_value'
      ,SUM([households]) AS 'value'
  FROM [estimates].[est_{estimates_version}].[dw_households] AS households_table
  LEFT JOIN [ws].[dbo].[series_15_mgra_denorm] AS series_15_denorm
  ON households_table.mgra_id = series_15_denorm.mgra_id
  GROUP BY series_15_denorm.[{geo_level}], yr_id, household_size_id
  ORDER BY series_15_denorm.[{geo_level}], yr_id, household_size_id