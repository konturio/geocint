drop table if exists facebook_roads_in_h3_r8;
create table facebook_roads_in_h3_r8 tablespace evo4tb as (
    select 8::int                                        as resolution,
           h3_lat_lng_to_cell(ST_StartPoint(s.geom)::point, 8) as h3,
           sum(ST_Length(s.geom::geography))             as fb_roads_in_length
    from facebook_roads_in r,
         ST_DumpSegments(r.geom) s
    group by h3
);
