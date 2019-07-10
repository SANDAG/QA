SELECT p.parcel_id AS parcel_id, 
		m.emp_id AS emp_id, SUM(m.emp1) AS emp1,SUM(m.emp2) AS emp2,SUM(m.emp3) AS emp3, SUM(m.payroll) as payroll, SUM(m.naics) AS naics, m.dba,
		b.building_id AS building_id, SUM(b.non_residential_sqft) AS nonresSqft,SUM(b.residential_sqft) AS resSqft, 
		d.name --, SUM(dbo.GetDataForID(m.naics)) as Data
From urbansim.urbansim.parcel p

INNER JOIN urbansim.urbansim.building b
	ON b.parcel_id = p.parcel_id

INNER JOIN urbansim.ref.development_type as d
	ON b.development_type_id = d.development_type_id

--join OPENQUERY(sql2014b8, 'SELECT * FROM  EMPCORE.dbo.CA_EDD_EMP2017') AS m
--	ON m.shape.STIntersects(b.shape) = 1

Right JOIN OPENQUERY(sql2014b8, 'SELECT * FROM  EMPCORE.dbo.CA_EDD_EMP2017') AS m
	ON m.shape.STIntersects(b.shape) = 1

Group By p.parcel_id, m.emp_id, m.dba, d.name, b.building_id

