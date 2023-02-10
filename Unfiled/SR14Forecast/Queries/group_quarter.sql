SELECT
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,population.housing_type_id
	,housing_type.short_name
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE population.datasource_id = 19
GROUP BY 
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,population.housing_type_id
	,housing_type.short_name
ORDER BY 
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,population.housing_type_id