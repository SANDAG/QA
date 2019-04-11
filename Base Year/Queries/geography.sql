WITH jur_names as (SELECT zone,name as jur_name FROM [data_cafe].[ref].[geography_zone] 
where geography_type_id = 150),
city_cpa_names as (SELECT zone,name as city_cpa_name FROM [data_cafe].[ref].[geography_zone] 
where geography_type_id = 147),
county_cpa_names as (SELECT zone,name as county_cpa_name FROM [data_cafe].[ref].[geography_zone] 
where geography_type_id = 148)
SELECT  [mgra_13] as mgra
      ,[taz_13]
       ,[tract_2010]
      ,COALESCE(cocpa_2016,cicpa_2016,jurisdiction_2016) as jurisdiction_and_cpa
         ,COALESCE(county_cpa_name,city_cpa_name,jur_name) as jurisdiction_and_cpa_name
      ,[jurisdiction_2016] as jurisdiction
      , jur_name as jurisdiction_name
  FROM [data_cafe].[ref].[vi_xref_geography_mgra_13]
  JOIN  jur_names ON jur_names.zone = jurisdiction_2016
  LEFT JOIN city_cpa_names ON city_cpa_names.zone = cicpa_2016
  LEFT JOIN county_cpa_names ON county_cpa_names.zone = cocpa_2016
