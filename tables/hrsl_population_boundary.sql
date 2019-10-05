create table hrsl_population_boundary as (
  select gid, gid_0 as iso, name_0 as name, geom 
    from gadm_countries_boundary c 
    where gid_0 in ( 'PHL', 'IDN', 'KHM', 'THA', 'LKA', 'ARG',  'HTI', 'GTM', 'MEX')
);

