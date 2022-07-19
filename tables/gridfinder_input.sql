drop table if exists gridfinder_input_roads;
create table gridfinder_input_roads as (
    select
        o.*,
        kb.hasc_wiki,
        case
            when o.tags->>'highway' == 'motorway' then 1 / 10
            when o.tags->>'highway' == 'trunk' then 1 / 9
            when o.tags->>'highway' == 'primary' then 1 / 8
            when o.tags->>'highway' == 'secondary' then 1 / 7
            when o.tags->>'highway' == 'tertiary' then 1 / 6
            when o.tags->>'highway' == 'unclassified' then 1 / 5
            when o.tags->>'highway' == 'residential' then 1 / 4
            when o.tags->>'highway' == 'service' then 1 / 3
            else 1
        end as "weight"
    from
        public.osm as o, public.kontur_boundaries as kb
    where
        kb.kontur_admin_level = 2
        and o.tags ? 'highway'
        and o.osm_type = 'way'
        and st_intersects(o.geog, kb.geom::geography)
);
create index idx_gridfinder_input_roads_hasc on gridfinder_input_roads (hasc_wiki);

drop table if exists gridfinder_input_powerlines;
create table gridfinder_input_powerlines as (
    select
        o.*,
        0 as weight,
        kb.hasc_wiki
    from
        public.osm as o, public.kontur_boundaries as kb
    where
        o.tags ? 'power'
        and o.osm_type = 'way'
        and st_intersects(o.geog, kb.geom::geography)
);
create index idx_gridfinder_input_powerlines_hasc on gridfinder_input_powerlines (hasc_wiki);


-- extract country boundries as AOI for gridfinder processing
drop table if exists gridfinder_input_aoi;
create table gridfinder_input_aoi as (
    select distinct
        hasc_wiki
    from
        public.kontur_boundaries
    where
        kontur_admin_level = 2
);
