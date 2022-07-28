drop table if exists bivariate_indicators;
create table bivariate_indicators
(
    param_id   text,
    param_label text,
    copyrights json,
    direction json,
    is_base boolean not null default false
);

alter table bivariate_indicators
    set (parallel_workers = 32);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('one', '1', '["Numbers © Muḥammad ibn Mūsā al-Khwārizmī"]'::json, '[["neutral"], ["neutral"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('area_km2', 'Area', '["Concept of areas © Brahmagupta, René Descartes"]'::json, '[["neutral"], ["neutral"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
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
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('count', 'OSM Objects', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('count_6_months', 'OSM Objects (last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('view_count', 'OSM Map Views', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('avgmax_ts', 'OSM Last Edit Date (avg)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('max_ts', 'OSM Last Edit Date (max)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad", "unimportant"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('min_ts', 'OSM First Edit Date (min)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["good"], ["neutral"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('osm_users', 'OSM Mappers Edited Here', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('building_count', 'OSM Buildings', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('building_count_6_months', 'OSM Buildings (last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('highway_length', 'OSM Road Length', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('highway_length_6_months', 'OSM Road Length (last 6 months)', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('local_hours', 'OSM Mapping Hours by Local Mappers', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('total_hours', 'OSM Mapping Hours by All Mappers', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'), '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('forest', 'Forest Landcover Area', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('evergreen_needle_leaved_forest', 'Evergreen Needle-leaved Forest Landcover Area', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('shrubs', 'Shrubland Area', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('herbage', 'Herbaceous Landcover Area', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('unknown_forest', 'Unknown Forest Type Landcover Area', jsonb_build_array('© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('gdp', 'Gross Domestic Product', jsonb_build_array(
'© Kontur https://kontur.io/',
'© 2019 The World Bank Group, CC-BY 4.0',
                                 'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe. https://dataforgood.fb.com/tools/population-density-maps/',
                                 'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
                                 'Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
                                 'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
                                 '@ OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
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
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
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
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('total_building_count', 'Total Buildings Estimate', jsonb_build_array(
        '© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Geoalert Urban Mapping: Chechnya, Moscow region, Tyva - https://github.com/Geoalert/urban-mapping',
        'Microsoft Buildings: Australia, Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        'NZ Building Outlines data sourced from the LINZ Data Service - https://data.linz.govt.nz/',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('wildfires', 'Wildfire Days Per Year', jsonb_build_array(
'© NRT VIIRS 375 m Active Fire product VJ114IMGTDL_NRT. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/VIIRS/VJ114IMGT_NRT.002',
    'NRT VIIRS 375 m Active Fire product VNP14IMGT. Available on-line [https://earthdata.nasa.gov/firms]. doi:10.5067/FIRMS/VIIRS/VNP14IMGT_NRT.002',
    'MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14DL. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14DL.NRT.006',
    'MODIS Collection 6 NRT Hotspot / Active Fire Detections MCD14ML. Available on-line [https://earthdata.nasa.gov/firms]. doi: 10.5067/FIRMS/MODIS/MCD14ML'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('hazardous_days_count', 'Number of days with any disaster occurs, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('earthquake_days_count', 'Number of days under earthquake impact, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('drought_days_count', 'Number of days under drought impact, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('cyclone_days_count', 'Number of days under cyclone impact, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('wildfire_days_count', 'Number of days under wildfire impact, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('volcano_days_count', 'Number of days under volcano impact, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('flood_days_count', 'Number of days under flood impact, last year', jsonb_build_array(
'Events data from Kontur Event Feed (https://www.kontur.io/portfolio/event-feed)'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('covid19_vaccines', 'COVID19 Vaccine Acceptance', jsonb_build_array(
'© Data from Delphi COVIDcast, covidcast.cmu.edu'),
    '[["bad"], ["neutral"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('covid19_confirmed', 'COVID19 Confirmed Cases', jsonb_build_array(
'© Data from JHU CSSE COVID-19 Dataset'),
   '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('avg_slope_gebco_2022', 'Average slope (GEBCO 2022)', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('avg_elevation_gebco_2022', 'Average elevation (GEBCO 2022)', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('avg_ndvi', 'Average NDVI, JUN 2019', jsonb_build_array(
'© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel'),
    '[["bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('industrial_area', 'OSM industrial area', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('volcanos_count', 'Number of volcanos', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('pop_under_5_total', 'Population under age of 5', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('pop_over_65_total', 'Population over age of 65', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('poverty_families_total', 'Families living below poverty line', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant", "good"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('pop_disability_total', 'Population with a disability', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('pop_not_well_eng_speak', 'Population with a difficulty speaking English', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["good"], ["important", "bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('pop_without_car', 'Population without a car', jsonb_build_array(
        '© United States Census Bureau. 2019 5-Year American Community Survey (ACS). https://www.census.gov/en.html'),
        '[["neutral"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('days_maxtemp_over_32c_1c', 'Days above 32C, recent scenario', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('days_maxtemp_over_32c_2c', 'Days above 32C, potential scenario (2C)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('days_mintemp_above_25c_1c', 'Nights above 25C, recent scenario', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('days_mintemp_above_25c_2c', 'Nights above 25C, potential scenario(2C)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('days_maxwetbulb_over_32c_1c', 'Days above 32C wet-bulb, recent scenario', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('days_maxwetbulb_over_32c_2c', 'Days above 32C wet-bulb, potential scenario(2C)', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('mandays_maxtemp_over_32c_1c', 'Man-days above 32C, recent scenario', jsonb_build_array(
        '© 2021 Probable Futures, a Project of the SouthCoast Community Foundation. https://probablefutures.org/, CC BY 4.0'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('man_distance_to_fire_brigade', 'Man-distance to fire brigade', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('man_distance_to_hospital', 'Man-distance to hospitals', jsonb_build_array(
        '© Kontur https://kontur.io/', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["good"], ["bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('total_road_length', 'Total Roads length', jsonb_build_array(
        '©2019 Facebook, Inc. and its affiliates https://github.com/facebookmicrosites/Open-Mapping-At-Facebook/blob/main/LICENSE.md',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('foursquare_places_count', 'Foursquare Japan places count', jsonb_build_array(
        '©Foursquare Labs Inc',
        'Sample data'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('foursquare_visits_count', 'Foursquare Japan visits count', jsonb_build_array(
        '©Foursquare Labs Inc',
        'Sample data'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('view_count_bf2402', 'OSM Map Views 30 days before 24.02.2022',
        jsonb_build_array('© Kontur', '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('powerlines', 'Medium voltage powerlines distribution', jsonb_build_array(
        '©9999 Facebook, Inc. and its affiliates https://dataforgood.facebook.com/dfg/tools/electrical-distribution-grid-maps'),
        '[["bad"], ["good"]]'::jsonb);

-- We use unimportant - important+bad for Multi-hazard risk, Multi-hazard exposure and Vulnerability 
-- because PDC does something only about regions that are under disasters
-- Also for this reason we use important+bad - good for Coping capacity and Resilience
-- We used https://test.pdc.org/risk-and-vulnerability/ as example in index estimation process

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('mhr_index', 'Multi-hazard risk PDC GRVA', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["unimportant"], ["important", "bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('mhe_index', 'Multi-hazard exposure PDC GRVA', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["unimportant"], ["important", "bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('coping_capacity_index', 'Coping Capacity PDC GRVA', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["important", "bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('resilience_index', 'Resilience PDC GRVA', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["important", "bad"], ["good"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('vulnerability_index', 'Vulnerability PDC GRVA', jsonb_build_array(
        '© 2022 Pacific Disaster Center. https://www.pdc.org/privacy-policy/'),
        '[["unimportant"], ["important", "bad"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('night_lights_intensity', 'VIIRS Nighttime lights intensity', jsonb_build_array(
        'Earth Observation Group © 2021. https://eogdata.mines.edu/products/vnl/#reference',
        'C. D. Elvidge, K. E. Baugh, M. Zhizhin, and F.-C. Hsu, “Why VIIRS data are superior to DMSP for mapping nighttime lights,” Asia-Pacific Advanced Network 35, vol. 35, p. 62, 2013.',
        'C. D. Elvidge, M. Zhizhin, T. Ghosh, F-C. Hsu, "Annual time series of global VIIRS nighttime lights derived from monthly averages: 2012 to 2019", Remote Sensing (In press)'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('eatery_count', 'Number of OSM eatery places', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('food_shops_count', 'Number of OSM food shops', jsonb_build_array(
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('mapswipe_area_km2', 'MapSwipe populated area km2', jsonb_build_array(
        'Copyright © 2022 MapSwipe https://mapswipe.org/en/privacy.html'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('gsa_ghi', 'GSA Global horizontal irradiation', jsonb_build_array(
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('gsa_gti', 'GSA Global irradiation for optimally tilted surface', jsonb_build_array(
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('gsa_pvout', 'GSA Photovoltaic power potential', jsonb_build_array(
        'Copyright © 2022 The World Bank https://globalsolaratlas.info/support/terms-of-use'),
        '[["bad", "unimportant"], ["good", "important"]]'::jsonb);

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