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
select ST_ClipByBox2D(
           ST_Transform(
               case
                   when hex_raw::geometry && 'BOX(0 -87, 0 87)'::box2d and
                        not _ST_DWithinUncached(hex_raw::geography, 'SRID=4326;LINESTRING(0 -87, 0 87)'::geography, 0) then
                       ST_WrapX(
                           ST_ShiftLongitude(hex.geom),
                           180,
                           -360)
                   else hex.geom
                   end,
               3857
               ),
           'BOX(-20037510 -20037510,20037510 20037510)'
           ),
       ST_Area(hex_raw::geography)
from (select h3_to_geo_boundary_geometry(h3) as hex_raw) hex_raw_geog
         join lateral (
    select case
               when h3_get_resolution(h3) < 3 then ST_Segmentize(hex_raw::geography, 200000)::geometry
               else hex_raw end as geom
    ) as hex on true;
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
select h3_geo_to_h3(ST_Transform(ST_PointOnSurface(geom), 4326), res), res
from generate_series(0, max_resolution) res
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
select h3_geo_to_h3(pt, res), res
from ST_Dimension(geog::geometry) dim,
     lateral (select case
                         when dim = 0 then geog::geometry
                         when dim = 1 then ST_StartPoint(geog::geometry)
                         else ST_PointOnSurface(geog::geometry) end::point as pt) as point,
     generate_series(0, max_resolution) res
$function$;


drop function if exists ST_H3Fill(geom geometry, max_resolution integer);

create or replace function ST_H3Fill(geom geometry, max_resolution integer default 8)
    returns table
            (
                h3         h3index,
                resolution integer
            )
    language plpgsql
    immutable strict parallel safe
as
$function$
declare
    z            integer;
    polyfills    h3index[];
    result_array h3index[];
begin
    for z in (select generate_series(0, max_resolution))
        loop
            select ARRAY(select h3_polyfill(ST_Transform(geom, 4326), z)) into polyfills;
            if COALESCE(array_length(polyfills, 1), 0) = 0 then
                select ARRAY(select h3_geo_to_h3(ST_Transform(ST_PointOnSurface(geom), 4326), z)) into polyfills;
                result_array = result_array || polyfills;
            else
                result_array = result_array || polyfills;
            end if;
        end loop;
    return query select u, h3_get_resolution(u) from unnest(result_array) u;
end;
$function$;