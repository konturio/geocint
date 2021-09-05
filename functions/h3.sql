drop function if exists st_hexagonfromh3(h3 h3index);
create or replace function ST_HexagonFromH3(h3 h3index)
    returns table
    (
        geom geometry,
        area float
    )
    language sql
    immutable strict parallel safe
as
$function$
select
    ST_ClipByBox2D(
        ST_QuantizeCoordinates(
            ST_Transform(
                case
                    when hex_raw::geometry && 'BOX(0 -87, 0 87)'::box2d and
                         not _ST_DWithinUncached(hex_raw::geography, 'SRID=4326;LINESTRING(0 -87, 0 87)'::geography, 0)
                        then
                        ST_WrapX(
                            ST_ShiftLongitude(hex.geom),
                            180,
                            -360)
                    else hex.geom
                end,
                3857
                ),
            1
            ),
        'BOX(-20037510 -20037510,20037510 20037510)'
        ),
    ST_Area(hex_raw::geography)
from
        ( select h3_to_geo_boundary_geometry(h3) as hex_raw ) hex_raw_geog
        join lateral (
                 select
                     case
                         when h3_get_resolution(h3) < 3 then ST_Segmentize(hex_raw::geography, 200000)::geometry
                         else hex_raw
                     end as geom
                 ) as                                         hex on true;
$function$;


create or replace function ST_Safe_HexagonFromH3(h3 h3index)
    returns table
    (
        geom geometry,
        area float
    )
    language plpgsql
    immutable strict parallel restricted
as
$$
begin
    return query select ST_HexagonFromH3(h3);
exception
    when others then
        raise exception 'h3: %s' , h3;

end;
$$;


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
select h3_to_parent(hex, res), res
from
    ( select h3_geo_to_h3(ST_Transform(ST_StartPoint(geom), 4326)::point, max_resolution) as hex ) hex,
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
select h3_to_parent(hex, res), res
from
    ( select
          h3_geo_to_h3(ST_StartPoint(geog::geometry)::point, max_resolution) as hex ) hex,
    generate_series(0, max_resolution)             res
$function$;
