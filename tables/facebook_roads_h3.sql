drop table if exists facebook_roads_h3;
create table facebook_roads_h3  as (
    select 8::int                                        as resolution,
           h3_lat_lng_to_cell(ST_StartPoint(s.geom)::point, 8) as h3,
           sum(ST_Length(s.geom::geography))             as fb_roads_length
    from facebook_roads r,
         ST_DumpSegments(r.geom) s
    group by h3
);
