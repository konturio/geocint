-- This rooting creates a table with a list of OpenStreetMap quality reports and its' properties for further deploy to Disaster Ninja.
-- Full description on populating procedure can be found in Fibery:
-- (https://kontur.fibery.io/Tasks/Task/Instruction-how-to-prepare-reports-7464)


-- create empty table on first run of pipeline
create table if not exists osm_reports_list
(
    id text,
    name text,
    link text,
    last_updated text,
    description_brief text,
    description_full text,
    sortable boolean not null default true,      -- flag indicating that the table has to be sortable or not
    searchable_columns_indexes integer[],        -- array of indexes of colums which will be used for search (start from 0)
    public_access boolean not null default true
);

-- Keep old osm_reports_list table to keep and compare previous timestamps
drop table if exists osm_reports_list_old;
create table osm_reports_list_old as (
        select * from osm_reports_list
);


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
    sortable boolean not null default true,      -- flag indicating that the table has to be sortable or not
    searchable_columns_indexes integer[],        -- array of indexes of colums which will be used for search (start from 0)
    public_access boolean not null default true
);


-- Populate table with reports
-- Population tag check report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, sortable, searchable_columns_indexes, public_access)
select 'population_tag_check',
        'Population tag check',
        '/population_check_osm.csv',
        json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
        'Find discrepancies between [Kontur Population](https://www.kontur.io/portfolio/population-dataset/) and [OpenStreetMap](https://wiki.openstreetmap.org/wiki/Key:population) data to see potential errors in OpenStreetMap population data. [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset) is a global population dataset generated based on various public data sources including OpenStreetMap. Inconsistencies in the values between Kontur data and OpenStreetMap population key on administrative division boundaries may indicate inaccuracies in OSM data.',
        E'Find discrepancies between [Kontur Population](https://www.kontur.io/portfolio/population-dataset/) and [OpenStreetMap](https://wiki.openstreetmap.org/wiki/Key:population) data to see potential errors in OpenStreetMap population data. 
        [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset) is a global population dataset generated based on various public data sources, including OpenStreetMap. 
        Inconsistencies in the values between Kontur data and OpenStreetMap population key on administrative division boundaries may indicate inaccuracies in OpenStreetMap data. 
        Click here to download this report as a csv-file: [https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/population_check_osm.csv](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/population_check_osm.csv). 
        \n\nNote: To use links in the Name field and open the exact area you want to edit, please install [JOSM](https://josm.openstreetmap.de/), an open-source editor for OpenStreetMap.',
        true,
        '{1}',
        true
from osm_meta;

-- Population inconsistencies report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, sortable, searchable_columns_indexes, public_access)
select 'osm_population_inconsistencies',
        'Population inconsistencies',
        '/osm_population_inconsistencies.csv',
        json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
        'This report indicates potential errors in OpenStreetMap population key values. [Kontur](https://www.kontur.io/) analyzes boundary objects to check if the population numbers on different levels of administrative boundaries do not conflict with each other. For example, a country’s population may not be smaller than the sum of its region’s population.',
        'This report indicates potential errors in OpenStreetMap [population key](https://wiki.openstreetmap.org/wiki/Key:population) values. [Kontur](https://www.kontur.io/) analyzes boundary objects to check if the population numbers on different levels of administrative boundaries do not conflict with each other. For example, a country’s population may not be smaller than the sum of its region’s population. Click the following link to download: [https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_population_inconsistencies.csv](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_population_inconsistencies.csv)',
        false,
        '{1}',
        true
from osm_meta;

-- OSM-GADM comparison report:
insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, sortable, searchable_columns_indexes, public_access)
select 'osm_gadm_comparison',
        'OSM-GADM comparison',
        '/osm_gadm_comparison.csv',
        json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
        'Compare [GADM](https://gadm.org/data.html) and OpenStreetMap statistics on administrative division to find potential gaps in OSM data. GADM boundary data is a global dataset with an administrative division of all countries. Its [license](https://gadm.org/license.html) forbids importing it into OpenStreetMap but this report by [Kontur](https://www.kontur.io/) allows you to analyze the hierarchy of boundaries in GADM and OpenStreetMap. The last column shows the number of subregions for every admin boundary found in GADM/OSM to make potential conclusions. GADM is not the [''ground truth''](https://wiki.openstreetmap.org/wiki/Ground_truth), but a big difference in stats is a good reason to look carefully into OSM data.',
        'Compare [GADM](https://gadm.org/data.html) and OpenStreetMap statistics on administrative division to find potential gaps in OSM data. GADM boundary data is a global dataset with an administrative division of all countries. Its [license](https://gadm.org/license.html) forbids importing it into OpenStreetMap but this report by [Kontur](https://www.kontur.io/) allows you to analyze the hierarchy of boundaries in GADM and OpenStreetMap. The last column shows the number of subregions for every admin boundary found in GADM/OSM to make potential conclusions. GADM is not the [''ground truth''](https://wiki.openstreetmap.org/wiki/Ground_truth), but a big difference in stats is a good reason to look carefully into OSM data. Click the following link to download: [https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_gadm_comparison.csv](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_gadm_comparison.csv)',
        false,
        '{2}',
        true
from osm_meta;

insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, sortable, searchable_columns_indexes, public_access)
select 'osm_unmapped_places',
        'OSM unmapped places',
        '/osm_unmapped_places.csv',
        json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
        'A list of viewed on [OpenStreetMap](https://www.openstreetmap.org) but unmapped places where people live according to [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset).',
        'A list of viewed on [OpenStreetMap](https://www.openstreetmap.org) but unmapped places where people live according to [Kontur Population](https://data.humdata.org/dataset/kontur-population-dataset). Click the following link to download: [https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_unmapped_places.csv](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_unmapped_places.csv)',
        false,
        '{1}',
        true
from osm_meta;

insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, sortable, searchable_columns_indexes, public_access)
select 'osm_missing_roads',
        'OSM missing roads',
        '/osm_missing_roads.csv',
        json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
        'A list of places with roads missing on OpenStreetMap while comparing with [Open-Mapping-At-Facebook](https://github.com/facebookmicrosites/Open-Mapping-At-Facebook).',
        'A list of places with roads missing on [OpenStreetMap](https://www.openstreetmap.org) while comparing with [Open-Mapping-At-Facebook](https://github.com/facebookmicrosites/Open-Mapping-At-Facebook). Click the following link to download: [https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_missing_roads.csv](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_missing_roads.csv)',
        true,
        '{2}',
        true
from osm_meta;

insert into osm_reports_list (id, name, link, last_updated, description_brief, description_full, sortable, searchable_columns_indexes, public_access)
select 'osm_missing_boundaries_report',
        'OSM missing boundaries',
        '/osm_missing_boundaries_report.csv',
        json_extract_path_text(meta::json, 'data', 'timestamp', 'last'),
        'A list of boundaries that disappeared from Kontur Boundaries dataset nightly version compared to the [last public one](https://data.humdata.org/dataset/kontur-boundaries). In most cases this means that the boundary polygon can not be extracted because relation in OpenStreetMap is broken and needs to be repaired.',
        'A list of boundaries that disappeared from Kontur Boundaries dataset nightly version compared to the [last public one](https://data.humdata.org/dataset/kontur-boundaries). In most cases this means that the boundary polygon can not be extracted because relation in OpenStreetMap is broken and needs to be repaired. Click the following link to download: [https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_missing_boundaries_report.csv](https://geodata-eu-central-1-kontur-public.s3.eu-central-1.amazonaws.com/kontur_reports@@@@@/osm_missing_boundaries_report.csv)',
        true,
        '{3}',
        false
from osm_meta;