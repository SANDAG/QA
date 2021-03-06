/****** Script for SelectTopNRows command from SSMS  ******/

--income Categories
SELECT
	syn_households.yr -1 as yr
	,syn_households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,syn_households.hinccat1
	,COUNT(*) as N
FROM [isam].[xpef03].[syn_households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = syn_households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
GROUP BY syn_households.yr
	,syn_households.mgra
	,syn_households.hinccat1
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
UNION ALL
SELECT
	households.yr -1 as yr
	,households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,households.hinccat1
	,COUNT(*) as N
FROM ws.[abm_population].[households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
WHERE households.yr = 2017 and bldgsz <> 9
GROUP BY households.yr
	,households.mgra
	,households.hinccat1
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
ORDER BY
	yr
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,syn_households.MGRA
	,syn_households.hinccat1
	



--Building Size

	SELECT
	syn_households.yr -1 as yr
	,syn_households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,syn_households.bldgsz
	,COUNT(*) as N
FROM [isam].[xpef03].[syn_households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize
	ON mgra_denormalize.mgra = syn_households.MGRA
		AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
GROUP BY syn_households.yr
	,syn_households.mgra
	,syn_households.bldgsz
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
UNION ALL
SELECT
	households.yr -1 as yr
	,households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,households.bldgsz
	,COUNT(*) as N
FROM ws.[abm_population].[households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
WHERE households.yr = 2017 AND household.bldgsz <> 9
GROUP BY households.yr
	,households.mgra
	,households.bldgsz
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
ORDER BY
	yr
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,syn_households.MGRA
	,syn_households.bldgsz
	

--average Persons per HH__NEED TO FIGURE OUT HOW TO PRESENT THE AVERAGE


	SELECT
	syn_households.yr -1 as yr
	,syn_households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,syn_households.persons
	,COUNT(*) as N
FROM [isam].[xpef03].[syn_households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize
	ON mgra_denormalize.mgra = syn_households.MGRA
		AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
GROUP BY syn_households.yr
	,syn_households.mgra
	,syn_households.persons
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
UNION ALL
SELECT
	households.yr -1 as yr
	,households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,households.persons
	,COUNT(*) as N
FROM ws.[abm_population].[households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
WHERE households.yr = 2017 and bldgsz <> 9
GROUP BY households.yr
	,households.mgra
	,households.persons
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
ORDER BY
	yr
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,syn_households.MGRA
	,syn_households.persons	

--hworkers

SELECT
	syn_households.yr -1 as yr
	,syn_households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,syn_households.hworkers
	,COUNT(*) as N
FROM [isam].[xpef03].[syn_households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize
	ON mgra_denormalize.mgra = syn_households.MGRA
		AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
GROUP BY syn_households.yr
	,syn_households.mgra
	,syn_households.hworkers
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
UNION ALL
SELECT
	households.yr -1 as yr
	,households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,households.hworkers
	,COUNT(*) as N
FROM ws.[abm_population].[households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
WHERE households.yr = 2017
GROUP BY households.yr
	,households.mgra
	,households.hworkers
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
ORDER BY
	yr
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,syn_households.MGRA
	,syn_households.hworkers





--household type

SELECT
	syn_households.yr -1 as yr
	,syn_households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,syn_households.hht
	,COUNT(*) as N
FROM [isam].[xpef03].[syn_households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = syn_households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
GROUP BY syn_households.yr
	,syn_households.mgra
	,syn_households.hht
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
UNION ALL
SELECT
	households.yr -1 as yr
	,households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,households.hht
	,COUNT(*) as N
FROM ws.[abm_population].[households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
WHERE households.yr = 2017
GROUP BY households.yr
	,households.mgra
	,households.hht
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
ORDER BY
	yr
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,syn_households.MGRA
	,syn_households.hht



--UNIT TYPE

SELECT
	syn_households.yr -1 as yr
	,syn_households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,syn_households.unittype
	,COUNT(*) as N
FROM [isam].[xpef03].[syn_households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = syn_households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
GROUP BY syn_households.yr
	,syn_households.mgra
	,syn_households.unittype
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
UNION ALL
SELECT
	households.yr -1 as yr
	,households.mgra
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id) as jcpa
	,cicpa13.name as cicpa13_name
	,cocpa13.name as cocpa13_name
	,jur16.name as jur16_name
	,households.unittype
	,COUNT(*) as N
FROM ws.[abm_population].[households]
	INNER JOIN demographic_warehouse.dim.mgra_denormalize --data_cafe.ref.vi_xref_geography_mgra_13
	ON mgra_denormalize.mgra = households.MGRA
	AND RIGHT(mgra_denormalize.mgra_id, 2) IN ('00','01')
		LEFT JOIN data_cafe.ref.geography_zone cicpa13
		ON cicpa13.geography_type_id = 117 --cicpa 2013
		AND cicpa13.zone = mgra_denormalize.cpa_id
			LEFT JOIN data_cafe.ref.geography_zone cocpa13
			ON cocpa13.geography_type_id = 118 --cocpa 2013
			AND cocpa13.zone = mgra_denormalize.cpa_id
				LEFT JOIN data_cafe.ref.geography_zone jur16
				ON jur16.geography_type_id = 150 --jur 2016
				AND jur16.zone = mgra_denormalize.jurisdiction_id
WHERE households.yr = 2017 AND households.unittype= 0
GROUP BY households.yr
	,households.mgra
	,households.unittype
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,mgra_denormalize.jurisdiction_id
	,cicpa13.name
	,cocpa13.name
	,jur16.name
ORDER BY
	yr
	,mgra_denormalize.jurisdiction_id
	,COALESCE(mgra_denormalize.cpa_id, mgra_denormalize.jurisdiction_id)
	,syn_households.MGRA
	,syn_households.unittype