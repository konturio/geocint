drop table if exists facebook_roads_h3;
create table facebook_roads_h3 tablespace evo4tb as (
    select 8::int                                        as resolution,
           h3_geo_to_h3(ST_StartPoint(s.geom)::point, 8) as h3,
           sum(ST_Length(s.geom::geography))             as fb_roads_length
    from facebook_roads r,
         ST_DumpSegments(r.geom) s
    group by h3
);
