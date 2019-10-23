
SELECT c.[parcel_id]
      ,[cap_jurisdiction_id]
      ,[capacity_2] as capacity_jur
	  ,COALESCE(unit_change_urbansim_jur,0) as unit_change_jur
      ,[capacity_3] as capacity_sch
	  ,COALESCE(unit_change_urbansim_sch,0) as unit_change_sch
      ,[capacity_ADU]
	  ,COALESCE(unit_change_urbansim_adu,0) as unit_change_adu
	  INTO #capacity_parcels
      FROM [urbansim].[urbansim].[vi_capacity] c
	  FULL JOIN (
			SELECT  parcel_id,sum([unit_change]) as unit_change_urbansim_sch
			FROM [urbansim].[urbansim].[urbansim_lite_output]
			WHERE run_id = 444 and capacity_type = 'sch'
			GROUP BY parcel_id
			) AS sch
		ON c.parcel_id = sch.parcel_id
	  FULL JOIN (
			SELECT  parcel_id,sum([unit_change]) as unit_change_urbansim_adu
			FROM [urbansim].[urbansim].[urbansim_lite_output]
			WHERE run_id = 444 and capacity_type = 'adu'
			GROUP BY parcel_id
			) AS adu
		ON c.parcel_id = adu.parcel_id
			  FULL JOIN (
			SELECT  parcel_id,sum([unit_change]) as unit_change_urbansim_jur
			FROM [urbansim].[urbansim].[urbansim_lite_output]
			WHERE run_id = 444 and capacity_type = 'jur'
			GROUP BY parcel_id
			) AS jur
		ON c.parcel_id = jur.parcel_id
	WHERE cap_jurisdiction_id = 1 and (capacity_2 != 0 OR capacity_3 != 0 OR capacity_ADU ! =0)

	--SELECT *
	--FROM #capacity_parcels


	SELECT cap_jurisdiction_id , sum(capacity_jur) + sum(capacity_sch) as capacity_jur_and_sch,
	sum(capacity_jur) + sum(capacity_sch) + sum(capacity_ADU) as capacity_jur_and_sch_adu,
	sum(unit_change_jur) + sum(unit_change_sch) +  sum(unit_change_adu) as unit_change,
	sum(capacity_jur) as capacity_jur,sum(unit_change_jur) as unit_change_jur,sum(capacity_sch) as capacity_sch,
	sum(unit_change_sch) as unit_change_sch,sum(capacity_ADU) as capacity_ADU,sum(unit_change_adu) AS unit_change_adu
	FROM #capacity_parcels
	GROUP BY cap_jurisdiction_id



