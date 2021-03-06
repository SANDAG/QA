USE socioec_data;
--retrieve DOF data

SELECT [fiscal_yr]
      ,sum(population) as pop
  FROM [socioec_data].[ca_dof].[population_proj_2018_1_20]
  where county_fips_code=6073 and fiscal_yr>2018
  Group by fiscal_yr
  order by fiscal_yr
