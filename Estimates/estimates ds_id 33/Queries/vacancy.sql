--Use demographic_warehouse


(SELECT
	housing.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
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
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = housing.mgra_id
		INNER JOIN dim.structure_type
		ON structure_type.structure_type_id = housing.structure_type_id
WHERE housing.datasource_id = ds_id
GROUP BY 
housing.yr_id
	,mgra_denormalize.jurisdiction
	,housing.structure_type_id
	,structure_type.short_name)
UNION
(SELECT
	housing.yr_id
	,'region' as geotype
	,mgra_denormalize.region as geozone
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
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = housing.mgra_id
		INNER JOIN dim.structure_type
		ON structure_type.structure_type_id = housing.structure_type_id
WHERE housing.datasource_id = ds_id
GROUP BY 
housing.yr_id
	,mgra_denormalize.region
	,housing.structure_type_id
	,structure_type.short_name)
UNION
(SELECT
	housing.yr_id
	,'cpa' as geotype
	,mgra_denormalize.cpa as geozone
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
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = housing.mgra_id
		INNER JOIN dim.structure_type
		ON structure_type.structure_type_id = housing.structure_type_id
WHERE housing.datasource_id = ds_id
GROUP BY 
housing.yr_id
	,mgra_denormalize.cpa
	,housing.structure_type_id
	,structure_type.short_name)
UNION
(SELECT
	housing.yr_id
	,'tract' as geotype
	,mgra_denormalize.tract as geozone
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
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = housing.mgra_id
		INNER JOIN dim.structure_type
		ON structure_type.structure_type_id = housing.structure_type_id
WHERE housing.datasource_id = ds_id
GROUP BY 
housing.yr_id
	,mgra_denormalize.tract
	,housing.structure_type_id
	,structure_type.short_name)
ORDER BY yr_id, geotype, geozone