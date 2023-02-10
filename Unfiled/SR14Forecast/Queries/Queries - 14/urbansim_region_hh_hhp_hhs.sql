SELECT  [year_simulation] as yr_id,
		'Region' as jcpa,
		sum(unit_change) as unit_chg
  FROM [urbansim].[urbansim].[urbansim_lite_output] o
 WHERE run_id = (select max(run_id) from [urbansim].[urbansim].[urbansim_lite_output] )
 GROUP BY year_simulation
 order by yr_id
