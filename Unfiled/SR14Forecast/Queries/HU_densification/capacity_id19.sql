-- datasource 19 query for capacity
SELECT '19' as ID,jcpa,jcpa_name, sum(COALESCE(capacity_3,capacity_2)) as jur_provided_cap, 
	COALESCE(sum(du),0) as additional_cap,COALESCE(sum(du),0) + sum(COALESCE(capacity_3,capacity_2)) as total_cap
    FROM [urbansim].[urbansim].[parcel]
    JOIN [urbansim].[ref].[vi_parcel_geo_names]
    ON vi_parcel_geo_names.parcel_id = parcel.parcel_id
    LEFT JOIN  [urbansim].[urbansim].[scheduled_development_parcel]
    ON scheduled_development_parcel.parcel_id = parcel.parcel_id
    LEFT JOIN   (SELECT * FROM [urbansim].[urbansim].[additional_capacity]
                WHERE additional_capacity.version_id = 109) as additional_cap
    ON additional_cap.parcel_id = parcel.parcel_id
    GROUP BY jcpa,jcpa_name
	order by jcpa
