USE urbansim;

select *
from  [urbansim].[urbansim].[urbansim_lite_output] o
join urbansim.parcel p on p.parcel_id=o.parcel_id
join ref.jurisdiction r on r.jurisdiction_id = p.jurisdiction_id
where  run_id = 444 and capacity_type = 'adu' and du_2018 > 1
ORDER BY p.jurisdiction_id