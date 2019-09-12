-- for SR14 forecast assumptions summary

USE demographic_warehouse


SELECT  [yr_id]  
	  ,sum([unoccupiable]) as unoccupiable
      ,sum([units]) as units
      ,sum([occupied]) as occupied_hh
      ,sum([vacancy]) as vacant_units
	  ,ROUND(100.0 *(1 - (CAST(sum(occupied) AS FLOAT)/( (CAST(sum(units) AS FLOAT) -CAST(sum(unoccupiable) AS FLOAT) )))),2)  as percent_vacancy
  FROM [demographic_warehouse].[fact].[housing]
  where datasource_id = 30
  group by yr_id
  order by yr_id

 -- compare to what was presented to BOD

 -- BOD 5/25/2018: vacancy rate of 4% by 2035
 --      (actual 3.74% in 2035)

  --BOD 5/25/2018: unoccupiable housing units 57,000 2016-2050 
  --     (actual 39,174 except 2016)