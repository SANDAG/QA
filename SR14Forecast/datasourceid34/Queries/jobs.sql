USE demographic_warehouse ;

SELECT
	jobs.datasource_id
	,jobs.yr_id
	,mgra.geotype
	,mgra.geozone
	,SUM(jobs.jobs) as jobs
FROM fact.jobs
	INNER JOIN dim.mgra
	ON mgra.mgra_id = jobs.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN dim.employment_type
		ON employment_type.employment_type_id = jobs.employment_type_id
WHERE jobs.datasource_id = ds_id
GROUP BY
	jobs.datasource_id
	,jobs.yr_id
	,mgra.geotype
	,mgra.geozone
