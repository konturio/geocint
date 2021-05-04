drop table if exists hrsl_population_boundary;
create table hrsl_population_boundary as (
    select gid, gid_0 as iso, name_0 as name, ST_Subdivide(geom) as geom
    from gadm_countries_boundary c
    where gid_0 in ('ABW', 'AGO', 'AIA', 'ALB', 'AND', 'ARE', 'ARG', 'ARM',
                    'ASM', 'ATF', 'ATG', 'AUT', 'BDI', 'BEL', 'BEN', 'BES',
                    'BFA', 'BGD', 'BGR', 'BHR', 'BHS', 'BIH', 'BLM', 'BLR',
                    'BLZ', 'BOL', 'BRB', 'BRN', 'BTN', 'BVT', 'BWA', 'CAF',
                    'CCK', 'CHE', 'CHL', 'CIV', 'CMR', 'COD', 'COG', 'COK',
                    'COL', 'COM', 'CPV', 'CRI', 'CXR', 'CYM', 'CZE', 'DEU',
                    'DJI', 'DMA', 'DNK', 'DZA', 'ECU', 'EGY', 'ERI', 'ESP',
                    'EST', 'FIN', 'FJI', 'FRA', 'FRO', 'FSM', 'GAB', 'GBR',
                    'GEO', 'GGY', 'GHA', 'GIB', 'GIN', 'GLP', 'GMB', 'GNB',
                    'GNQ', 'GRC', 'GRD', 'GRL', 'GTM', 'GUF', 'GUM', 'GUY',
                    'HKG', 'HMD', 'HND', 'HRV', 'HTI', 'IDN', 'IMN', 'IRL',
                    'IRQ', 'ISL', 'ITA', 'JAM', 'JEY', 'JOR', 'JPN', 'KAZ',
                    'KGZ', 'KHM', 'KIR', 'KNA', 'KOR', 'KWT', 'LAO', 'LBN',
                    'LBR', 'LCA', 'LIE', 'LKA', 'LSO', 'LTU', 'LUX', 'LVA',
                    'MAC', 'MAF', 'MCO', 'MDA', 'MDG', 'MDV', 'MEX', 'MHL',
                    'MKD', 'MLI', 'MLT', 'MNG', 'MNP', 'MOZ', 'MRT', 'MSR',
                    'MUS', 'MYS', 'MYT', 'NAM', 'NCL', 'NER', 'NGA', 'NIC',
                    'NLD', 'NOR', 'NPL', 'NRU', 'NZL', 'OMN', 'PAK', 'PAN',
                    'PER', 'PHL', 'PLW', 'PNG', 'PRI', 'PRT', 'PRY', 'PSE',
                    'PYF', 'QAT', 'REU', 'ROU', 'RWA', 'SAU', 'SEN', 'SGP',
                    'SLB', 'SLE', 'SLV', 'SMR', 'SPM', 'SSD', 'STP', 'SUR',
                    'SVN', 'SWE', 'SWZ', 'SXM', 'SYC', 'TCA', 'TCD', 'TGO',
                    'THA', 'TJK', 'TKM', 'TLS', 'TTO', 'TUN', 'TUR', 'TUV',
                    'TWN', 'TZA', 'UGA', 'UMI', 'URY', 'USA', 'UZB', 'VAT',
                    'VCT', 'VGB', 'VIR', 'VNM', 'VUT', 'WSM', 'XCL', 'ZAF')
);
