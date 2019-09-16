SELECT p.parcel_id AS parcel_id
		,m.emp_id AS emp_id, SUM(m.emp1) AS emp1,SUM(m.emp2) AS emp2,SUM(m.emp3) AS emp3, SUM(m.payroll) as payroll, SUM(m.naics) AS naics, m.dba
		,b.bldgID AS building_id--, SUM(b.non_residential_sqft) AS nonresSqft,SUM(b.residential_sqft) AS resSqft
		,d.name --, SUM(dbo.GetDataForID(m.naics)) as Data
From spacecore.urbansim.parcels p

INNER JOIN spacecore.GIS.building_outlines_divided b
	ON b.parcelID = p.parcel_id

INNER JOIN spacecore.ref.development_type as d
	ON p.development_type_id_2017 = d.development_type_id

--join OPENQUERY(sql2014b8, 'SELECT * FROM  EMPCORE.dbo.CA_EDD_EMP2017') AS m
--	ON m.shape.STIntersects(b.shape) = 1

RIGHT JOIN OPENQUERY(sql2014b8, 'SELECT * FROM  EMPCORE.dbo.CA_EDD_EMP2017') AS m
	ON m.shape.STIntersects(b.shape) = 1

Group By p.parcel_id, m.emp_id, m.dba, d.name, b.bldgID
