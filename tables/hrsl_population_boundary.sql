drop table if exists hrsl_population_boundary;
create table hrsl_population_boundary as (
    select gid, gid_0 as iso, name_0 as name, ST_Subdivide(geom) as geom
    from gadm_countries_boundary c
    where gid_0 not in ('RUS', 'CAN', 'UKR', 'POL', 'HUN', 'SRB', 'MNE', 'CYP', 'XNC', 'SYR', 'AZE',
                        'IRN', 'AFG', 'IND', 'ISR', 'YEM', 'CHN', 'MMR', 'PRK', 'AUS', 'ETH', 'KEN',
                        'SOM', 'ZMB', 'MWI', 'ZWE', 'SDN', 'LBY', 'ESH', 'MAR', 'BRA', 'VEN', 'CUB',
                        'DOM', 'MTQ', 'CUW', 'SVK', 'WLF', 'TON', 'NIU', 'BMU', 'XCA', 'XKO', 'ATA',
                        'FLK', 'NFK', 'ALA', 'TKL', 'SJM', 'SHN', 'SGS', 'PCN', 'XPI', 'XSP', 'XAD',
                        'IOT')
);
