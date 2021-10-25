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
        'https://geocint.kontur.io/geocint/reports/population_check_osm.csv',
        '',
        'Here in Kontur, we generate our own global [population](https://www.kontur.io/portfolio/population-dataset/) [dataset](https://data.humdata.org/dataset/kontur-population-dataset) based on several various data sources including OpenStreetMap. As a result, we can compare it with OpenStreetMap population data (from [population](https://wiki.openstreetmap.org/wiki/Key:population) key on administrative division boundaries). Using this report you can find cases with the most difference between Kontur population dataset and OpenStreetMap which may indicate potential errors in OpenStreetMap.',
        'Here in Kontur, we generate our own global population dataset based on several various data sources including OpenStreetMap. As a result, we can compare it with OpenStreetMap population data (from population key on administrative division boundaries). Using this report you can find cases with the most difference between Kontur population dataset and OpenStreetMap which may indicate potential errors in OpenStreetMap.',
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
        'https://geocint.kontur.io/geocint/reports/osm_population_inconsistencies.csv',
        '',
        'This report indicates some potential errors in OpenStreetMap population key values. We analyze boundary objects to make sure that the population of administrative boundaries on different levels do conflict with each other. For example, a country''s population may not be smaller than SUM of its regions'' population.',
        'This report indicates some potential errors in OpenStreetMap population key values. We analyze boundary objects to make sure that the population of administrative boundaries on different levels do conflict with each other. For example, a country''s population may not be smaller than SUM of its regions'' population.',
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

-- OSM-GADM comparison report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, column_link_templates, sortable, public_access)
values ('osm_gadm_comparison',
        'OSM-GADM comparison',
        'https://geocint.kontur.io/geocint/reports/osm_gadm_comparison.csv',
        '',
        'You may already know about the [GADM](https://gadm.org/data.html) boundaries dataset. It’s a global dataset with an administrative division of all countries of the world. It’s not ideal (as well as OSM) and its [license](https://gadm.org/license.html) directly forbids using it for commercial purposes (so it can’t be imported into OpenStreetMap!). But we can compare statistics on GADM and OpenStreetMap to find some potential “gaps” in OSM data. In this report we analyze the hierarchy of boundaries in GADM and OpenStreetMap. In the last column you can see how many subregions for every admin boundary were found in GADM/OSM to make some potential conclusions. If the difference in stats is big then it’s a good reason to look carefully into OSM data. But remember that GADM is not the “ground truth” and may also contain errors.',
        'You may already know about the GADM boundaries dataset. It’s a global dataset with an administrative division of all countries of the world. It’s not ideal (as well as OSM) and its license directly forbids using it for commercial purposes (so it can’t be imported into OpenStreetMap!). But we can compare statistics on GADM and OpenStreetMap to find some potential “gaps” in OSM data. In this report we analyze the hierarchy of boundaries in GADM and OpenStreetMap. In the last column you can see how many subregions for every admin boundary were found in GADM/OSM to make some potential conclusions. If the difference in stats is big then it’s a good reason to look carefully into OSM data. But remember that GADM is not the ["ground truth"](https://wiki.openstreetmap.org/wiki/Ground_truth) and may also contain errors.',
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


-- Populate timestamp column with previous values to keep them in case reports won't update (then old timestamp will be the valid one!)
update table osm_reports_list n
    set last_updated = o.last_updated
    from osm_reports_list_old o
    where n.id = o.id;