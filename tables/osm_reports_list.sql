-- This rooting creates a table with a list of OpenStreetMap quality reports and its' properties for further deploy to Disaster Ninja.
-- Full description on populating procedure can be found in Fibery:
-- (https://kontur.fibery.io/Tasks/Task/Instruction-how-to-prepare-reports-7464)

-- Keep old osm_reports_list table to keep and compare previous timestamps
drop table if exists osm_reports_list_old;
create table if not exists osm_reports_list (id text, last_updated text);   -- Create empty table if there isn't one already
alter table osm_reports_list rename to osm_reports_list_old;                -- Rename actual table to old


-- Create new empty table osm_reports_list:
drop table if exists osm_reports_list;
create table osm_reports_list
(
    id text,
    name text,
    link text,
    last_updated text,
    description_brief text,
    description_full text,
    column_link_templates json,
    sortable boolean not null default true,
    public_access boolean not null default true
);


-- Populate table with reports
-- Population tag check report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, column_link_templates, sortable, public_access)
values ('population_tag_check',
        'Population tag check',
        '/population_check_osm.csv',
        '',
        'Find discrepancies between [Kontur Population](https://www.kontur.io/portfolio/population-dataset/) and [OpenStreetMap](https://wiki.openstreetmap.org/wiki/Key:population) data to see potential errors in OpenStreetMap population data. [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset) is a global population dataset generated based on various public data sources including OpenStreetMap. Inconsistencies in the values between Kontur data and OpenStreetMap population key on administrative division boundaries may indicate inaccuracies in OSM data.',
        'Find discrepancies between [Kontur Population](https://www.kontur.io/portfolio/population-dataset/) and [OpenStreetMap](https://wiki.openstreetmap.org/wiki/Key:population) data to see potential errors in OpenStreetMap population data. [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset) is a global population dataset generated based on various public data sources including OpenStreetMap. Inconsistencies in the values between Kontur data and OpenStreetMap population key on administrative division boundaries may indicate inaccuracies in OSM data.',
       '[
          {
            "OSM ID": "https://www.openstreetmap.org/relation/{{OSM ID}}"
          },
          {
            "Name": "http://localhost:8111/load_object?new_layer=false&objects=r{{OSM ID}}&relation_members=true"
          }]'::json,
        true,
        true
        );

-- Population inconsistencies report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, column_link_templates, sortable, public_access)
values ('osm_population_inconsistencies',
        'Population inconsistencies',
        '/osm_population_inconsistencies.csv',
        '',
        'This report indicates potential errors in OpenStreetMap population key values. [Kontur](https://www.kontur.io/) analyzes boundary objects to check if the population numbers on different levels of administrative boundaries do not conflict with each other. For example, a country’s population may not be smaller than the sum of its region’s population.',
        'This report indicates potential errors in OpenStreetMap population key values. [Kontur](https://www.kontur.io/) analyzes boundary objects to check if the population numbers on different levels of administrative boundaries do not conflict with each other. For example, a country’s population may not be smaller than the sum of its region’s population.',
       '[
          {
            "OSM ID": "https://www.openstreetmap.org/relation/{{OSM ID}}"
          },
          {
            "Name": "http://localhost:8111/load_object?new_layer=false&objects=r{{OSM ID}}&relation_members=true"
          }]'::json,
        false,
        true
        );

-- OSM-GADM comparison report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, column_link_templates, sortable, public_access)
values ('osm_gadm_comparison',
        'OSM-GADM comparison',
        '/osm_gadm_comparison.csv',
        '',
        'Compare [GADM](https://gadm.org/data.html) and OpenStreetMap statistics on administrative division to find potential gaps in OSM data. GADM boundary data is a global dataset with an administrative division of all countries. Its [license](https://gadm.org/license.html) forbids importing it into OpenStreetMap but this report by [Kontur](https://www.kontur.io/) allows you to analyze the hierarchy of boundaries in GADM and OpenStreetMap. The last column shows the number of subregions for every admin boundary found in GADM/OSM to make potential conclusions. GADM is not the [''ground truth''](https://wiki.openstreetmap.org/wiki/Ground_truth), but a big difference in stats is a good reason to look carefully into OSM data.',
        'Compare [GADM](https://gadm.org/data.html) and OpenStreetMap statistics on administrative division to find potential gaps in OSM data. GADM boundary data is a global dataset with an administrative division of all countries. Its [license](https://gadm.org/license.html) forbids importing it into OpenStreetMap but this report by [Kontur](https://www.kontur.io/) allows you to analyze the hierarchy of boundaries in GADM and OpenStreetMap. The last column shows the number of subregions for every admin boundary found in GADM/OSM to make potential conclusions. GADM is not the [''ground truth''](https://wiki.openstreetmap.org/wiki/Ground_truth), but a big difference in stats is a good reason to look carefully into OSM data.',
       '[
          {
            "OSM ID": "https://www.openstreetmap.org/relation/{{OSM ID}}"
          },
          {
            "OSM name": "http://localhost:8111/load_object?new_layer=false&objects=r{{OSM ID}}&relation_members=true"
          }]'::json,
        false,
        true
        );

insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, column_link_templates, sortable, public_access)
values ('osm_unmapped_places',
        'OSM unmapped places',
        '/osm_unmapped_places.csv',
        '',
        'A list of viewed on [OpenStreetMap](https://www.openstreetmap.org) but unmapped places where people live according to [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset).',
        'A list of viewed on [OpenStreetMap](https://www.openstreetmap.org) but unmapped places where people live according to [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset).',
       '[
          {
            "Bounding box": "http://localhost:8111/load_and_zoom?{{Bounding box}}"
          }]'::json,
        false,
        false
        );

-- Populate timestamp column with previous values to keep them in case reports won't update (then old timestamp will be the valid one!)
update osm_reports_list n
    set last_updated = o.last_updated
    from osm_reports_list_old o
    where n.id = o.id;