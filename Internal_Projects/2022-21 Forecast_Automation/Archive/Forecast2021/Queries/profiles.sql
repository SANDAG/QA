USE demographic_warehouse


--To get sum values for household Population, Units, people per household
SELECT
	population.yr_id
	,'region' as geotype
	,mgra_denormalize.region as geozone
	,ds_id
	,hh.hh AS households
	,hh.du as units
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'region' as geotype,mgra_denormalize.region as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied, housing.datasource_id as ds_id
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id in (30)
			GROUP BY yr_id, mgra_denormalize.region, housing.datasource_id
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.region
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE datasource_id in (30)
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra_denormalize.region, hh.hh, hh.unoccupied, hh.du, population.housing_type_id, ds_id

--To get value for 2050 Jobs

SELECT
	jobs.yr_id
	,'region' as geotype
	,mgra_denormalize.region as geozone
	,ds_id
	,SUM(jobs) as jobs
FROM fact.jobs
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = jobs.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'region' as geotype,mgra_denormalize.region as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied, housing.datasource_id as ds_id
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id in (30)
			GROUP BY yr_id, mgra_denormalize.region, housing.datasource_id
		) hh
		ON hh.yr_id = jobs.yr_id and hh.geozone = mgra_denormalize.region
WHERE datasource_id in (30)
GROUP BY jobs.yr_id, mgra_denormalize.region, hh.hh, hh.unoccupied, hh.du, ds_id

--To get a profile table of Profiles-Pop (Note, percentage change are calculated in excel)
SELECT
	population.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
	,ds_id
	,SUM(population) as hhp
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'jurisdiction' as geotype,mgra_denormalize.jurisdiction as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied, housing.datasource_id as ds_id
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id in (30)
			GROUP BY yr_id, mgra_denormalize.jurisdiction, housing.datasource_id
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.jurisdiction
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE datasource_id in (30)
AND population.housing_type_id = 1
AND population.yr_id in (2016,2025,2035,2050)
GROUP BY population.yr_id, mgra_denormalize.jurisdiction, hh.hh, hh.unoccupied, hh.du, population.housing_type_id, ds_id

--To get a profile table of Profiles-Housing (Note, percentage change are calculated in excel)
SELECT
	population.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
	,ds_id
	,hh.du as units
FROM fact.population
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = population.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'jurisdiction' as geotype,mgra_denormalize.jurisdiction as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied, housing.datasource_id as ds_id
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id in (30)
			GROUP BY yr_id, mgra_denormalize.jurisdiction, housing.datasource_id
		) hh
		ON hh.yr_id = population.yr_id and hh.geozone = mgra_denormalize.jurisdiction
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE datasource_id in (30)
AND population.housing_type_id = 1
AND population.yr_id in (2016,2025,2035,2050)
GROUP BY population.yr_id, mgra_denormalize.jurisdiction, hh.hh, hh.unoccupied, hh.du, population.housing_type_id, ds_id


--To get a profile table of Profiles-Jobs (Note, percentage change are calculated in excel)
SELECT
	jobs.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
	,ds_id
	,SUM(jobs) as jobs
FROM fact.jobs
		 INNER JOIN dim.mgra_denormalize
         ON mgra_denormalize.mgra_id = jobs.mgra_id	
		INNER JOIN
		(
			SELECT yr_id, 'jurisdiction' as geotype,mgra_denormalize.jurisdiction as geozone, SUM(occupied) as hh,
					SUM(units) as du, SUM(housing.unoccupiable) as unoccupied, housing.datasource_id as ds_id
			FROM fact.housing
					 INNER JOIN dim.mgra_denormalize
					ON mgra_denormalize.mgra_id = housing.mgra_id
			WHERE housing.datasource_id in (30)
			GROUP BY yr_id, mgra_denormalize.jurisdiction, housing.datasource_id
		) hh
		ON hh.yr_id = jobs.yr_id and hh.geozone = mgra_denormalize.jurisdiction
WHERE datasource_id in (30)
AND jobs.yr_id in (2016,2025,2035,2050)
GROUP BY jobs.yr_id, mgra_denormalize.jurisdiction, hh.hh, hh.unoccupied, hh.du, ds_id
