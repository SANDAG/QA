SELECT TOP (1000) base_data.[mgra_id]
      ,[yr_id]
      ,[population]
	  ,geotype
	  ,geozone
	  ,ethnicity
  FROM [isam].[xpef41].[dw_ethnicity] AS base_data
	  LEFT JOIN (
		SELECT mgra_id, mgra, geotype, geozone 
		FROM demographic_warehouse.dim.mgra 
		WHERE series = 14 AND (geotype='cpa' OR geotype='jurisdiction')
		) AS geo_data
		ON base_data.mgra_id = geo_data.mgra_id
			LEFT JOIN (
			SELECT [ethnicity_id]
				  ,[short_name] AS 'ethnicity'
			  FROM [demographic_warehouse].[dim].[ethnicity]
			  ) AS dim_data
			  ON base_data.[ethnicity_id] = dim_data.ethnicity_id

	