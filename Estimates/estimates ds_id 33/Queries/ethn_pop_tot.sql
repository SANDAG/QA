USE demographic_warehouse;
SELECT
   FirstEthn.yr_id
   ,FirstEthn.tot_pop
   ,SecondEthn.ethn_pop
   ,ThirdEthn.age_sex_ethn_pop
FROM
(
    SELECT 
      yr_id
      ,sum(population) as tot_pop
    FROM [demographic_warehouse].[fact].[population]
    where datasource_id=33
    group by yr_id
) as FirstEthn
inner join
(  
    SELECT 
       yr_id
      ,sum(population) as ethn_pop
    FROM [demographic_warehouse].[fact].[ethnicity]
    where datasource_id=33
    group by yr_id
) as SecondEthn
ON FirstEthn.yr_id=SecondEthn.yr_id
inner JOIN
(
    SELECT 
       yr_id
      ,sum(population) as age_sex_ethn_pop
    FROM [demographic_warehouse].[fact].[age_sex_ethnicity]
    where datasource_id=33
    group by yr_id
) as ThirdEthn
on FirstEthn.yr_id=ThirdEthn.yr_id

order by firstEthn.yr_id