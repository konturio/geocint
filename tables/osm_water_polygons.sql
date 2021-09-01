drop table if exists osm_water_polygons_unsorted;
create table osm_water_polygons_unsorted as (
    select osm_type,
           osm_id,
           geom
    from osm_water_polygons_in_subdivided

    union all

    select 'oceans' as osm_type,
           gid as osm_id,
           geom
    from water_polygons_vector

    union all

    select osm_type,
           osm_id,
           geom
    from osm_water_lines_buffers_subdivided
);

drop table if exists osm_water_polygons;
create table osm_water_polygons as (
    select *
    from osm_water_polygons_unsorted
    order by _ST_SortableHash(geom)
);
drop table osm_water_polygons_unsorted;
vacuum analyze osm_water_polygons;
create index on osm_water_polygons using gist (geom);

drop table if exists osm_water_polygons_in_subdivided;
drop table if exists osm_water_lines_buffers_subdivided;
