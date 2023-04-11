select area_name AS 'region', 
est_yr AS 'yr_id',
total_pop AS 'Total Population',
household_pop AS 'Household Population',
group_quarters AS 'Total GQ Population',
total_hu AS 'Total Households',
single_detached AS 'Single Family - Detached',
-- signle_attached has no connection to our excels
multiple AS 'Single Family - Multiple Unit',
two_to_four,
five_plus,
mobile_homes AS 'Mobile Home',
occupied,
unoccupied
FROM [socioec_data].[ca_dof].[population_housing_estimates]
where vintage_yr= 2022 AND area_type= 'County' AND area_name = 'San Diego' AND summary_type='Total' AND est_yr IN (2020, 2021, 2022);