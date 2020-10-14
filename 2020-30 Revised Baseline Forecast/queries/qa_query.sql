/****** Script for SelectTopNRows command from SSMS  ******/
SELECT * FROM (
SELECT 
	b.mgra as urbansim_mgra
	,a.mgra as forecast_mgra
	,b.units_2018 as urbansim_2018
	,b.units_2020 as urbansim_2020
	,COALESCE(a.units_added_2020,0) as forecast_2020
	,CASE WHEN b.units_2020 = a.units_added_2020 THEN 'pass' ELSE 'fail' END as check_2020
	,b.units_2025 as urbansim_2025
	,COALESCE(a.units_added_2025,0) as forecast_2025
	,CASE WHEN b.units_2025 = a.units_added_2025 THEN 'pass' ELSE 'fail' END as check_2025
	,b.units_2030 as urbansim_2030
	,COALESCE(a.units_added_2030,0) as forecast_2030
	,CASE WHEN b.units_2030 = a.units_added_2030 THEN 'pass' ELSE 'fail' END as check_2030
	,b.units_2035 as urbansim_2035
	,COALESCE(a.units_added_2035,0) as forecast_2035
	,CASE WHEN b.units_2035 = a.units_added_2035 THEN 'pass' ELSE 'fail' END as check_2035
	,b.units_2040 as urbansim_2040
	,COALESCE(a.units_added_2040,0) as forecast_2040
	,CASE WHEN b.units_2040 = a.units_added_2040 THEN 'pass' ELSE 'fail' END as check_2040
	,b.units_2045 as urbansim_2045
	,COALESCE(a.units_added_2045,0) as forecast_2045
	,CASE WHEN b.units_2045 = a.units_added_2045 THEN 'pass' ELSE 'fail' END as check_2045
	,b.units_2050 as urbansim_2050
	,COALESCE(a.units_added_2050,0) as forecast_2050
	,CASE WHEN b.units_2050 = a.units_added_2050 THEN 'pass' ELSE 'fail' END as check_2050
FROM (
SELECT 
	[mgra]
	,(sum(CASE WHEN [yr_id] = 2020 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2018 THEN units ELSE 0 END)) as units_added_2020
	,(sum(CASE WHEN [yr_id] = 2025 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2020 THEN units ELSE 0 END)) as units_added_2025
	,(sum(CASE WHEN [yr_id] = 2030 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2025 THEN units ELSE 0 END)) as units_added_2030
	,(sum(CASE WHEN [yr_id] = 2035 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2030 THEN units ELSE 0 END)) as units_added_2035
	,(sum(CASE WHEN [yr_id] = 2040 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2035 THEN units ELSE 0 END)) as units_added_2040
	,(sum(CASE WHEN [yr_id] = 2045 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2040 THEN units ELSE 0 END)) as units_added_2045
	,(sum(CASE WHEN [yr_id] = 2050 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2045 THEN units ELSE 0 END)) as units_added_2050
FROM [demographic_warehouse].[fact].[housing] h
inner join demographic_warehouse.dim.mgra_denormalize m
	on m.mgra_id = h.mgra_id
where datasource_id = 36
group by m.mgra
having (sum(CASE WHEN [yr_id] = 2050 THEN units ELSE 0 END) - sum(CASE WHEN [yr_id] = 2018 THEN units ELSE 0 END)) > 0
) a
RIGHT JOIN (
SELECT 
	p.mgra
	,sum(CASE WHEN year_simulation IN (2018) THEN unit_change ELSE 0 END) as units_2018
	,sum(CASE WHEN year_simulation IN (2019,2020) THEN unit_change ELSE 0 END) as units_2020
	,sum(CASE WHEN year_simulation IN (2021,2022,2023,2024,2025) THEN unit_change ELSE 0 END) as units_2025
	,sum(CASE WHEN year_simulation IN (2026,2027,2028,2029,2030) THEN unit_change ELSE 0 END) as units_2030
	,sum(CASE WHEN year_simulation IN (2031,2032,2033,2034,2035) THEN unit_change ELSE 0 END) as units_2035
	,sum(CASE WHEN year_simulation IN (2036,2037,2038,2039,2040) THEN unit_change ELSE 0 END) as units_2040
	,sum(CASE WHEN year_simulation IN (2041,2042,2043,2044,2045) THEN unit_change ELSE 0 END) as units_2045
	,sum(CASE WHEN year_simulation IN (2046,2047,2048,2049,2050) THEN unit_change ELSE 0 END) as units_2050
FROM [urbansim].[urbansim].[urbansim_lite_output] o
inner join urbansim.urbansim.scs_parcel p
	on o.parcel_id = p.parcel_id
where run_id = 477
group by p.mgra
) b
ON a.mgra = b.mgra
) c
where (urbansim_mgra <> forecast_mgra)
	OR check_2020 = 'fail' 
	OR check_2025 = 'fail'
	OR check_2030 = 'fail'
	OR check_2035 = 'fail'
	OR check_2040 = 'fail'
	OR check_2045 = 'fail'
	OR check_2050 = 'fail'
order by urbansim_mgra