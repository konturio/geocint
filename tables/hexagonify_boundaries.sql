-- filter out boundaries with invalid admin_levels:
drop table if exists osm_country_boundaries;
create table osm_country_boundaries as (
    select osm_id,
            admin_level::int,
            hasc_wiki,
            ST_Area(geom) as area,
            geom
    from kontur_boundaries
    where admin_level ~ '^\d{1,2}$' -- filter to match only integer OSM admin levels
);

-- generate h3 grid for every boundary:
drop table if exists h3_in;
create table h3_in as (
    select  h3_polyfill(ST_Subdivide(geom), 8) as h3,
            osm_id,
            admin_level,
            hasc_wiki,
            area
    from osm_country_boundaries
    -- According to OpenStreetMap wiki only levels from 2 to 11 are valid:
    -- (https://wiki.openstreetmap.org/wiki/Key:admin_level):
    where admin_level between 2 and 11
);

-- -- filter out duplicated h3 cells (where boundaries of same admin_level overlaps):
-- create table h3_in_2 as (
--     select disstinct on (h3, admin_level) *
--     from h3_in
--     order by h3, admin_level, area desc -- select boundary with bigger area for now
-- );

create index on h3_in using btree(h3);

-- gather h3 cells with boundaries of all levels:
drop table if exists hexagonify_boundaries;
create table hexagonify_boundaries as (
    select h3,
           8                                           as resolution,
           max(osm_id) filter (where admin_level = 2)  as osm_id_lvl_2,
           max(osm_id) filter (where admin_level = 3)  as osm_id_lvl_3,
           max(osm_id) filter (where admin_level = 4)  as osm_id_lvl_4,
           max(osm_id) filter (where admin_level = 5)  as osm_id_lvl_5,
           max(osm_id) filter (where admin_level = 6)  as osm_id_lvl_6,
           max(osm_id) filter (where admin_level = 7)  as osm_id_lvl_7,
           max(osm_id) filter (where admin_level = 8)  as osm_id_lvl_8,
           max(osm_id) filter (where admin_level = 9)  as osm_id_lvl_9,
           max(osm_id) filter (where admin_level = 10) as osm_id_lvl_10,
           max(osm_id) filter (where admin_level = 11) as osm_id_lvl_11,
           array_agg(hasc_wiki) as hasc_wiki
    from h3_in
    group by h3
);

drop table if exists osm_country_boundaries;
drop table if exists h3_in;
