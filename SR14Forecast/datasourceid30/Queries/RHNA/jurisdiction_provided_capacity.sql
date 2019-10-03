
-- need to check these numbers with Grace

SELECT jurisdiction_id, sum(COALESCE(capacity_3,capacity_2)) as jur_provided_cap
    FROM [urbansim].[urbansim].[parcel]
    LEFT JOIN  [urbansim].[urbansim].[scheduled_development_parcel]
    ON scheduled_development_parcel.parcel_id = parcel.parcel_id
    GROUP BY jurisdiction_id
	ORDER by jurisdiction_id


-- without scheduled development

	SELECT jurisdiction_id, sum(capacity_2) as jur_provided_cap
    FROM [urbansim].[urbansim].[parcel]
    LEFT JOIN  [urbansim].[urbansim].[scheduled_development_parcel]
    ON scheduled_development_parcel.parcel_id = parcel.parcel_id
    GROUP BY jurisdiction_id
	ORDER by jurisdiction_id