SELECT
	  CAST([BASENAME] AS decimal(10,2)) * 100 AS 'census_tract'
      ,[H0010001] AS 'units'
      ,[H0010002] AS 'occupied'
      ,[H0010003] AS 'vacancy'
  FROM [census].[decennial].[pl_94_171_2020_ca]
  WHERE SUMLEV = 140 AND GEOCODE LIKE '06073%'