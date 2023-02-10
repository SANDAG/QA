
-- The planning period for the RHNA Cycle is April 2021 to April 2029.

-- Assuming a uniform distribution of units across the year in urbansim,
-- use 75% of unit change in 2021 and 25% of unit change in 2029

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
WHERE run_id = 444 and year_simulation BETWEEN 2021 AND 2029
GROUP BY p.jurisdiction_id, name,year_simulation
)
SELECT *, unit_change*factor as adjusted_unit_change,CAST(round(unit_change*factor,0) as integer) as round_adjusted_unit_change
INTO #Forecast_2021_to_2029
FROM  adjust_unit_change

--SELECT * from #Forecast_2021_to_2029 
--ORDER BY jurisdiction_id,year_simulation


SELECT jurisdiction_id,name,sum(round_adjusted_unit_change) as unit_change_urbansim_ds30
FROM #Forecast_2021_to_2029 
GROUP BY jurisdiction_id,name
ORDER BY name

