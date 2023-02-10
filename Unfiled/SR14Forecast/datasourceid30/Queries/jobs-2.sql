USE demographic_warehouse;

SELECT
	jobs.datasource_id
	,jobs.yr_id
	,mgra.geotype
	,mgra.geozone
	,jobs.employment_type_id
	,SUM(jobs.jobs) as jobs
FROM fact.jobs
	INNER JOIN dim.mgra
	ON mgra.mgra_id = jobs.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN dim.employment_type
		ON employment_type.employment_type_id = jobs.employment_type_id
WHERE jobs.datasource_id = 30
GROUP BY
	jobs.datasource_id
	,jobs.yr_id
	,mgra.geotype
	,mgra.geozone
	,jobs.employment_type_id
Order By
	jobs.datasource_id
	,jobs.yr_id
	,mgra.geotype
	,mgra.geozone
	,jobs.employment_type_id
