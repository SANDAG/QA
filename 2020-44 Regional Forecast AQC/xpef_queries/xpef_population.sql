USE demographic_warehouse;

SELECT 
	[mgra_id]
    ,[yr_id]
    ,[housing_type_id]
	,SUM(population) as pop
FROM [isam].[xpef33].[dw_population]
GROUP BY
	[mgra_id]
    ,[yr_id]
    ,[housing_type_id]
ORDER BY [mgra_id]
    ,[yr_id]
    ,[housing_type_id]
