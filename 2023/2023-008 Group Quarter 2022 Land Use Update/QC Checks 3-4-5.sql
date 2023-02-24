-- =======================================================
-- 2023-008 GROUP QUARTER 2022 LAND USE UPDATE QC
-- Author: Dante Lee
-- Date Created: 1/12/2023
-- Description: Conduct QC checks 3/4/5 - see Test Plan
-- =======================================================

-- CHECK 3: Confirm [gqMil] only on military Facility Type
SELECT DISTINCT [facilityType]
  FROM [WS].[gis].[GROUPQUARTER2022]
  WHERE gqMil > 0

-- CHECK 4: Confirm [gqCiv] = 0 on military Facility Type
SELECT *
  FROM [WS].[gis].[GROUPQUARTER2022]
  WHERE facilityType in (404, 600, 601, 602) and gqCiv != 0

-- CHECK 5: Check distributions against SDGQ22 Excel file
SELECT [name]
	  ,SUM([gqPop]) as [tot_gq]
  FROM [WS].[gis].[GROUPQUARTER2022]
  WHERE comment LIKE '%sdgq%'
  GROUP BY [name]