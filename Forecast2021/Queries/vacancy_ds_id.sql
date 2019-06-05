
USE demographic_warehouse;

SELECT
	housing.yr_id
	,housing.datasource_id
	,mgra.geotype
	,mgra.geozone
	,SUM(housing.unoccupiable) as unoccupiable
	,SUM(housing.occupied) as hh
	,SUM(housing.units) as units
	,ROUND(CASE WHEN SUM(housing.occupied) = 0 THEN 0 
				ELSE 1.0 - SUM(housing.occupied)  / 
				CASE WHEN (SUM(housing.units))=0 THEN 0 
					ELSE CAST(SUM(housing.units) as float) END END, 4) as vacancy_rate
FROM fact.housing
	INNER JOIN dim.mgra
	ON mgra.mgra_id = housing.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
WHERE housing.datasource_id IN (ds_id) 
GROUP BY 
	housing.yr_id
	,mgra.geotype
	,mgra.geozone
	,housing.datasource_id
order by geotype,geozone,yr_id,datasource_id

-- total rows
--864 rows
--SELECT (87 + 1 + 1 + 19) * 8	
--note 87 cpas + 1 not in a cpa + 1 region + 19 (18 jurisdictions + unincorporated) x 8 increments
