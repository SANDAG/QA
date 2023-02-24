USE urbansim;

DECLARE @run_id smallint = 468; -- corresponds to datasource id 34


-- ADUs in forecast
SELECT  count(o.parcel_id) as forecast_adus			
FROM [urbansim].[urbansim].[urbansim_lite_output] o			
WHERE run_id = @run_id and capacity_type = 'adu';

-- total possible ADUs
SELECT CAST(round(count(p.parcel_id) *.05,0) as integer) 		
FROM [urbansim].[urbansim].[parcel] p			
WHERE 43560 * parcel_acres >= 5000 and du_2018 = 1 and development_type_id_2018=19;

-- 7 parcels with more than one unit in 2018
SELECT o.parcel_id, development_type_id_2018,du_2015,du_2018,year_simulation,
capacity_type, run_id, unit_change
FROM  [urbansim].[urbansim].[urbansim_lite_output] o
JOIN urbansim.urbansim.parcel p on p.parcel_id=o.parcel_id
JOIN urbansim.ref.jurisdiction r on r.jurisdiction_id = p.jurisdiction_id
WHERE  run_id = @run_id and capacity_type = 'adu' and du_2018 > 1
ORDER BY p.jurisdiction_id;

--forecast adus by city
WITH ADUS as (		
SELECT  j.jurisdiction_id, count(o.parcel_id) as parcels_w_adus		
FROM urbansim.[ref].[jurisdiction] j 	
JOIN [urbansim].[urbansim].[parcel] p on p.jurisdiction_id = j.jurisdiction_id	
LEFT JOIN [urbansim].[urbansim].[urbansim_lite_output] o 
ON o.parcel_id = p.parcel_id and capacity_type = 'adu' and run_id = @run_id	
GROUP BY j.jurisdiction_id, name)	
SELECT p.jurisdiction_id, j.name		
,COUNT(p.parcel_id) as available_parcels_for_adus, parcels_w_adus
,ROUND(CAST(1.0 * parcels_w_adus/count(p.parcel_id) as float),4) as 
proportion_of_available
FROM [urbansim].[urbansim].[parcel] p		
LEFT JOIN ADUS on ADUS.jurisdiction_id = p.jurisdiction_id	
JOIN urbansim.[ref].[jurisdiction] j on p.jurisdiction_id = j.jurisdiction_id	
WHERE 43560 * parcel_acres >= 5000 and du_2018 = 1 and development_type_id_2018=19	
GROUP BY p.jurisdiction_id,parcels_w_adus,name	
ORDER BY p.jurisdiction_id;	

-- ADUs outside of SDCWA
DROP TABLE IF EXISTS #uspa;
SELECT * INTO #uspa
FROM [urbansim].[urbansim].[parcel]
WHERE parcel_id IN (SELECT parcel_id 
FROM [urbansim].[urbansim].[urbansim_lite_output]
WHERE run_id = @run_id and capacity_type = 'adu');
DROP TABLE IF EXISTS #selection4;
SELECT uspa.[parcel_id],uspa.[shape],uspa.[parcel_acres],
uspa.[mgra_id],uspa.[jurisdiction_id],uspa.site_id
INTO #selection4
FROM #uspa AS uspa
JOIN [ws].[dbo].[CWA_DEMAND_FORECAST_2019] AS cwa 
ON cwa.[Shape].STIntersects(uspa.[centroid]) = 1
ORDER BY parcel_acres;
SELECT *
FROM urbansim.[urbansim].parcel p
WHERE p.parcel_id IN (select parcel_id 
from  [urbansim].[urbansim].[urbansim_lite_output] 
where  run_id = @run_id and capacity_type = 'adu') AND
p.parcel_id NOT IN (select parcel_id from #selection4)


-- ADUs prior to 2035
select r.name,p.jurisdiction_id,  count(*) as [ADUs before 2035]
from  [urbansim].[urbansim].[urbansim_lite_output] o
join urbansim.parcel p on p.parcel_id=o.parcel_id
join ref.jurisdiction r on r.jurisdiction_id = p.jurisdiction_id
where  run_id = @run_id and capacity_type = 'adu' and year_simulation <= 2035
GROUP by p.jurisdiction_id,r.name
ORDER BY p.jurisdiction_id
