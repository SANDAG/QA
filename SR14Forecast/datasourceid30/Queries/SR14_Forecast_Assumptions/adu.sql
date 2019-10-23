SELECT [parcel_id]
		 ,centroid.STY as Y, centroid.STX as X 
      ,[development_type_id_2015]
      ,round([parcel_acres],4) as parcel_acres
      ,[mgra_id]
      ,[jurisdiction_id]
      ,[zone]
      ,[du_2015]
      ,[capacity_1]
      ,[cap_jurisdiction_id]
      ,[cap_source]
      ,[site_id]
      ,[du_2017]
      ,[max_res_units_2015]
      ,[capacity_2_2015]
      ,[cpa_jurisdiction_id]
      ,[lu_2015]
      ,[lu_2017]
      ,[development_type_id_2017]
      ,[lu_2017_p]
      ,[jurisdiction_id_zoning]
      ,[lu_2017_xref]
      ,[development_type_id_2017_xref]
      ,[capacity_2]
      ,[max_res_units_2017]
      ,[du_2018]
      ,[capacity_2_2017]
      ,[max_res_units_2018]
      ,[lu_2018]
      ,[development_type_id_2018]
  FROM [urbansim].[urbansim].[parcel]
  WHERE parcel_id IN (SELECT parcel_id FROM [urbansim].[urbansim].[urbansim_lite_output]
						WHERE run_id = 444 and capacity_type = 'adu') 

--    43560 * parcel_acres >= 5000  and (du_2018 = 1) and  
--    and jurisdiction_id != 19 

--14303

