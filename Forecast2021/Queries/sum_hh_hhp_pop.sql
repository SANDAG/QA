--sum by jurisdiction

WITH jur_hhp AS
(   SELECT 
	population.yr_id
	,SUM(population) as [JUR]
	,'household_pop' as [Variable]
FROM fact.population 
INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction')
WHERE datasource_id IN (28) and series = 14
GROUP BY yr_id ),
cpa_hhp AS 
(SELECT 
	population.yr_id
	,SUM(population) as [CPA]
FROM fact.population 
INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('cpa')
WHERE datasource_id IN (28) and series = 14
GROUP BY yr_id),
jur_hh AS
(  SELECT housing.[yr_id]
      ,SUM([occupied]) as [JUR]
	,'households' as [Variable] 
  FROM [demographic_warehouse].[fact].[housing]
  INNER JOIN dim.mgra
	ON mgra.mgra_id = housing.mgra_id
	AND mgra.geotype IN ('jurisdiction')
	 WHERE datasource_id = 28
  GROUP BY yr_id),
cpa_hh AS 
(SELECT housing.[yr_id]
      ,SUM([occupied]) as [CPA]
  FROM [demographic_warehouse].[fact].[housing]
  INNER JOIN dim.mgra
	ON mgra.mgra_id = housing.mgra_id
	AND mgra.geotype IN ('cpa')
	 WHERE datasource_id = 28
  GROUP BY yr_id)
SELECT jur_hhp.yr_id,Variable,JUR,CPA
FROM cpa_hhp
JOIN jur_hhp ON jur_hhp.yr_id = cpa_hhp.yr_id
UNION
SELECT jur_hh.yr_id,Variable,JUR,CPA
FROM cpa_hh
JOIN jur_hh ON jur_hh.yr_id = cpa_hh.yr_id
ORDER BY [Variable],yr_id





--SELECT housing.[yr_id]
--      ,SUM([occupied]) as [JUR]
--	,'households' as [Variable] 
--  FROM [demographic_warehouse].[fact].[housing]
--  INNER JOIN dim.mgra
--	ON mgra.mgra_id = housing.mgra_id
--	AND mgra.geotype IN ('jurisdiction')
--	 WHERE datasource_id = 28
--  GROUP BY yr_id





