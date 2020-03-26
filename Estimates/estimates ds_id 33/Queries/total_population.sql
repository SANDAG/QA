(SELECT yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
WHERE datasource_id = ds_id
GROUP BY yr_id, mgra_denormalize.jurisdiction)
UNION
(SELECT yr_id
	,'region' as geotype 
	,mgra_denormalize.region as geozone
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
WHERE datasource_id = ds_id
GROUP BY yr_id, mgra_denormalize.region)
UNION
(SELECT yr_id
	,'cpa' as geotype
	,mgra_denormalize.cpa as geozone
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
WHERE datasource_id = ds_id
GROUP BY yr_id, mgra_denormalize.cpa)
UNION
(SELECT yr_id
	,'zip' as geotype
	,mgra_denormalize.tract as geozone
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
WHERE datasource_id = ds_id
GROUP BY yr_id, mgra_denormalize.tract)
ORDER BY yr_id, geotype, geozone


