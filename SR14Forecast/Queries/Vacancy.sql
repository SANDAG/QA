Use demographic_warehouse


SELECT
	housing.yr_id
	,mgra.geotype
	,mgra.geozone
	,housing.structure_type_id
	,structure_type.short_name
	,SUM(housing.unoccupiable) as unoccupiable
	,SUM(housing.occupied) as hh
	,SUM(housing.units) as units
	,ROUND(CASE WHEN SUM(housing.occupied) = 0 THEN 0 
				ELSE 1.0 - SUM(housing.occupied) END / 
				CASE WHEN (SUM(housing.units - housing.unoccupiable))=0 THEN 1 
					ELSE CAST(SUM(housing.units - housing.unoccupiable) as float) END, 2) as vac
FROM fact.housing
	INNER JOIN dim.mgra
	ON mgra.mgra_id = housing.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN dim.structure_type
		ON structure_type.structure_type_id = housing.structure_type_id
WHERE housing.datasource_id = 18
GROUP BY 
housing.yr_id
	,mgra.geotype
	,mgra.geozone
	,housing.structure_type_id
	,structure_type.short_name
ORDER BY 1,2,3,4


