USE demographic_warehouse;

SELECT datasource_id,housing.[yr_id], geozone, geotype
      ,SUM([occupied]) as [Households]
	  ,SUM([units]) as [Housing_Units]
	  ,SUM([units])-SUM([occupied]) as vacant_units
	  ,CASE WHEN (SUM([units])-SUM([occupied]) >= 0)
	  	THEN 'PASS'
		ELSE 'FAIL'
		END AS QC_Result
  FROM [demographic_warehouse].[fact].[housing]
	INNER JOIN dim.mgra 
	ON mgra.mgra_id = housing.mgra_id AND mgra.geotype IN ('jurisdiction', 'region', 'cpa') 
  WHERE datasource_id = 28
  GROUP BY yr_id,geozone,geotype,datasource_id
  ORDER BY geotype DESC,geozone,yr_id
  
  
-- 864 rows 
 -- select (1 + 88 + 19) * 8  
 -- 1 region, 87 CPAs + 1 NOT IN CPA + 18 cities + 1 unincorporated * 8 years