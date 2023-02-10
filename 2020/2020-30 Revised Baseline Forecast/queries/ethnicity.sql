

USE demographic_warehouse

SELECT
    age_sex_ethnicity.datasource_id
	,age_sex_ethnicity.yr_id
	,age_sex_ethnicity.mgra_id
	,mgra_denormalize.jurisdiction
	,mgra_denormalize.cpa
	,mgra_denormalize.zip
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
	,SUM(age_sex_ethnicity.population) as pop
FROM fact.age_sex_ethnicity
	INNER JOIN dim.mgra_denormalize
	ON mgra_denormalize.mgra_id = age_sex_ethnicity.mgra_id
				INNER JOIN dim.ethnicity
				ON ethnicity.ethnicity_id = age_sex_ethnicity.ethnicity_id
WHERE age_sex_ethnicity.datasource_id = ds_id
GROUP BY 
    age_sex_ethnicity.datasource_id
	,age_sex_ethnicity.yr_id
	,age_sex_ethnicity.mgra_id
	,mgra_denormalize.jurisdiction
	,mgra_denormalize.cpa
	,mgra_denormalize.zip
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
ORDER BY  age_sex_ethnicity.datasource_id
	,age_sex_ethnicity.yr_id
	,age_sex_ethnicity.mgra_id
	,mgra_denormalize.jurisdiction
	,mgra_denormalize.cpa
	,mgra_denormalize.zip
	,age_sex_ethnicity.ethnicity_id
	,ethnicity.short_name
