select c.sandag_sector,d.sector_description,c.sandag_jobs,d.edd_jobs, c.sandag_jobs - d.edd_jobs as diff
from
(
select b.sandag_sector,count(a.job_id) as sandag_jobs
from 
(
select *,
case
when job_id > 200000000 then 0 /* self-employed */
when job_id > 50000000 and sector_id not in (22,27) then 21 /* fed government owned */
when job_id > 50000000 and sector_id in (22,27) then sector_id /* fed government owned */
when job_id > 40000000 and sector_id not in (23) then 24 /* state government owned */
when job_id > 40000000 and sector_id in (23) then sector_id /* state government owned */
when job_id > 30000000 and sector_id not in (25) then 26 /* local government owned */
else sector_id
end as sandag_industry_id
from [urbansim].[urbansim].[job_2016]
) as a
inner join [socioec_data].[ca_edd].[xref_sandag_industry_edd_sector] as b on a.sandag_industry_id=b.sandag_industry_id
group by b.sandag_sector
) as c

inner join 
(
SELECT x.sector,x.description as sector_description,x.employment as edd_jobs
FROM [socioec_data].[ca_edd].[sd_industry_employment] as x
inner join [socioec_data].[ca_edd].[xref_sandag_industry_edd_sector] as y on x.sector=y.sandag_sector
where x.sector is not null and x.vintage_yr=2016 and x.yr=2016
) as d

on c.sandag_sector = d.sector
order by sandag_sector
