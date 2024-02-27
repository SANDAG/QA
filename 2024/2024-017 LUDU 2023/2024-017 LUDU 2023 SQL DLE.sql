/* 
2022-84 LUDU 2022 QC
Conduct trend checks between 2021 and 2022

Author: Dante Lee
Date: 12/5/22
*/

-- TREND CHECK 2:
-- COMPARE SUM OF DU BY LU BETWEEN 2021 AND 2022

;WITH du_CTE as
       (
       SELECT [lu22]
              ,[du22]
              ,[lu23]
              ,[du23]
              ,([du23] - [du22]) as [du23-21]
         FROM (SELECT [lu] as [lu22], SUM([du]) as [du22]
                       FROM [GeoDepot].[gis].[LUDU2022]
                       GROUP BY [lu]
                     ) AS a
         FULL JOIN
         (
              SELECT [lu] as [lu23], SUM([du]) as [du23]
                FROM [WS].[gis].[LUDU2023_DRAFT_20240223]
                GROUP BY [lu]
         ) AS b ON [lu23] = [lu22]
       )

SELECT *
  FROM du_CTE
  ORDER BY [du23-21]

-- TREND CHECK 3:
-- COMPARE SUM OF ACREAGE BY LU BETWEEN 2021 AND 2022
  
;WITH lu_CTE AS 
       ( 
       SELECT [lu22] 
              ,[acres22] 
              ,[lu23] 
              ,[acres23] 
              ,ROUND(([acres23] - [acres22]),2) as [diff23-22] 
         FROM (SELECT [lu] AS [lu22], SUM([Shape].STArea()/43560) AS [acres22] 
                       FROM [GeoDepot].[gis].[LUDU2022] 
                       GROUP BY [lu]) AS a 
              FULL JOIN 
               ( 
                     SELECT [lu] AS [lu23], SUM([Shape].STArea()/43560) AS [acres23] 
                       FROM [WS].[gis].[LUDU2023_DRAFT_20240223]
                       GROUP BY [lu] 
               ) AS b ON [lu22] = [lu23] 
         ) 
  
SELECT * 
 FROM lu_CTE 
 WHERE [diff23-22] > 500 
   OR [diff23-22] < -500  
   OR [diff23-22] is null 
ORDER BY [diff23-22]