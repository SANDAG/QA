/*
For informational purposes only.
Methodology:	Since  RHNA Cycle is April 2021 to April 2029 and demographic warehouse only has increments, 
use urbansim database (note: urbansim may not be exactly the same as forecast in demographic warehouse).				
use urbansim run 444 for ds id 30 and run 474 for ds id 35
RHNA cycle is April 2021 to April 2029: use 75% of year 2021 (April - Dec) and 25% of year 2029 (Jan-Mar) for percent 
of units to include for that year in urbansim run
(assumes uniform distribution over the year)					
*/			


DECLARE @run_id int
SET @run_id = 474;
				
DROP TABLE IF EXISTS #Forecast_2021_to_2029;				
				
WITH adjust_unit_change as (				
SELECT  p.jurisdiction_id,name,sum([unit_change]) as unit_change,[year_simulation],				
		CASE   		
			WHEN year_simulation=2021 THEN .75	
			WHEN year_simulation = 2029 THEN .25	
			ELSE 1  	
		END  as factor		
FROM [urbansim].[urbansim].[urbansim_lite_output] o				
JOIN [urbansim].[urbansim].[parcel] p on p.parcel_id = o.parcel_id				
JOIN urbansim.[ref].[jurisdiction] r ON r.jurisdiction_id = p.jurisdiction_id				
WHERE run_id = @run_id and year_simulation BETWEEN 2021 AND 2029				
GROUP BY p.jurisdiction_id, name,year_simulation				
)				
SELECT *, unit_change*factor as adjusted_unit_change,
       CAST(round(unit_change*factor,0) as integer) as round_adjusted_unit_change				
INTO #Forecast_2021_to_2029				
FROM  adjust_unit_change				
				
--SELECT * from #Forecast_2021_to_2029 				
--ORDER BY jurisdiction_id,year_simulation

SELECT jurisdiction_id,name,
       sum(round_adjusted_unit_change) as unit_change_RHNA_from_urbansim			
FROM #Forecast_2021_to_2029 				
GROUP BY jurisdiction_id,name				
ORDER BY name;	


USE demographic_warehouse;				
	
DECLARE @ds_id int
SET @ds_id = 35;	
	
				
WITH units_2016  AS (				
SELECT mgra.geotype,mgra.geozone,sum(units) as units				
FROM fact.housing				
INNER JOIN dim.mgra				
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction' )				
WHERE housing.datasource_id = @ds_id and yr_id = 2016				
GROUP BY yr_id, mgra.geotype, mgra.geozone				
),				
units_2050  AS				
(SELECT  mgra.geotype,mgra.geozone,sum(units) as units				
FROM fact.housing				
INNER JOIN dim.mgra				
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction')				
WHERE housing.datasource_id = @ds_id and yr_id = 2050				
GROUP BY yr_id, mgra.geotype, mgra.geozone				
),	
units_2020  AS				
(SELECT  mgra.geotype,mgra.geozone,sum(units) as units				
FROM fact.housing				
INNER JOIN dim.mgra				
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction')				
WHERE housing.datasource_id = @ds_id and yr_id = 2020				
GROUP BY yr_id, mgra.geotype, mgra.geozone				
),				
units_2030  AS				
(SELECT  mgra.geotype,mgra.geozone,sum(units) as units				
FROM fact.housing				
INNER JOIN dim.mgra				
ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction')				
WHERE housing.datasource_id = @ds_id and yr_id = 2030				
GROUP BY yr_id, mgra.geotype, mgra.geozone				
)				
SELECT u16.geozone,u16.geotype,u16.units as units_2016,u50.units as units_2050, 
       u50.units - u16.units as unit_growth_2016_to_2050,
	   u20.units as units_2020,u30.units as units_2030,
	   u30.units - u20.units as unit_growth_2020_to_2030,
	   ROUND((u30.units - u20.units) * 0.8,0) as [unit_growth_2020_to_2030_multiplied_by_0.8]			
FROM units_2016 u16				
JOIN units_2050 u50 on u50.geozone=u16.geozone AND u16.geotype = u50.geotype	
JOIN units_2030 u30 on u30.geozone=u16.geozone AND u16.geotype = u30.geotype
JOIN units_2020 u20 on u20.geozone=u16.geozone AND u16.geotype = u20.geotype		
ORDER BY u16.geozone;			
			
				
								