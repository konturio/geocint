drop table if exists osm_road_segments_new_unsorted;
create table osm_road_segments_new_unsorted as (
    select
        seg_id,
        node_from,
        node_to,
        -- TODO: elevation profile
        length_m as length,
        length_m / walk_speed as walk_time,
        length_m / drive_speed as drive_time,
        seg_geom
    from
        osm_roads                                                       as o,
        osm_way_nodes_to_segments(geom, way_nodes, osm_id)              as z,

        -- TODO: investigate why ST_Length(geography) consumes inappropriate amount of memory
        -- ST_Length(z.seg_geom::geography)                   as length_m

        -- using dirty mercator*coslat distance as substitute to geography distance.
        -- cosine is taken from whole way.
        -- typical error ratio compared to geography length is 1e-6.
        lateral (select
                         ST_Length(ST_Transform(z.seg_geom, 3857)) *
                         cosd(ST_X(ST_StartPoint(o.geom))) as length_m) as l
    where
         walk_speed is not null
      or drive_speed is not null
);

drop table if exists osm_road_segments_new;
create table osm_road_segments_new as (
    select *
    from osm_road_segments_new_unsorted
    -- ordering by segment geometry is required for BRIN index to work.
    order by seg_geom
);

drop table osm_road_segments_new_unsorted;