
SELECT
	population.yr_id as year
	,population.datasource_id
	,datasource.name as datasource
	,mgra.geotype
	,round(mgra.geozone,2)as geozone
	,hh.hh AS hh
	,SUM(population) as hhpop
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 6) as [hhsize]
	,hh.unoccupied as unoccupiable
	,hh.du as units
	,ROUND(CASE WHEN SUM(hh.hh) = 0 THEN 0 
				ELSE 1.0 - SUM(hh.hh)  / 
				CASE WHEN (SUM(hh.du -hh.unoccupied))=0 THEN 1 
					ELSE CAST(SUM(hh.du -hh.unoccupied) as float) END END, 2) as vac
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('tract')
		INNER JOIN
		(
			SELECT yr_id, mgra.geotype, mgra.geozone, SUM(occupied) as hh, SUM(units) as du, SUM(housing.unoccupiable) as unoccupied
			FROM fact.housing
				INNER JOIN dim.mgra
				ON mgra.mgra_id = housing.mgra_id
				AND mgra.geotype IN ('tract')
			WHERe housing.datasource_id IN (ds_id)
			GROUP BY yr_id, mgra.geotype, mgra.geozone
		) hh
		ON hh.yr_id = population.yr_id
		AND hh.geozone = mgra.geozone
		AND hh.geotype = mgra.geotype
	LEFT JOIN [dim].[datasource] 
	on dim.datasource.datasource_id = population.datasource_id
WHERE population.datasource_id IN (ds_id)
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh, hh.unoccupied,hh.du,population.datasource_id,datasource.name
ORDER BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh
