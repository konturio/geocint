drop table if exists bivariate_indicators;
create table bivariate_indicators
(
    param_id   text,
    param_label text,
    copyrights json,
    direction json,
    is_base boolean not null default false,
    description text,
    coverage text,
    update_frequency text,
    is_public boolean,
    application json,
    unit_id text
);

alter table bivariate_indicators
    set (parallel_workers = 32);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('one', '1', '["Numbers © Muḥammad ibn Mūsā al-Khwārizmī"]'::json, '[["neutral"], ["neutral"]]'::jsonb, '', 'World', 'static', NULL, FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('area_km2', 'Area', '["Concept of areas © Brahmagupta, René Descartes"]'::json, '[["neutral"], ["neutral"]]'::jsonb, '', 'World', 'static', 'km2', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('populated_area_km2', 'Populated area', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping',
        'Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, '', 'World', 'daily', 'km2', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('count', 'OSM: objects count', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total number of objects in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('count_6_months', 'OSM: objects mapped (6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of objects mapped in OpenStreetMap in the last 6 months.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('view_count', 'OSM: map views (last 30 days)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Number of tile requests in a given area for the last 30 days.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('avgmax_ts', 'OSM: last edit (avg)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good"]]'::jsonb, 'Average of latest OpenStreetMap edit dates in a given area.', 'World', 'daily', 'unixtime', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('max_ts', 'OSM: last edit', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good"]]'::jsonb, 'Date of latest OpenStreetMap edit in a given area at highest resolution.', 'World', 'daily', 'unixtime', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('min_ts', 'OSM: first edit', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["good"], ["neutral"]]'::jsonb, 'Date of earliest OpenStreetMap edit in a given area.', 'World', 'daily', 'unixtime', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('osm_users', 'OSM: contributors count', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of users who have edited a given area in OpenStreetMap.', 'World', 'daily', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('building_count', 'OSM: buildings count', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total number of buildings in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('building_count_6_months', 'OSM: new buildings (last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of buildings mapped in OpenStreetMap in the last 6 months.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('highway_length', 'OSM: road length', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total length of roads in a given area according to OpenStreetMap.', 'World', 'daily', 'km', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('highway_length_6_months', 'OSM: new road length (last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Length of roads mapped in OpenStreetMap in the last 6 months.', 'World', 'daily', 'km', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('local_hours', 'OSM: local contributor activity', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of OpenStreetMap mapping hours by active local mappers in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object. Mapper is considered active if they contributed more than 30 mapping hours in the last 2 years. The position of the active mapper is estimated by the region of their highest activity.', 'World', 'daily', 'h', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('total_hours', 'OSM: contributor activity', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total number of OpenStreetMap mapping hours by all users in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object.', 'World', 'daily', 'h', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('forest', 'Landcover: forest', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by forest - where tree canopy is more than 15%.', 'World', 'static', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('evergreen_needle_leaved_forest', 'Landcover: evergreen needleleaf forest', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by either closed or open evergreen needleleaf forest. Almost all needleleaf trees remain green all year. Canopy is never without green foliage. Closed forest has tree canopy >70%. Open forest has top layer - trees 15-70 % - and second layer - mix of shrubs and grassland.', 'World', 'static', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('shrubs', 'Landcover: shrubland', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Shrubland, or area where vegetation is dominated by woody perennial plants generally less than 5 meters in height, with persistent and woody stems and without any defined main stem. The shrub foliage can be either evergreen or deciduous.', 'World', 'static', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('herbage', 'Landcover: herbaceous vegetation', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by herbaceous plants. These plants have no persistent woody stems above ground and lack definite firm structure. Tree and shrub cover is less than 10%.', 'World', 'static', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('unknown_forest', 'Landcover: unknown forest type', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by forest that does not match defined forest types.', 'World', 'static', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('gdp', 'Gross Domestic Product', jsonb_build_array(
'© Kontur https://kontur.io/',
'© 2019 The World Bank Group, CC-BY 4.0',
                                 'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
                                 'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
                                 'Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
                                 'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
                                 '@ OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad"], ["good"]]'::jsonb, 'A country GDP (Gross Domestic Product) per capita multiplied by the population in a given area. For areas covering multiple countries, a sum of their respective GDP portions is used. GDP is the standard measure of the value created through the production of goods and services in a country during a certain period.', 'World', 'static', 'USD', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('population', 'Population', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping',
        'Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of people living in a given area according to Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data. The datasets detailed methodology is available here: https://data.humdata.org/dataset/kontur-population-dataset', 'World', 'daily', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('population_prev', 'Population (previous version)', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping',
        'Unconstrained Individual countries 2020 (100m resolution): WorldPop - https://www.worldpop.org/',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, '', 'World', 'daily', 'ppl', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('total_building_count', 'Total buildings count', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Estimated number of buildings in a given area based on various data sources.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('wildfires', 'Wildfire days', jsonb_build_array(
'© NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002',
    'NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi:10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002',
    'MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14DL. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006',
    'MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14ML. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14ML'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days per year when a thermal anomaly was recorded in the last 13 months.', 'World', 'daily', 'days', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('hazardous_days_count', 'Exposure: all disaster types', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme disasters of any types were recorded.', 'World', 'daily', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('earthquake_days_count', 'Exposure: earthquake', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme earthquakes were recorded.', 'World', 'daily', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('drought_days_count', 'Exposure: drought', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme droughts were recorded.', 'World', 'daily', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('cyclone_days_count', 'Exposure: cyclone', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme cyclones were recorded.', 'World', 'daily', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('wildfire_days_count', 'Exposure: wildfire', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme wildfires were recorded.', 'World', 'daily', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('volcano_days_count', 'Exposure: volcanic eruption', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme volcanos were recorded.', 'World', 'daily', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('flood_days_count', 'Exposure: flood', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme floods were recorded. ', 'World', 'daily', 'days', TRUE);
/*
insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('covid19_vaccines', 'COVID19 Vaccine Acceptance', jsonb_build_array(
'© Data from Delphi COVIDcast, covidcast.cmu.edu'),
    '[["bad"], ["neutral"]]'::jsonb);*/

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('covid19_confirmed', 'COVID-19 confirmed сases', jsonb_build_array(
'© Data from JHU CSSE COVID-19 Dataset'),
   '[["good"], ["bad"]]'::jsonb, 'Number of COVID-19 confirmed cases for the entire observation period according to the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (JHU).', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('avg_slope_gebco_2022', 'Slope (avg)', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Average surface slope.', 'World', 'static', 'deg', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('avg_elevation_gebco_2022', 'Elevation (avg)', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Average surface elevation in meters.',  'World', 'static', 'm', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('avg_ndvi', 'NDVI (avg)', jsonb_build_array(
'© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel'),
    '[["bad"], ["good"]]'::jsonb, 'Average values of Normalized Difference Vegetation Index (NDVI), as of June 2019. Negative values of NDVI (values approaching -1) correspond to water. Values close to zero (-0.1 to 0.1) generally correspond to barren areas of rock, sand, or snow. Low, positive values represent shrub and grassland (approximately 0.2 to 0.4), while high values indicate temperate and tropical rainforests (values approaching 1).', 'World', 'static', 'index', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('industrial_area', 'OSM: industrial area', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Areas of land used for industrial purposes, which may include facilities such as workshops, factories and warehouses, and their associated infrastructure (car parks, service roads, yards, etc.).', 'World', 'daily', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('volcanos_count', 'OSM: volcanoes count', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of volcanoes in a given area.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('pop_under_5_total', 'Population: under 5', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of children (ages 0-5) in the United States.', 'The United States of America', 'static', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('pop_over_65_total', 'Population: over 65', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of elderly people (ages 65+) in the United States.', 'The United States of America', 'static', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('poverty_families_total', 'Population: families below poverty line', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant", "good"], ["important"]]'::jsonb, 'Number of households living below the poverty line in the United States.', 'The United States of America', 'static', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('pop_disability_total', 'Population: with disabilities', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of people with disabilities in the United States based on the U.S. Census Bureaus American Community Survey (ACS). This page describes how disability is defined and collected in the ACS: https://www.census.gov/topics/health/disability/guidance/data-collection-acs.html', 'The United States of America', 'static', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('pop_not_well_eng_speak', 'Population: limited English proficiency', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["good"], ["important", "bad"]]'::jsonb, 'Number of people who have difficulty speaking English in the United States.', 'The United States of America', 'static', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('pop_without_car', 'Population: without a car', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["neutral"], ["important"]]'::jsonb, 'Number of working people without a car in the United States.', 'The United States of America', 'static', 'ppl', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('days_maxtemp_over_32c_1c', 'Days above 32°C (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the "recent" climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).', 'World (-60:60 latitudes)', 'static', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('days_maxtemp_over_32c_2c', 'Days above 32°C (+2°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the "potential" climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('days_mintemp_above_25c_1c', 'Nights above 25°C (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the "recent" climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions.', 'World (-60:60 latitudes)', 'static', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('days_mintemp_above_25c_2c', 'Nights above 25°C (+2°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the "potential" climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions. 
The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('days_maxwetbulb_over_32c_1c', 'Days above 32°C wet-bulb (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the "recent" climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F)  and 55% humidity.', 'World (-60:60 latitudes)', 'static', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('days_maxwetbulb_over_32c_2c', 'Days above 32°C wet-bulb (+2°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the "potential" climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F)  and 55% humidity.
The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('mandays_maxtemp_over_32c_1c', 'Man-days above 32°C, (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'other', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('man_distance_to_fire_brigade', 'Man-distance to fire brigade', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'other', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('man_distance_to_hospital', 'Man-distance to hospitals', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'other', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('man_distance_to_bomb_shelters', 'Man-distance to bomb shelters', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'other', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('man_distance_to_charging_stations', 'Man-distance to charging stations', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'other', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('total_road_length', 'Total road length', jsonb_build_array(
        '©2019 Facebook, Inc. and its affiliates https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/blob/main/LICENSE.md',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright', '© Kontur https://kontur.io/'),
        '[["unimportant"], ["important"]]'::jsonb, 'Estimated total road length according to Meta (Facebook) AI and OpenStreetMap data. For places where Meta (Facebook) roads data are unavailable, the estimation is based on statistical regression from Kontur Population data.', 'World', 'daily', 'km', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('foursquare_places_count', 'Foursquare Japan places count', jsonb_build_array(
        '©Foursquare Labs Inc',
        'Sample data'),
        '[["unimportant"], ["important"]]'::jsonb, '', 'Japan', 'static', 'n', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('foursquare_visits_count', 'Foursquare Japan visits count', jsonb_build_array(
        '©Foursquare Labs Inc',
        'Sample data'),
        '[["unimportant"], ["important"]]'::jsonb, '', 'Japan', 'static', 'n', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('view_count_bf2402', 'OSM: map views (Jan 25 - Feb 24, 2022)',
        jsonb_build_array('© Kontur', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Number of tile requests in a given area for the 30 days before Feb 24, 2022.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('powerlines', 'Medium-voltage powerlines distribution (predictive)', jsonb_build_array(
        '©9999 Facebook, Inc. and its affiliates https://dataforgood.facebook.com/dfg/tools/electrical-distribution-grid-maps'),
        '[["bad"], ["good"]]'::jsonb, 'Facebook has produced a model to help map global medium voltage (MV) grid infrastructure, i.e. the distribution lines which connect high-voltage transmission infrastructure to consumer-serving low-voltage distribution. The data found here are model outputs for six select African countries: Malawi, Nigeria, Uganda, DRC, Cote D’Ivoire, and Zambia. The grid maps are produced using a new methodology that employs various publicly-available datasets (night time satellite imagery, roads, political boundaries, etc) to predict the location of existing MV grid infrastructure.', 'World', 'static', 'other', FALSE);

-- We use unimportant - important+bad for Multi-hazard risk, Multi-hazard exposure and Vulnerability 
-- because PDC does something only about regions that are under disasters
-- Also for this reason we use important+bad - good for Coping capacity and Resilience
-- We used https://test.pdc.org/risk-and-vulnerability/ as example in index estimation process

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('mhr_index', 'PDC GRVA Multi-hazard risk', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["unimportant"], ["important", "bad"]]'::jsonb, '', 'World', 'static', 'index', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('mhe_index', 'PDC GRVA Multi-hazard exposure', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["unimportant"], ["important", "bad"]]'::jsonb, '', 'World', 'static', 'index', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('coping_capacity_index', 'PDC GRVA Coping сapacity', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["important", "bad"], ["good"]]'::jsonb, '', 'World', 'static', 'index', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('resilience_index', 'PDC GRVA Resilience', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["important", "bad"], ["good"]]'::jsonb, '', 'World', 'static', 'index', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('vulnerability_index', 'PDC GRVA Vulnerability', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["unimportant"], ["important", "bad"]]'::jsonb, '', 'World', 'static', 'index', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('night_lights_intensity', 'Nighttime lights intensity', jsonb_build_array(
        'Earth Observation Group © 2021. https://eogdata.mines.edu/products/vnl/#reference',
        'C. D. Elvidge, K. E. Baugh, M. Zhizhin, and F.-C. Hsu, “Why VIIRS data are superior to DMSP for mapping nighttime lights,” Asia-Pacific Advanced Network 35, vol. 35, p. 62, 2013.',
        'C. D. Elvidge, M. Zhizhin, T. Ghosh, F-C. Hsu, "Annual time series of global VIIRS nighttime lights derived from monthly averages: 2012 to 2019", Remote Sensing (In press)'),
        '[["unimportant"], ["important"]]'::jsonb, 'Remote sensing of nighttime light emissions offers a unique perspective for investigations into human behaviors. The Visible Infrared Imaging Radiometer Suite (VIIRS) instruments aboard the Suomi NPP and NOAA-20 satellites provide global daily measurements of nighttime light.', 'World', 'static', 'nW_cm2_sr', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('eatery_count', 'OSM: eatery places count', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of places where you can buy and eat food (such as restaurants, cafés, fast-food outlets, etc.) in a given area.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('food_shops_count', 'OSM: food shops count', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of places where you can buy fresh or packaged food products in a given area.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('mapswipe_area_km2', 'Human activity ', jsonb_build_array(
        'Copyright © 2022 MapSwipe https://mapswipe.org/en/privacy.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Places were MapSwipe users have detected some human activity through features (i.e. buildings, roadways, waterways, etc.) on satellite images.', 'World', 'daily', 'km2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('gsa_ghi', 'Global Horizontal Irradiance (GHI)', jsonb_build_array(
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Total amount of shortwave terrestrial irradiance received by a surface horizontal to the ground.', 'World (-60:60 latitudes)', 'static', 'W_m2', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('worldclim_avg_temperature', 'Air temperature (avg)', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["good"], ["bad"]]'::jsonb, 'Monthly average air temperature according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('worldclim_min_temperature', 'Air temperature (min)', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["bad"], ["good"]]'::jsonb, 'Monthly minimum air temperature according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('worldclim_max_temperature', 'Air temperature (max)', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["good"], ["bad"]]'::jsonb, 'Monthly maximum air temperature according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('worldclim_amp_temperature', 'Air temperature (amplitude)', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["good"], ["bad"]]'::jsonb, 'Monthly amplitude of air temperatures according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('powerlines_proximity_m', 'Proximity to: powerlines grid', jsonb_build_array(
        'Copyright © OpenStreetMap contributors https://www.openstreetmap.org/copyright',
        '© 2020 The World Bank Group, CC-BY 4.0'),
        '[["important"], ["unimportant"]]'::jsonb, 'Distance to closest powerline', 'World', 'static', 'm', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('waste_basket_coverage_area_km2', 'OSM: waste containers count', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad"], ["good"]]'::jsonb, 'Number of waste containers in a given area.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('populated_areas_proximity_m', 'Proximity to densely populated areas', jsonb_build_array(
        'Copyright © Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, 'Distance to closest Kontur Population cell with population > 80 ppl', 'World', 'daily', 'm', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('power_substations_proximity_m', 'Proximity to power substations, m', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, 'Distance to closest power substation', 'World', 'daily', 'm', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('solar_farms_placement_suitability', 'Suitability estimation for solar farms placement', jsonb_build_array(
        'Copyright © Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright',
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html', 
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad"], ["good"]]'::jsonb, 'Multi-criteria analysis based layer dedicated to estimation of suitability of solar farms placement. 0 means absolutely unsuitable, 1 means perfectly suitable. Analysis is based on solar irradiace, powerlines grid proximity, power substations proximity, elevation slope, minimal and maximal temperatures, populated areas proximity', 'World (-60:60 latitudes)', 'daily', 'index', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('residential', 'Percentage of permanent population', jsonb_build_array(
        'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016'),
        '[["unimportant"], ["important"]]'::jsonb, 'Estimation of residential population percentage according to GHS-POP dataset (2015)', 'World', 'static', 'fract', FALSE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('solar_power_plants', 'Solar power plants', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Total number of solar power plants in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public)
values ('safety_index', 'Safety (Global Peace Index 2022)', jsonb_build_array(
        '© The Institute for Economics and Peace Limited 2022 https://www.visionofhumanity.org/'),
        '[["good"], ["bad"]]'::jsonb, 'The Global Peace Index covers 99.7% of the world’s population, and is calculated using 23 qualitative and quantitative indicators from highly respected sources, and measures the state of peace across three domains: the level of Societal Safety and Security, the extent of Ongoing Domestic and International Conflict, and the degree of Militarisation.', 'World', 'static', 'index', TRUE);

-- set indicator is_base to become denominators
update bivariate_indicators
set is_base = true
where param_id in ('population', 'area_km2', 'one'); -- experiment with disabling three base indicators/denominators
-- where param_id in ('population', 'total_building_count', 'area_km2', 'populated_area_km2', 'one', 'total_road_length');

--- this is an ugly hack to enable Parallel Seq Scan on bivariate_indicators
-- Postgres parallel seq scan works on page level, so we can't really get it to run more workers than there are
-- pages in source table, so we make sure that the pages are filled in as sparsely as possible.
alter table bivariate_indicators set (fillfactor = 10);
alter table bivariate_indicators add column baloon text;
alter table bivariate_indicators alter column baloon set storage external;
alter table bivariate_indicators alter column copyrights set storage external;
update bivariate_indicators set baloon = repeat(' ', 3000);
vacuum full bivariate_indicators;
alter table bivariate_indicators drop column baloon;