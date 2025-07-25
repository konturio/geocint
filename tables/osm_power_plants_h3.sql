drop table if exists osm_power_plants_h3_in;
create table osm_power_plants_h3_in as (
    select ST_PointOnSurface(geog::geometry) as geom,
           parse_float(regexp_replace(coalesce(tags->>'plant:output:electricity', tags->>'generator:output:electricity', tags->>'output:electricity', tags->>'output'), '[^0-9\.-]', '', 'g')) as output_mw
    from osm
    where tags @> '{"power":"plant"}'
);

drop table if exists osm_power_plants_h3;
create table osm_power_plants_h3 as (
    select h3_lat_lng_to_cell(geom::point, 8) as h3,
           count(*) as osm_power_plants_count,
           sum(output_mw) as osm_power_plants_capacity_mw,
           8 as resolution
    from (
        select distinct on (h3_lat_lng_to_cell(geom::point, 11)) geom, output_mw
        from osm_power_plants_h3_in
    ) s
    group by 1
);

drop table if exists osm_power_plants_h3_in;

call generate_overviews('osm_power_plants_h3', '{osm_power_plants_count,osm_power_plants_capacity_mw}'::text[], '{sum,sum}'::text[], 8);

create index on osm_power_plants_h3 (h3);
