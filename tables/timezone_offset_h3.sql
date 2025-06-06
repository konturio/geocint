-- timezone offsets from OSM timezone tag
drop table if exists timezone_in;
create table timezone_in as (
    select osm_id,
           ST_Subdivide(ST_Transform(ST_Normalize(o.geog::geometry),3857)) as geom,
           extract(timezone from (now() at time zone 'UTC') at time zone
                           case
                               when tags ->> 'timezone' = 'Europe/Pristina' then 'Europe/Belgrade'
                               else tags ->> 'timezone'
                           end
                  ) / 3600.0                                               as utc_offset
    from osm o
    where tags ? 'timezone' and tags ->> 'timezone' is not null
);

create index on timezone_in using gist(geom);

drop table if exists timezone_offset_h3;
create table timezone_offset_h3 as (
	select distinct on (l.h3) l.h3       as h3, 
	                          utc_offset,
	                          8::integer as resolution
    from timezone_in o,
         land_polygons_h3_r8 l
    where o.geom && l.geom and ST_Intersects(o.geom, l.geom)
    order by l.h3, o.osm_id desc
);

call generate_overviews('timezone_offset_h3', '{utc_offset}'::text[], '{avg}'::text[], 8);

create index on timezone_offset_h3(h3);

drop table if exists timezone_points;
