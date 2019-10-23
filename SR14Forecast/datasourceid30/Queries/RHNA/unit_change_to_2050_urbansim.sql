
-- unit change urbansim EXCLUDING year 2018

SELECT  p.jurisdiction_id,name,sum([unit_change]) as unit_change
FROM [urbansim].[urbansim].[urbansim_lite_output] o
JOIN [urbansim].[urbansim].[parcel] p on p.parcel_id = o.parcel_id
JOIN urbansim.[ref].[jurisdiction] r ON r.jurisdiction_id = p.jurisdiction_id
WHERE run_id = 444 and year_simulation != 2018
GROUP BY p.jurisdiction_id, name
ORDER BY name