/*
For informational purposes only.
Methodology:	Since  RHNA Cycle is April 2021 to April 2029 and demographic warehouse only has increments, 
use urbansim database (note: urbansim may not be exactly the same as forecast in demographic warehouse).				
use urbansim run 444 for ds id 30 and run 468 for ds id 34
RHNA cycle is April 2021 to April 2029: use 75% of year 2021 (April - Dec) and 25% of year 2029 (Jan-Mar) for percent 
of units to include for that year in urbansim run
(assumes uniform distribution over the year)					
*/			


DECLARE @run_id int
SET @run_id = 468;
				
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
				
								