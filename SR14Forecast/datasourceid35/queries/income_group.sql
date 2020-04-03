USE demographic_warehouse;

 SELECT [income_group_id]
      ,[income_group]
      ,[name]
      ,[constant_dollars_year]
      ,[lower_bound]
      ,[upper_bound]
      ,[categorization]
  FROM [demographic_warehouse].[dim].[income_group]
  where constant_dollars_year = 2010 and categorization = 10

