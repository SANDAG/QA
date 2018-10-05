USE demographic_warehouse
GO

--HH, HHP, HHS
SELECT
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,hh.hh AS households
	,SUM(population) as hhp
	,ROUND(CASE WHEN hh.hh IS NULL OR hh.hh = 0 THEN 0 ELSE SUM(population) / CAST(hh.hh as float) END, 2) as hhs
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN
		(
			SELECT yr_id, mgra.geotype, mgra.geozone, SUM(occupied) as hh
			FROM fact.housing
				INNER JOIN dim.mgra
				ON mgra.mgra_id = housing.mgra_id
				AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
			WHERe housing.datasource_id = 18
			GROUP BY yr_id, mgra.geotype, mgra.geozone
		) hh
		ON hh.yr_id = population.yr_id
		AND hh.geozone = mgra.geozone
		AND hh.geotype = mgra.geotype
WHERE datasource_id = 18
AND population.housing_type_id = 1
GROUP BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh
ORDER BY population.yr_id, mgra.geotype, mgra.geozone, hh.hh

--GQ by type
SELECT
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,population.housing_type_id
	,housing_type.short_name
	,SUM(population) as pop
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN dim.housing_type
		ON housing_type.housing_type_id = population.housing_type_id
WHERE population.datasource_id = 18
GROUP BY 
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,population.housing_type_id
	,housing_type.short_name
ORDER BY 
	population.yr_id
	,mgra.geotype
	,mgra.geozone
	,population.housing_type_id


--hh inc
SELECT 
	household_income.yr_id
	,mgra.geotype
	,mgra.geozone
	,household_income.income_group_id
	,income_group.name
	,SUM(household_income.households) as hh
FROM fact.household_income
	INNER JOIN dim.mgra
	ON mgra.geotype IN ('jurisdiction', 'cpa', 'region')
	AND mgra.mgra_id = household_income.mgra_id
		INNER JOIN dim.income_group
		ON income_group.income_group_id = household_income.income_group_id
WHERE household_income.datasource_id = 18
GROUP BY 
	household_income.yr_id
	,mgra.geotype
	,mgra.geozone
	,household_income.income_group_id
	,income_group.name
ORDER BY 1,2,3,4


--Age
SELECT
	age.yr_id
	,mgra.geotype
	,mgra.geozone
	,age.age_group_id
	,age_group.name
	,SUM(age.population) as pop
FROM fact.age
	INNER JOIN dim.mgra
	ON mgra.mgra_id = age.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN dim.age_group
		ON age_group.age_group_id = age.age_group_id
WHERE age.datasource_id = 18
GROUP BY age.yr_id
	,mgra.geotype
	,mgra.geozone
	,age.age_group_id
	,age_group.name
ORDER BY age.yr_id
	,mgra.geotype
	,mgra.geozone
	,age.age_group_id

--Sex
SELECT
	sex.yr_id
	,mgra.geotype
	,mgra.geozone
	,sex.sex_id
	,dim_sex.abbreviation
	,SUM(sex.population) as pop
FROM fact.sex
	INNER JOIN dim.mgra
	ON mgra.mgra_id = sex.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN dim.sex as dim_sex
		ON sex.sex_id = dim_sex.sex_id
WHERE sex.datasource_id = 18
GROUP BY sex.yr_id
	,mgra.geotype
	,mgra.geozone
	,sex.sex_id
	,dim_sex.abbreviation
ORDER BY sex.yr_id
	,mgra.geotype
	,mgra.geozone
	,sex.sex_id


--age, sex, eth
SELECT
	age_sex_ethnicity.yr_id
	,mgra.geotype
	,mgra.geozone
	,age_sex_ethnicity.age_group_id
	,age_group.name as age_group_name
	,age_sex_ethnicity.sex_id
	,sex.abbreviation as sex
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
	,SUM(age_sex_ethnicity.population) as pop
FROM fact.age_sex_ethnicity
	INNER JOIN dim.mgra
	ON mgra.mgra_id = age_sex_ethnicity.mgra_id
		INNER JOIN dim.age_group
		ON age_group.age_group_id = age_sex_ethnicity.age_group_id
			INNER JOIN dim.sex
			ON sex.sex_id = age_sex_ethnicity.sex_id
				INNER JOIN dim.ethnicity
				ON ethnicity.ethnicity_id = age_sex_ethnicity.ethnicity_id
WHERE age_sex_ethnicity.datasource_id = 18
AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
GROUP BY age_sex_ethnicity.yr_id
	,mgra.geotype
	,mgra.geozone
	,age_sex_ethnicity.age_group_id
	,age_group.name
	,age_sex_ethnicity.sex_id
	,sex.abbreviation
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
ORDER BY age_sex_ethnicity.yr_id
	,mgra.geotype
	,mgra.geozone
	,age_sex_ethnicity.age_group_id
	,age_sex_ethnicity.sex_id
	,age_sex_ethnicity.ethnicity_id

--Did not update below 10-5-2018 DCO (should 14 be updated to 18)

--median income
--EXECUTE dbo.compute_median_income_all_zones 14, 'jurisdiction'
--EXECUTE dbo.compute_median_income_all_zones 14, 'cpa'
--EXECUTE dbo.compute_median_income_all_zones 14, 'region'

--median age
--EXECUTE dbo.compute_median_age_all_zones 14, 'jurisdiction'
--EXECUTE dbo.compute_median_age_all_zones 14, 'cpa'
--EXECUTE dbo.compute_median_age_all_zones 14, 'region'

--pop
SELECT yr_id
	,mgra.geotype
	,mgra.geozone
	,SUM(population)
FROM fact.population
	INNER JOIN dim.mgra
	ON mgra.mgra_id = population.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
WHERE datasource_id = 18
GROUP BY yr_id, mgra.geotype, mgra.geozone
ORDER BY yr_id, mgra.geotype, mgra.geozone

--hh (get from first query)
--emp (coming from Dmitry soon)
SELECT jobs.yr_id
	,mgra.geotype
	,mgra.geozone
	,jobs.employment_type_id
	,employment_type.full_name
	,SUM(jobs.jobs) as jobs
FROM fact.jobs
	INNER JOIN dim.mgra
	ON mgra.mgra_id = jobs.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'cpa', 'region')
		INNER JOIN dim.employment_type
		ON employment_type.employment_type_id = jobs.employment_type_id
WHERE jobs.datasource_id = 18
GROUP BY jobs.yr_id
	,mgra.geotype
	,mgra.geozone
	,jobs.employment_type_id
	,employment_type.short_name
ORDER BY yr_id, mgra.geotype, mgra.geozone, jobs.employment_type_id




--vacancy rates
SELECT
	housing.yr_id
	,mgra.geotype
	,mgra.geozone
	,housing.structure_type_id
	,structure_type.short_name
	,SUM(housing.occupied) as hh
	,SUM(housing.units) as units
	,ROUND(CASE WHEN SUM(housing.occupied) = 0 THEN 0 ELSE 1.0 - SUM(housing.occupied) / CAST(SUM(housing.units) as float) END, 2) as vac
FROM fact.housing
	INNER JOIN dim.mgra
	ON mgra.mgra_id = housing.mgra_id
	AND mgra.geotype IN ('jurisdiction', 'region', 'cpa')
		INNER JOIN dim.structure_type
		ON structure_type.structure_type_id = housing.structure_type_id
WHERE housing.datasource_id = 18
GROUP BY 
housing.yr_id
	,mgra.geotype
	,mgra.geozone
	,housing.structure_type_id
	,structure_type.short_name
ORDER BY 1,2,3,4