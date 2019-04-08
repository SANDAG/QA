SELECT
	age_sex_ethnicity.yr_id
	,'tract' as geotype
	,mgra_denormalize.tract as geozone
	,age_sex_ethnicity.age_group_id
	,age_group.name as age_group_name
	,age_sex_ethnicity.sex_id
	,sex.abbreviation as sex
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
	,SUM(age_sex_ethnicity.population) as pop
FROM fact.age_sex_ethnicity
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = age_sex_ethnicity.mgra_id
		INNER JOIN dim.age_group
		ON age_group.age_group_id = age_sex_ethnicity.age_group_id
			INNER JOIN dim.sex
			ON sex.sex_id = age_sex_ethnicity.sex_id
				INNER JOIN dim.ethnicity
				ON ethnicity.ethnicity_id = age_sex_ethnicity.ethnicity_id
WHERE age_sex_ethnicity.datasource_id = ds_id
GROUP BY age_sex_ethnicity.yr_id
	,mgra_denormalize.tract
	,age_sex_ethnicity.age_group_id
	,age_group.name
	,age_sex_ethnicity.sex_id
	,sex.abbreviation
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
ORDER BY age_sex_ethnicity.yr_id
	,geotype
	,geozone
	--,mgra_denormalize.cpa
	,age_sex_ethnicity.age_group_id
	,age_sex_ethnicity.sex_id
	,age_sex_ethnicity.ethnicity_id