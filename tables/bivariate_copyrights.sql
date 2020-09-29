drop table if exists bivariate_copyrights;

create table bivariate_copyrights
(
    param_id   text,
    copyrights json
);

alter table bivariate_copyrights
    set (parallel_workers = 32);

insert into bivariate_copyrights (param_id, copyrights)
values ('one', '["Numbers © Muḥammad ibn Mūsā al-Khwārizmī"]'::json);

insert into bivariate_copyrights (param_id, copyrights)
values ('area_km2', '["Concept of areas © Brahmagupta, René Descartes"]'::json);

insert into bivariate_copyrights (param_id, copyrights)
values ('count', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('view_count', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('avg_ts', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('max_ts', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('p90_ts', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('osm_users', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('building_count', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('highway_length', jsonb_build_array('© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('local_hours', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('total_hours', jsonb_build_array('© Kontur https://kontur.io/',
'© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('gdp', jsonb_build_array(
'© Kontur https://kontur.io/',
'© 2019 The World Bank Group, CC-BY 4.0',
                                 'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe.',
                                 'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
                                 'Copernicus Global Land Service: Land Cover 100m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, Myroslava Lesiv, Nandin-Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) [Data set]. Zenodo. http://doi.org/10.5281/zenodo.3939050',
                                 'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
                                 '@ OpenStreetMap contributors https://www.openstreetmap.org/copyright'));

insert into bivariate_copyrights (param_id, copyrights)
values ('population', jsonb_build_array(
'© Kontur https://kontur.io/',
        'Facebook Connectivity Lab and Center for International Earth Science Information Network - CIESIN - Columbia University. 2016. High Resolution Settlement Layer (HRSL). Source imagery for HRSL © 2016 DigitalGlobe.',
        'Dataset: Schiavina, Marcello; Freire, Sergio; MacManus, Kytt (2019): GHS population grid multitemporal (1975, 1990, 2000, 2015) R2019A. European Commission, Joint Research Centre (JRC) DOI: 10.2905/42E8BE89-54FF-464E-BE7B-BF9E64DA5218 PID: http://data.europa.eu/89h/0c6b9751-a71f-4062-830b-43c9f432370f Concept & Methodology: Freire, Sergio; MacManus, Kytt; Pesaresi, Martino; Doxsey-Whitfield, Erin; Mills, Jane (2016): Development of new open and free multi-temporal global population grids at 250 m resolution. Geospatial Data in a Changing World; Association of Geographic Information Laboratories in Europe (AGILE). AGILE 2016',
        'Copernicus Global Land Service: Land Cover 100 m: Marcel Buchhorn, Bruno Smets, Luc Bertels, Bert De Roo, MyroslavaLesiv, Nandin - Erdene Tsendbazar, … Steffen Fritz. (2020). Copernicus Global Land Service: Land Cover 100m: collection 3: epoch 2019: Globe (Version V3.0.1) [Data set]. Zenodo. http://doi.org/10.5281/zenodo.3939050',
        'Microsoft Buildings: Canada, Tanzania, Uganda, USA: This data is licensed by Microsoft under the Open Data Commons Open Database License (ODbL).',
        '© OpenStreetMap contributors https://www.openstreetmap.org/copyright'));
