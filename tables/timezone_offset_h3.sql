-- timezone offsets from OSM timezone tag
drop table if exists timezone_in;
create table timezone_in as (
    select osm_id,
           ST_Subdivide(ST_Transform(ST_Normalize(o.geog::geometry),3857)) as geom,
           tags ->> 'timezone'                                             as tz
    from osm o
    where tags ? 'timezone'
);

create index on timezone_in using gist(geom);

drop table if exists timezone;
create table timezone as (
	select distinct on (l.h3) l.h3 as h3, 
	       tz
    from timezone_in o
    join land_polygons_h3_r8 l
      on ST_Intersects(o.geom, l.geom)
    order by l.h3, o.osm_id desc
);

-- drop table if exists timezone_in;

drop table if exists timezone_offset_h3;
create table timezone_offset_h3 as (
	select h3,
           extract(timezone from (now() at time zone 'UTC') at time zone
                           case
                               when tz = 'Europe/Pristina' then 'Europe/Belgrade'
                               else tz
                           end
                  ) / 3600.0 as utc_offset,
           8                 as resolution
    from timezone_points
    where tz is not null
);

call generate_overviews('timezone_offset_h3', '{utc_offset}'::text[], '{avg}'::text[], 8);

create index on timezone_offset_h3(h3);

drop table if exists timezone_points;
