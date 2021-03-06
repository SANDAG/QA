USE demographic_warehouse;
SELECT
   FirstSex.yr_id
   ,FirstSex.tot_pop
   ,SecondSex.sex_pop
   ,ThirdSex.age_sex_ethn_pop
FROM
(
    SELECT 
      yr_id
      ,sum(population) as tot_pop
    FROM [demographic_warehouse].[fact].[population]
    where datasource_id=33
    group by yr_id
) as FirstSex
inner join
(  
    SELECT 
       yr_id
      ,sum(population) as sex_pop
    FROM [demographic_warehouse].[fact].[sex]
    where datasource_id=33
    group by yr_id
) as SecondSex
ON FirstSex.yr_id=SecondSex.yr_id
inner JOIN
(
    SELECT 
       yr_id
      ,sum(population) as age_sex_ethn_pop
    FROM [demographic_warehouse].[fact].[age_sex_ethnicity]
    where datasource_id=33
    group by yr_id
) as ThirdSex
on FirstSex.yr_id=ThirdSex.yr_id

order by firstSex.yr_id