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
        'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'),
        '[["unimportant"], ["important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('total_building_count', 'Total Buildings Estimate', jsonb_build_array(
'© Kontur https://kontur.io/',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) Data set. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
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
values ('covid19_vaccines', 'COVID Vaccine Acceptance', jsonb_build_array(
'© Data from Delphi COVIDcast, covidcast.cmu.edu'),
    '[["bad"], ["neutral"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('covid19_cases', 'COVID Cases (per 100,000 people, 7-day average)', jsonb_build_array(
'© Data from Delphi COVIDcast, covidcast.cmu.edu'),
    '[["good"], ["bad"]]'::jsonb);


insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('covid19_confirmed', 'COVID19 Confirmed Cases', jsonb_build_array(
'© Data from JHU CSSE COVID-19 Dataset'),
   '[["good"], ["bad"]]'::jsonb);


insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('avg_slope', 'Average slope', jsonb_build_array(
'© Data from General Bathymatric Chart of the Oceans, www.gebco.net'),
    '[["good", "unimportant"], ["bad", "important"]]'::jsonb);

insert into bivariate_indicators (param_id, param_label, copyrights, direction)
values ('avg_ndvi', 'Average NDVI, JUN 2019', jsonb_build_array(
'© Data from Sentinel-2 L2A 120m Mosaic, CC-BY 4.0, https://forum.sentinel-hub.com/c/aws-sentinel'),
    '[["bad"], ["good"]]'::jsonb);

update bivariate_indicators
set is_base = true
where param_id in ('population', 'total_building_count', 'area_km2', 'one');
