

-- unit change in urbansim summed to increments
SELECT increment_from_urbansim, sum(unit_change) [Unit Change]
FROM
(
  select unit_change,
    CASE   
		 WHEN year_simulation=2018 THEN '2017_to_2018'
         WHEN year_simulation BETWEEN 2019 AND 2020 THEN '2020'  
         WHEN year_simulation BETWEEN 2021 AND 2025 THEN '2025'  
         WHEN year_simulation BETWEEN 2026 AND 2030 THEN '2030'  
         WHEN year_simulation BETWEEN 2031 AND 2035 THEN '2035'  
		 WHEN year_simulation BETWEEN 2036 AND 2040 THEN '2040'  
		 WHEN year_simulation BETWEEN 2041 AND 2045 THEN '2045'  
		 WHEN year_simulation BETWEEN 2046 AND 2050 THEN '2050' 
         ELSE '2051'  
      END  as increment_from_urbansim
FROM [urbansim].[urbansim].[urbansim_lite_output] where run_id = 444
) urbansim_output
GROUP BY increment_from_urbansim;


-- unit change in demographic warehouse
WITH t as (
SELECT [datasource_id]
      ,[yr_id]
      ,sum([units])  as [Number of units]
  FROM [demographic_warehouse].[fact].[housing]
  where datasource_id = 30 
  GROUP BY datasource_id,yr_id)
  select *,
    [Number of units] - lag([Number of units], 1) over ( order by yr_id) diff
from t;

