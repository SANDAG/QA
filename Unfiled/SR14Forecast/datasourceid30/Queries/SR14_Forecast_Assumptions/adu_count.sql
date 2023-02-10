
USE urbansim;

SELECT COUNT(*) 
FROM [urbansim].[urbansim].[urbansim_lite_output]
WHERE run_id = 444 and capacity_type = 'adu'

-- TWG on 8/9/2018: Assume that ADUs will be allocated to 5 percent of all available 
--lots that are 5,000 square feet or larger in the region -
-- the result is approximately 24,000 ADUs in the region by 2050

-- compare to actual of 14,303
