USE demographic_warehouse;

DECLARE @ds_id int
SET @ds_id = 34;

WITH units_2016  AS (
SELECT mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction')
WHERE housing.datasource_id = @ds_id and yr_id = 2016
GROUP BY yr_id, mgra.geotype, mgra.geozone
),
units_2035  AS (
SELECT mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction')
WHERE housing.datasource_id = 34 and yr_id = 2035
GROUP BY yr_id, mgra.geotype, mgra.geozone
),
units_2050  AS
(SELECT  mgra.geotype,mgra.geozone,sum(units) as units
FROM fact.housing
INNER JOIN dim.mgra
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction')
WHERE housing.datasource_id = 34 and yr_id = 2050
GROUP BY yr_id, mgra.geotype, mgra.geozone
)
SELECT u16.geozone,u16.geotype,u16.units as units_2016,
u50.units as units_2050,
u50.units - u16.units as unit_growth_2016_to_2050,u35.units - u16.units as unit_growth_2016_to_2035,u50.units - u35.units as unit_growth_2035_to_2050
FROM units_2016 u16
FULL OUTER JOIN units_2050 u50 on u16.geozone= u50.geozone AND u16.geotype = u50.geotype
FULL OUTER JOIN units_2035 u35 on u16.geozone=u35.geozone AND u16.geotype = u35.geotype
ORDER BY u16.geotype,u16.geozone;






