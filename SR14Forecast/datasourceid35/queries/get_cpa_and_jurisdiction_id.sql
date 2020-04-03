USE demographic_warehouse;

SELECT  jurisdiction as geozone,jurisdiction_id as id
FROM [demographic_warehouse].[dim].[mgra_denormalize]
WHERE series = 14
--GROUP BY jurisdiction,jurisdiction_id;
UNION 
SELECT  cpa as geozone,cpa_id as geo_id
FROM [demographic_warehouse].[dim].[mgra_denormalize]
WHERE series = 14
GROUP BY cpa,cpa_id,jurisdiction,jurisdiction_id
ORDER BY id


--select 19 + 87 + 1 --(not in a cpa) = 107

