USE demographic_warehouse;

SELECT 
    household_income.datasource_id
	,household_income.yr_id
	,mgra.mgra_id
	,mgra.geotype
	,mgra.geozone
	,household_income.income_group_id
	,income_group.name
	,SUM(household_income.households) as hh
FROM fact.household_income
	INNER JOIN dim.mgra
	ON mgra.geotype IN ('jurisdiction')
	AND mgra.mgra_id = household_income.mgra_id
		INNER JOIN dim.income_group
		ON income_group.income_group_id = household_income.income_group_id
WHERE household_income.datasource_id = ds_id
GROUP BY 
     household_income.datasource_id
	,household_income.yr_id
	,mgra.mgra_id
	,mgra.geotype
	,mgra.geozone
	,household_income.income_group_id
	,income_group.name
ORDER BY 1,2,3,4

