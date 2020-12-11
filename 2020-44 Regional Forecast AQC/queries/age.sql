
SELECT
      datasource_id
      ,yr_id
      ,mgra_id
      ,age_group.age_group_id
	  ,age_group.name as age_group_name
      ,sum([population]) as pop
  FROM [demographic_warehouse].[fact].[age]
  INNER JOIN dim.age_group
		ON age_group.age_group_id = age.age_group_id
	WHERE age.datasource_id = ds_id
  GROUP BY 
		age_id
      ,datasource_id
      ,yr_id
      ,mgra_id
	  ,age_group.name
      ,age_group.age_group_id
