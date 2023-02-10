USE [demographic_warehouse]
GO

/****** Object:  StoredProcedure [dbo].[compute_median_income_all_zones]    Script Date: 11/1/2018 2:44:10 PM ******/


--creates temp table with number of hh for each jurisdiction for each year
SELECT i.yr_id
	,m.geozone
	,SUM(i.households) as hh
INTO #num_hh
FROM fact.household_income i
	INNER JOIN dim.mgra m
	ON m.mgra_id = i.mgra_id
WHERE i.datasource_id = 17
AND m.geotype = 'jurisdiction'
GROUP BY i.yr_id
	,m.geozone;

SELECT * from #num_hh
order by geozone, yr_id

SELECT i.yr_id
	,m.geozone
	,i.income_group_id
	,ig.lower_bound
	,ig.upper_bound
	,ig.upper_bound - ig.lower_bound + 1 as interval_width
	,SUM(i.households) hh
INTO #inc_dist
FROM fact.household_income i
	INNER JOIN dim.mgra m
	ON m.mgra_id = i.mgra_id
		INNER JOIN dim.income_group ig
		ON i.income_group_id = ig.income_group_id
WHERE i.datasource_id = 17
AND m.geotype = 'jurisdiction'
GROUP BY i.yr_id
	,m.geozone
	,i.income_group_id
	,ig.lower_bound
	,ig.upper_bound;

SELECT * from #inc_dist
order by geozone, yr_id, income_group_id

SELECT ROW_NUMBER() OVER (PARTITION BY num_hh.geozone, a.yr_id ORDER BY a.yr_id, num_hh.geozone, a.income_group_id) as row_num
	,a.yr_id
	,num_hh.geozone
	,a.income_group_id
	,a.lower_bound
	,a.upper_bound
	,a.interval_width
	,a.hh
	,SUM(b.hh) as cum_sum
INTO #cum_dist
FROM #inc_dist a
	INNER JOIN #inc_dist b
	ON a.income_group_id >= b.income_group_id
	AND a.yr_id = b.yr_id
    AND a.geozone = b.geozone
		LEFT JOIN #num_hh num_hh
		ON num_hh.yr_id = a.yr_id
        AND num_hh.geozone = a.geozone
GROUP BY a.yr_id
	,num_hh.geozone
	,a.income_group_id
	,a.lower_bound
	,a.upper_bound
	,a.interval_width
    ,a.hh
    ,num_hh.hh
HAVING SUM(b.hh) > (num_hh.hh / 2.0);

SELECT * from #cum_dist
Where geozone='Carlsbad'
order by geozone, yr_id, income_group_id

SELECT cum_dist.yr_id
	,cum_dist.geozone
    ,CAST(ROUND((lower_bound + ((num_hh.hh / 2.0 - (cum_sum - cum_dist.hh)) / cum_dist.hh) * interval_width), 0) as INT) as median_inc
FROM #cum_dist cum_dist
	INNER JOIN #num_hh num_hh
	ON num_hh.yr_id = cum_dist.yr_id
    AND num_hh.geozone = cum_dist.geozone
	AND cum_dist.row_num = 1
ORDER BY cum_dist.yr_id;
END

GO


