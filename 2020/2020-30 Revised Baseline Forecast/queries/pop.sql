-- est pop by jurisdiction
USE demographic_warehouse;

SELECT 
	yr_id
	,datasource_id
	,mgra_denormalize.jurisdiction
	,mgra_denormalize.mgra
	,mgra_denormalize.mgra_id
	,SUM(population) as pop
FROM
	fact.population
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = population.mgra_id
WHERE
	datasource_id = ds_id
GROUP BY
	yr_id
	,datasource_id
	,mgra_denormalize.jurisdiction
	,mgra_denormalize.mgra
	,mgra_denormalize.mgra_id
ORDER BY yr_id
	,datasource_id
	,mgra_denormalize.jurisdiction
	,mgra_denormalize.mgra
	,mgra_denormalize.mgra_id
