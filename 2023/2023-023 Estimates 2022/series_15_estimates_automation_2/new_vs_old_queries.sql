SELECT old.[mgra_id] AS 'old_mgra_id'
	,new.mgra_id AS 'new_mgra_id'
      ,new.[yr_id]
      ,new.[age_group_id]
      ,new.[population]
  FROM [estimates].[est_2022_02].[dw_age] AS new
  LEFT JOIN [estimates].[est_2022_01].[dw_age] AS old
  ON new.mgra_id = old.mgra_id
  WHERE new.mgra_id = 150000100

SELECT * 
FROM [estimates].[est_2022_01].[dw_age] AS old
WHERE old.mgra_id = 1500001000