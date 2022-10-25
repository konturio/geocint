drop table if exists osm_road_segments_6_months_h3;

create table osm_road_segments_6_months_h3 tablespace evo4tb as (
    select
        resolution,
        h3,
        sum(length) as highway_length_6_months
    from osm_road_segments_6_months
    group by h3, resolution);
