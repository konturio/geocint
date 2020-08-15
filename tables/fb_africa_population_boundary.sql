drop table if exists fb_africa_population_boundary;
create table fb_africa_population_boundary as (
    select gid, gid_0 as iso, name_0 as name, ST_Subdivide(geom) as geom
    from
        gadm_countries_boundary c
    where
            gid_0 in
            ('AGO', 'BDI', 'BEN', 'BFA', 'BWA', 'CAF', 'CIV', 'CMR', 'COD', 'COG', 'COM', 'DJI', 'DZA', 'EGY', 'ERI',
             'ESH', 'ESP', 'GAB', 'GHA', 'GIN', 'GMB', 'GNB', 'GNQ', 'KEN', 'LBR', 'LBY', 'LSO', 'MDG', 'MLI', 'MOZ',
             'MRT', 'MUS', 'MWI', 'MYT', 'NAM', 'NER', 'NGA', 'PRT', 'REU', 'RWA', 'SEN', 'SLE', 'STP', 'SWZ', 'SYC',
             'TCD', 'TGO', 'TUN', 'TZA', 'UGA', 'ZAF', 'ZMB', 'ZWE'
            )
);

