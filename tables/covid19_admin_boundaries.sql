drop table if exists covid19_admin;
create table covid19_admin (
    id       serial,
    province text,
    country  text,
    geog     geography,
    bounds   geometry,
    tags     jsonb,
    area     float,
    population int
);

insert into covid19_admin (geog, province, country)
select distinct ST_SetSRID(ST_MakePoint(lon, lat), 4326), province, country
from
    covid19_in;

update covid19_admin set geog = 'SRID=4326;POINT( 15.3136 -4.3276 )' where country like 'Congo%';
update covid19_admin set geog = 'SRID=4326;POINT( -144.2731 -16.4381 )' where province like '%Polynesia';
update covid19_admin set geog = 'SRID=4326;POINT( 114.9042 33.882 )' where province like 'Henan'
                                                                           and country like 'China';

drop table if exists tmp_all_admin;
create table tmp_all_admin as ( select tags, geog from osm where tags @> '{"boundary":"administrative"}'
                                                              or tags @> '{"boundary":"maritime"}');
create index on tmp_all_admin using gist (geog);
create index on tmp_all_admin using gin (tags);
delete from tmp_all_admin where ST_GeometryType(geog::geometry) = 'ST_Point';
delete from tmp_all_admin where ST_GeometryType(geog::geometry) = 'ST_LineString';
update covid19_admin a
set
    (bounds, tags, area) = ( select geog::geometry, tags, ST_Area(geog)
                             from
                                 tmp_all_admin o
                             where
                                 --          not tags @> '{"admin_level":"2"}' and
                                 _ST_DWithinUncached(a.geog, o.geog, 100000)
                             order by
                                 least(
                                     levenshtein(coalesce(province, country), tags ->> 'name:en'),
                                     levenshtein(coalesce(province, country), tags ->> 'int_name'),
                                     levenshtein(coalesce(province, country), tags ->> 'name'),
                                     levenshtein(province || ' (' || country || ')', tags ->> 'name'), -- Saint-Martin (France)
                                     levenshtein(province || ' County', tags ->> 'name'), -- Minnehaha, SD is not Minnesota
                                     levenshtein('Republic ' || replace(coalesce(province, country), ', South', ''),
                                                 tags ->> 'official_name:en') -- "Korea, South" is "South Korea"
                                     ),
                                 _ST_DistanceUncached(a.geog, o.geog),
                                 ST_Area(geog) desc
                             limit 1
    );
create index on covid19_admin using gist (bounds);

drop table if exists covid19_admin_subdivided;
create table covid19_admin_subdivided as ( select id, ST_Subdivide(bounds) as geom, area
                                           from
                                               covid19_admin
                                           order by 2 );
create index on covid19_admin_subdivided using gist (geom);

update covid19_admin_subdivided a
set
    geom = ST_Difference(geom, ( select ST_Union(geom)
                                 from
                                     covid19_admin_subdivided b
                                 where
                                       ST_Intersects(a.geom, b.geom)
                                   and a.area > b.area ))
where
    exists(select from covid19_admin_subdivided b where ST_Intersects(a.geom, b.geom) and a.area > b.area);


with
    complex_areas_to_subdivide as (
        delete from covid19_admin_subdivided
            where ST_NPoints(geom) > 100
            returning id, area, geom
    )
insert
into covid19_admin_subdivided (id, area, geom)
select
    id, area,
    ST_Subdivide(geom) as geom
from
    complex_areas_to_subdivide;

vacuum full covid19_admin_subdivided;

drop table if exists tmp_all_admin;