USE demographic_warehouse;

SELECT
	population.datasource_id
	--,datasource.description
	--,datasource.name
	,population.yr_id
	,mgra.geotype
	,mgra.geozone
	,SUM(population) as gqpop
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
		INNER JOIN dim.datasource
		ON population.datasource_id = datasource.datasource_id
WHERE population.datasource_id = ds_id and population.housing_type_id != 1
GROUP BY 
	population.datasource_id
	,datasource.description
	,datasource.name
	,population.yr_id
	,mgra.geotype
	,mgra.geozone
ORDER BY mgra.geotype
	,mgra.geozone
	,population.yr_id
