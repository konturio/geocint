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
    unit_id text,
    emoji text,
    downscale text
);

alter table bivariate_indicators
    set (parallel_workers = 32);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('one', '1', '["Numbers © Muḥammad ibn Mūsā al-Khwārizmī"]'::json, '[["neutral"], ["neutral"]]'::jsonb, '', 'World', 'static', NULL, TRUE, '1️⃣', NULL);

-- area is mostly used in denominator so start the name as lowercase to build better sentences
insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('area_km2', 'area', '["Concept of areas © Brahmagupta, René Descartes"]'::json, '[["neutral"], ["neutral"]]'::jsonb, '', 'World', 'static', 'km2', TRUE, '📐', NULL);

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('populated_area_km2_next_gen', 'populated area (next generation)', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina M., Freire S., Carioli A., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030).European Commission, Joint Research Centre (JRC) PID: http://data.europa.eu/89h/2ff68a52-5b5b-4a22-8f40-c41da8332cfe, doi:10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE Concept & Methodology: Freire S., MacManus K., Pesaresi M., Doxsey-Whitfield E., Mills J. (2016) Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE), AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva, Tashkent, Bukhara, Samarkand, Navoi, Chirchiq - https://github.com/Geoalert/urban-mapping',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Populated area according to the most recent daily build of Kontur Population dataset', 'World', 'daily', 'km2', TRUE, '🏡','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('populated_area_km2', 'populated area', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina M., Freire S., Carioli A., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030).European Commission, Joint Research Centre (JRC) PID: http://data.europa.eu/89h/2ff68a52-5b5b-4a22-8f40-c41da8332cfe, doi:10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE Concept & Methodology: Freire S., MacManus K., Pesaresi M., Doxsey-Whitfield E., Mills J. (2016) Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE), AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva, Tashkent, Bukhara, Samarkand, Navoi, Chirchiq - https://github.com/Geoalert/urban-mapping',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Populated area according to the actual release of Kontur Population dataset (2023.11.01).', 'World', 'daily', 'km2', TRUE, '🏡','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('population_next_gen', 'population (next generation)', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina M., Freire S., Carioli A., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030).European Commission, Joint Research Centre (JRC) PID: http://data.europa.eu/89h/2ff68a52-5b5b-4a22-8f40-c41da8332cfe, doi:10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE Concept & Methodology: Freire S., MacManus K., Pesaresi M., Doxsey-Whitfield E., Mills J. (2016) Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE), AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva, Tashkent, Bukhara, Samarkand, Navoi, Chirchiq - https://github.com/Geoalert/urban-mapping',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of people living in a given area according to the most recent daily build of Kontur Population dataset. The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data. The datasets detailed methodology is available here: https://data.humdata.org/dataset/kontur-population-dataset', 'World', 'daily', 'ppl', TRUE, '👫','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('population', 'population', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
        'Dataset: Schiavina M., Freire S., Carioli A., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030).European Commission, Joint Research Centre (JRC) PID: http://data.europa.eu/89h/2ff68a52-5b5b-4a22-8f40-c41da8332cfe, doi:10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE Concept & Methodology: Freire S., MacManus K., Pesaresi M., Doxsey-Whitfield E., Mills J. (2016) Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE), AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva, Tashkent, Bukhara, Samarkand, Navoi, Chirchiq - https://github.com/Geoalert/urban-mapping',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of people living in a given area according to the actual release of Kontur Population dataset (2023.11.01). The dataset was produced by overlaying the Global Human Settlement Layer (GHSL) with available Facebook population data and constraining known artifacts using OpenStreetMap data. The datasets detailed methodology is available here: https://data.humdata.org/dataset/kontur-population-dataset', 'World', 'daily', 'ppl', TRUE, '👫','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('count', 'OSM objects', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total number of objects in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🧱','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('count_6_months', 'OSM objects (edited in last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of objects mapped in OpenStreetMap in the last 6 months.', 'World', 'daily', 'n', TRUE, '🧱🆕','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('view_count', 'OSM map views (last 30 days)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Number of tile requests in a given area for the last 30 days.', 'World', 'daily', 'n', TRUE, '🗺️🆕','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avgmax_ts', 'OSM last edit (avg)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good"]]'::jsonb, 'Average of latest OpenStreetMap edit dates in a given area.', 'World', 'daily', 'unixtime', TRUE, '🕓👥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('max_ts', 'OSM last edit', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good"]]'::jsonb, 'Date of latest OpenStreetMap edit in a given area at highest resolution.', 'World', 'daily', 'unixtime', TRUE, '🕓','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('min_ts', 'OSM first edit', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["good"], ["neutral"]]'::jsonb, 'Date of earliest OpenStreetMap edit in a given area.', 'World', 'daily', 'unixtime', TRUE, '🕒','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_users', 'OSM contributors', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of users who have edited a given area in OpenStreetMap.', 'World', 'daily', 'ppl', TRUE, '👥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('building_count', 'OSM buildings', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total number of buildings in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏠','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('building_count_6_months', 'OSM buildings (edited in last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of buildings mapped in OpenStreetMap in the last 6 months.', 'World', 'daily', 'n', TRUE, '🏠🆕','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('highway_length', 'OSM road length', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total length of roads in a given area according to OpenStreetMap.', 'World', 'daily', 'km', TRUE, '🛣️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('highway_length_6_months', 'OSM road length (edited in last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Length of roads mapped in OpenStreetMap in the last 6 months.', 'World', 'daily', 'km', TRUE, '🛣️🆕','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('local_hours', 'OSM local contributor activity', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of OpenStreetMap mapping hours by active local mappers in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object. Mapper is considered active if they contributed more than 30 mapping hours in the last 2 years. The position of the active mapper is estimated by the region of their highest activity.', 'World', 'daily', 'h', TRUE, '⏰👤','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('total_hours', 'OSM contributor activity', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Total number of OpenStreetMap mapping hours by all users in the last 2 years. A mapping hour is an hour in which a user uploaded at least one tagged object.', 'World', 'daily', 'h', TRUE, '⏰','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('forest', 'Forest landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by forest - where tree canopy is more than 15%.', 'World', 'static', 'km2', TRUE, '🌳','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('evergreen_needle_leaved_forest', 'Evergreen needleleaf forest landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by either closed or open evergreen needleleaf forest. Almost all needleleaf trees remain green all year. Canopy is never without green foliage. Closed forest has tree canopy >70%. Open forest has top layer - trees 15-70 % - and second layer - mix of shrubs and grassland.', 'World', 'static', 'km2', TRUE, '🌲','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('shrubs', 'Shrubland landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Shrubland, or area where vegetation is dominated by woody perennial plants generally less than 5 meters in height, with persistent and woody stems and without any defined main stem. The shrub foliage can be either evergreen or deciduous.', 'World', 'static', 'km2', TRUE, '🌵','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('herbage', 'Herbaceous vegetation landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by herbaceous plants. These plants have no persistent woody stems above ground and lack definite firm structure. Tree and shrub cover is less than 10%.', 'World', 'static', 'km2', TRUE, '🌿','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('unknown_forest', 'Unknown forest type landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Area covered by forest that does not match defined forest types.', 'World', 'static', 'km2', TRUE, '🤔🌲','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('cropland', 'Cropland landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Cropland, Lands covered with temporary crops followed by harvest and a bare soil period (e.g., single and multiple cropping systems). Note that perennial woody crops will be classified as the appropriate forest or shrub land cover type.', 'World', 'static', 'km2', TRUE, '🌱','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('wetland', 'Landcover wetland', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Wetland, Lands with a permanent mixture of water and herbaceous or woody vegetation. The vegetation can be present in either salt, brackish, or fresh water.', 'World', 'static', 'km2', TRUE, '🐸💦','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('moss_lichen', 'Landcover moss and lichen', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Land with moss and lichen coverage.', 'World', 'static', 'km2', TRUE, '🍄','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('bare_vegetation', 'Landcover bare vegetation', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Bare or sparse vegetation. Lands with exposed soil, sand, or rocks and never has more than 10 % vegetated cover during any time of the year.', 'World', 'static', 'km2', TRUE, '🌾','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('builtup', 'Landcover builtup', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Land covered by buildings and other man-made structures.', 'World', 'static', 'km2', TRUE, '🏙️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('snow_ice', 'Landcover snow and ice', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Snow and Ice. Lands under snow or ice cover throughout the year.', 'World', 'static', 'km2', TRUE, '❄️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('permanent_water', 'Permanent water landcover', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb, 'Permanent water bodies. Lakes, reservoirs, and rivers. Can be either fresh or salt-water bodies.', 'World', 'static', 'km2', TRUE, '💧','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('gdp', 'Gross Domestic Product', jsonb_build_array(
'© Kontur https://kontur.io/',
'© 2019 The World Bank Group, CC-BY 4.0',
                                 'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
                                 'Dataset: Schiavina M., Freire S., Carioli A., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030).European Commission, Joint Research Centre (JRC) PID: http://data.europa.eu/89h/2ff68a52-5b5b-4a22-8f40-c41da8332cfe, doi:10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE Concept & Methodology: Freire S., MacManus K., Pesaresi M., Doxsey-Whitfield E., Mills J. (2016) Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE), AGILE 2016',
                                 'Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
                                 'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
                                 '@ OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad"], ["good"]]'::jsonb, 'A country GDP (Gross Domestic Product) per capita multiplied by the population in a given area. For areas covering multiple countries, a sum of their respective GDP portions is used. GDP is the standard measure of the value created through the production of goods and services in a country during a certain period.', 'World', 'static', 'USD', TRUE, '💰','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('total_building_count', 'buildings', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva, Tashkent, Bukhara, Samarkand, Navoi, Chirchiq - https://github.com/Geoalert/urban-mapping',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Estimated number of buildings in a given area based on various data sources.', 'World', 'daily', 'n', TRUE, '🏘️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('hazardous_days_count', 'All disaster types exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme disasters of any types were recorded.', 'World', 'daily', 'days', TRUE, '🚨📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('earthquake_days_count', 'Earthquake exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme earthquakes were recorded.', 'World', 'daily', 'days', TRUE, '🌍📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('drought_days_count', 'Drought exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme droughts were recorded.', 'World', 'daily', 'days', TRUE, '🏜️📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('cyclone_days_count', 'Cyclone exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme cyclones were recorded.', 'World', 'daily', 'days', TRUE, '🌀📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('wildfire_days_count', 'Wildfire exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme wildfires were recorded.', 'World', 'daily', 'days', TRUE, '🔥📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('wildfires', 'Thermal anomaly exposure', jsonb_build_array(
'© NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002',
    'NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi:10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002',
    'MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14DL. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006',
    'MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14ML. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14ML'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days per year when a thermal anomaly was recorded in the last 13 months.', 'World', 'daily', 'days', TRUE, '🔥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('volcano_days_count', 'Volcano exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme volcanos were recorded.', 'World', 'daily', 'days', TRUE, '🌋📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('flood_days_count', 'Flood exposure', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Number of days in the last year when severe and extreme floods were recorded. ', 'World', 'daily', 'days', TRUE, '🌊📅','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('covid19_confirmed', 'COVID-19 confirmed сases', jsonb_build_array(
'© Data from JHU CSSE COVID-19 Dataset'),
   '[["good"], ["bad"]]'::jsonb, 'Number of COVID-19 confirmed cases for the entire observation period according to the Center for Systems Science and Engineering (CSSE) at Johns Hopkins University (JHU).', 'World', 'daily', 'n', TRUE, '🦠','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avg_slope_gebco_2022', 'Slope', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Average surface slope.', 'World', 'static', 'deg', TRUE, '⛷️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avg_elevation_gebco_2022', 'Elevation', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Average surface elevation in meters.',  'World', 'static', 'm', TRUE, '🏔️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avg_ndvi', 'NDVI', jsonb_build_array(
'© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel'),
    '[["bad"], ["good"]]'::jsonb, 'Average values of Normalized Difference Vegetation Index (NDVI), as of June 2019. Negative values of NDVI (values approaching -1) correspond to water. Values close to zero (-0.1 to 0.1) generally correspond to barren areas of rock, sand, or snow. Low, positive values represent shrub and grassland (approximately 0.2 to 0.4), while high values indicate temperate and tropical rainforests (values approaching 1).', 'World', 'static', 'index', TRUE, '🌿','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('industrial_area', 'OSM Industrial area', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Areas of land used for industrial purposes in OpenStreetMap, which may include facilities such as workshops, factories and warehouses, and their associated infrastructure (car parks, service roads, yards, etc.). Data may be incomplete.', 'World', 'daily', 'km2', TRUE, '🏭','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('volcanos_count', 'Volcanoes', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of volcanoes in a given area.', 'World', 'daily', 'n', TRUE, '🌋','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('pop_under_5_total', 'Population under 5', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of children (ages 0-5) in the United States.', 'The United States of America', 'static', 'ppl', TRUE, '👧👦','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('pop_over_65_total', 'Population over 65', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of elderly people (ages 65+) in the United States.', 'The United States of America', 'static', 'ppl', TRUE, '👴👵','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('poverty_families_total', 'Families below poverty line', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant", "good"], ["important"]]'::jsonb, 'Number of households living below the poverty line in the United States.', 'The United States of America', 'static', 'n', TRUE, '💸','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('pop_disability_total', 'Population with disabilities', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of people with disabilities in the United States based on the U.S. Census Bureaus American Community Survey (ACS). This page describes how disability is defined and collected in the ACS: https://www.census.gov/topics/health/disability/guidance/data-collection-acs.html', 'The United States of America', 'static', 'ppl', TRUE, '♿','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('pop_not_well_eng_speak', 'Population with limited English proficiency', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["good"], ["important", "bad"]]'::jsonb, 'Number of people who have difficulty speaking English in the United States.', 'The United States of America', 'static', 'ppl', TRUE, '🗣️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('pop_without_car', 'Population without a car', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["neutral"], ["important"]]'::jsonb, 'Number of working people without a car in the United States.', 'The United States of America', 'static', 'ppl', TRUE, '👫','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('days_maxtemp_over_32c_1c', 'Days above 32°C (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the ”recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).', 'World (-60:60 latitudes)', 'static', 'days', TRUE, '🌞','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('days_maxtemp_over_32c_2c', 'Days above 32°C (+2°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum temperature exceeding 32°C (90°F) at the ”potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE, '🌞🔥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('days_mintemp_above_25c_1c', 'Nights above 25°C (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the ”recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science).
The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions.', 'World (-60:60 latitudes)', 'static', 'days', TRUE, '🌜','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('days_mintemp_above_25c_2c', 'Nights above 25°C (+2°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily minimum temperature exceeding 25°C (77°F) at the ”potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). The lowest temperature during the day happens at night when temperatures dip after sunset. The human experience of a “hot” night is relative to location, so a threshold of 20°C is often used for higher latitudes (Europe and the US) and a threshold of 25°C is often used for tropical and equatorial regions. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE, '🌜🔥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('days_maxwetbulb_over_32c_1c', 'Days above 32°C wet-bulb (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the ”recent” climate warming scenario of +1.0°C. In 2017 the average surface temperature passed 1.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F)  and 55% humidity. For each warming scenario, the number of days exceeding 32°C (90°F) wet-bulb are identified from daily maximum wet-bulb temperatures computed using daily maximum temperature and daily minimum relative humidity, variables that are projected by climate models. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE, '🌞','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('days_maxwetbulb_over_32c_2c', 'Days above 32°C wet-bulb (+2°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, 'Number of days per year with a daily maximum wet-bulb temperature exceeding 32°C (90°F) at the ”potential” climate warming scenario of +2.0°C. On the current path of emissions, in the 2040s the average surface temperature will likely pass 2.0°C above the pre-industrial 1850-1900 average (a standard baseline time period in climate science). Wet-bulb temperature is calculated using temperature and humidity. High wet-bulb temperatures can impair the human body’s ability to self-cool through sweating. 32°C or 90°F wet-bulb can occur at 32°C (90°F) air temperature and 99% relative humidity, or 40°C (104°F)  and 55% humidity.For each warming scenario, the number of days exceeding 32°C (90°F) wet-bulb are identified from daily maximum wet-bulb temperatures computed using daily maximum temperature and daily minimum relative humidity, variables that are projected by climate models. The displayed values are from a range of simulated years from multiple models. Actual outcomes may prove to be higher or lower than the displayed values.', 'World (-60:60 latitudes)', 'static', 'days', TRUE, '🌞🔥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('mandays_maxtemp_over_32c_1c', 'Man-days above 32°C, (+1°C scenario)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'other', TRUE, '🌞👥','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('man_distance_to_fire_brigade', 'Man-distance to fire brigade', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'ppl_km2', TRUE, '🚒🏃','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('man_distance_to_hospital', 'Man-distance to hospitals', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'ppl_km2', TRUE, '🏥🏃','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('man_distance_to_bomb_shelters', 'Man-distance to bomb shelters', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'ppl_km2', TRUE, '🏠🏃','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('man_distance_to_charging_stations', 'Man-distance to charging stations', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, '', 'World', 'daily', 'ppl_km2', TRUE, '🔌🏃','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('total_road_length', 'road length', jsonb_build_array(
        '©2019 Facebook, Inc. and its affiliates https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/blob/main/LICENSE.md',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright', '© Kontur https://kontur.io/'),
        '[["unimportant"], ["important"]]'::jsonb, 'Estimated total road length according to Meta (Facebook) AI and OpenStreetMap data. For places where Meta (Facebook) roads data are unavailable, the estimation is based on statistical regression from Kontur Population data.', 'World', 'daily', 'km', TRUE, '🛣️📏','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('view_count_bf2402', 'OSM map views (30 days before Feb 24, 2022)',
        jsonb_build_array('© Kontur', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Number of tile requests in a given area for the 30 days before Feb 24, 2022.', 'World', 'daily', 'n', TRUE, '🗺️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('powerlines', 'Medium-voltage powerlines distribution (predictive)', jsonb_build_array(
        '©9999 Facebook, Inc. and its affiliates https://dataforgood.facebook.com/dfg/tools/electrical-distribution-grid-maps'),
        '[["bad"], ["good"]]'::jsonb, 'Facebook has produced a model to help map global medium voltage (MV) grid infrastructure, i.e. the distribution lines which connect high-voltage transmission infrastructure to consumer-serving low-voltage distribution. The data found here are model outputs for six select African countries: Malawi, Nigeria, Uganda, DRC, Cote D’Ivoire, and Zambia. The grid maps are produced using a new methodology that employs various publicly-available datasets (night time satellite imagery, roads, political boundaries, etc) to predict the location of existing MV grid infrastructure.', 'World', 'static', 'other', TRUE, '⚡','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('night_lights_intensity', 'Nighttime lights intensity', jsonb_build_array(
        'Earth Observation Group © 2021. https://eogdata.mines.edu/products/vnl/#reference',
        'C. D. Elvidge, K. E. Baugh, M. Zhizhin, and F.-C. Hsu, “Why VIIRS data are superior to DMSP for mapping nighttime lights,” Asia-Pacific Advanced Network 35, vol. 35, p. 62, 2013.',
        'C. D. Elvidge, M. Zhizhin, T. Ghosh, F-C. Hsu, "Annual time series of global VIIRS nighttime lights derived from monthly averages: 2012 to 2019", Remote Sensing (In press)'),
        '[["unimportant"], ["important"]]'::jsonb, 'Remote sensing of nighttime light emissions offers a unique perspective for investigations into human behaviors. The Visible Infrared Imaging Radiometer Suite (VIIRS) instruments aboard the Suomi NPP and NOAA-20 satellites provide global daily measurements of nighttime light.', 'World', 'static', 'nW_cm2_sr', TRUE, '🌌','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('eatery_count', 'Eatery places', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of places where you can buy and eat food (such as restaurants, cafés, fast-food outlets, etc.) in a given area.', 'World', 'daily', 'n', TRUE, '🍽️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('food_shops_count', 'Food shops', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Number of places where you can buy fresh or packaged food products in a given area.', 'World', 'daily', 'n', TRUE, '🛒','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('mapswipe_area_km2', 'MapSwipe human activity', jsonb_build_array(
        'Copyright © 2022 MapSwipe https://mapswipe.org/en/privacy.html'),
        '[["unimportant"], ["important"]]'::jsonb, 'Places where MapSwipe users have detected some human activity through features (i.e. buildings, roadways, waterways, etc.) on satellite images.', 'World', 'daily', 'km2', TRUE, '👣','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('gsa_ghi', 'Global Horizontal Irradiance', jsonb_build_array(
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Total amount of shortwave terrestrial irradiance received by a surface horizontal to the ground.', 'World (-60:60 latitudes)', 'static', 'W_m2', TRUE, '☀️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('worldclim_avg_temperature', 'Air temperature average', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["good"], ["bad"]]'::jsonb, 'Monthly average air temperature according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE, '🌡️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('worldclim_min_temperature', 'Air temperature minimum', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["bad"], ["good"]]'::jsonb, 'Monthly minimum air temperature according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE, '🌡️❄️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('worldclim_max_temperature', 'Air temperature maximum', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["good"], ["bad"]]'::jsonb, 'Monthly maximum air temperature according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE, '🌡️🔥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('worldclim_amp_temperature', 'Air temperature monthly amplitude', jsonb_build_array(
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html'),
        '[["good"], ["bad"]]'::jsonb, 'Monthly amplitude of air temperatures according to WorldClim data for the years 1970-2000.', 'World', 'static', 'celc_deg', TRUE, '🌡️↕️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('powerlines_proximity_m', 'Powerlines proximity', jsonb_build_array(
        'Copyright © OpenStreetMap contributors https://www.openstreetmap.org/copyright',
        '© 2020 The World Bank Group, CC-BY 4.0'),
        '[["important"], ["unimportant"]]'::jsonb, 'Distance to closest powerline', 'World', 'static', 'm', TRUE, '⚡👫','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('waste_basket_coverage_area_km2', 'Waste containers', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad"], ["good"]]'::jsonb, 'Number of waste containers in a given area.', 'World', 'daily', 'n', TRUE, '🗑️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('populated_areas_proximity_m', 'Densely populated area proximity', jsonb_build_array(
        'Copyright © Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, 'Distance to closest Kontur Population cell with population > 80 ppl. This indicator is valid for non-populated areas between cities.', 'World', 'daily', 'm', TRUE, '🏡👫','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('power_substations_proximity_m', 'Power substations proximity', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb, 'Distance to closest power substation', 'World', 'daily', 'm', TRUE, '🏭👫','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('solar_farms_placement_suitability', 'Suitability estimation for solar farms placement', jsonb_build_array(
        'Copyright © Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright',
        'Copyright © 2022 WorldClim https://www.worldclim.org/data/index.html', 
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad"], ["good"]]'::jsonb, 'Multi-criteria analysis based layer dedicated to estimation of suitability of solar farms placement. 0 means absolutely unsuitable, 1 means perfectly suitable. Analysis is based on solar irradiace, powerlines grid proximity, power substations proximity, elevation slope, minimal and maximal temperatures, populated areas proximity', 'World (-60:60 latitudes)', 'daily', 'index', TRUE, '☀️💡','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('residential', 'Percentage of permanent population', jsonb_build_array(
        'Dataset: Schiavina M., Freire S., Carioli A., MacManus K. (2023): GHS-POP R2023A - GHS population grid multitemporal (1975-2030).European Commission, Joint Research Centre (JRC) PID: http://data.europa.eu/89h/2ff68a52-5b5b-4a22-8f40-c41da8332cfe, doi:10.2905/2FF68A52-5B5B-4A22-8F40-C41DA8332CFE Concept & Methodology: Freire S., MacManus K., Pesaresi M., Doxsey-Whitfield E., Mills J. (2016) Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE), AGILE 2016'),
        '[["unimportant"], ["important"]]'::jsonb, 'Estimation of residential population percentage according to GHS-POP dataset (2015)', 'World', 'static', 'fract', TRUE, '🏡', 'equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('solar_power_plants', 'Solar power plants', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb, 'Total number of solar power plants in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE, '☀️⚡','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('safety_index', 'Safety (Global Peace Index 2022)', jsonb_build_array(
        '© The Institute for Economics and Peace Limited 2022 https://www.visionofhumanity.org/'),
        '[["bad"], ["good"]]'::jsonb, 'The Global Peace Index covers 99.7% of the world’s population, and is calculated using 23 qualitative and quantitative indicators from highly respected sources, and measures the state of peace across three domains: the level of Societal Safety and Security, the extent of Ongoing Domestic and International Conflict, and the degree of Militarisation. Higher values indicate more peace and safety, low values imply ongoing conflicts and high militarization.', 'World', 'static', 'index', TRUE, '🛡️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('stddev_accel', 'Road Quality', jsonb_build_array(
        '© Kontur https://kontur.io/'),
        '[["good"], ["bad"]]'::jsonb, 'Road quality is measured by volunteers using mobile application that records phone accelerometer while driving. The areas that have highest typical standard deviation of acceleration are considered uncomfortable for driving.', 'World', 'daily', 'm_s2', TRUE, '🚙📊','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avg_forest_canopy_height', 'Forest canopy average height', jsonb_build_array(
        'High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery.', 'World', 'static', 'm', TRUE, '🌲📐','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('max_forest_canopy_height', 'Forest canopy maximal height', jsonb_build_array(
        'High Resolution Canopy Height Maps by WRI and Meta was accessed on 20.05.2024 from https://registry.opendata.aws/dataforgood-fb-forests. Meta and World Resources Institude (WRI) - 2024. High Resolution Canopy Height Maps (CHM). Source imagery for CHM © 2016 Maxar. Accessed 20 may 2024.'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb, 'Global and regional Canopy Height Maps (CHM). Created using machine learning models on high-resolution worldwide Maxar satellite imagery.', 'World', 'static', 'm', TRUE, '🌲⬆️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('worldbank_tax_rate', 'Total tax and contribution rate', jsonb_build_array(
        '© 2024 The World Bank Group, Doing Business project (http://www.doingbusiness.org/). NOTE: Doing Business has been discontinued as of 9/16/2021. For more information: https://bit.ly/3CLCbme'),
        '[["good"], ["bad"]]'::jsonb, 'Total tax rate measures the amount of taxes and mandatory contributions payable by businesses after accounting for allowable deductions and exemptions as a share of commercial profits. Taxes withheld (such as personal income tax) or collected and remitted to tax authorities (such as value added taxes, sales taxes or goods and service taxes) are excluded. Data for 2019.', 'World', 'static', 'perc', TRUE, '🧮','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('years_to_naturalisation', 'Legal residence duration required for naturalization', jsonb_build_array(
        'This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.'),
        '[["good"], ["bad"]]'::jsonb, 'The duration of legal residence before a national of a foreign state, without any cultural, historical, or marriage ties or connections to the state in question, can request citizenship under that states naturalization laws.', 'World', 'static', 'years', TRUE, '📊','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('multiple_citizenship', 'Dual/Multiple citizenship allowed', jsonb_build_array(
        'This dataset use material from the Wikipedia article https://en.wikipedia.org/wiki/Naturalization, which is released under the https://en.wikipedia.org/wiki/Wikipedia:Text_of_the_Creative_Commons_Attribution-ShareAlike_4.0_International_License.'),
        '[["bad"],["good"]]'::jsonb, 'Possibility to have dual (multiple) citizenship: 1 - no, 2 - with restrictions regulated by local legislation, 3 - dual (multiple) citizenship is allowed.', 'World', 'static', 'other', TRUE, '🛂','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('ghs_max_building_height', 'Building height maximum', jsonb_build_array(
        'Dataset: Schiavina, M., Melchiorri, M., Pesaresi, M., Politis, P., Carneiro Freire, S.M., Maffenini, L., Florio, P., Ehrlich, D., Goch, K., Carioli, A., Uhl, J., Tommasi, P. and Kemper, T., GHSL Data Package 2023, Publications Office of the European Union, Luxembourg, 2023, ISBN 978-92-68-02341-9 (online), doi:10.2760/098587 (online), JRC133256.'),
        '[["unimportant"], ["important"]]'::jsonb, 'GHS Average of the Net Building Height (ANBH). Values are expressed as decimals (Float) reporting about the average height of the built surfaces. ', 'World', 'static', 'm', TRUE, '🏙️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('ghs_avg_building_height', 'Building height average', jsonb_build_array(
        'Dataset: Schiavina, M., Melchiorri, M., Pesaresi, M., Politis, P., Carneiro Freire, S.M., Maffenini, L., Florio, P., Ehrlich, D., Goch, K., Carioli, A., Uhl, J., Tommasi, P. and Kemper, T., GHSL Data Package 2023, Publications Office of the European Union, Luxembourg, 2023, ISBN 978-92-68-02341-9 (online), doi:10.2760/098587 (online), JRC133256.'),
        '[["unimportant"], ["important"]]'::jsonb, 'GHS Average of the Net Building Height (ANBH). Values are expressed as decimals (Float) reporting about the average height of the built surfaces.', 'World', 'static', 'm', TRUE, '🏠','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('max_osm_building_levels', 'Building levels maximum', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["good"], ["bad"]]'::jsonb, 'Maximal level of buildings in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏢⬆️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avg_osm_building_levels', 'Building levels average', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["good"], ["bad"]]'::jsonb, 'Average levels of buildings in a given area according to OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏠⬆️','equal'); 

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_hotels_count', 'Hotels', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of hotels in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏨','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('max_osm_hotels_assesment', 'Hotel stars rating maximum', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Max hotel level assesment from OSM.', 'World', 'daily', 'n', TRUE, '🏨🌟','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('avg_osm_hotels_assesment', 'Hotel stars rating average', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Average hotel level assesment from OSM.', 'World', 'daily', 'n', TRUE, '🏨⭐','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('oam_coverage_area', 'OpenAerialMap coverage area', jsonb_build_array('© Kontur https://kontur.io','All imagery is publicly licensed and made available through the Humanitarian OpenStreetMap Team‘s Open Imagery Network (OIN) Node. All imagery contained in OIN is licensed CC-BY 4.0, with attribution as contributors of Open Imagery Network. All imagery is available to be traced in OpenStreetMap. © OpenAerialMap'), '[["bad"], ["good"]]'::jsonb, 'Area covered by OpenAerialMap images.', 'World', 'every_30min', 'km2', TRUE, '🗺️🛰️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('oam_number_of_pixels', 'OpenAerialMap coverage pixels number', jsonb_build_array('© Kontur https://kontur.io','All imagery is publicly licensed and made available through the Humanitarian OpenStreetMap Team‘s Open Imagery Network (OIN) Node. All imagery contained in OIN is licensed CC-BY 4.0, with attribution as contributors of Open Imagery Network. All imagery is available to be traced in OpenStreetMap. © OpenAerialMap'), '[["bad"], ["good"]]'::jsonb, 'Number of pixels of OpenAerialMap images.', 'World', 'every_30min', 'n', TRUE, '🗺️🔍','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_historical_sites_and_museums_count', 'Historical sites and museums', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of historical sites and museums in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏰','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_art_venues_count', 'Art venues', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of art venues in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🖼️🖌️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_entertainment_venues_count', 'Entertainment venues', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of entertainment venues OpenStreetMap.', 'World', 'daily', 'n', TRUE, '📽️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_cultural_and_comunity_centers_count', 'Cultural and community centers', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of cultural and community centers in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🫂','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('worldbank_inflation', 'Price inflation rate', jsonb_build_array(
        'Ha, Jongrim, M. Ayhan Kose, and Franziska Ohnsorge (2023). One-Stop Source: A Global Database of Inflation. Journal of International Money and Finance 137 (October): 102896'),
        '[["good"], ["bad"]]'::jsonb, 'Inflation, measured by the Consumer Price Index (CPI), is the annual change in prices of a typical basket of goods and services purchased by households. Data are drawn from multiple databases: OECD.Stat, the IMF World Economic Outlook database and International Financial Statistics, ILOSTAT, UNdata and country-specific sources including central banks and statistical offices.', 'World', 'static', 'perc', TRUE, '💸','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_pharmacy_count', 'Pharmacies', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of pharmacy in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '⚕️💊','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('conflict_stock_displacement', 'Conflict stock displacement', jsonb_build_array('© Kontur Boundaries https://data.humdata.org/dataset/kontur-boundaries', '© 2012-2024 Internal Displacement Monitoring Centre (IDMC)'), '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Percent of total population of IDPs (rounded figures at the national level), as a result of conflicts and violence as of the end of the reporting year.', 'World', 'static', 'perc', TRUE, '🆘🧑🏻‍🤝‍🧑🏿','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('disaster_stock_displacement', 'Disaster stock displacement', jsonb_build_array('© Kontur Boundaries https://data.humdata.org/dataset/kontur-boundaries', '© 2012-2024 Internal Displacement Monitoring Centre (IDMC)'), '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Percent of total population of IDPs (rounded figures at the national level), as a result of disasters as of the end of the reporting year.', 'World', 'static', 'perc', TRUE, '⚠️🧑🏻‍🤝‍🧑🏿','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('conflict_internal_displacements', 'Conflict internal displacements', jsonb_build_array('© Kontur Boundaries https://data.humdata.org/dataset/kontur-boundaries', '© 2012-2024 Internal Displacement Monitoring Centre (IDMC)'), '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Percent of total population of internal displacements reported (rounded figures at national level), as a result of conflict and violence over the 2023.', 'World', 'static', 'perc', TRUE, '💣🧑🏻‍🤝‍🧑🏿','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('disaster_internal_displacements', 'Disaster internal displacements', jsonb_build_array('© Kontur Boundaries https://data.humdata.org/dataset/kontur-boundaries', '© 2012-2024 Internal Displacement Monitoring Centre (IDMC)'), '[["good", "unimportant"], ["bad", "important"]]'::jsonb, 'Percent of total population of internal displacements reported (rounded figures at national level), as a result of disasters over the 2023.', 'World', 'static', 'perc', TRUE, '🌋🧑🏻‍🤝‍🧑🏿','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('hdi_2022', 'The Human Development Index', jsonb_build_array('© 2024 United Nations Development Programme https://hdr.undp.org/data-center/human-development-index'), '[["bad"], ["good"]]'::jsonb, 'The Human Development Index (HDI) is a summary measure of average achievement in key dimensions of human development: a long and healthy life, being knowledgeable and having a decent standard of living. The HDI is the geometric mean of normalized indices for each of the three dimensions. The health dimension is assessed by life expectancy at birth, the education dimension is measured by mean of years of schooling for adults aged 25 years and more and expected years of schooling for children of school entering age. The standard of living dimension is measured by gross national income per capita. The HDI uses the logarithm of income, to reflect the diminishing importance of income with increasing GNI. The scores for the three HDI dimension indices are then aggregated into a composite index using geometric mean. The entire series of Human Development Index (HDI) values and rankings are recalculated every year using the same the most recent (revised) data and functional forms. The HDI rankings and values in the 2014 Human Development Report cannot therefore be compared directly to indices published in previous Reports. Please see hdr.undp.org for more information. The HDI was created to emphasize that people and their capabilities should be the ultimate criteria for assessing the development of a country, not economic growth alone. The HDI can also be used to question national policy choices, asking how two countries with the same level of GNI per capita can end up with different human development outcomes. These contrasts can stimulate debate about government policy priorities.', 'World', 'static', 'index', TRUE, '🧑🏻‍🤝‍🧑🏿','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('inform_risk', 'INFORM Risk Index', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Composite index assessing humanitarian risk based on hazards, vulnerability, and coping capacity on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌍','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('hazard_and_exposure', 'Hazard & Exposure', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Level of exposure to natural or human-made hazards affecting a population on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌪️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('natural_0_to_10', 'Natural hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'The metric for the natural hazard risk used in INFORM is the annual average exposed population (AAEP) or, when hazard maps for different return periods are not available, annual exposed population (AEP). Measure of a population’s exposure to natural hazards, including geophysical and meteorological risks on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌋','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('earthquake', 'Earthquake hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Exposure of a region to seismic risks due to earthquakes on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌍','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('river_flood', 'River flood hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'The River flood hazard reflects the probability of physical impact associated with river flooding events on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌊','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('tsunami', 'Tsunami Hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Population exposure to tsunami hazards in coastal regions on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌊','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('tropical_cyclone', 'Tropical Cyclone hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Population exposure to tropical cyclones, hurricanes, and typhoons on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌀','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('coastal_flood', 'Coastal Flood hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Risk of flooding in coastal areas affecting population and infrastructure on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌊','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('drought', 'Drought hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Likelihood of population exposure to severe water scarcity on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '☀️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('epidemic', 'Epidemic hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Risk of population exposure to outbreaks of disease on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🦠','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('human', 'Human hazard', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Population exposure to risks caused by human activity, such as conflict on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '👤','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('projected_conflict_probability', 'Projected Conflict Probability', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Estimate of likelihood of future conflict impacting the population on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '💥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('current_conflict_intensity', 'Current Conflict Intensity', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Measure of ongoing conflict severity affecting local populations on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '💣','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('vulnerability', 'Vulnerability', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Indicator measuring susceptibility of populations to suffer from adverse impacts on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🤕','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('socio_economic_vulnerability', 'Socio-Economic Vulnerability', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Level of social and economic disadvantage increasing exposure to risks on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '📉','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('development_and_deprivation', 'Development & Deprivation', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Socioeconomic disadvantage impacting resilience and coping abilities on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🏚️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('inequality', 'Inequality', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Mesure of susceptibility of populations to suffer from inequality impacts on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '⚖️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('economic_dependency', 'Economic Dependency', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Measure of a region’s dependency on external economic factors, impacting resilience on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '💸','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('vulnerable_groups', 'Vulnerable Groups', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Extent of vulnerability among specific population groups on a scale of 0 to 10..', 'World', 'annual', 'index', TRUE, '👥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('uprooted_people', 'Uprooted People', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'The Uprooted people component is the arithmetic average of the absolute and relative value of uprooted people. The absolute value is presented using the log transformation while the uprooted people relative to the total population are transformed into indicator using the GNA criteria and then normalised into range from 0 to 10.', 'World', 'annual', 'index', TRUE, '🏠','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('health_conditions', 'Health Conditions', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Health condition subcomponent refers to people in a weak health conditions. It is calculated as the arithmetic average of the indicators for three deadly infectious diseases, AIDS, tuberculosis and malaria, which are considered as pandemics of low- and middle-income countries and then normalised into range from 0 to 10.', 'World', 'annual', 'index', TRUE, '🏥','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('children_u5', 'Children Under 5', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Percentage of children under age 5, indicating demographic vulnerability normalised into range from 0 to 10.', 'World', 'annual', 'index', TRUE, '👶','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('recent_shocks', 'Recent Shocks', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Recent shocks subcomponent accounts for increased vulnerability during the recovery period after a disaster and considers people affected by natural disasters in the past 3 years on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '⚡','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('food_security', 'Food Security', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Risk of food insecurity impacting vulnerable populations on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🍞','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('other_vulnerable_groups', 'Other Vulnerable Groups', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, ' Measure of other groups within a population with heightened vulnerability on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🙎','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('lack_of_coping_capacity', 'Lack of Coping Capacity', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["good"], ["bad"]]'::jsonb, 'Measure of a population’s limited ability to recover from shocks normalised into range from 0 to 10.', 'World', 'annual', 'index', TRUE, '🆘','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('institutional', 'Institutional Capacity', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Institutional resilience and governance affecting disaster response on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🏛️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('drr', 'Disaster Risk Reduction (DRR)', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Extent of disaster risk reduction initiatives improving resilience on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🌍','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('governance', 'Government stability', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Level of governance stability affecting overall risk levels on a scale of 0 to 10. The subjectivity of HFA Scores is counterweighted by arithmetical average with external indicators of Governance component, i.e. the Government Effectiveness and Corruption Perception Index. The Government Effectiveness captures perceptions of the quality of public services, the quality of the civil service and the degree of its independence from political pressures, the quality of policy formulation and implementation, and the credibility of the government’s commitment to such policies while the Corruption Perception Index adds another perspective, that is the level of misuse of political power for privatebenefit, which is not directly considered in the construction of the Government Effectiveness even though interrelated.', 'World', 'annual', 'index', TRUE, '📜','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('infrastructure', 'Infrastructure resilience', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Condition and resilience of essential infrastructure in a region on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🏗️','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('communication', 'Communication Capacity', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Ability to disseminate information during crises affecting resilience on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '📡','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('physical_infrastructure', 'Physical Infrastructure', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Physical infrastructure component is the arithmetic average of different proxy measures. Inform mainly try to assess the accessibility as well as the redundancy of the lifeline systems, which are crucial in a crisis situation, i.e. roads, water and sanitation systems on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🏢','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('access_to_health_care', 'Access to Health Care', jsonb_build_array('© INFORM Initiative https://www.inform-index.org/'), '[["bad"], ["good"]]'::jsonb, 'Availability and quality of healthcare services on a scale of 0 to 10.', 'World', 'annual', 'index', TRUE, '🩺','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_banks_count', 'Banks', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of banks in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏦','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_atms_count', 'ATMs', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of ATMs in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🏧','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_kindergartens_count', 'Kindergartens', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of kindergartens in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '👶','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_schools_count', 'Schools', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of schools in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🎒','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_colleges_count', 'Colleges and Affiliates', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of colleges and affiliates in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '👩🏾‍🏫','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_universities_count', 'Higher Education Institutions and Affiliates', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of higher education institutions and affiliates in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🎓','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_defibrillators_count', 'Defibrillators', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of defibrillators in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🆘','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_airports_count', 'Airports', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of airports in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🛬','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_railway_stations_count', 'Railway stations', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of railway stations in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🚉','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_public_transport_stops_count', 'Public transport stops', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of public transports stops, except railways stations in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🚏','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_car_parkings_capacity', 'Car parkings capacity', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of car parking spaces in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🅿️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('osm_heritage_sites_count', 'Heritage sites', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb, 'Number of heritage sites in OpenStreetMap.', 'World', 'daily', 'n', TRUE, '🗿','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('min_osm_heritage_admin_level',  'Heritage Protection Level', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["important"], ["neutral"]]'::jsonb, 'The most significant recognized administrative level of heritage protection within each hex cell. For instance, a lower numeric value might correspond to an internationally recognized (e.g., UNESCO) site, while higher values may indicate national, regional, or local protections.', 'World', 'daily', 'n', TRUE, '🏰','equal');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('foursquare_os_places_count', 'Foursquare open source places', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Total count of POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '📍','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('coffee_shops_fsq_count', 'Coffee shops', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of coffee shops POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '☕','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('kebab_restaurants_fsq_count', 'Kebab restaurants', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of kebab restaurants POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🥙','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('business_and_professional_services_fsq_count', 'Business services', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of business and professional services POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🏢','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('dining_and_drinking_fsq_count', 'Dining and drinking', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of dining and drinking POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🍽️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('retail_fsq_count', 'Retail', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of retail POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🛍️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('community_and_government_fsq_count', 'Community and government', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of community and government POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🏛️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('travel_and_transportation_fsq_count', 'Travel and transportation', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of travel and transportation POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '✈️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('landmarks_and_outdoors_fsq_count', 'Landmarks and outdoors', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of landmarks and outdoor POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🏞️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('health_and_medicine_fsq_count', 'Health and medicine', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of health and medicine POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '⚕️','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('arts_and_entertainment_fsq_count', 'Arts and entertainment', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of arts and entertainment POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🎨','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('sports_and_recreation_fsq_count', 'Sports and recreation', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of sports and recreation POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '⚽','proportional');

insert into bivariate_indicators (param_id, param_label, copyrights, direction, description, coverage, update_frequency, unit_id, is_public, emoji, downscale)
values ('events_fsq_count', 'Events', jsonb_build_array('Copyright 2024 Foursquare Labs, Inc. All rights reserved.'), '[["bad"], ["good"]]'::jsonb, 'Number of events POIs in Foursquare’s Open Source Places.', 'World', 'static', 'n', TRUE, '🎉','proportional');

-- set indicator is_base to become denominators
update bivariate_indicators
set is_base = true
where param_id in ('population', 'total_building_count', 'area_km2', 'populated_area_km2', 'one', 'total_road_length');

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
