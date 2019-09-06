DROP TABLE IF EXISTS #uspa;
SELECT *
INTO #uspa
FROM [urbansim].[urbansim].[parcel]
WHERE parcel_id IN 
    (SELECT parcel_id FROM [urbansim].[urbansim].[urbansim_lite_output]
    WHERE run_id = 444 and capacity_type = 'adu')
;
DROP TABLE IF EXISTS #selection4;
SELECT
 uspa.[parcel_id]
 ,uspa.[shape]
 ,uspa.[parcel_acres]
 ,uspa.[mgra_id]
 ,uspa.[jurisdiction_id]
INTO #selection4
FROM #uspa AS uspa
JOIN [ws].[dbo].[CWA_DEMAND_FORECAST_2019] AS cwa
 ON cwa.[Shape].STIntersects(uspa.[centroid]) = 1
ORDER BY parcel_acres
;


select * from #selection4