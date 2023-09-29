-- Total GQ Population from Estimates 
SELECT 
      SUM([population]) AS 'Total_GQ_Pop_Estimates'
  FROM [estimates].[est_2022_04].[dw_population]
  WHERE [housing_type_id] != 1 AND yr_id = 2022


-- Total GQ Population from MGRA Base 2022
--  SELECT 
--      SUM([gq_civ]) + SUM([gq_mil]) As 'Total_GQ_MGRA_Base'
--  FROM [ws].[mgra_base].[sr15_v6_2022_01]
