create or replace function ST_H3Bucket(geom geometry, max_resolution integer default 8)
    returns table
    (
        h3         h3index,
        resolution integer
    )
    language sql
    immutable strict parallel safe
as
$function$
select h3_cell_to_parent(hex, res), res
from
    ( select h3_lat_lng_to_cell(ST_Transform(ST_StartPoint(geom), 4326)::point, max_resolution) as hex ) hex,
    generate_series(0, max_resolution)                                                                 res
$function$;

create or replace function ST_H3Bucket(geog geography, max_resolution integer default 8)
    returns table
    (
        h3         h3index,
        resolution integer
    )
    language sql
    immutable strict parallel safe
as
$function$
select h3_cell_to_parent(hex, res), res
from
    ( select
          h3_lat_lng_to_cell(ST_StartPoint(geog::geometry)::point, max_resolution) as hex ) hex,
    generate_series(0, max_resolution)             res
$function$;
