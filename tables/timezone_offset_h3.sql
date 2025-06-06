-- timezone offsets from OSM timezone tag
drop table if exists timezone_points;

create table timezone_points as
select
    ST_PointOnSurface(geog::geometry) as geom,
    tags ->> 'timezone'               as tz
from osm
where tags ? 'timezone';

drop table if exists timezone_offset_h3;

create table timezone_offset_h3 as
select
    h3_lat_lng_to_cell(geom::point, 8) as h3,
    avg(
        extract(timezone
                from (now() at time zone 'UTC') at time zone
                    case
                        when tz = 'Europe/Pristina' then 'Europe/Belgrade'
                        else tz
                    end
        ) / 3600.0
    ) as utc_offset,
    8 as resolution
from timezone_points
where tz is not null
group by 1;

create index on timezone_offset_h3(h3);

drop table if exists timezone_points;

call generate_overviews('timezone_offset_h3', '{utc_offset}'::text[], '{avg}'::text[], 8);
