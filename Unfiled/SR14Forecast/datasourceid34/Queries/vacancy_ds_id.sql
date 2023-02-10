-- Forecast of unoccupiable units for region

DECLARE @ds_id int
SET @ds_id = 30

USE demographic_warehouse;

SELECT
	housing.yr_id
	,housing.datasource_id
	,mgra.geotype 
	,mgra.geozone
	,SUM(housing.unoccupiable) as unoccupiable
	,SUM(housing.occupied) as hh
	,SUM(housing.units) as units
	,CASE
		  WHEN (SUM(housing.units))=0 THEN 0 
		  ELSE round(1 - SUM(housing.occupied)/CAST(SUM(housing.units) as float),4) 
	END as vacancy_rate
	,CASE
		  WHEN (SUM(housing.units))=0 THEN 0 
		  ELSE round(1 - SUM(housing.occupied)/CAST((SUM(housing.units) - 
		  SUM(housing.unoccupiable))as float),4) 
	END as vacancy_rate_effective
FROM fact.housing
	INNER JOIN dim.mgra
	ON mgra.mgra_id = housing.mgra_id
	--AND mgra.geotype IN ('region')
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
--WHERE housing.datasource_id IN (ds_id) AND housing.yr_id NOT IN (2023,2026,2029,2032)
WHERE housing.datasource_id IN (ds_id) 
GROUP BY 
	housing.yr_id
	,mgra.geotype
	,mgra.geozone
	,housing.datasource_id
ORDER BY geotype,geozone,yr_id,datasource_id

-- total rows
--972 rows
--SELECT (87 + 1 + 1 + 19) * 9	
--note 87 cpas + 1 not in a cpa + 1 region + 19 (18 jurisdictions + unincorporated) x 9 increments
