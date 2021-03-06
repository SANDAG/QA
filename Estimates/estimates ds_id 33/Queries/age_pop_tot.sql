USE demographic_warehouse;
SELECT
   FirstAge.yr_id
   ,FirstAge.tot_pop
   ,SecondAge.age_pop
   ,ThirdAge.age_sex_ethn_pop
FROM
(
    SELECT 
      yr_id
      ,sum(population) as tot_pop
    FROM [demographic_warehouse].[fact].[population]
    where datasource_id=33
    group by yr_id
) as FirstAge
inner join
(  
    SELECT 
       yr_id
      ,sum(population) as age_pop
    FROM [demographic_warehouse].[fact].[age]
    where datasource_id=33
    group by yr_id
) as SecondAge
ON FirstAge.yr_id=SecondAge.yr_id
inner JOIN
(
    SELECT 
       yr_id
      ,sum(population) as age_sex_ethn_pop
    FROM [demographic_warehouse].[fact].[age_sex_ethnicity]
    where datasource_id=33
    group by yr_id
) as ThirdAge
on firstage.yr_id=thirdage.yr_id

order by firstage.yr_id