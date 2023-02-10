USE demographic_warehouse;

WITH units_2018  AS (
SELECT mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction', 'region')
WHERE housing.datasource_id = 30 and yr_id = 2018
GROUP BY yr_id, mgra.geotype, mgra.geozone
),
units_2016  AS (
SELECT mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction', 'region')
WHERE housing.datasource_id = 30 and yr_id = 2016
GROUP BY yr_id, mgra.geotype, mgra.geozone
),
units_2050  AS
(SELECT  mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction', 'region')
WHERE housing.datasource_id = 30 and yr_id = 2050
GROUP BY yr_id, mgra.geotype, mgra.geozone
),
urbansim_units_chg AS 
(SELECT  name as geozone,sum([unit_change]) as unit_change_urbansim,'jurisdiction' as geotype
FROM [urbansim].[urbansim].[urbansim_lite_output] o
JOIN urbansim.urbansim.parcel p on p.parcel_id = o.parcel_id
JOIN urbansim.[ref].[jurisdiction]  j ON j.jurisdiction_id = p.cap_jurisdiction_id
WHERE run_id = 444
GROUP BY cap_jurisdiction_id,name)
SELECT u18.geozone,u18.geotype,u16.geotype,u50.geotype,urb.geotype,u16.units as units_2016,u18.units as units_2018,u18.units - u16.units as unit_growth_2016_to_2018,
u50.units as units_2050, u50.units - u18.units as unit_growth_2018_to_2050,unit_change_urbansim,
u50.units - u16.units as unit_growth_2016_to_2050
FROM units_2018 u18
FULL OUTER JOIN units_2050 u50 on u18.geozone= u50.geozone AND u18.geotype = u50.geotype
FULL OUTER JOIN units_2016 u16 on u18.geozone=u16.geozone AND u18.geotype = u16.geotype
FULL OUTER JOIN urbansim_units_chg urb on u18.geozone = urb.geozone  AND u18.geotype = urb.geotype
ORDER BY u18.geotype,u18.geozone;


SELECT  name as geozone,sum([unit_change]) as unit_change_urbansim,'jurisdiction' as geotype
FROM [urbansim].[urbansim].[urbansim_lite_output] o
JOIN urbansim.urbansim.parcel p on p.parcel_id = o.parcel_id
JOIN urbansim.[ref].[jurisdiction]  j ON j.jurisdiction_id = p.cap_jurisdiction_id
WHERE run_id = 444
GROUP BY cap_jurisdiction_id,name

SELECT  sum([unit_change]) as unit_change_urbansim,'region' as geotype,'San Diego' as geozone
FROM [urbansim].[urbansim].[urbansim_lite_output] o
JOIN urbansim.urbansim.parcel p on p.parcel_id = o.parcel_id
JOIN urbansim.[ref].[jurisdiction]  j ON j.jurisdiction_id = p.cap_jurisdiction_id
WHERE run_id = 444




