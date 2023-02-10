USE urbansim;

select r.name,p.jurisdiction_id,  count(*) as [ADUs before 2035]
from  [urbansim].[urbansim].[urbansim_lite_output] o
join urbansim.parcel p on p.parcel_id=o.parcel_id
join ref.jurisdiction r on r.jurisdiction_id = p.jurisdiction_id
where  run_id = 444 and capacity_type = 'adu' and year_simulation <= 2035
GROUP by p.jurisdiction_id,r.name
ORDER BY p.jurisdiction_id