/****** Script for SelectTopNRows command from SSMS  ******/
SELECT  fact.jobs.mgra_id as mgra_id
      ,geotype
	  ,geozone
	  ,mgra
	  --,[mgra_id]
  FROM [demographic_warehouse].[fact].[jobs]
  	  JOIN dim.mgra on fact.jobs.mgra_id = dim.mgra.mgra_id
	  WHERE yr_id=2016 and datasource_id=19 and jobs >0 and (geotype='jurisdiction' or geotype='cpa')
	  group by mgra, geotype, geozone,fact.jobs.mgra_id
	order by mgra

  
  
  