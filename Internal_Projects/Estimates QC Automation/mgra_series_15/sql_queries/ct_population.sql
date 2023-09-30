SELECT
	  CAST([BASENAME] AS decimal(10,2)) * 100 AS 'census_tract'
      ,P0020002 AS 'Hispanic'
	  ,P0020007 AS 'Non-Hispanic, American Indian or Alaska Native'
	  ,P0020008 AS 'Non-Hispanic, Asian'
	  ,P0020006 AS 'Non-Hispanic, Black'
	  ,P0020009 AS 'Non-Hispanic, Hawaiian or Pacific Islander'
	  ,P0020010 AS 'Non-Hispanic, Other'
	  ,P0020012 AS 'Non-Hispanic, Two or More Races'
	  ,P0020005 AS 'Non-Hispanic, White'
  FROM [census].[decennial].[pl_94_171_2020_ca]
  WHERE SUMLEV = 140 AND GEOCODE LIKE '06073%'