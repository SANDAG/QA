USE demographic_warehouse;

DECLARE @ds_id smallint = 35; 

SELECT [yr_id],sum([population]) as pop
  FROM [demographic_warehouse].[fact].[population]
  where datasource_id =  @ds_id
  GROUP BY yr_id
  ORDER BY yr_id;

SELECT [yr_id],sum([jobs]) as jobs
  FROM [demographic_warehouse].[fact].[jobs]
  where datasource_id =  @ds_id
  GROUP BY yr_id
  ORDER BY yr_id;

EXECUTE dbo.compute_median_age_all_zones  @ds_id, 'region';

SELECT population.yr_id, ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ( 'region')
		INNER JOIN
		(
			SELECT yr_id, mgra.geotype, mgra.geozone, SUM(occupied) as hh,sum(units) as units
			FROM fact.housing
				INNER JOIN dim.mgra
				ON mgra.mgra_id = housing.mgra_id
				AND mgra.geotype IN ('region')
			WHERe housing.datasource_id = @ds_id
			GROUP BY yr_id, mgra.geotype, mgra.geozone
		) hh
		ON hh.yr_id = population.yr_id
		AND hh.geozone = mgra.geozone
		AND hh.geotype = mgra.geotype
WHERE datasource_id =@ds_id
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh,population.datasource_id,hh.units
ORDER BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh
