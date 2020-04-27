(SELECT 
	household_income.yr_id
	,'jurisdiction' as geotype
	,mgra_denormalize.jurisdiction as geozone
    ,household_income.income_group_id
	,income_group.name
	,SUM(household_income.households) as hh
FROM fact.household_income
	 INNER JOIN dim.mgra_denormalize
                ON mgra_denormalize.mgra_id = household_income.mgra_id	
	INNER JOIN dim.income_group
		ON income_group.income_group_id = household_income.income_group_id
WHERE household_income.datasource_id = ds_id
GROUP BY 
	household_income.yr_id
	,mgra_denormalize.jurisdiction
    ,household_income.income_group_id
	,income_group.name)
UNION
(SELECT 
	household_income.yr_id
	,'cpa' as geotype
	,mgra_denormalize.cpa as geozone
    ,household_income.income_group_id
	,income_group.name
	,SUM(household_income.households) as hh
FROM fact.household_income
	 INNER JOIN dim.mgra_denormalize
                ON mgra_denormalize.mgra_id = household_income.mgra_id	
	INNER JOIN dim.income_group
		ON income_group.income_group_id = household_income.income_group_id
WHERE household_income.datasource_id = ds_id
GROUP BY 
	household_income.yr_id
	,mgra_denormalize.cpa
    ,household_income.income_group_id
	,income_group.name)
UNION
(SELECT 
	household_income.yr_id
	,'region' as geotype
	,mgra_denormalize.region as geozone
    ,household_income.income_group_id
	,income_group.name
	,SUM(household_income.households) as hh
FROM fact.household_income
	 INNER JOIN dim.mgra_denormalize
                ON mgra_denormalize.mgra_id = household_income.mgra_id	
	INNER JOIN dim.income_group
		ON income_group.income_group_id = household_income.income_group_id
WHERE household_income.datasource_id = ds_id
GROUP BY 
	household_income.yr_id
	,mgra_denormalize.region
    ,household_income.income_group_id
	,income_group.name)
UNION
(SELECT 
	household_income.yr_id
	,'tract' as geotype
	,mgra_denormalize.tract as geozone
    ,household_income.income_group_id
	,income_group.name
	,SUM(household_income.households) as hh
FROM fact.household_income
	 INNER JOIN dim.mgra_denormalize
                ON mgra_denormalize.mgra_id = household_income.mgra_id	
	INNER JOIN dim.income_group
		ON income_group.income_group_id = household_income.income_group_id
WHERE household_income.datasource_id = ds_id
GROUP BY 
	household_income.yr_id
	,mgra_denormalize.tract
    ,household_income.income_group_id
	,income_group.name)
ORDER BY 1,2,3,4
