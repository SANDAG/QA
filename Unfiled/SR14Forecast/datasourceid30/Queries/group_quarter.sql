(SELECT
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
WHERE population.datasource_id = ds_id
GROUP BY 
	population.yr_id
	,mgra_denormalize.jurisdiction
	,population.housing_type_id
	,housing_type.short_name)
UNION
(SELECT
	population.yr_id
	,'region' as geotype
	,mgra_denormalize.region as geozone
    ,population.housing_type_id
	,housing_type.short_name
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE population.datasource_id = ds_id
GROUP BY 
	population.yr_id
	,mgra_denormalize.region
	,population.housing_type_id
	,housing_type.short_name)
UNION
(SELECT
	population.yr_id
	,'cpa' as geotype
	,mgra_denormalize.cpa as geozone
    ,population.housing_type_id
	,housing_type.short_name
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE population.datasource_id = ds_id
GROUP BY 
	population.yr_id
	,mgra_denormalize.cpa
	,population.housing_type_id
	,housing_type.short_name)
ORDER BY 
	geotype
	,geozone
	,population.yr_id
	,population.housing_type_id
