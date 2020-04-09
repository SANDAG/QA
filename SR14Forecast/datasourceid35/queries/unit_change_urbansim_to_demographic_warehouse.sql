USE demographic_warehouse;

DECLARE @run_id int
SET @run_id = 474;

DECLARE @ds_id int
SET @ds_id = 35;

WITH units_2016  AS (
SELECT mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction', 'region')
WHERE housing.datasource_id = @ds_id and yr_id = 2016
GROUP BY yr_id, mgra.geotype, mgra.geozone
),
units_2050  AS
(SELECT  mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction', 'region')
WHERE housing.datasource_id = @ds_id and yr_id = 2050
GROUP BY yr_id, mgra.geotype, mgra.geozone
),

urbansim_units_chg AS 
(SELECT  name as geozone,sum([unit_change]) as unit_change_urbansim,'jurisdiction' as geotype
FROM [urbansim].[urbansim].[urbansim_lite_output] o
JOIN urbansim.urbansim.parcel p on p.parcel_id = o.parcel_id
JOIN urbansim.[ref].[jurisdiction]  j ON j.jurisdiction_id = p.cap_jurisdiction_id
WHERE run_id = @run_id
GROUP BY cap_jurisdiction_id,name
UNION
SELECT  'San Diego' as geozone,sum([unit_change]) as unit_change_urbansim, 'region' AS geotype
FROM [urbansim].[urbansim].[urbansim_lite_output] o
WHERE run_id = @run_id)
SELECT u16.geozone, 
--u16.units as units_2016,
--u50.units as units_2050,
unit_change_urbansim,
u50.units - u16.units as unit_change_demographic_warehouse,
(u50.units - u16.units) -  unit_change_urbansim as dw_minus_urbansim,
u16.geotype
FROM units_2016 u16
FULL OUTER JOIN units_2050 u50 on u16.geozone= u50.geozone AND u16.geotype = u50.geotype
FULL OUTER JOIN urbansim_units_chg urb on u16.geozone = urb.geozone  AND u16.geotype = urb.geotype
ORDER BY u16.geotype,u16.geozone;



