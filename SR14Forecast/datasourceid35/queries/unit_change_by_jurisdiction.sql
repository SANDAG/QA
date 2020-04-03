USE demographic_warehouse;

DECLARE @ds_id int
SET @ds_id = 34;

With dw2050 AS (
SELECT datasource_id,geozone,sum([units]) as units2050,geotype
  FROM [demographic_warehouse].[fact].[housing]
   INNER JOIN demographic_warehouse.dim.mgra on mgra.mgra_id = housing.mgra_id
  WHERE datasource_id = @ds_id and geotype = 'jurisdiction'  and yr_id = 2050
  GROUP by yr_id,datasource_id,geozone,geotype),
dw2016 AS (
  SELECT geozone,sum([units]) as units2016,geotype
  FROM [demographic_warehouse].[fact].[housing]
  INNER JOIN demographic_warehouse.dim.mgra on mgra.mgra_id = housing.mgra_id
  WHERE datasource_id = @ds_id  and geotype = 'jurisdiction' and yr_id = 2016
  GROUP by yr_id,geozone,geotype,datasource_id)
SELECT dw2050.datasource_id,dw2050.geotype,dw2050.geozone,units2016,units2050,
       units2050-units2016 as unit_change_dw
  FROM dw2050
  JOIN dw2016
  ON dw2016.geozone = dw2050.geozone AND dw2016.geotype = dw2050.geotype
  ORDER BY geozone



  