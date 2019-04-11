USE demographic_warehouse

SELECT [income_group] as hinccat1
      ,[name]
,[constant_dollars_year]
,[lower_bound]
,[upper_bound]
,[categorization]
FROM [demographic_warehouse].[dim].[income_group]
where categorization = 5 and constant_dollars_year = 2010
