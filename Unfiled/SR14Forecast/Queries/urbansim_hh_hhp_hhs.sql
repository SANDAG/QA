SELECT  [year_simulation] as yr_id,
		jcpa, run_id,
		geotype =  
       CASE   
         WHEN jcpa <  20 THEN 'jurisdiction'  
         ELSE 'CPA'
		 END,
		COALESCE(cicpa_13_name,cocpa_2016_name,jurisdiction_2016_name) AS geozone,
		sum(unit_change) as unit_chg,
		capacity_type
  FROM [urbansim].[urbansim].[urbansim_lite_output] o
 JOIN [ref].[vi_parcel_xref] x
 ON x.parcel_id = o.parcel_id
 WHERE run_id = (select max(run_id) from [urbansim].[urbansim].[urbansim_lite_output] )
 GROUP BY year_simulation,jcpa,cicpa_13_name,cocpa_2016_name,jurisdiction_2016_name,run_id,capacity_type
 order by jcpa,yr_id

