drop table if exists timezone_in_lines_points;
create table timezone_in_lines_points as (
    select h3_lat_lng_to_cell(ST_PointOnSurface(ST_Normalize(o.geog::geometry))::point, 8) as h3,
           osm_id,
           o.tags ->> 'name',
           extract(epoch from (now() at time zone 
                      case
                          when tags ->> 'timezone' = 'Europe/Pristina' then 'Europe/Belgrade'
                          else tags ->> 'timezone'
                      end) - now() at time zone 'UTC') / 3600.0                           as utc_offset
    from osm o
    where tags ? 'timezone' 
          and tags ->> 'timezone' is not null
          and GeometryType(o.geog::geometry) not in ('POLYGON', 'MULTIPOLYGON')
);

drop table if exists timezone_in;
create table timezone_in as (
    select h3_polygon_to_cells(ST_Subdivide(ST_Normalize(o.geog::geometry)), 8) as h3,
           osm_id,
           extract(epoch from (now() at time zone 
                      case
                          when tags ->> 'timezone' = 'Europe/Pristina' then 'Europe/Belgrade'
                          else tags ->> 'timezone'
                      end) - now() at time zone 'UTC') / 3600.0                           as utc_offset
    from osm o
    where tags ? 'timezone' 
          and tags ->> 'timezone' is not null
          and GeometryType(o.geog::geometry) in ('POLYGON', 'MULTIPOLYGON')
    union all
    select h3,
           osm_id,
           utc_offset
    from timezone_in_lines_points
);

create index on timezone_in (h3, osm_id);

drop table if exists timezone_in_lines_points;

drop table if exists timezone_offset_h3;
create table timezone_offset_h3 as (
	select distinct on (l.h3) l.h3       as h3, 
	                          utc_offset,
	                          8::integer as resolution
    from timezone_in l
    order by l.h3, l.osm_id desc
);

call generate_overviews('timezone_offset_h3', '{utc_offset}'::text[], '{avg}'::text[], 8);

drop table if exists timezone_in;
