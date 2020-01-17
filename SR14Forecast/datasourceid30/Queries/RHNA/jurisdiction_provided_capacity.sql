



  WITH jur as (
	SELECT jurisdiction_id, sum(capacity_2) as jur_provided_cap
    FROM [urbansim].[urbansim].[parcel]
	WHERE site_id is null
    GROUP BY jurisdiction_id),
	sched_dev as (
	SELECT p.jurisdiction_id, sum(capacity_3) as sched_dev_cap
	FROM  [urbansim].[urbansim].[scheduled_development_parcel] s
	JOIN urbansim.urbansim.parcel p ON s.parcel_id = p.parcel_id
    GROUP BY jurisdiction_id)
	SELECT jur.jurisdiction_id,jur_provided_cap,sched_dev_cap,jur_provided_cap+sched_dev_cap as totalcap
	FROM jur
	JOIN sched_dev ON jur.jurisdiction_id = sched_dev.jurisdiction_id
	ORDER BY jur.jurisdiction_id;



-- need to check these numbers with Grace

SELECT jurisdiction_id, sum(COALESCE(capacity_3,capacity_2)) as jur_provided_cap
    FROM [urbansim].[urbansim].[parcel]
    LEFT JOIN  [urbansim].[urbansim].[scheduled_development_parcel]
    ON scheduled_development_parcel.parcel_id = parcel.parcel_id
    GROUP BY jurisdiction_id
	ORDER by jurisdiction_id;

	--------------------------------------

	SELECT p.jurisdiction_id, sum(capacity_3) as sched_dev_cap
	FROM  [urbansim].[urbansim].[scheduled_development_parcel] s
	JOIN urbansim.urbansim.parcel p ON s.parcel_id = p.parcel_id
    GROUP BY jurisdiction_id
	ORDER by jurisdiction_id;


	--------------------------------------------------

	SELECT jurisdiction_id, sum(COALESCE(capacity_3,capacity_2)) as jur_provided_cap
    FROM [urbansim].[urbansim].[parcel] 
    LEFT JOIN  [urbansim].[urbansim].[scheduled_development_parcel]
    ON scheduled_development_parcel.parcel_id = parcel.parcel_id
	where capacity_2>0 and capacity_3>0 and parcel.site_id is NULL
    GROUP BY jurisdiction_id
	ORDER by jurisdiction_id;

	--------------------------

	/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP (1000) [jurisdiction_id]
      ,[name]
  FROM [urbansim].[ref].[jurisdiction];



  -- without scheduled development
