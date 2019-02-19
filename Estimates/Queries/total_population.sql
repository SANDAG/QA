SELECT yr_id
	,mgra.geotype
	,mgra.geozone
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
WHERE datasource_id = ds_id
GROUP BY yr_id, mgra.geotype, mgra.geozone
ORDER BY yr_id, mgra.geotype, mgra.geozone