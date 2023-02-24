use isam
GO

--hh x size
SELECT yr as yr
	,mgra.geotype
	,mgra.geozone
	,persons
	,COUNT(*) as hh
FROM ws.abm_population.households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
WHERE yr = 2017
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,persons
UNION ALL
SELECT yr - 1 as yr
	,mgra.geotype
	,mgra.geozone
	,persons
	,COUNT(*) as hh
FROM xpef03.syn_households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = syn_households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,persons
ORDER BY yr
	,mgra.geotype
	,mgra.geozone
	,persons


--income cat
SELECT yr as yr
	,hinccat1
	,hh_income_cat.hh_income_cat_desc
	,COUNT(*) as hh
FROM ws.abm_population.households
	INNER JOIN abm_13_2_3.ref.hh_income_cat
	ON hh_income_cat.hh_income_cat_id = households.hinccat1
WHERE yr = 2017
GROUP BY yr, hinccat1,hh_income_cat.hh_income_cat_desc
	UNION ALL
SELECT yr - 1 as yr
	,hinccat1
	,hh_income_cat.hh_income_cat_desc
	,COUNT(*) as hh
FROM xpef03.syn_households
	INNER JOIN abm_13_2_3.ref.hh_income_cat
	ON hh_income_cat.hh_income_cat_id = syn_households.hinccat1
GROUP BY yr, hinccat1, hh_income_cat.hh_income_cat_desc
ORDER BY yr, hinccat1


--unittype
SELECT yr as yr
	,mgra.geotype
	,mgra.geozone
	,unittype
	,unit_type.unit_type_desc
	,COUNT(*) as hh
FROM ws.abm_population.households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN abm_13_2_3.ref.unit_type
		ON unit_type.unit_type_id = households.unittype
WHERE yr = 2017
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,unittype
	,unit_type.unit_type_desc
UNION ALL
SELECT yr - 1 as yr
	,mgra.geotype
	,mgra.geozone
	,unittype
	,unit_type.unit_type_desc
	,COUNT(*) as hh
FROM xpef03.syn_households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = syn_households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN abm_13_2_3.ref.unit_type
		ON unit_type.unit_type_id = syn_households.unittype
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,unittype
	,unit_type.unit_type_desc
ORDER BY yr
	,mgra.geotype
	,mgra.geozone
	,unittype


--hht (refer to PUMS data dictionary for codes)
SELECT yr as yr
	,mgra.geotype
	,mgra.geozone
	,hht
	,COUNT(*) as hh
FROM ws.abm_population.households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')		
WHERE yr = 2017
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,hht
UNION ALL
SELECT yr - 1 as yr
	,mgra.geotype
	,mgra.geozone
	,hht
	,COUNT(*) as hh
FROM xpef03.syn_households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = syn_households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,hht
ORDER BY yr
	,mgra.geotype
	,mgra.geozone
	,hht

--bldgsz (refer to PUMS data dictionary for codes)
SELECT yr as yr
	,mgra.geotype
	,mgra.geozone
	,bldgsz
	,COUNT(*) as hh
FROM ws.abm_population.households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')		
WHERE yr = 2017
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,bldgsz
UNION ALL
SELECT yr - 1 as yr
	,mgra.geotype
	,mgra.geozone
	,bldgsz
	,COUNT(*) as hh
FROM xpef03.syn_households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = syn_households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,bldgsz
ORDER BY yr
	,mgra.geotype
	,mgra.geozone
	,bldgsz


--workers
SELECT yr as yr
	,mgra.geotype
	,mgra.geozone
	,hworkers
	,COUNT(*) as hh
FROM ws.abm_population.households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')		
WHERE yr = 2017
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,hworkers
UNION ALL
SELECT yr - 1 as yr
	,mgra.geotype
	,mgra.geozone
	,hworkers
	,COUNT(*) as hh
FROM xpef03.syn_households
	INNER JOIN demographic_warehouse.dim.mgra
	ON mgra.mgra = syn_households.MGRA
	AND RIGHT(mgra.mgra_id, 2) = '00'
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
GROUP BY yr
	,mgra.geotype
	,mgra.geozone
	,hworkers
ORDER BY yr
	,mgra.geotype
	,mgra.geozone
	,hworkers


/*********************************************************************
 *  Person level tabulations
 *
 *********************************************************************/
--ptype
SELECT persons.yr as yr
	,mgra.geotype
	,mgra.geozone
	,persons.ptype
	,ptype.ptype_desc
	,COUNT(*) as persons
FROM ws.abm_population.persons
	INNER JOIN ws.abm_population.households
	ON households.household_serial_no = persons.household_serial_no
		INNER JOIN demographic_warehouse.dim.mgra
		ON mgra.mgra = households.MGRA
		AND RIGHT(mgra.mgra_id, 2) = '00'
		AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')		
			INNER JOIN abm_13_2_3.ref.ptype
			ON ptype.ptype_id = persons.ptype
WHERE persons.yr = 2017
AND households.yr = 2017
GROUP BY persons.yr
	,mgra.geotype
	,mgra.geozone
	,persons.ptype
	,ptype.ptype_desc
UNION ALL
SELECT syn_persons.yr - 1 as yr
	,mgra.geotype
	,mgra.geozone
	,syn_persons.ptype
	,COUNT(*) as hh
FROM xpef03.syn_persons
	INNER JOIN xpef03.syn_households
	ON syn_households.household_serial_no = syn_persons.household_serial_no
		INNER JOIN demographic_warehouse.dim.mgra
		ON mgra.mgra = syn_households.MGRA
		AND RIGHT(mgra.mgra_id, 2) = '00'
		AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
			INNER JOIN abm_13_2_3.ref.ptype
			ON ptype.ptype_id = syn_persons.ptype
GROUP BY syn_persons.yr
	,mgra.geotype
	,mgra.geozone
	,syn_persons.ptype
	,ptype.ptype_desc
ORDER BY yr
	,geotype
	,geozone
	,ptype