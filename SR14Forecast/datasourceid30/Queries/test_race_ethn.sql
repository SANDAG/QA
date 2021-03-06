USE demographic_warehouse;

-- Declare the variable to be used.
DECLARE @geozone nvarchar(30);
DECLARE @geotype nvarchar(30);

-- Initialize the variable.

-- Kearny Mesa
--SET @geozone = 'Kearny Mesa';
--SET @geotype = 'cpa';

-- San Diego region
--SET @geozone = 'San Diego';
--SET @geotype = 'region';

-- National City
SET @geozone = 'National City';
SET @geotype = 'jurisdiction';


DROP TABLE IF EXISTS #race_ethn_30;
SELECT [datasource_id]
      ,[yr_id]
     ,d.geotype
	 ,d.geozone
      ,a.[ethnicity_id]
      ,sum([population]) as population
       ,CASE   
		 WHEN short_name = 'Asian' THEN 'Asian'
         WHEN short_name = 'Hispanic' THEN 'Hispanic'
         WHEN short_name = 'White' THEN 'White' 
         WHEN short_name = 'Black' THEN 'Black'    
         ELSE 'Other'  
      END  as race_ethn
	INTO #race_ethn_30
  FROM [demographic_warehouse].[fact].[age_sex_ethnicity] a
JOIN [dim].[mgra] d on d.mgra_id = a.mgra_id AND d.geotype IN ('cpa','jurisdiction', 'region')
JOIN [dim].[ethnicity] on a.ethnicity_id = ethnicity.ethnicity_id
  where datasource_id = 30 and geozone = @geozone and geotype = @geotype
  GROUP BY a.ethnicity_id,datasource_id,yr_id,d.geotype,d.geozone,short_name
  ORDER BY short_name,yr_id,geozone


SELECT datasource_id,yr_id,geotype,geozone,race_ethn,sum(population) as pop
FROM #race_ethn_30
 GROUP BY datasource_id,yr_id,geotype,geozone,race_ethn
 ORDER BY race_ethn,yr_id,geozone



-- TOTAL POPULATION AT EACH INCREMENT
SELECT [yr_id]
     ,geotype
	 ,geozone
      ,sum([population]) as population
FROM [demographic_warehouse].[fact].[age_sex_ethnicity] a
JOIN [dim].[mgra] d on d.mgra_id = a.mgra_id AND d.geotype IN ('cpa','jurisdiction', 'region')
WHERE datasource_id = 30 and geozone =  @geozone and geotype = @geotype
GROUP BY datasource_id,yr_id,geotype,geozone
ORDER BY yr_id,geozone