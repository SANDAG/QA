USE demographic_warehouse;
--HH, HHP, HHS

(SELECT
	population.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
	,hh.hh AS households
	,hh.unoccupied as unoccupiable
	,hh.du as units
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'jurisdiction' as geotype,mgra_denormalize.jurisdiction as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id = ds_id
			GROUP BY yr_id, mgra_denormalize.jurisdiction
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.jurisdiction
WHERE datasource_id = ds_id
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra_denormalize.jurisdiction, hh.hh, hh.unoccupied, hh.du)
UNION
(SELECT
	population.yr_id
	,'cpa' as geotype
	,mgra_denormalize.cpa as geozone
	,hh.hh AS households
	,hh.unoccupied as unoccupiable
	,hh.du as units
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'cpa' as geotype,mgra_denormalize.cpa as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id = ds_id
			GROUP BY yr_id, mgra_denormalize.cpa
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.cpa
WHERE datasource_id = ds_id
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra_denormalize.cpa, hh.hh, hh.unoccupied, hh.du)
UNION
(SELECT
	population.yr_id
	,'region' as geotype
	,mgra_denormalize.region as geozone
	,hh.hh AS households
	,hh.unoccupied as unoccupiable
	,hh.du as units
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'region' as geotype,mgra_denormalize.region as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id = ds_id
			GROUP BY yr_id, mgra_denormalize.region
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.region
WHERE datasource_id = ds_id
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra_denormalize.region, hh.hh, hh.unoccupied, hh.du)
UNION
(SELECT
	population.yr_id
	,'zip' as geotype
	,mgra_denormalize.tract as geozone
	,hh.hh AS households
	,hh.unoccupied as unoccupiable
	,hh.du as units
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'zip' as geotype,mgra_denormalize.tract as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id = ds_id
			GROUP BY yr_id, mgra_denormalize.tract
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.tract
WHERE datasource_id = ds_id
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra_denormalize.tract, hh.hh, hh.unoccupied, hh.du)
ORDER BY population.yr_id, geotype, geozone, hh.hh
