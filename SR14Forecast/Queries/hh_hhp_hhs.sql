--HH, HHP, HHS

SELECT
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,hh.hh AS households
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN
		(
			SELECT yr_id, mgra.geotype, mgra.geozone, SUM(occupied) as hh
			FROM fact.housing
				INNER JOIN dim.mgra
				ON mgra.mgra_id = housing.mgra_id
				AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
			WHERe housing.datasource_id = 17
			GROUP BY yr_id, mgra.geotype, mgra.geozone
		) hh
		ON hh.yr_id = population.yr_id
		AND hh.geozone = mgra.geozone
		AND hh.geotype = mgra.geotype
WHERE datasource_id = 17
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh
ORDER BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh
