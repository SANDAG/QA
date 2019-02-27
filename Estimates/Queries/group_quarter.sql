SELECT
	population.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
    ,population.housing_type_id
	,housing_type.short_name
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE population.datasource_id = 26
GROUP BY 
	population.yr_id
	,mgra_denormalize.jurisdiction
	,population.housing_type_id
	,housing_type.short_name
ORDER BY 
	geotype
	,geozone
	,population.yr_id
	,population.housing_type_id
